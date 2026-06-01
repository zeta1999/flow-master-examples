#!/usr/bin/env python3
"""regime/consumer.py — BOCPD change-point detection over a return series,
against a BINARY-ONLY Paganini build (ctypes, no compiler, no source).

Calls `paganini_bocpd_changepoints`: feed a sequence of observations, get a
per-step "recent change mass" — small under a stationary regime, spiking
right after a regime shift.
"""
import ctypes
import os
import sys


def load():
    dist = os.environ.get("PAGANINI_DIST") or os.path.normpath(
        os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "dist")
    )
    for name in ("libpaganini.dylib", "libpaganini.so"):
        cand = os.path.join(dist, "lib", name)
        if os.path.exists(cand):
            lib = ctypes.CDLL(cand)
            break
    else:
        sys.exit(f"ERROR: libpaganini not found under {dist}/lib — run scripts/setup.sh")

    lib.paganini_bocpd_changepoints.restype = ctypes.c_int32
    lib.paganini_bocpd_changepoints.argtypes = [
        ctypes.POINTER(ctypes.c_double),  # xs
        ctypes.c_size_t,                  # n
        ctypes.c_double,                  # hazard_lambda
        ctypes.c_double,                  # alpha
        ctypes.c_double,                  # beta
        ctypes.c_size_t,                  # window
        ctypes.POINTER(ctypes.c_double),  # out_mass
    ]
    return lib


def changepoints(lib, xs, hazard_lambda, alpha, beta, window):
    n = len(xs)
    arr = (ctypes.c_double * n)(*xs)
    out = (ctypes.c_double * n)()
    rc = lib.paganini_bocpd_changepoints(arr, n, hazard_lambda, alpha, beta, window, out)
    if rc != 0:
        sys.exit(f"bocpd failed rc={rc}")
    return list(out)


def main():
    lib = load()

    # 24 stationary observations near 0.0, then a hard level shift to 3.0.
    series = [0.0] * 24 + [3.0] * 8
    mass = changepoints(lib, series, hazard_lambda=50.0, alpha=5.0, beta=1e-3, window=10)

    # The detector should light up right where the regime changes (index 24).
    peak_i = max(range(len(mass)), key=lambda i: mass[i])
    print(f"BOCPD series_len={len(series)} shift_at=24")
    print(f"BOCPD peak_index={peak_i} peak_mass={mass[peak_i]:.4f}")
    print(f"BOCPD stationary_mass[20]={mass[20]:.4f}")


if __name__ == "__main__":
    main()
