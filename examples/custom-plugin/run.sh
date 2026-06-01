#!/usr/bin/env bash
# CUSTOM plugin path: run gpu-backtest's bt-bridge typed-plugin examples.
#
# Counterpart to examples/aria/ (the DEFAULT, binary-only Paganini plugin).
# Here a developer implements their OWN QuantPlugin / FeaturePlugin /
# StrategyPlugin (Rust traits) and registers them in a TypedRegistry — the
# `paganini-bridge` path. Built with --features paganini-bridge, which uses
# gpu-backtest's bundled paganini-stub, so this needs NO PAGANINI_DIST.
#
# See examples/aria/PLUGINS.md for the default-vs-custom comparison.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
GPU_BT="${GPU_BACKTEST_SRC:-$(cd "$HERE/../../../gpu-backtest" 2>/dev/null && pwd || true)}"

if ! command -v cargo >/dev/null 2>&1; then
    echo "SKIP: cargo not found"; exit 0
fi
if [ -z "$GPU_BT" ] || [ ! -f "$GPU_BT/Cargo.toml" ]; then
    echo "SKIP: gpu-backtest checkout not found (set GPU_BACKTEST_SRC=/path/to/gpu-backtest)"; exit 0
fi

cd "$GPU_BT"
for ex in paganini_quant_plugin paganini_feature_plugin paganini_strategy_plugin; do
    echo "── bt-bridge custom plugin: $ex ──"
    cargo run --quiet --example "$ex" -p bt-bridge --features paganini-bridge
    echo
done
