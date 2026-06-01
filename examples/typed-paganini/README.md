# Real Paganini via the typed plugin (plugin B, binary-only)

Registers **real Paganini** quants (`paganini::bs_price`,
`paganini::iv_schadner`) into gpu-backtest's `TypedRegistry` — the **typed
plugin** path (plugin B) — but reaches them over the **binary-only libpaganini
C ABI**. No Paganini source is compiled into gpu-backtest; only the compiled
library is linked.

This is the typed-plugin counterpart to [`../aria/`](../aria/) (plugin A, which
calls Paganini from the Aria DSL). Both consume *real* Paganini binary-only.
See [`../aria/PLUGINS.md`](../aria/PLUGINS.md) for the full comparison.

## Run

```bash
source ../../scripts/env.sh          # or: export PAGANINI_DIST=/path/to/dist
# needs a sibling gpu-backtest checkout (or GPU_BACKTEST_SRC=/path/to/gpu-backtest)
./run.sh
```

Expected:

```
typed registry: 2 Paganini quants registered
typed-plugin paganini::bs_price (100/100/1y/20%) = 8.8273
typed-plugin paganini::iv_schadner recovers sigma = 0.200000
shape guard fired (expected): shape mismatch: paganini::bs_price: expected input_dim=7, got 3
```

## How it works

gpu-backtest's `bt-bridge` crate gains a `paganini-cabi` feature providing
`CAbiQuant`, a `bt_plugin::QuantPlugin` whose `predict()` calls
`paganini_bridge_run_quant(...)` from libpaganini. The example registers two of
Paganini's bridge quants by name and runs them through the standard typed
registry — identical numbers to calling Paganini directly (bs_price 8.8273;
Schadner IV round-trips σ=0.20), and the `QuantPlugin` shape contract is
enforced.

```
Aria/host code → TypedRegistry → CAbiQuant (bt_plugin::QuantPlugin)
                                      │  paganini_bridge_run_quant  (C ABI)
                                      ▼
                              libpaganini.{dylib,so}   ← built from the Paganini repo
```

`bt-bridge/build.rs` links libpaganini from `$PAGANINI_DIST` only under
`--features paganini-cabi`; the default gpu-backtest build links nothing
Paganini. **The Paganini algorithms stay in the Paganini repo.**
