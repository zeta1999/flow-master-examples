# Custom plugin (typed Rust)

The **custom-plugin** path: a developer writes their *own* `QuantPlugin` /
`FeaturePlugin` / `StrategyPlugin` (Rust traits) and registers them in
gpu-backtest's `TypedRegistry`. This is the counterpart to
[`examples/aria/`](../aria/), which uses Paganini's *default* algorithms
binary-only over the C ABI.

See [`../aria/PLUGINS.md`](../aria/PLUGINS.md) for the full default-vs-custom
feature comparison.

## Run

```bash
# needs a sibling gpu-backtest checkout (or GPU_BACKTEST_SRC=/path/to/gpu-backtest)
./run.sh
```

This runs gpu-backtest's three `bt-bridge` typed-plugin examples with
`--features paganini-bridge`. That feature uses gpu-backtest's bundled
`paganini-stub`, so **no `PAGANINI_DIST` is needed** — it demonstrates the
plugin *mechanism*, not binary linkage.

Expected (abridged):

```
── bt-bridge custom plugin: paganini_quant_plugin ──
  input 0: [...] -> output [0.51]
  Shape error fired (expected): linear_quant_demo: expected input_dim=8, got 6
── bt-bridge custom plugin: paganini_feature_plugin ──
  OrderFlowImbalance(window=5) demo:
  ...
── bt-bridge custom plugin: paganini_strategy_plugin ──
  Total orders emitted: 3
```

## What it shows

| Plugin | Trait | Demonstrates |
|--------|-------|--------------|
| `LinearQuant` | `QuantPlugin` | `predict(&[f64]) -> Vec<f64>`, `input_dim`/`output_dim` shape checks |
| `OrderFlowImbalance` | `FeaturePlugin` | streaming `on_tick(&TickEvent) -> Option<f64>` + `snapshot`/`restore` |
| `PaganiniStrategy` | `StrategyPlugin` | `on_tick(&TickEvent) -> Vec<MetaOrder>`, calling a registered quant |

These plugins are registered via `TypedRegistry::register_quant/feature/strategy`.
A custom plugin can also be discovered from a `features.toml` manifest, loaded as
a dynamic `.so`/`.dylib` (the `bt_plugin_info` C ABI in `bt-plugin::loader`), or
auto-registered via `linkme` statics — see the plugin-registration decision doc
in gpu-backtest.

The plugin source lives in gpu-backtest (`crates/bt-bridge/examples/`); this repo
only drives it, keeping the no-Paganini-source rule intact.
