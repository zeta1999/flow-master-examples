#!/usr/bin/env bash
# Plugin B (mechanism only): run gpu-backtest's bt-bridge typed-plugin examples,
# where a developer implements their OWN QuantPlugin / FeaturePlugin /
# StrategyPlugin (Rust traits) and registers them in a TypedRegistry.
#
# Built with --features paganini-bridge, which uses gpu-backtest's bundled
# paganini-stub — so this needs NO PAGANINI_DIST and links NO Paganini. It
# shows the plugin *mechanism*; for real Paganini through the same registry see
# examples/plugin-typed-real/. Comparison: examples/PLUGINS.md.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
GPU_BT="${GPU_BACKTEST_SRC:-$(cd "$HERE/../../../gpu-backtest" 2>/dev/null && pwd || true)}"

if ! command -v cargo >/dev/null 2>&1; then
    echo "SKIP: cargo not found"; exit 0
fi
if [ -z "$GPU_BT" ] || [ ! -f "$GPU_BT/Cargo.toml" ]; then
    echo "SKIP: gpu-backtest checkout not found (set GPU_BACKTEST_SRC=/path/to/gpu-backtest)"; exit 0
fi

# ── what actually runs ── three examples whose source lives in the gpu-backtest
#    repo (not here). Read them at the paths below; SHOW_SOURCE=1 prints them.
echo "Executed code (in the gpu-backtest repo, crates/bt-bridge/examples/):"
for ex in paganini_quant_plugin paganini_feature_plugin paganini_strategy_plugin; do
    echo "  $GPU_BT/crates/bt-bridge/examples/$ex.rs"
done
echo "  command : cargo run --example <name> -p bt-bridge --features paganini-bridge"
echo

cd "$GPU_BT"
for ex in paganini_quant_plugin paganini_feature_plugin paganini_strategy_plugin; do
    echo "── custom plugin: $ex ($GPU_BT/crates/bt-bridge/examples/$ex.rs) ──"
    if [ "${SHOW_SOURCE:-0}" = "1" ]; then
        cat "crates/bt-bridge/examples/$ex.rs"; echo
    fi
    cargo run --quiet --example "$ex" -p bt-bridge --features paganini-bridge
    echo
done
