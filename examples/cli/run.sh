#!/usr/bin/env bash
# Drive the `paganini` CLI binary from the binary-only dist (no FFI).
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
DIST="${PAGANINI_DIST:-$(cd "$HERE/../../dist" && pwd)}"
BIN="$DIST/bin/paganini"

if [ ! -x "$BIN" ]; then
    echo "ERROR: $BIN not found. Run ../../scripts/setup.sh first." >&2
    exit 1
fi

echo "── paganini version ──"
"$BIN" version

echo
echo "Note: the CLI surface is intentionally minimal today (only \`version\`)."
echo "Planned subcommands are tracked in ../../NOT_YET_EXPOSED.md."
