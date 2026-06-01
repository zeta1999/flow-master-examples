# Plugin B — real Paganini as a typed plugin

**One of three plugin examples — start at [`../PLUGINS.md`](../PLUGINS.md).**

Registers **real Paganini** quants (`paganini::bs_price`, `paganini::iv_schadner`)
into gpu-backtest's `TypedRegistry` as a `bt_plugin::QuantPlugin`, reaching them
over the **binary-only libpaganini C ABI**. No Paganini source is compiled into
gpu-backtest; only the compiled library is linked.

Same Paganini quants as [`../plugin-aria-dsl/`](../plugin-aria-dsl/) — that one
calls them from the Aria DSL, this one from a typed Rust plugin.

## Run

```bash
source ../../scripts/env.sh          # or: export PAGANINI_DIST=/path/to/dist
# needs a sibling gpu-backtest checkout (or GPU_BACKTEST_SRC=/path/to/gpu-backtest)
./run.sh
```

Expected output (exact — this whole block is asserted by `scripts/run_all.sh`):

```
typed registry: 2 Paganini quants registered
typed-plugin paganini::bs_price (100/100/1y/20%) = 8.8273
typed-plugin paganini::iv_schadner recovers sigma = 0.200000
shape guard fired (expected): shape mismatch: paganini::bs_price: expected input_dim=7, got 3
```

## What actually runs (and where)

This example has **no local logic** — `run.sh` builds and runs code that lives in
the sibling gpu-backtest repo (it prints these paths when you run it):

- example main: `gpu-backtest/crates/bt-bridge/examples/paganini_cabi_quant.rs`
- the adapter: `gpu-backtest/crates/bt-bridge/src/cabi.rs` (`CAbiQuant`)

Run `SHOW_SOURCE=1 ./run.sh` to print both files inline before execution.

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
