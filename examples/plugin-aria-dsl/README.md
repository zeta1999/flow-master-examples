# Plugin A — call Paganini from the Aria DSL

**One of three plugin examples — start at [`../PLUGINS.md`](../PLUGINS.md).**

A market-making / mean-reversion strategy written in **Aria** (gpu-backtest's
`.aria` strategy DSL) that calls **Paganini** by name. The strategy runs in
gpu-backtest's `bt-engine`; the `paganini` feature resolves the strategy's
`pag_*` calls over the binary-only libpaganini C ABI. Real Paganini, binary-only.

Sibling examples: [`../plugin-typed-real/`](../plugin-typed-real/) (same Paganini
quants via a typed Rust plugin) and [`../plugin-typed-custom/`](../plugin-typed-custom/)
(the typed mechanism with your own model).

## Run

```bash
source ../../scripts/env.sh          # or: export PAGANINI_DIST=/path/to/dist
# Needs a sibling gpu-backtest checkout (or GPU_BACKTEST_SRC=/path/to/gpu-backtest)
./run.sh
```

`run.sh` builds `bt-engine --features paganini` (which links the binary-only
`libpaganini` from `dist/`), then backtests `microprice_mm.aria` on gpu-backtest's
bundled synthetic `SYNTH_BTC` data and prints the result summary
(`Results for SYNTH_BTC:` / `PnL:` / `Trades:` …).

## The strategy (`microprice_mm.aria`)

```
signal fair = pag_microprice()        -- Paganini microprice (the plugin feature)
signal edge = mid - fair
signal vol  = stdev(mid, 20)
signal band = max(vol, 0.0001)
signal atm_call = pag_bs_price(mid, mid, 1.0, max(vol,0.01), 0.03, 0.0, 0.0)

strategy microprice_mm {
    when edge < -band -> buy(1.0)      -- mid cheap vs Paganini fair → buy
    when edge >  band -> sell(1.0)     -- mid rich vs Paganini fair → sell
    when ...neutral...-> flatten()
}
```

It trades the naive mid's deviation from Paganini's size-weighted **microprice**
fair value, scaled by recent realised vol. `pag_bs_price(...)` additionally
exercises the bridge **registry** quant path (an ATM call fair value).

## What actually runs (and where)

- **The strategy** is the local file [`microprice_mm.aria`](microprice_mm.aria)
  in this dir — that's the code under test (run.sh feeds it to bt-engine).
- **The engine + plugin glue** lives in the sibling gpu-backtest repo: the DSL
  compiler/VM recognise `pag_*` and dispatch over the C ABI —
  `gpu-backtest/crates/bt-dsl/src/{compiler.rs,vm_cpu.rs,paganini_ffi.rs}`,
  linked by `gpu-backtest/crates/bt-dsl/build.rs`.

## How the Paganini plugin works (binary-only)

gpu-backtest's `paganini` cargo feature (added to `bt-dsl`/`bt-strategy`/`bt-engine`)
teaches the Aria compiler + VM two name families:

| Aria call | Resolves to (libpaganini C ABI) |
|-----------|----------------------------------|
| `pag_microprice()` | `paganini_microprice(bid, ask, bid_vol, ask_vol)` — read from the live book input slots |
| `pag_bs_price(…)` / `pag_sabr_iv(…)` / `pag_iv_schadner(…)` | `paganini_bridge_run_quant("paganini::…", …)` — the `paganini-bridge` registry, by name |

The feature's `build.rs` links `libpaganini` from `$PAGANINI_DIST/lib` (with an
rpath), so **no Paganini source is compiled into gpu-backtest** — it consumes the
compiled library exactly like the other examples here. With the feature off
(gpu-backtest's default), nothing Paganini is linked and `pag_*` names are
unknown — the standard build and its test suite are unaffected.

See the explanation note in the Paganini repo (source-checkout only):
`Paganini/docs/ARIA_PAGANINI_PLUGIN.md`.
