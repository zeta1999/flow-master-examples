# Market-impact calibration (Kyle's λ)

Calibrates **Kyle's λ** — the linear price-impact coefficient — from a trade
tape using online recursive least squares, via the binary-only C ABI. Go +
cgo.

## Run

```bash
source ../../scripts/env.sh   # or: export PAGANINI_DIST=/path/to/dist
./run.sh
```

Expected output:

```
Kyle trades=10 true_lambda=0.0500
Kyle estimated_lambda=0.0499
```

## What it does

We synthesise a tape of 10 trades where each trade moves the mid by
`λ · signed_volume` with a known `λ = 0.05` (`+qty` = buy, `−qty` = sell).
`paganini_kyle_lambda` regresses the per-trade mid change on signed volume
with RLS (forgetting factor `0.99`) and recovers `λ ≈ 0.0499` — i.e. it backs
out the impact coefficient from the tape alone.

On real data, λ is the slope of "how far does the mid move per unit of signed
flow" — a core input to optimal execution and adverse-selection models.

## C ABI used

```c
double paganini_kyle_lambda(const double *signed_volumes, const double *mids,
                            size_t n, double lambda_ff, double p0);
```

`mids[i]` is the mid **after** trade `i`. `lambda_ff` is the RLS forgetting
factor (~0.99), `p0` the initial inverse covariance (~1.0). Returns `NaN` on a
null pointer or `n < 2`. References (Kyle 1985; RLS — Haykin):
`Paganini/docs/BIBLIOGRAPHY.md` (in the Paganini source checkout) in the
Paganini repo.

See [`../go/README.md`](../go/README.md) for cgo specifics (`CGO_ENABLED`,
loader path, the harmless duplicate-library warning).
