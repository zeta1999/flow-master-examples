# Not yet in the examples (backlog)

These examples cover Paganini's **current** binary-only surface, now seven
C-ABI functions:

- `paganini_abi_version`
- `paganini_as_quote` (Avellaneda–Stoikov)
- `paganini_microprice`
- `paganini_sample_variance` (Welford)
- `paganini_bocpd_changepoints` (BOCPD regime detection) ✅ *new*
- `paganini_mass_profile` / `paganini_mass_best_match` (MASS) ✅ *new*
- `paganini_kyle_lambda` (Kyle's λ impact calibration) ✅ *new*

…plus the `paganini version` CLI command.

Paganini's source build contains a *much* larger algorithm set. None of it is
reachable from a binary-only consumer yet, because it has no C-ABI wrapper
and no CLI subcommand. This file is the running inventory of what's there but
not here — **we will add examples as the wrappers land.**

Legend — binary-only access today:
**C** = needs a `paganini_*` C-ABI wrapper · **CLI** = needs a CLI subcommand.

---

## A. Algorithms in the library but not in the C ABI

Grouped by Paganini workspace crate. Sourced from the crate table in
Paganini's `README.md`.

### `paganini-pricing` — options pricing & vol surfaces
| Capability | Needs |
|------------|-------|
| Forward Black–Scholes + 12 Greeks | C |
| Three IV inverters (Schadner variance-space Halley ≈78 ns, Jäckel, Corrado–Miller) | C |
| Five surface parameterisations (SABR / Wing / SVI / SSVI / eSSVI) + NM/BFGS/ridge calibration | C |
| PAV isotonic + iterative-local butterfly arb repair | C |
| `TermStructure`, `Portfolio` + per-strike/tenor Greek buckets | C |
| 8 `OptionStrategy` templates, `IncrementalGreeks` Taylor pricer | C |
| Deribit-style inverse converters | C |
| Variance-swap fair-strike, forward variance, VIX-style 30-day CM vol | C |
| OHLC realised vol (CTC / Parkinson / Garman–Klass / Rogers–Satchell / Yang–Zhang) | C |
| Delta-quoted RR/BF, per-Greek P&L attribution | C |

### `paganini-mm` — market making
| Capability | Needs |
|------------|-------|
| GLFT quoter | C |
| Regime quoter | C |
| Cartea–Jaimungal alpha-aware quoting | C |
| Whalley–Wilmott no-trade band | C |
| `options_mm` quote-chain | C |
| (Avellaneda–Stoikov **is** exposed ✅) | — |

### `paganini-lob` — limit order book & microstructure
| Capability | Needs |
|------------|-------|
| Price-level LOB build/apply | C |
| `QueueTracker` + iceberg detector | C |
| OFI, depth imbalance, Lee–Ready, Hawkes, VPIN | C |
| Kyle's λ | ✅ exposed → `examples/impact/` |
| (Microprice + Welford RV **are** exposed ✅) | — |

### `paganini-features` — microstructure features
| Capability | Needs |
|------------|-------|
| Markout (1/10/100/1000/10000 ms) | C |
| Jump-robust RV (bipower / MedRV / tripower / realised-kernel) | C |
| Hayashi–Yoshida | C |
| Toxicity (OCR + markout trigger + composite score) | C |

### `paganini-regime` — regime detection
| Capability | Needs |
|------------|-------|
| Gaussian HMM + Baum–Welch + sticky priors, online filter | C |
| HJB-RK4 | C |
| BOCPD (Adams–MacKay) | ✅ exposed → `examples/regime/` |
| Kalman / EKF vol+drift | C |
| Viterbi MAP path | C |

### `paganini-execution` — execution scheduling
| Capability | Needs |
|------------|-------|
| Obizhaeva–Wang transient-impact schedule | C |
| Bouchaud propagator + cross-impact baskets | C |
| Perold implementation-shortfall decomposition | C |
| Cartea–Jaimungal closed-form VWAP | C |
| Auction-aware open/close allocator | C |

### `paganini-amm` — automated market makers / DeFi
| Capability | Needs |
|------------|-------|
| CPMM (Uniswap v2) | C |
| CLMM (v3 within-tick sqrt-price) | C |
| Stableswap (Curve invariant) | C |
| Oracle pool (GMX) | C |
| IL hedge + LP value, gas-cost + MEV-exposure score | C |

### `paganini-portfolio` — portfolio optimisation
| Capability | Needs |
|------------|-------|
| Markowitz MVO via Cholesky | C |
| Pure-Rust PCA via Jacobi rotations | C |
| QUBO matrix + simulated annealing | C |
| Simulated Bifurcation (Goto et al.) | C |

### `paganini-ml` — ML signals & policies
| Capability | Needs |
|------------|-------|
| `Model` + `MlBackend` adapter, ONNX via `tract` | C |
| CVaR objective | C |
| `HedgePolicy` + `HjbWarmStartPolicy` + `backtest_hedge_path` | C |
| `RlQuoter` + `LatencyBudgetedQuoter` | C |
| AlphaRNN inference | C |
| `LinearAutoencoder` + `StreamingAnomalyDetector` | C |
| `TabularModel` + L2-boosting decision-stump baseline | C |

### `paganini-hedging` — options hedging
| Capability | Needs |
|------------|-------|
| BS pricing + grid hedge search + adaptive refine | C |

### `paganini-tss` — time-series subroutines
| Capability | Needs |
|------------|-------|
| MASS (distance profile + nearest match) | ✅ exposed → `examples/tss/` |
| STOMP / PAA / SAX / rolling-distance | C |

### `paganini-oms` / `paganini-quant` / `paganini-stream`
| Capability | Needs |
|------------|-------|
| Order state machine + multi-asset cross-impact slicer (`oms`) | C |
| optim (NM/BFGS/ridge/PAV), volsurface (SVI/SSVI), cross-impact (`quant`) | C |
| Ring buffer, `DirtyTracker`, `DriftDetector`, `DependencyGraph` (`stream`) | C |

### `paganini-gpu` / `paganini-fpga` / `paganini-bridge`
| Capability | Needs |
|------------|-------|
| Metal + OpenCL dispatch, `MemoryView` (`gpu`) | C |
| Kernel registry + CPU fallback, LOB-delta-apply kernel (`fpga`) | C |
| gpu-backtest plugin registry round-trip (`bridge`) | C |

---

## B. Runnable demo binaries that exist in source builds

Paganini's `paganini-example` crate builds ~24 end-to-end demo binaries.
Today's minimal binary dist (`scripts/setup.sh`) ships only the `paganini`
CLI, not these. Each is a candidate "run a bundled demo" example once the
dist packages them (per `docs/DISTRIBUTION.md §8`, which lists
`bin/paganini-example`).

| Binary | Demonstrates |
|--------|--------------|
| `paganini-example` | Spot-MM: synthetic ticks → LOB → AS quoter → PnL |
| `paganini-example-options-mm` | Options-MM end-to-end: SABR → quote chain → caps → hedge |
| `paganini-example-options-stream` | Streaming options-MM (10-tick ridge + EWMA loop) |
| `paganini-example-pricing` | Pricing pipeline: BS → IV recovery → SABR refit → arb |
| `paganini-example-hedging` | Grid hedge search + adaptive refine |
| `paganini-example-backtest` | Strategy backtest harness (AS / GLFT / regime) |
| `paganini-example-bridge` | gpu-backtest plugin registry round-trip |
| `paganini-example-gpu` | Metal + OpenCL GPU dispatch |
| `paganini-example-in-context` | In-context / TabICL-style inference |
| `paganini-example-regime-quoter` | Regime-switching quoter |
| `paganini-example-bocpd-vol-quoter` | BOCPD change-point vol quoter |
| `paganini-example-basket` | Cross-impact basket execution |
| `paganini-example-ml-signal` | ML signal → quoting |
| `paganini-example-microstructure` | OFI / imbalance / Lee–Ready / Kyle λ features |
| `paganini-example-execution` | Obizhaeva–Wang / propagator schedules |
| `paganini-example-glft` | GLFT quoter |
| `paganini-example-portfolio` | Markowitz MVO / PCA / QUBO / SB |
| `paganini-example-rl-quoter` | RL quoter + latency budget |
| `paganini-example-anomaly` | Streaming anomaly detector |
| `paganini-example-queue` | Queue tracker + iceberg detector |
| `paganini-example-amm` | CPMM / CLMM / Stableswap / IL hedge |
| `paganini-example-cross-impact` | Cross-impact propagator |
| `paganini-example-tss` | MASS / STOMP / SAX |

---

## C. How to add the next example

1. **If it needs a new C function:** add a `#[no_mangle] extern "C"` wrapper
   in `crates/paganini-c-api/src/lib.rs`, declare it in
   `include/paganini.h`, bump `PAGANINI_ABI_VERSION`. Then add an example
   directory here that calls it, with deterministic expected output, and wire
   it into `scripts/run_all.sh` + `TESTING.md`.
2. **If it's a demo binary:** extend `scripts/setup.sh` to copy the
   `paganini-example-*` binaries into `dist/bin/`, then add a `cli`-style
   example that runs one.
3. Keep the rule intact: **no Paganini source or binaries committed here.**
