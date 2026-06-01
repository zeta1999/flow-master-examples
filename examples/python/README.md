# Python example

Calls Paganini from Python with the standard-library `ctypes` module — **no
compiler, no build step, no third-party packages**. The most accessible way
to consume the binary build.

## Run

```bash
source ../../scripts/env.sh   # or: export PAGANINI_DIST=/path/to/dist
./run.sh                       # or: python3 consumer.py
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

`ctypes.CDLL(".../libpaganini.dylib")` loads the compiled library at runtime;
no header and no Paganini source are needed. You then declare each function's
`argtypes` / `restype` so Python marshals C doubles correctly:

```python
lib.paganini_microprice.restype  = ctypes.c_double
lib.paganini_microprice.argtypes = [ctypes.c_double] * 4
```

Two marshalling details worth copying:

- **Out-parameters** (`paganini_as_quote` writes `*bid`/`*ask`): pass
  `ctypes.byref(c_double(...))` and read `.value` back after the call.
- **Arrays** (`paganini_sample_variance` takes `const double*`): build a
  `(c_double * n)(*xs)` C array and pass it plus the length.

`NaN` sentinels come straight through as Python floats — check with
`math.isnan`.

See [`../c/README.md`](../c/README.md) for the algorithm explanations.
