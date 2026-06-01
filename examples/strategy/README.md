# Market-making strategy skeleton (C)

A minimal **market-making strategy** built on the binary-only Paganini C ABI —
the skeleton you'd extend into a real strategy. Plus it runs the bundled
`paganini-example-bridge` demo (the gpu-backtest plugin registry round-trip).

## Run

```bash
source ../../scripts/env.sh   # or: export PAGANINI_DIST=/path/to/dist
./run.sh
```

Expected output (numbers are deterministic on a given libm):

```
── market-making strategy (built on the Paganini C ABI) ──
MM ticks=200 fills=44
MM final_inventory=-4 cash=376.4362
MM MtM_PnL=-30.8673 final_sigma=0.0288

── same algos via the gpu-backtest plugin registry (bundled demo) ──
=== paganini-bridge end-to-end demo ===
registry: 3 quants + 2 features pre-loaded
...
```

## What it does

Each tick the strategy uses **three Paganini algorithms** to quote:

1. `paganini_microprice(bid, ask, bid_vol, ask_vol)` → size-weighted fair value.
2. `paganini_sample_variance(returns)` → per-tick realised vol (Welford),
   widening the spread when vol is high.
3. `paganini_as_quote(fair, inventory, γ, k, σ, T)` → the Avellaneda–Stoikov
   bid/ask, skewed by inventory.

It runs an inventory band, simulates fills against the next mid, and marks to
market. **The PnL is negative by construction**: a symmetric maker bleeds to
directional moves / adverse selection over an incomplete cycle. That's the
central market-making lesson — and the motivation for the regime/impact algos
(`examples/regime/`, `examples/impact/`) you'd layer on next.

Then it runs `paganini-example-bridge`: the exact `PluginRegistry::with_paganini_defaults()`
a gpu-backtest VM pre-loads — the same registry the `examples/aria/` strategy
reaches by name over the C ABI.

See [`../c/README.md`](../c/README.md) for the algorithm references, and
[`../aria/README.md`](../aria/README.md) for the Aria/plugin counterpart.
