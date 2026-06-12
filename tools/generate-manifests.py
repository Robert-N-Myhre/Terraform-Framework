#!/usr/bin/env python3
"""Generate machine-readable module manifests for AI-assisted composition.

Walks modules/<cloud>/... and emits:
  registry/index.json                     - compact catalog for module SELECTION
  registry/manifests/<cloud>/<module>.json - full interface for module WIRING

Stdlib only. Relies on the repo convention that all .tf files are
`terraform fmt`-formatted (enforced in CI), which keeps the HCL subset
parsed here predictable: one attribute per line, standard block layout.

Usage:  python3 tools/generate-manifests.py [--check]
        --check  exit 1 if the committed registry differs from regenerated
                 output (for CI), without writing anything.
"""

import json
import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
MODULES_DIR = REPO_ROOT / "modules"
REGISTRY_DIR = REPO_ROOT / "registry"

# Universal governance contract (docs/adr/002).
GOVERNANCE_INPUTS = (
    "prefix",
    "environment",
    "owner",
    "cost_center",
    "additional_tags",
    "name_suffix",
)


def scan_block(text, start):
    """Return index just past the brace-balanced block opening at text[start] == '{'.

    Tracks double-quoted strings (with escapes) and ${...} interpolations so
    braces inside string literals do not break the count.
    """
    assert text[start] == "{"
    i = start
    depth = 0          # brace depth in code
    stack = []         # 'string' / interp brace counters
    in_string = False
    interp_depth = []  # brace depth within each open interpolation
    while i < len(text):
        c = text[i]
        if in_string:
            if c == "\\":
                i += 2
                continue
            if c == '"':
                in_string = False
            elif c == "$" and text[i : i + 2] == "${":
                in_string = False
                interp_depth.append(0)
                stack.append("interp")
                i += 1
        else:
            if c == "#" or text[i : i + 2] == "//":
                i = text.find("\n", i)
                if i == -1:
                    break
                continue
            heredoc = re.match(r"<<-?(\w+)\n", text[i:])
            if heredoc:
                marker = heredoc.group(1)
                m = re.search(
                    rf"^\s*{marker}\s*$", text[i + heredoc.end() :], re.MULTILINE
                )
                if not m:
                    raise ValueError(f"unterminated heredoc {marker}")
                i += heredoc.end() + m.end()
                continue
            if c == '"':
                in_string = True
            elif c == "{":
                if stack and stack[-1] == "interp":
                    interp_depth[-1] += 1
                else:
                    depth += 1
            elif c == "}":
                if stack and stack[-1] == "interp":
                    if interp_depth[-1] == 0:
                        stack.pop()
                        interp_depth.pop()
                        in_string = True
                    else:
                        interp_depth[-1] -= 1
                else:
                    depth -= 1
                    if depth == 0:
                        return i + 1
        i += 1
    raise ValueError(f"unbalanced block starting at offset {start}")


def find_blocks(text, kind):
    """Yield (label, body) for each top-level `kind "label" { ... }` block."""
    for m in re.finditer(rf'^{kind}\s+"([^"]+)"\s*{{', text, re.MULTILINE):
        open_brace = m.end() - 1
        end = scan_block(text, open_brace)
        yield m.group(1), text[open_brace + 1 : end - 1]


def attr_string(body, name):
    """Extract a string attribute: single-line quoted or heredoc."""
    m = re.search(rf'^\s*{name}\s*=\s*"(.*)"\s*$', body, re.MULTILINE)
    if m:
        return m.group(1)
    m = re.search(
        rf"^\s*{name}\s*=\s*<<-?(\w+)\n(.*?)\n\s*\1\s*$",
        body,
        re.MULTILINE | re.DOTALL,
    )
    if m:
        lines = [ln.strip() for ln in m.group(2).splitlines()]
        return " ".join(ln for ln in lines if ln)
    return None


def attr_bool(body, name):
    m = re.search(rf"^\s*{name}\s*=\s*(true|false)\s*$", body, re.MULTILINE)
    return m.group(1) == "true" if m else None


def attr_raw(body, name):
    """Extract a possibly multi-line attribute expression, whitespace-collapsed."""
    m = re.search(rf"^(\s*){name}\s*=\s*", body, re.MULTILINE)
    if not m:
        return None
    start = m.end()
    # Consume until brackets/braces/parens balance and the line ends.
    depth = 0
    in_string = False
    i = start
    kept = []
    while i < len(body):
        c = body[i]
        if in_string:
            if c == "\\":
                kept.append(body[i : i + 2])
                i += 2
                continue
            if c == '"':
                in_string = False
        elif c == "#" or body[i : i + 2] == "//":
            nl = body.find("\n", i)
            i = len(body) if nl == -1 else nl
            continue
        elif c == '"':
            in_string = True
        elif c in "{[(":
            depth += 1
        elif c in "}])":
            depth -= 1
        elif c == "\n" and depth == 0:
            break
        kept.append(c)
        i += 1
    return re.sub(r"\s+", " ", "".join(kept).strip())


def parse_variables(path):
    if not path.exists():
        return []
    text = path.read_text()
    variables = []
    for name, body in find_blocks(text, "variable"):
        default = attr_raw(body, "default")
        var = {
            "name": name,
            "type": attr_raw(body, "type") or "any",
            "description": attr_string(body, "description") or "",
            "required": default is None,
        }
        if default is not None:
            var["default"] = default
        if attr_bool(body, "sensitive"):
            var["sensitive"] = True
        if re.search(r"^\s*validation\s*{", body, re.MULTILINE):
            var["has_validation"] = True
        variables.append(var)
    return variables


def parse_outputs(path):
    if not path.exists():
        return []
    text = path.read_text()
    outputs = []
    for name, body in find_blocks(text, "output"):
        out = {"name": name, "description": attr_string(body, "description") or ""}
        if attr_bool(body, "sensitive"):
            out["sensitive"] = True
        outputs.append(out)
    return outputs


def parse_versions(path):
    info = {"required_version": None, "providers": {}}
    if not path.exists():
        return info
    text = path.read_text()
    m = re.search(r'required_version\s*=\s*"([^"]+)"', text)
    if m:
        info["required_version"] = m.group(1)
    rp = re.search(r"required_providers\s*{", text)
    if rp:
        end = scan_block(text, rp.end() - 1)
        body = text[rp.end() : end - 1]
        for pm in re.finditer(r"(\w+)\s*=\s*{", body):
            pend = scan_block(body, pm.end() - 1)
            pbody = body[pm.end() : pend - 1]
            info["providers"][pm.group(1)] = {
                "source": attr_string(pbody, "source"),
                "version": attr_string(pbody, "version"),
            }
    return info


def parse_readme(path):
    """Return (title, summary): first heading and first prose paragraph."""
    if not path.exists():
        return None, None
    title = None
    summary_lines = []
    for line in path.read_text().splitlines():
        stripped = line.strip()
        if title is None:
            if stripped.startswith("#"):
                title = stripped.lstrip("# ").strip()
            continue
        if stripped.startswith("#") and summary_lines:
            break
        if stripped and not stripped.startswith("#"):
            summary_lines.append(stripped)
        elif not stripped and summary_lines:
            break
    return title, " ".join(summary_lines) or None


def discover_modules():
    """Leaf module = any directory under modules/ containing main.tf."""
    return sorted(
        p.parent for p in MODULES_DIR.rglob("main.tf")
    )


def build_manifest(module_dir):
    rel = module_dir.relative_to(MODULES_DIR)
    parts = rel.parts  # (cloud, domain, name) or (cloud, name) for core-network
    cloud = parts[0]
    domain = parts[1] if len(parts) > 2 else parts[-1]
    name = parts[-1]

    title, summary = parse_readme(module_dir / "README.md")
    versions = parse_versions(module_dir / "versions.tf")
    all_vars = parse_variables(module_dir / "variables.tf")

    governance = [v for v in all_vars if v["name"] in GOVERNANCE_INPUTS]
    specific = [v for v in all_vars if v["name"] not in GOVERNANCE_INPUTS]

    return {
        "id": str(rel),
        "path": f"modules/{rel}",
        "cloud": cloud,
        "domain": domain,
        "name": name,
        "title": title,
        "summary": summary,
        "terraform": {"required_version": versions["required_version"]},
        "providers": versions["providers"],
        "inputs": {"governance": governance, "module": specific},
        "outputs": parse_outputs(module_dir / "outputs.tf"),
    }


def build_index(manifests):
    modules = [
        {
            "id": m["id"],
            "path": m["path"],
            "cloud": m["cloud"],
            "domain": m["domain"],
            "title": m["title"],
            "summary": m["summary"],
            "providers": {
                k: v["version"] for k, v in m["providers"].items()
            },
            "required_inputs": [
                v["name"] for v in m["inputs"]["module"] if v["required"]
            ],
            "outputs": [o["name"] for o in m["outputs"]],
            "manifest": f"registry/manifests/{m['id']}.json",
        }
        for m in manifests
    ]
    return {
        "generated_by": "tools/generate-manifests.py",
        "conventions": {
            "governance_inputs": list(GOVERNANCE_INPUTS),
            "naming_pattern": "{prefix}-{cloud}-{environment}-{resource-type}-{suffix}",
            "composition_rule": (
                "Modules never reference each other (docs/adr/001). Compose in a "
                "root module by wiring one module's outputs into another's "
                "inputs, as in examples/."
            ),
            "interface_contract": "docs/adr/002-convention-based-interface.md",
        },
        "module_count": len(modules),
        "modules": modules,
    }


def render(manifests):
    """Return {relative_path: json_text} for every registry file."""
    files = {
        "registry/index.json": json.dumps(build_index(manifests), indent=2) + "\n"
    }
    for m in manifests:
        files[f"registry/manifests/{m['id']}.json"] = json.dumps(m, indent=2) + "\n"
    return files


def main():
    check = "--check" in sys.argv
    manifests = [build_manifest(d) for d in discover_modules()]
    files = render(manifests)

    if check:
        stale = []
        for rel, content in files.items():
            p = REPO_ROOT / rel
            if not p.exists() or p.read_text() != content:
                stale.append(rel)
        existing = {
            str(p.relative_to(REPO_ROOT))
            for p in REGISTRY_DIR.rglob("*.json")
        } if REGISTRY_DIR.exists() else set()
        orphaned = sorted(existing - set(files))
        if stale or orphaned:
            for rel in stale:
                print(f"stale: {rel}")
            for rel in orphaned:
                print(f"orphaned: {rel}")
            print("\nRegistry out of date. Run: python3 tools/generate-manifests.py")
            sys.exit(1)
        print(f"registry up to date ({len(manifests)} modules)")
        return

    for rel, content in files.items():
        p = REPO_ROOT / rel
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text(content)
    print(f"wrote registry for {len(manifests)} modules -> registry/")


if __name__ == "__main__":
    main()
