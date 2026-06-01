# Flow-Master Examples

Worked, runnable examples for consuming **[Paganini](https://github.com/local/Paganini)**
— a Rust quantlib for algo trading, market making, HFT, and options dealer
flow — **from a binary-only build**, in several languages.

> **The contract of this repo:** it contains *no Paganini source and no
> Paganini binaries*. Every example links against the compiled, stable C ABI
> (`libpaganini`) or drives the `paganini` CLI. You bring a binary build of
> Paganini; these examples show how to call it. That keeps Paganini
> proprietary while making it trivially consumable from C, C++, Python, Go,
> and the shell.

## What the binary build exposes

Paganini's source-free consumption seam today is its stable **C ABI**
(`crates/paganini-c-api`, shipped as `libpaganini.{a,dylib,so}` +
`paganini.h`) plus the `paganini` CLI binary. The C ABI currently exports
four functions, each wrapping an algorithm whose correctness is
machine-checked in Paganini's Lean specs:

| C function | Algorithm | What it does |
|------------|-----------|--------------|
| `paganini_abi_version()` | — | ABI version probe (currently `1`). |
| `paganini_as_quote(mid, inv, γ, k, σ, T, *bid, *ask)` | **Avellaneda–Stoikov** | Optimal symmetric maker quote around `mid` given inventory and risk params. |
| `paganini_microprice(bid, ask, bid_qty, ask_qty)` | **Microprice** | Size-weighted fair value, provably within `[bid, ask]`. |
| `paganini_sample_variance(xs, n)` | **Welford** | Online Bessel-corrected sample variance; equals the batch result. |
| `paganini_bocpd_changepoints(xs, n, λ, α, β, window, *out)` | **BOCPD** (Adams–MacKay) | Per-step change-point mass over a return series; spikes at regime shifts. |
| `paganini_mass_profile(series, n, query, m, *out)` / `…_best_match(…)` | **MASS** | Z-normalised distance profile / nearest-subsequence match for time-series similarity. |
| `paganini_kyle_lambda(signed_vols, mids, n, λ_ff, p0)` | **Kyle's λ** (RLS) | Calibrate linear price impact from a trade tape. |

A much larger algorithm surface still exists inside Paganini but is **not yet
reachable** through this binary seam — see
[`NOT_YET_EXPOSED.md`](NOT_YET_EXPOSED.md) for the full backlog (we will add
more examples as those wrappers land).

## Layout

```
flow-master-examples/
├── README.md            ← you are here
├── TESTING.md           ← step-by-step manual; validated to actually work
├── NOT_YET_EXPOSED.md   ← Paganini features not yet in these examples (backlog)
├── LICENSE-EXAMPLES     ← CC0 for the examples (Paganini itself stays proprietary)
├── scripts/
│   ├── setup.sh         ← build the binary-only dist from a Paganini checkout → ./dist
│   ├── env.sh           ← `source` to put libpaganini + the CLI on your paths
│   └── run_all.sh       ← build+run every example and assert its output (the test gate)
└── examples/
    ├── c/               ← link libpaganini from C (dynamic + static)
    ├── cpp/             ← idiomatic C++17 wrapper over the C ABI
    ├── python/          ← ctypes; zero compiler required
    ├── go/              ← cgo
    ├── regime/          ← BOCPD change-point detection (Python/ctypes)
    ├── tss/             ← MASS time-series similarity (C)
    ├── impact/          ← Kyle's λ impact calibration from tape (Go/cgo)
    ├── strategy/        ← market-making strategy skeleton on the C ABI (C)
    ├── aria/            ← Aria DSL strategy + the DEFAULT Paganini plugin (binary-only C ABI)
    ├── custom-plugin/   ← CUSTOM typed-Rust plugin (gpu-backtest bt-bridge)
    └── cli/             ← drive the `paganini` binary
```

The `c`/`cpp`/`python`/`go` examples each call the same four core functions
(AS quote, microprice, variance, ABI probe) — one per language, to show the
binding pattern. The `regime`/`tss`/`impact` examples each demonstrate one
additional algorithm exposed through the C ABI. The `strategy` example builds a
market-making skeleton on those algos; the `aria` example runs a strategy in
gpu-backtest's Aria DSL where a **Paganini plugin** resolves `pag_*` calls over
the binary-only C ABI (see `examples/aria/README.md`).

## Quick start

```bash
# 1. Produce a binary-only Paganini dist into ./dist (gitignored).
#    Defaults to a sibling ../Paganini checkout; override with PAGANINI_SRC,
#    or skip the build entirely by pointing PAGANINI_DIST at an unpacked
#    release tarball.
./scripts/setup.sh

# 2. Build & run every example, asserting the expected output.
./scripts/run_all.sh
#    → ... → ALL EXAMPLES PASSED

# Or run one language at a time:
source scripts/env.sh
examples/c/build_and_run.sh
examples/python/run.sh
```

Every FFI example deterministically prints:

```
paganini ABI version: 1
AS quote bid=99.3526 ask=100.6474 spread=1.2948
microprice=99.5000
variance=2.5000
```

See [`TESTING.md`](TESTING.md) for the full, validated walkthrough including
prerequisites, per-example expected output, and troubleshooting.

## Licensing

Examples here are CC0 (see [`LICENSE-EXAMPLES`](LICENSE-EXAMPLES)) — copy them
freely. **Paganini itself is proprietary** and governed by its own license;
this repo only consumes its published binary surface.
