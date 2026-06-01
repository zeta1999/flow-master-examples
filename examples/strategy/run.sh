#!/usr/bin/env bash
# Build & run the market-making strategy skeleton against the binary-only
# dist, then show the same algos pre-loaded in the gpu-backtest plugin
# registry (the bundled paganini-example-bridge demo, if present).
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
DIST="${PAGANINI_DIST:-$(cd "$HERE/../../dist" && pwd)}"
LIB="$DIST/lib"
INC="$DIST/include"

if [ ! -d "$LIB" ]; then
    echo "ERROR: $LIB not found. Run ../../scripts/setup.sh first." >&2
    exit 1
fi

echo "── market-making strategy (built on the Paganini C ABI) ──"
CC="${CC:-cc}"
OUT="$(mktemp -d)"
"$CC" -std=c11 -Wall -Wextra -I "$INC" "$HERE/mm_strategy.c" \
      -L "$LIB" -lpaganini -lm -o "$OUT/mm_strategy"
DYLD_LIBRARY_PATH="$LIB" LD_LIBRARY_PATH="$LIB" "$OUT/mm_strategy"

echo
echo "── same algos via the gpu-backtest plugin registry (bundled demo) ──"
BRIDGE="$DIST/bin/paganini-example-bridge"
if [ -x "$BRIDGE" ]; then
    DYLD_LIBRARY_PATH="$LIB" LD_LIBRARY_PATH="$LIB" "$BRIDGE"
else
    echo "(paganini-example-bridge not in this dist — skipping; run scripts/setup.sh"
    echo " to build it, or see NOT_YET_EXPOSED.md)"
fi
