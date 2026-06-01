# CLI example

Drives the `paganini` binary shipped in the binary-only dist — no FFI, no
compiler. This is the simplest possible "is the binary build present and
working?" smoke test.

## Run

```bash
source ../../scripts/env.sh   # or: export PAGANINI_DIST=/path/to/dist
./run.sh
```

Expected output (the version tracks the installed library, e.g. `0.1.0`):

```
── paganini version ──
paganini <version>
```

## Status

The CLI surface is intentionally **minimal today — only `version`**. The
algorithm-bearing functionality is reached through the C ABI (see the other
examples). Planned CLI subcommands (quote, price, backtest, …) are tracked in
[`../../NOT_YET_EXPOSED.md`](../../NOT_YET_EXPOSED.md); we will add CLI
examples here as those land.
