# Plugin examples — read this first

gpu-backtest can call Paganini through a **plugin**. There are exactly **three**
plugin examples here. Pick by what you want to do:

| Example dir | One line | Real Paganini? | Binary-only? |
|-------------|----------|----------------|--------------|
| [`plugin-aria-dsl/`](plugin-aria-dsl/) | Call Paganini from a **strategy written in the Aria DSL** (`pag_microprice()`, `pag_bs_price()`) | ✅ | ✅ links libpaganini |
| [`plugin-typed-real/`](plugin-typed-real/) | Register **real Paganini** quants as a **typed Rust plugin** (`QuantPlugin`) and call them | ✅ | ✅ links libpaganini |
| [`plugin-typed-custom/`](plugin-typed-custom/) | The **same typed-plugin mechanism with your *own* model** (no Paganini) | ❌ (toy plugins) | ❌ stub, no link |

The first two run the *same* Paganini quants over the *same* libpaganini C ABI —
they differ only in the **entry point**: an Aria `.aria` script vs. a Rust
`QuantPlugin`. The third shows that the plugin slot accepts *any* model you write.

> **All three keep Paganini's source in the Paganini repo.** gpu-backtest declares
> the C ABI as `extern "C"` and links the compiled `libpaganini`; the
> `plugin-typed-custom` example links nothing Paganini at all (it uses a stub).
> Each example's `run.sh` prints the exact gpu-backtest source file it executes.

---

## The two mechanisms in detail

| | **A — Aria DSL plugin** | **B — typed-registry plugin** |
|---|---|---|
| **Example(s)** | `plugin-aria-dsl/` | `plugin-typed-real/` (real Paganini), `plugin-typed-custom/` (your own) |
| **gpu-backtest feature** | `bt-dsl --features paganini` | `bt-bridge --features paganini-cabi` (real) / `--features paganini-bridge` (custom/stub) |
| **How you call Paganini** | inline in `.aria`: `signal fair = pag_microprice()` | a `bt_plugin::QuantPlugin` (`CAbiQuant`) registered in a `TypedRegistry` |
| **Reaches Paganini via** | DSL opcode → libpaganini C ABI | `predict()` → `paganini_bridge_run_quant` → libpaganini C ABI |
| **Who writes it** | a strategy author (no Rust) | a Rust developer implementing the trait |
| **Linkage** | binary-only (`$PAGANINI_DIST`) | binary-only for the real one; the custom one uses gpu-backtest's stub |

## Rules of thumb

- Want a strategy author to call Paganini's published algorithms with zero Rust →
  **`plugin-aria-dsl/`**.
- Want real Paganini inside Rust host/strategy code as a typed plugin →
  **`plugin-typed-real/`**.
- Want to drop in *your own* model behind the same plugin slot →
  **`plugin-typed-custom/`**.

Both A and B can be enabled at once; the DSL opcodes and the typed plugins don't
conflict.
