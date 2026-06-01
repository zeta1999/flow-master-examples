#!/usr/bin/env bash
# Plugin B with REAL Paganini, binary-only: register Paganini's bridge quants in
# gpu-backtest's TypedRegistry via a CAbiQuant adapter that dispatches over the
# binary-only libpaganini C ABI. No Paganini source is compiled into
# gpu-backtest — only libpaganini (from $PAGANINI_DIST) is linked.
#
# Counterpart to examples/plugin-aria-dsl/. See examples/PLUGINS.md.
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

# ── what actually runs ── this example has NO local logic; the executed code
#    lives in the gpu-backtest repo and is built/run there.
EX="$GPU_BT/crates/bt-bridge/examples/paganini_cabi_quant.rs"   # the demo main
ADAPTER="$GPU_BT/crates/bt-bridge/src/cabi.rs"                  # CAbiQuant: QuantPlugin → C ABI
echo "Executed code (in the gpu-backtest repo):"
echo "  example : $EX"
echo "  adapter : $ADAPTER"
echo "  command : cargo run --example paganini_cabi_quant -p bt-bridge --features paganini-cabi"
echo "  (read either file to see what runs; SHOW_SOURCE=1 prints them inline)"
if [ "${SHOW_SOURCE:-0}" = "1" ]; then
    for f in "$ADAPTER" "$EX"; do
        echo; echo "────── $f ──────"; cat "$f"
    done
fi
echo

echo "── real Paganini quants via gpu-backtest's TypedRegistry (C ABI) ──"
( cd "$GPU_BT" && PAGANINI_DIST="$DIST" \
    cargo run --quiet --example paganini_cabi_quant -p bt-bridge --features paganini-cabi )
