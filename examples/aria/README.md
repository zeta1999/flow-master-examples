# Aria strategy + Paganini plugin (gpu-backtest)

A market-making / mean-reversion strategy written in **Aria** — gpu-backtest's
`.aria` strategy DSL — that calls **Paganini** through a binary-only plugin.

This is the one example that doesn't link libpaganini itself: instead it runs a
real **strategy** in gpu-backtest's `bt-engine`, and gpu-backtest's Paganini
plugin resolves the strategy's `pag_*` calls over the libpaganini C ABI.

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

See the explanation note in the Paganini repo:
`docs/ARIA_PAGANINI_PLUGIN.md`.
