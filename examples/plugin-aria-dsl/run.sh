#!/usr/bin/env bash
# Run the Paganini-powered Aria strategy through gpu-backtest's bt-engine.
#
# Builds bt-engine with --features paganini (which links the binary-only
# libpaganini from our dist), then backtests microprice_mm.aria on gpu-backtest's
# bundled synthetic data. The Aria strategy calls pag_microprice() / pag_bs_price()
# which resolve over the libpaganini C ABI — Paganini consumed binary-only.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
DIST="${PAGANINI_DIST:-$(cd "$HERE/../../dist" && pwd)}"
GPU_BT="${GPU_BACKTEST_SRC:-$(cd "$HERE/../../../gpu-backtest" 2>/dev/null && pwd || true)}"

if ! command -v cargo >/dev/null 2>&1; then
    echo "SKIP: cargo not found (needed to build bt-engine)"; exit 0
fi
if [ -z "$GPU_BT" ] || [ ! -f "$GPU_BT/Cargo.toml" ]; then
    echo "SKIP: gpu-backtest checkout not found (set GPU_BACKTEST_SRC=/path/to/gpu-backtest)"; exit 0
fi
if [ ! -d "$DIST/lib" ]; then
    echo "ERROR: $DIST/lib not found. Run ../../scripts/setup.sh first." >&2; exit 1
fi

DUCKDB="$GPU_BT/data/synth_oss.duckdb"
if [ ! -f "$DUCKDB" ]; then
    echo "── generating gpu-backtest synthetic dataset (one-time) ──"
    ( cd "$GPU_BT" && cargo run --release --quiet --bin bt-engine -- synth-data "$DUCKDB" )
fi

echo "── building bt-engine --features paganini (links libpaganini from dist) ──"
( cd "$GPU_BT" && PAGANINI_DIST="$DIST" cargo build --release --quiet -p bt-engine --features paganini )
BTE="$GPU_BT/target/release/bt-engine"

# Resolve the config's path placeholders to absolute paths.
CFG="$(mktemp -d)/microprice_mm.toml"
sed -e "s#__ARIA__#$HERE/microprice_mm.aria#" \
    -e "s#__DUCKDB__#$DUCKDB#" \
    "$HERE/microprice_mm.toml" > "$CFG"

echo "── running the Paganini-powered Aria backtest ──"
DYLD_LIBRARY_PATH="$DIST/lib" LD_LIBRARY_PATH="$DIST/lib" "$BTE" "$CFG"
