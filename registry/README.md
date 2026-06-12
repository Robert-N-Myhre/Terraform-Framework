# Module Registry

Machine-readable manifests of every leaf module's interface, generated from
the HCL source. The registry exists so that an AI assistant (hosted or local)
can compose modules from this framework into a new project **without reading
raw `.tf` files** — selection and wiring decisions are made from small,
structured JSON instead.

## Layout

| File | Purpose | Size |
|------|---------|------|
| `index.json` | Catalog of all modules: id, summary, providers, required inputs, output names. Use for **selection**. | ~38 KB |
| `manifests/<cloud>/<...>/<module>.json` | Full interface of one module: every input (type, description, default, required), every output, provider pins. Use for **wiring**. | ~5–15 KB each |

Manifests are generated — do not edit them by hand. Regenerate after any
change to a module's `variables.tf`, `outputs.tf`, `versions.tf`, or README:

```sh
python3 tools/generate-manifests.py          # rewrite registry/
python3 tools/generate-manifests.py --check  # CI: fail if stale
```

The generator is stdlib-only Python; it relies on `terraform fmt`-formatted
source (enforced in this repo).

## Recommended AI workflow

The two-stage split keeps context small enough for local models:

1. **Select** — load only `index.json`. Choose modules by cloud/domain/summary.
   Note the `composition_rule` and `governance_inputs` in the `conventions`
   block.
2. **Wire** — load only the chosen modules' manifest files. Generate a root
   module that:
   - copies (or sources by relative path) each module directory verbatim;
   - passes the six governance inputs to every module;
   - satisfies each manifest's `required: true` inputs, wiring one module's
     `outputs` into another's inputs in the root (modules never reference each
     other — see `docs/adr/001`);
   - pins providers per the manifest's `providers` block.
3. **Gate** — never trust generated HCL unvalidated:

   ```sh
   terraform fmt -check -recursive
   terraform init -backend=false && terraform validate
   ```

   Feed any error output back to the model and iterate.

Worked examples of correct composition live in [`examples/`](../examples/) —
`examples/aws/core-network-with-dns` shows the output→input wiring pattern.

A ready-to-run implementation of this workflow for local models (Ollama,
LM Studio, llama.cpp, vLLM) lives in
[`tools/ai-compose/`](../tools/ai-compose/README.md).

## Manifest schema (abridged)

```jsonc
{
  "id": "aws/core-network",          // cloud-relative module id
  "path": "modules/aws/core-network",
  "cloud": "aws",
  "domain": "core-network",          // per-domain output contracts: docs/adr/002
  "title": "...", "summary": "...",  // from the module README
  "terraform": { "required_version": ">= 1.5.0" },
  "providers": { "aws": { "source": "hashicorp/aws", "version": "~> 5.0" } },
  "inputs": {
    "governance": [ /* prefix, environment, owner, cost_center, ... */ ],
    "module": [
      { "name": "subnets", "type": "map(object({...}))",
        "description": "...", "required": true, "has_validation": true }
    ]
  },
  "outputs": [ { "name": "network_id", "description": "..." } ]
}
```
