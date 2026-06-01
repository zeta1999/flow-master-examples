#!/usr/bin/env bash
# Compile consumer.cpp against the binary-only Paganini dist and run it.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
DIST="${PAGANINI_DIST:-$(cd "$HERE/../../dist" && pwd)}"
LIB="$DIST/lib"

if [ ! -d "$LIB" ]; then
    echo "ERROR: $LIB not found. Run ../../scripts/setup.sh first." >&2
    exit 1
fi

CXX="${CXX:-c++}"
OUT="$(mktemp -d)"

echo "── compiling C++ consumer (dynamic link) ──"
"$CXX" -std=c++17 -Wall -Wextra "$HERE/consumer.cpp" \
       -L "$LIB" -lpaganini -o "$OUT/consumer_cpp"
DYLD_LIBRARY_PATH="$LIB" LD_LIBRARY_PATH="$LIB" "$OUT/consumer_cpp"
