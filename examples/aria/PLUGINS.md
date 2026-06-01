# Two ways Paganini plugs into gpu-backtest

gpu-backtest can reach Paganini through **two different plugin paths**. They are
complementary, not competing — one is for using Paganini's *shipped* algorithms
binary-only, the other is for writing your *own* typed plugins.

| | **A. `paganini` (C-ABI plugin)** | **B. `paganini-bridge` (typed Rust plugin)** |
|---|---|---|
| **What it's for** | Call Paganini's **default** shipped algorithms from an Aria strategy | Register **custom** quant/feature/strategy plugins (yours or Paganini-backed) |
| **gpu-backtest crate / feature** | `bt-dsl --features paganini` (forwarded by bt-strategy/bt-engine) | `bt-bridge --features paganini-bridge` |
| **How Paganini is linked** | **Binary-only**: links compiled `libpaganini.{dylib,so}` via `$PAGANINI_DIST`. No Paganini Rust source in gpu-backtest. | **Rust source**: pulls `paganini-core` (or the `paganini-stub` patch in CI) for canonical `TickEvent` types + compile-time `EVENT_SCHEMA_VERSION` asserts. |
| **How a strategy uses it** | Inline in the `.aria` DSL: `signal fair = pag_microprice()`, `pag_bs_price(...)` | Rust `impl QuantPlugin/FeaturePlugin/StrategyPlugin`, registered in a `TypedRegistry` (explicit `register_*`, a `features.toml` manifest, dynamic `.so` via `bt_plugin_info`, or `linkme` statics) |
| **Who authors the plugin** | Paganini ships the C ABI; the strategy author only *calls* `pag_*`. No Rust needed. | A Rust developer implements the trait (the **custom** plugin). |
| **Surface exposed** | Curated/default set on the C ABI: `microprice` (feature) + bridge registry quants by name (`bs_price` / `sabr_implied_vol` / `iv_schadner`). | Anything: arbitrary user models, rich typed API (`input_dim`/`output_dim`, `snapshot`/`restore`, `on_tick(&TickEvent)`). |
| **Values** | scalar `f64` in/out (DSL register machine) | `Vec<f64>` in/out, stateful, per-plugin snapshot/restore |
| **Extending it** | add a `paganini_*` C fn + a `pag_*` opcode/name mapping | just `impl` the trait and register it — no ABI change |
| **Determinism / safety** | `unsafe` FFI; panic-free C ABI; isolated behind `#[cfg(feature="paganini")]` | safe Rust traits; version-asserted against `paganini-core`; ties into journal replay + the Phase-12 PnL **parity test** |
| **Binary-only / proprietary-friendly** | ✅ yes — ship only the compiled lib + header | ⚠️ compiles against `paganini-core` (uses a stub when Paganini is absent) |
| **Example here** | [`examples/aria/`](.) (this dir) | [`examples/custom-plugin/`](../custom-plugin/) (runs gpu-backtest's `bt-bridge` typed-plugin examples) |

## Rules of thumb

- **Use A (`paganini` C-ABI)** when you want a strategy author to call Paganini's
  published algorithms from Aria with zero Rust and a binary-only distribution.
  This is the "default plugins" path.
- **Use B (`paganini-bridge` typed)** when you need a *custom* model/feature in
  the loop, stateful plugins, or the canonical `TickEvent` contract — the
  "custom plugins" path. It's also what the nightly **PnL parity** test exercises.

Both can be enabled at once: the DSL `pag_*` opcodes resolve over the C ABI while
typed plugins resolve through the Rust traits — they don't conflict.
