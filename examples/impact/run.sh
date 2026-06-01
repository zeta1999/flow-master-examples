#!/usr/bin/env bash
# Build & run the Kyle's-lambda market-impact calibration example (cgo)
# against the binary-only Paganini dist.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
DIST="${PAGANINI_DIST:-$(cd "$HERE/../../dist" && pwd)}"
LIB="$DIST/lib"

if [ ! -d "$LIB" ]; then
    echo "ERROR: $LIB not found. Run ../../scripts/setup.sh first." >&2
    exit 1
fi

export CGO_ENABLED=1
export CGO_LDFLAGS="-L$LIB -lpaganini"
export DYLD_LIBRARY_PATH="$LIB:${DYLD_LIBRARY_PATH:-}"
export LD_LIBRARY_PATH="$LIB:${LD_LIBRARY_PATH:-}"

cd "$HERE"
exec go run .
