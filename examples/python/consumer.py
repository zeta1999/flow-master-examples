#!/usr/bin/env python3
"""consumer.py — call Paganini from Python against a BINARY-ONLY build.

No compiler, no Paganini source: ctypes loads the compiled
libpaganini.{dylib,so} directly and declares the four stable C-ABI entry
points. Locate the library via $PAGANINI_DIST/lib (set by scripts/setup.sh).
"""
import ctypes
import math
import os
import sys


def _libpath() -> str:
    dist = os.environ.get("PAGANINI_DIST")
    if not dist:
        here = os.path.dirname(os.path.abspath(__file__))
        dist = os.path.normpath(os.path.join(here, "..", "..", "dist"))
    for name in ("libpaganini.dylib", "libpaganini.so"):
        cand = os.path.join(dist, "lib", name)
        if os.path.exists(cand):
            return cand
    sys.exit(f"ERROR: libpaganini not found under {dist}/lib — run scripts/setup.sh")


def load():
    lib = ctypes.CDLL(_libpath())

    lib.paganini_abi_version.restype = ctypes.c_uint32
    lib.paganini_abi_version.argtypes = []

    lib.paganini_as_quote.restype = ctypes.c_int32
    lib.paganini_as_quote.argtypes = [ctypes.c_double] * 6 + [
        ctypes.POINTER(ctypes.c_double),
        ctypes.POINTER(ctypes.c_double),
    ]

    lib.paganini_microprice.restype = ctypes.c_double
    lib.paganini_microprice.argtypes = [ctypes.c_double] * 4

    lib.paganini_sample_variance.restype = ctypes.c_double
    lib.paganini_sample_variance.argtypes = [
        ctypes.POINTER(ctypes.c_double),
        ctypes.c_size_t,
    ]
    return lib


def as_quote(lib, mid, inventory, gamma, k, sigma, time_left):
    bid, ask = ctypes.c_double(0.0), ctypes.c_double(0.0)
    rc = lib.paganini_as_quote(
        mid, inventory, gamma, k, sigma, time_left,
        ctypes.byref(bid), ctypes.byref(ask),
    )
    if rc != 0:
        return None
    return bid.value, ask.value


def sample_variance(lib, xs):
    arr = (ctypes.c_double * len(xs))(*xs)
    return lib.paganini_sample_variance(arr, len(xs))


def main():
    lib = load()
    print(f"paganini ABI version: {lib.paganini_abi_version()}")

    q = as_quote(lib, 100.0, 0.0, 0.1, 1.5, 0.2, 1.0)
    if q is None:
        sys.exit("as_quote: no quote")
    bid, ask = q
    print(f"AS quote bid={bid:.4f} ask={ask:.4f} spread={ask - bid:.4f}")

    mp = lib.paganini_microprice(99.0, 101.0, 5.0, 15.0)
    print(f"microprice={mp:.4f}")

    var = sample_variance(lib, [100.0, 101.0, 99.0, 102.0, 98.0])
    print(f"variance={var:.4f}")

    if math.isnan(sample_variance(lib, [100.0])):
        print("variance(n<2)=NaN (guard OK)")


if __name__ == "__main__":
    main()
