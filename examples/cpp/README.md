# C++ example

Wraps Paganini's C ABI in a small idiomatic `paganini` namespace — C++17
`std::optional<Quote>` for the AS quote, `std::vector<double>` for variance —
then calls it. Links dynamically against `libpaganini`.

## Run

```bash
source ../../scripts/env.sh   # or: export PAGANINI_DIST=/path/to/dist
./build_and_run.sh
```

Expected output:

```
paganini ABI version: 1
AS quote bid=99.3526 ask=100.6474 spread=1.2948
microprice=99.5000
variance=2.5000
variance(n<2)=NaN (guard OK)
```

## How the binary-only linkage works

`consumer.cpp` declares the C entry points inside an `extern "C" { … }` block
(so the symbols are not name-mangled) and wraps them — no Paganini source is
included. Build:

```
c++ -std=c++17 consumer.cpp -L "$PAGANINI_DIST/lib" -lpaganini
```

> Your editor may flag `std::optional` if it defaults to an older C++
> standard; the build uses `-std=c++17`, where it is valid.

The wrapper shows the idiomatic-binding pattern: map the C `rc != 0` failure
to `std::nullopt`, and accept any contiguous container by passing
`.data()` / `.size()` to `paganini_sample_variance`.

See [`../c/README.md`](../c/README.md) for the algorithm explanations
(Avellaneda–Stoikov, microprice, Welford).
