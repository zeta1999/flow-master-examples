# C example

Calls Paganini's four C-ABI functions from plain C11, both **dynamically**
(against `libpaganini.dylib`/`.so`) and **statically** (against
`libpaganini.a`).

## Run

```bash
source ../../scripts/env.sh   # or: export PAGANINI_DIST=/path/to/dist
./build_and_run.sh
```

Expected output (twice — once per link mode):

```
paganini ABI version: 1
AS quote bid=99.3526 ask=100.6474 spread=1.2948
microprice=99.5000
variance=2.5000
variance(n<2)=NaN (guard OK)
```

## How the binary-only linkage works

`consumer.c` declares the four entry points with `extern` prototypes that
mirror `paganini.h` exactly — so the example file itself carries **no
Paganini source**. The compiler emits unresolved symbols; the linker
resolves them from the compiled library:

```
cc -I "$PAGANINI_DIST/include" consumer.c -L "$PAGANINI_DIST/lib" -lpaganini -lm
```

- **Dynamic:** `-lpaganini` picks `libpaganini.dylib`/`.so`; the loader finds
  it at runtime via `DYLD_LIBRARY_PATH` / `LD_LIBRARY_PATH`.
- **Static:** linking `libpaganini.a` directly pulls the Rust `std` runtime
  in, so you must add the platform system libraries (`-framework
  CoreFoundation -framework Security -lc++ -liconv` on macOS;
  `-lpthread -ldl -lm` on Linux). `build_and_run.sh` does this for you.

## The algorithms

- **Avellaneda–Stoikov** (`paganini_as_quote`): the canonical inventory-aware
  market-making quote. With flat inventory the bid/ask straddle the mid
  symmetrically; the spread widens with `γ` (risk aversion), `σ`
  (volatility), and time-to-horizon.
- **Microprice** (`paganini_microprice`): `(bid·ask_qty + ask·bid_qty) /
  (bid_qty + ask_qty)`. Here the ask carries 15 vs the bid's 5, so the fair
  value sits below the 100.00 mid, at 99.50. Returns `NaN` if total size ≤ 0.
- **Welford variance** (`paganini_sample_variance`): a numerically stable
  one-pass variance equal to the batch sample variance. Returns `NaN` for
  `n < 2` or a null pointer.
