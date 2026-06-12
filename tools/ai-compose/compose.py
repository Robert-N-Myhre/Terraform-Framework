#!/usr/bin/env python3
"""Compose a new Terraform project from framework modules using a local LLM.

Talks to any OpenAI-compatible chat endpoint (Ollama, LM Studio, llama.cpp
server, vLLM). Stdlib only.

Pipeline (see registry/README.md):
  1. SELECT - feed registry/index.json catalog, model picks module ids
  2. COPY   - copy chosen module dirs into the new project (deterministic)
  3. WIRE   - feed only the chosen manifests, model writes root main.tf/
              variables.tf/outputs.tf
  4. GATE   - terraform fmt + init -backend=false + validate; on failure,
              feed the error back for up to --max-repairs repair rounds

Examples:
  # Ollama (default url): qwen2.5-coder against an AWS task
  python3 tools/ai-compose/compose.py \
      "VPC with private subnets in us-east-1 plus a private DNS zone" \
      --out ~/projects/my-network --model qwen2.5-coder:14b

  # Print the selection prompt to paste into any chat UI, then exit
  python3 tools/ai-compose/compose.py "..." --out /tmp/x --dry-run

  # Skip selection if you already know the modules
  python3 tools/ai-compose/compose.py "..." --out /tmp/x \
      --modules aws/core-network,aws/dns/private-zones

NOTE (Ollama): the OpenAI-compatible endpoint cannot set the context window
per-request. Run the server with a window large enough for the wire prompt,
e.g.:  OLLAMA_CONTEXT_LENGTH=16384 ollama serve
A truncated context fails silently and is the #1 cause of bad wiring.
"""

import argparse
import json
import re
import shutil
import subprocess
import sys
import urllib.error
import urllib.request
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent.parent
REGISTRY = REPO_ROOT / "registry"
PROMPTS = Path(__file__).resolve().parent / "prompts"

ROOT_FILES = ("main.tf", "variables.tf", "outputs.tf")


def render(template_name, **tokens):
    text = (PROMPTS / template_name).read_text()
    for key, value in tokens.items():
        text = text.replace("{" + key + "}", value)
    return text


def chat(args, prompt):
    payload = json.dumps(
        {
            "model": args.model,
            "messages": [{"role": "user", "content": prompt}],
            "temperature": 0,
            "stream": False,
        }
    ).encode()
    req = urllib.request.Request(
        args.url.rstrip("/") + "/chat/completions",
        data=payload,
        headers={"Content-Type": "application/json"},
    )
    try:
        with urllib.request.urlopen(req, timeout=args.timeout) as resp:
            body = json.load(resp)
    except urllib.error.URLError as e:
        sys.exit(f"error: cannot reach model at {args.url} ({e.reason})")
    return body["choices"][0]["message"]["content"]


def load_index():
    return json.loads((REGISTRY / "index.json").read_text())


def catalog_lines(index):
    lines = []
    for m in index["modules"]:
        req = ",".join(m["required_inputs"]) or "-"
        outs = ",".join(m["outputs"])
        lines.append(f"- {m['id']} — {m['summary']} | requires: {req} | outputs: {outs}")
    return "\n".join(lines)


def select_modules(args, index):
    prompt = render("select.txt", task=args.task, catalog=catalog_lines(index))
    if args.dry_run:
        print(prompt)
        sys.exit(0)
    reply = chat(args, prompt)
    m = re.search(r"\[.*?\]", reply, re.DOTALL)
    if not m:
        sys.exit(f"error: no JSON array in selection reply:\n{reply}")
    ids = json.loads(m.group(0))
    known = {mod["id"] for mod in index["modules"]}
    bad = [i for i in ids if i not in known]
    if bad:
        sys.exit(f"error: model selected unknown module ids: {bad}")
    return ids


def copy_modules(ids, out_dir):
    for mid in ids:
        src = REPO_ROOT / "modules" / mid
        dst = out_dir / "modules" / mid
        if dst.exists():
            shutil.rmtree(dst)
        shutil.copytree(src, dst)


def manifests_blob(ids):
    docs = [
        json.loads((REGISTRY / "manifests" / f"{mid}.json").read_text())
        for mid in ids
    ]
    return json.dumps(docs, indent=1)


def parse_files(reply):
    """Parse '=== FILE: name ===' delimited blocks; tolerate stray fences."""
    files = {}
    for m in re.finditer(
        r"^=== FILE: (\S+) ===\n(.*?)(?=^=== (?:FILE:|END))", reply, re.DOTALL | re.MULTILINE
    ):
        content = m.group(2)
        content = re.sub(r"^```\w*\n|^```$\n?", "", content, flags=re.MULTILINE)
        files[m.group(1)] = content.rstrip() + "\n"
    return files


def write_files(files, out_dir):
    for name, content in files.items():
        if "/" in name or name.startswith("."):
            sys.exit(f"error: model emitted unsafe filename: {name}")
        (out_dir / name).write_text(content)


def run_gate(out_dir):
    """Return None on success, else combined error text."""
    subprocess.run(
        ["terraform", "fmt", "-recursive"], cwd=out_dir, capture_output=True
    )
    for cmd in (
        ["terraform", "init", "-backend=false", "-input=false", "-no-color"],
        ["terraform", "validate", "-no-color"],
    ):
        r = subprocess.run(cmd, cwd=out_dir, capture_output=True, text=True)
        if r.returncode != 0:
            return f"$ {' '.join(cmd)}\n{r.stdout}{r.stderr}"
    return None


def files_blob(out_dir):
    parts = []
    for name in ROOT_FILES:
        p = out_dir / name
        if p.exists():
            parts.append(f"=== FILE: {name} ===\n{p.read_text()}")
    return "\n".join(parts) + "=== END ==="


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("task", help="plain-language description of what to deploy")
    ap.add_argument("--out", required=True, help="directory for the new project")
    ap.add_argument("--model", default="qwen2.5-coder:14b")
    ap.add_argument("--url", default="http://localhost:11434/v1",
                    help="OpenAI-compatible base url (default: local Ollama)")
    ap.add_argument("--modules", help="comma-separated ids; skips SELECT stage")
    ap.add_argument("--max-repairs", type=int, default=3)
    ap.add_argument("--timeout", type=int, default=600, help="per-request seconds")
    ap.add_argument("--no-validate", action="store_true",
                    help="skip the terraform gate (e.g. no network for init)")
    ap.add_argument("--dry-run", action="store_true",
                    help="print the SELECT prompt and exit")
    args = ap.parse_args()

    index = load_index()
    out_dir = Path(args.out).expanduser().resolve()

    # 1. SELECT
    if args.modules and not args.dry_run:
        ids = args.modules.split(",")
        known = {m["id"] for m in index["modules"]}
        bad = [i for i in ids if i not in known]
        if bad:
            sys.exit(f"error: unknown module ids: {bad}")
    else:
        ids = select_modules(args, index)
    print(f"selected: {', '.join(ids)}")

    # 2. COPY (deterministic - the model never touches module internals)
    out_dir.mkdir(parents=True, exist_ok=True)
    copy_modules(ids, out_dir)
    print(f"copied {len(ids)} module(s) -> {out_dir}/modules/")

    # 3. WIRE
    manifests = manifests_blob(ids)
    reply = chat(args, render("wire.txt", task=args.task, manifests=manifests))
    files = parse_files(reply)
    missing = [f for f in ROOT_FILES if f not in files]
    if missing:
        sys.exit(f"error: model reply missing {missing}; got: {list(files)}\n{reply}")
    write_files(files, out_dir)
    print(f"wrote root files: {', '.join(files)}")

    # 4. GATE + repair loop
    if args.no_validate:
        print("skipped terraform gate (--no-validate); run validate yourself")
        return
    for attempt in range(args.max_repairs + 1):
        error = run_gate(out_dir)
        if error is None:
            print("terraform validate: PASS")
            return
        if attempt == args.max_repairs:
            print(error)
            sys.exit(f"error: still failing after {args.max_repairs} repair round(s)")
        print(f"validate failed; repair round {attempt + 1}/{args.max_repairs}")
        reply = chat(
            args,
            render("repair.txt", error=error, files=files_blob(out_dir),
                   manifests=manifests),
        )
        fixed = parse_files(reply)
        if not fixed:
            sys.exit(f"error: unparseable repair reply:\n{reply}")
        write_files(fixed, out_dir)


if __name__ == "__main__":
    main()
