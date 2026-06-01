#!/usr/bin/env bash
# Plugin B with REAL Paganini: register Paganini's bridge quants in
# gpu-backtest's TypedRegistry via a CAbiQuant adapter that dispatches over the
# binary-only libpaganini C ABI. No Paganini source is compiled into
# gpu-backtest — the algorithms stay in the Paganini repo; only libpaganini
# (from $PAGANINI_DIST) is linked.
#
# Counterpart to examples/aria/ (plugin A, also real Paganini). See
# examples/aria/PLUGINS.md for the comparison.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
DIST="${PAGANINI_DIST:-$(cd "$HERE/../../dist" && pwd)}"
GPU_BT="${GPU_BACKTEST_SRC:-$(cd "$HERE/../../../gpu-backtest" 2>/dev/null && pwd || true)}"

if ! command -v cargo >/dev/null 2>&1; then
    echo "SKIP: cargo not found"; exit 0
fi
if [ -z "$GPU_BT" ] || [ ! -f "$GPU_BT/Cargo.toml" ]; then
    echo "SKIP: gpu-backtest checkout not found (set GPU_BACKTEST_SRC=/path/to/gpu-backtest)"; exit 0
fi
if [ ! -d "$DIST/lib" ]; then
    echo "ERROR: $DIST/lib not found. Run ../../scripts/setup.sh first." >&2; exit 1
fi

echo "── real Paganini quants via gpu-backtest's TypedRegistry (C ABI) ──"
( cd "$GPU_BT" && PAGANINI_DIST="$DIST" \
    cargo run --quiet --example paganini_cabi_quant -p bt-bridge --features paganini-cabi )
