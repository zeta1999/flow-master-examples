# TESTING — Flow-Master Examples

A step-by-step manual to set up a binary-only Paganini build and run every
example. Every command and every expected output below has been executed and
verified. The whole thing is also automated as a single gate:
`./scripts/run_all.sh`.

> **Golden rule of this repo:** no Paganini source or binaries are committed
> here. `scripts/setup.sh` *produces* a binary-only distribution into a
> gitignored `dist/`; the examples consume only that.

---

## 0. Prerequisites

| Tool | Needed for | Check | If missing |
|------|-----------|-------|------------|
| `cargo` + `rustc` | building the binary-only dist | `cargo --version` | install Rust (rustup) |
| A Paganini source checkout **or** an unpacked release | source of the binary build | `ls ../Paganini/Cargo.toml` | set `PAGANINI_SRC` or `PAGANINI_DIST` |
| `cc` (clang/gcc) | C example | `cc --version` | install Xcode CLT / build-essential |
| `c++` (clang++/g++) | C++ example | `c++ --version` | same |
| `python3` | Python example | `python3 --version` | install Python 3 |
| `go` | Go example | `go version` | install Go ≥ 1.21 |
| a `gpu-backtest` checkout | Aria example (`bt-engine`) | `ls ../gpu-backtest/Cargo.toml` | set `GPU_BACKTEST_SRC`; else `aria` SKIPs |

Only `cargo` + a Paganini source (or a prebuilt `PAGANINI_DIST`) are
**required**. Each language example **auto-SKIPs** in `run_all.sh` if its
toolchain is absent — a skip is not a failure.

---

## 1. One-time setup — produce the binary-only dist

```bash
./scripts/setup.sh
```

By default this builds `paganini-c-api` + `paganini-cli` (release) from a
sibling `../Paganini` checkout and assembles `./dist`. Override the source
location with `PAGANINI_SRC=/path/to/Paganini`, or skip the build entirely by
pointing `PAGANINI_DIST` at an already-unpacked release tarball.

**Expected:** a success banner ending with the dist contents:

```
✓ Binary-only dist ready at: .../flow-master-examples/dist

  Add this to your shell (or run examples via scripts/run_all.sh):
      export PAGANINI_DIST=".../flow-master-examples/dist"

  Contents:
      ./bin/paganini
      ./docs/DISTRIBUTION.md
      ./docs/getting_started.md
      ./include/paganini.h
      ./lib/libpaganini.a
      ./lib/libpaganini.dylib        # libpaganini.so on Linux
```

Then point your shell at it (the examples also fall back to `./dist`
automatically if `PAGANINI_DIST` is unset):

```bash
source scripts/env.sh
```

---

## 2. Run everything (the gate)

```bash
./scripts/run_all.sh
```

This (a) runs `setup.sh` if `dist/` is missing, (b) builds and runs each
example, (c) asserts each prints the expected numbers, and (d) summarises.

**Expected tail:**

```
════════════════════════ SUMMARY ════════════════════════
  PASS  c
  PASS  cpp
  PASS  python
  PASS  go
  PASS  regime
  PASS  tss
  PASS  impact
  PASS  strategy
  PASS  plugin-aria-dsl
  PASS  plugin-typed-real
  PASS  plugin-typed-custom
  PASS  cli
──────────────────────────────────────────────────────────
  PASS=12  FAIL=0  SKIP=0

ALL EXAMPLES PASSED
```

Exit code is `0` iff no example FAILED. Examples whose toolchain or sibling repo
is absent **SKIP** (not fail): e.g. without Go you'd see `SKIP go`/`SKIP impact`;
without a `gpu-backtest` checkout you'd see `SKIP plugin-aria-dsl` /
`SKIP plugin-typed-real` / `SKIP plugin-typed-custom`. A run with everything
present is `PASS=12 FAIL=0 SKIP=0`.

---

## 3. Per-example walkthrough

All four FFI examples call the same `libpaganini` with the same inputs, so
they print identical numbers:

```
paganini ABI version: 1
AS quote bid=99.3526 ask=100.6474 spread=1.2948
microprice=99.5000
variance=2.5000
variance(n<2)=NaN (guard OK)
```

What the numbers mean:

- **`ABI version: 1`** — `paganini_abi_version()`; confirms the linked
  library's contract version.
- **`bid=99.3526 ask=100.6474`** — Avellaneda–Stoikov optimal quote around a
  100.00 mid with flat inventory (`γ=0.1, k=1.5, σ=0.2, T=1.0`). Symmetric
  about the mid because inventory is 0; spread ≈ 1.2948.
- **`microprice=99.5000`** — size-weighted fair value of a 99/101 book with
  bid_qty=5, ask_qty=15. Heavier ask size pulls fair value below the mid,
  staying inside `[99, 101]`.
- **`variance=2.5000`** — Welford sample variance of
  `{100, 101, 99, 102, 98}` (Bessel-corrected).
- **`variance(n<2)=NaN`** — the documented guard: variance of a length-1
  sample is undefined and returns `NaN` rather than trapping.

### 3.1 C — `examples/c/`

```bash
examples/c/build_and_run.sh
```

Prints the block **twice**: once dynamically linked
(`-lpaganini` → `libpaganini.dylib`/`.so`), once statically linked
(`libpaganini.a` + platform system libs). Both must match.

### 3.2 C++ — `examples/cpp/`

```bash
examples/cpp/build_and_run.sh
```

Builds with `-std=c++17` and links dynamically. (Editor warnings about
`std::optional` under an older standard are cosmetic; the build sets C++17.)

### 3.3 Python — `examples/python/`

```bash
examples/python/run.sh        # or: python3 examples/python/consumer.py
```

No compile step — `ctypes` loads the dylib directly.

### 3.4 Go — `examples/go/`

```bash
examples/go/run.sh
```

Uses cgo (`CGO_ENABLED=1`). A `ld: warning: ignoring duplicate libraries:
'-lpaganini'` line on macOS is harmless.

### 3.5 Regime detection (BOCPD) — `examples/regime/`

```bash
examples/regime/run.sh
```

**Expected:**

```
BOCPD series_len=32 shift_at=24
BOCPD peak_index=24 peak_mass=1.0000
BOCPD stationary_mass[20]=0.0398
```

24 stationary observations then a level shift at index 24; the change-point
mass spikes to ≈1.0 exactly there, vs ≈0.04 while stationary. See
[`examples/regime/README.md`](examples/regime/README.md).

### 3.6 Time-series similarity (MASS) — `examples/tss/`

```bash
examples/tss/build_and_run.sh
```

**Expected:**

```
MASS profile_len=5
MASS profile[0]=0.0000 profile[4]=0.0000
MASS best_index=0 best_dist=0.0000
```

The query `[1,2,3,4]` appears at offsets 0 and 4 of the series (distance ≈ 0).
See [`examples/tss/README.md`](examples/tss/README.md).

### 3.7 Market-impact calibration (Kyle's λ) — `examples/impact/`

```bash
examples/impact/run.sh
```

**Expected:**

```
Kyle trades=10 true_lambda=0.0500
Kyle estimated_lambda=0.0499
```

A synthetic tape built with `λ=0.05`; RLS recovers `≈0.0499` from the tape
alone. See [`examples/impact/README.md`](examples/impact/README.md).

### 3.8 Market-making strategy skeleton — `examples/strategy/`

```bash
examples/strategy/run.sh
```

A C strategy built on the C ABI: per tick it computes a microprice fair value,
a Welford vol-scaled spread, and an Avellaneda–Stoikov inventory-skewed quote,
simulates fills and tracks PnL — then runs the bundled `paganini-example-bridge`
demo (the gpu-backtest plugin registry). The `fills`/`cash`/`MtM_PnL`/`sigma`
numbers depend on the platform libm, so only the shape + stable markers are
asserted:

```
MM ticks=200 fills=<N>
MM final_inventory=<I> cash=<…>
MM MtM_PnL=<…> final_sigma=<…>
...
registry: 3 quants + 2 features pre-loaded
```

The MM skeleton's PnL is negative by construction — a symmetric maker bleeds to
directional risk; that's the motivation for the regime/impact algos. See
[`examples/strategy/README.md`](examples/strategy/README.md).

> The three `plugin-*` examples below show how gpu-backtest calls Paganini
> through its plugin system. Read [`examples/PLUGINS.md`](examples/PLUGINS.md)
> first — it says which to pick. Each one's `run.sh` prints the exact
> gpu-backtest source file it executes.

### 3.9 Plugin: Aria DSL → Paganini — `examples/plugin-aria-dsl/`

```bash
# needs a sibling gpu-backtest checkout (or GPU_BACKTEST_SRC=/path/to/gpu-backtest)
examples/plugin-aria-dsl/run.sh
```

Runs a strategy written in gpu-backtest's **Aria** DSL through `bt-engine`, where
the Paganini plugin resolves `pag_microprice()` / `pag_bs_price(...)` over the
binary-only libpaganini C ABI. Builds `bt-engine --features paganini` (slow the
first time) and backtests on bundled synthetic data. Expected tokens:

```
Results for SYNTH_BTC:
    ...
    Trades:      ...
```

SKIPs cleanly if `cargo` or a `gpu-backtest` checkout is absent. See
[`examples/plugin-aria-dsl/README.md`](examples/plugin-aria-dsl/README.md).

### 3.10 Plugin: real Paganini as a typed plugin — `examples/plugin-typed-real/`

```bash
# needs a sibling gpu-backtest checkout
examples/plugin-typed-real/run.sh
```

Registers Paganini's bridge quants in gpu-backtest's `TypedRegistry` via a
`CAbiQuant` adapter that dispatches over libpaganini. Full expected output
(every line asserted by `run_all.sh`):

```
typed registry: 2 Paganini quants registered
typed-plugin paganini::bs_price (100/100/1y/20%) = 8.8273
typed-plugin paganini::iv_schadner recovers sigma = 0.200000
shape guard fired (expected): shape mismatch: paganini::bs_price: expected input_dim=7, got 3
```

No Paganini source is compiled into gpu-backtest. See
[`examples/plugin-typed-real/README.md`](examples/plugin-typed-real/README.md).

### 3.11 Plugin: your own custom typed plugin — `examples/plugin-typed-custom/`

```bash
# needs a sibling gpu-backtest checkout
examples/plugin-typed-custom/run.sh
```

The same typed mechanism as 3.10 but with custom (non-Paganini) plugins, built
with `--features paganini-bridge` (stub — no `PAGANINI_DIST`). Asserted markers:
`linear_quant_demo`, `OrderFlowImbalance`, `Total orders emitted: 3`. See
[`examples/plugin-typed-custom/README.md`](examples/plugin-typed-custom/README.md)
and the comparison in [`examples/PLUGINS.md`](examples/PLUGINS.md).

### 3.12 CLI — `examples/cli/`

```bash
examples/cli/run.sh
```

**Expected:**

```
── paganini version ──
paganini 0.1.0
```

---

## 4. Confirm the no-source / no-binary rule

From a populated checkout, none of these should be tracked by git
(only produced under the gitignored `dist/`):

```bash
git -C . status --porcelain dist/                 # → nothing (ignored)
git -C . ls-files | grep -E '\.rs$|paganini\.h$|libpaganini|/paganini$'   # → no output
```

---

## 5. Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| `setup.sh: no Paganini checkout at '.../Paganini'` | sibling source not found | `export PAGANINI_SRC=/path/to/Paganini`, or set `PAGANINI_DIST` to a prebuilt dist |
| `libpaganini not found under .../dist/lib` | setup not run | run `./scripts/setup.sh` |
| `dyld: Library not loaded: libpaganini.dylib` (or `error while loading shared libraries`) | loader can't find the dylib | `source scripts/env.sh`, or set `DYLD_LIBRARY_PATH`/`LD_LIBRARY_PATH` to `$PAGANINI_DIST/lib` |
| Go: `cgo: C compiler not found` / build does nothing | cgo disabled or no `cc` | `export CGO_ENABLED=1`; install a C compiler |
| C static link: undefined symbols (`_CFRelease`, `pthread_*`, …) | Rust `std` runtime libs missing | use `build_and_run.sh` (adds the platform system libs), or link the dylib instead |
| `SKIP` lines in `run_all.sh` | that example's toolchain isn't installed | install the tool, or ignore — skips don't fail the gate |
