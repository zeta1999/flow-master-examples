# Time-series similarity (MASS)

Finds the nearest subsequence of a query pattern inside a longer series with
**MASS** (Mueen's Algorithm for Similarity Search) — an FFT-accelerated,
z-normalised Euclidean distance profile — via the binary-only C ABI. Plain C.

## Run

```bash
source ../../scripts/env.sh   # or: export PAGANINI_DIST=/path/to/dist
./build_and_run.sh
```

Expected output:

```
MASS profile_len=5
MASS profile[0]=0.0000 profile[4]=0.0000
MASS best_index=0 best_dist=0.0000
```

## What it does

The series `[1,2,3,4,1,2,3,4]` contains the query `[1,2,3,4]` twice — at
offset 0 and offset 4. `paganini_mass_profile` returns the distance profile
(length `n - m + 1 = 5`); both matches show distance ≈ 0, and the rest are
larger. `paganini_mass_best_match` is the convenience that returns just the
best offset and its distance.

Because the distances are **z-normalised**, MASS matches *shape*, not level
or scale — a pattern shifted up or stretched in amplitude still matches.

## C ABI used

```c
int32_t paganini_mass_profile(const double *series, size_t n,
                              const double *query, size_t m, double *out);
int32_t paganini_mass_best_match(const double *series, size_t n,
                                 const double *query, size_t m,
                                 size_t *out_index, double *out_dist);
```

`out` must hold `n - m + 1` doubles. Both return `-1` on a null pointer,
`m == 0`, `m > n`, or a numeric failure. Reference:
[`docs/BIBLIOGRAPHY.md`](../../../Paganini/docs/BIBLIOGRAPHY.md) (MASS / matrix
profile) in the Paganini repo.
