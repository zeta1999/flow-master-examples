# Regime detection (BOCPD)

Detects a regime change in a return series using **Bayesian Online
Change-Point Detection** (Adams & MacKay, 2007), via the binary-only C ABI.
Python + `ctypes` — no compiler, no Paganini source.

## Run

```bash
source ../../scripts/env.sh   # or: export PAGANINI_DIST=/path/to/dist
./run.sh                       # or: python3 consumer.py
```

Expected output:

```
BOCPD series_len=32 shift_at=24
BOCPD peak_index=24 peak_mass=1.0000
BOCPD stationary_mass[20]=0.0398
```

## What it does

The input is 24 stationary observations near `0.0` followed by a hard level
shift to `3.0`. `paganini_bocpd_changepoints` runs the detector once over the
whole series and returns, per step, the **recent-change mass** — the
posterior probability that a change point occurred within the last `window`
steps.

- Under the stationary regime that mass stays small — a few times the
  per-step hazard `1/λ = 0.02` (here `≈0.0398` at index 20).
- At the shift (index 24) it **spikes to ≈1.0** — the detector is almost
  certain a new regime began.

The argmax of the returned profile is the most-likely change point: `24`,
exactly where the level shifts.

## C ABI used

```c
int32_t paganini_bocpd_changepoints(const double *xs, size_t n,
                                    double hazard_lambda, double alpha,
                                    double beta, size_t window,
                                    double *out_mass);
```

Params: `hazard_lambda` = expected run length (here 50), `alpha`/`beta` = the
Normal-Inverse-Gamma variance prior (here `5`, `1e-3` — a tight prior so a
single outlier is identifiable), `window` = how many recent run lengths count
as "post-change" (`0` → 10). Returns `-1` on a null pointer, `n == 0`, or a
non-finite observation. The reference is the
`Paganini/docs/BIBLIOGRAPHY.md` (in the Paganini source checkout) entry for
BOCPD in the Paganini repo.
