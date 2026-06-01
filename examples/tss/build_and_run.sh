#!/usr/bin/env bash
# Compile the MASS (TSS) C consumer against the binary-only dist and run it.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
DIST="${PAGANINI_DIST:-$(cd "$HERE/../../dist" && pwd)}"
LIB="$DIST/lib"
INC="$DIST/include"

if [ ! -d "$LIB" ]; then
    echo "ERROR: $LIB not found. Run ../../scripts/setup.sh first." >&2
    exit 1
fi

CC="${CC:-cc}"
OUT="$(mktemp -d)"
"$CC" -std=c11 -Wall -Wextra -I "$INC" "$HERE/consumer.c" \
      -L "$LIB" -lpaganini -lm -o "$OUT/tss"
DYLD_LIBRARY_PATH="$LIB" LD_LIBRARY_PATH="$LIB" "$OUT/tss"
