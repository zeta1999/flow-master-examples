# Go example

Calls Paganini from Go via **cgo**, linking the compiled `libpaganini`.

## Run

```bash
source ../../scripts/env.sh   # or: export PAGANINI_DIST=/path/to/dist
./run.sh
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

The four C entry points are declared in `main.go`'s cgo preamble (the comment
block immediately above `import "C"`), so no Paganini source is vendored.
Because the dist path is only known at runtime, the link and loader flags are
injected by `run.sh` rather than hard-coded in a `#cgo` directive:

```bash
export CGO_ENABLED=1
export CGO_LDFLAGS="-L$PAGANINI_DIST/lib -lpaganini"
export DYLD_LIBRARY_PATH="$PAGANINI_DIST/lib"   # LD_LIBRARY_PATH on Linux
go run .
```

Notes:

- cgo requires a C toolchain (`cc`) and `CGO_ENABLED=1` (cross-compiles
  disable cgo by default).
- Passing a Go slice to a `const double*` parameter:
  `(*C.double)(unsafe.Pointer(&xs[0]))` with `[]C.double` backing storage —
  fine because the C call does not retain the pointer.
- A harmless `ld: warning: ignoring duplicate libraries: '-lpaganini'` may
  appear on macOS; it does not affect the result.

See [`../c/README.md`](../c/README.md) for the algorithm explanations.
