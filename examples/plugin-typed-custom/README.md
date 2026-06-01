# Plugin B (mechanism) — your own custom typed plugin

**One of three plugin examples — start at [`../PLUGINS.md`](../PLUGINS.md).**

The same typed-registry mechanism as [`../plugin-typed-real/`](../plugin-typed-real/),
but with a developer's **own** `QuantPlugin` / `FeaturePlugin` / `StrategyPlugin`
(Rust traits) instead of Paganini. It uses gpu-backtest's bundled `paganini-stub`
(`--features paganini-bridge`), so it needs **no `PAGANINI_DIST` and links no
Paganini** — it shows the plugin *mechanism*, not binary-only consumption.

## Run

```bash
# needs a sibling gpu-backtest checkout (or GPU_BACKTEST_SRC=/path/to/gpu-backtest)
./run.sh
```

It runs gpu-backtest's three `bt-bridge` typed-plugin examples in turn. The output
ends each section with a stable marker (`run_all.sh` asserts
`linear_quant_demo`, `OrderFlowImbalance`, and `Total orders emitted: 3`):

```
── custom plugin: paganini_quant_plugin (.../paganini_quant_plugin.rs) ──
  ... a shape-error line for linear_quant_demo (expected) ...
── custom plugin: paganini_feature_plugin (.../paganini_feature_plugin.rs) ──
  OrderFlowImbalance(window=5) demo: ... + a snapshot/restore line
── custom plugin: paganini_strategy_plugin (.../paganini_strategy_plugin.rs) ──
  Total orders emitted: 3
```

(Per-plugin numeric outputs aren't pinned here — only the markers above are
asserted — so this README doesn't quote specific values that could drift.)

## What actually runs (and where)

This example has **no local logic**. `run.sh` runs three examples whose source is
in the sibling gpu-backtest repo (it prints these paths when you run it):

- `gpu-backtest/crates/bt-bridge/examples/paganini_quant_plugin.rs` — `QuantPlugin`
- `gpu-backtest/crates/bt-bridge/examples/paganini_feature_plugin.rs` — `FeaturePlugin`
- `gpu-backtest/crates/bt-bridge/examples/paganini_strategy_plugin.rs` — `StrategyPlugin`

Run `SHOW_SOURCE=1 ./run.sh` to print each file before it executes.

These register via `TypedRegistry::register_quant/feature/strategy`. A custom
plugin can also come from a `features.toml` manifest, a dynamic `.so`/`.dylib`
(`bt_plugin_info` C ABI in `bt-plugin::loader`), or `linkme` statics.
