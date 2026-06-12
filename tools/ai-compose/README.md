# ai-compose — local-model project composition

Reference implementation of the registry workflow described in
[`registry/README.md`](../../registry/README.md): a local LLM selects modules
from this framework and writes the root module that wires them together, with
`terraform validate` as the quality gate.

Stdlib-only Python; talks to any **OpenAI-compatible** chat endpoint, which
covers Ollama, LM Studio, llama.cpp server, and vLLM.

## Quick start (Ollama)

```sh
ollama pull qwen2.5-coder:14b

# IMPORTANT: small default context windows truncate silently and are the
# #1 cause of bad wiring. Give the server a real window:
OLLAMA_CONTEXT_LENGTH=16384 ollama serve

python3 tools/ai-compose/compose.py \
  "VPC with two private subnets in us-east-1 and a private DNS zone internal.example.com" \
  --out ~/projects/my-network \
  --model qwen2.5-coder:14b
```

Result: `~/projects/my-network/` containing copied framework modules under
`modules/`, a generated `main.tf` / `variables.tf` / `outputs.tf`, already
`terraform validate`-clean (the script runs up to `--max-repairs` fix rounds,
feeding validate errors back to the model).

## How it works

| Stage | Who does it | Context given to the model |
|-------|------------|-----------------------------|
| 1. SELECT | model | `registry/index.json` as a ~50-line catalog |
| 2. COPY | script (deterministic) | — modules are copied verbatim, never model-edited |
| 3. WIRE | model | only the selected modules' manifests + framework conventions |
| 4. GATE | terraform | fmt → init `-backend=false` → validate; errors loop back |

The split is the point: the model only ever sees small structured JSON, never
the whole framework, so even a 7–14B model has the exact input/output names
in context instead of hallucinating them. The prompts live in
[`prompts/`](prompts/) — tune them there, not in the script.

## Using a chat UI instead of the API

`--dry-run` prints the stage-1 selection prompt so you can paste it into any
chat window. For stage 2, build the wire prompt yourself: take
`prompts/wire.txt`, replace `{task}`, and replace `{manifests}` with the
contents of the selected `registry/manifests/...json` files. Then run the
gate by hand:

```sh
terraform fmt -recursive && terraform init -backend=false && terraform validate
```

## Useful flags

```text
--modules id1,id2     skip SELECT when you already know what you want
--url <base>          e.g. http://localhost:1234/v1 for LM Studio
--no-validate         skip the terraform gate (offline / no provider mirror)
--max-repairs N       validate-fix rounds before giving up (default 3)
--dry-run             print the SELECT prompt and exit
```

## Model guidance

- **qwen2.5-coder 14B / 32B, devstral, codestral** — reliable for 1–3 module
  compositions; 32B-class for cross-provider or many-module roots.
- **7B-class** — workable for single-module pulls with `--modules` pinned;
  expect the repair loop to do more work.
- Temperature is forced to 0; composition is not a creativity task.

If validate still fails after all repair rounds, the partial project is left
in `--out` for manual fixing — the copied modules are always pristine.
