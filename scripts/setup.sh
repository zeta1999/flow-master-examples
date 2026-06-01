#!/usr/bin/env bash
#
# setup.sh — produce a *binary-only* Paganini distribution this repo can
# consume, without ever committing Paganini source or binaries here.
#
# Two modes:
#   1. You already have an unpacked release tarball:
#        export PAGANINI_DIST=/path/to/unpacked   # must contain lib/ + include/
#        ./scripts/setup.sh                        # validates it, then exits
#   2. Local dev (default): builds the C-ABI + CLI from the sibling Paganini
#      source checkout and assembles ./dist with ONLY the binary artifacts
#      (lib + header + CLI + read-only docs) — mirroring DISTRIBUTION.md §8.
#
# The assembled ./dist is gitignored. Nothing Paganini-owned is tracked by
# this repo; we only *consume* the compiled binary surface.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PAGANINI_SRC="${PAGANINI_SRC:-$(cd "$REPO_ROOT/.." && pwd)/Paganini}"

# Platform-specific dynamic-library suffix.
case "$(uname -s)" in
    Darwin) DYLIB="libpaganini.dylib" ;;
    Linux)  DYLIB="libpaganini.so" ;;
    *)      DYLIB="libpaganini.so" ;;  # best effort
esac

is_populated_dist() { [ -n "${1:-}" ] && [ -d "$1/lib" ] && [ -d "$1/include" ]; }

# Mode 1: caller supplied an external dist (an unpacked release tarball).
if [ -n "${PAGANINI_DIST:-}" ] && is_populated_dist "$PAGANINI_DIST"; then
    echo "✓ Using pre-supplied PAGANINI_DIST=$PAGANINI_DIST"
    echo "  (skipping local build)"
    exit 0
fi

# Mode 2: build from the sibling source checkout, assemble ./dist.
DIST="$REPO_ROOT/dist"
echo "── Paganini source checkout: $PAGANINI_SRC"
if [ ! -f "$PAGANINI_SRC/Cargo.toml" ]; then
    echo "ERROR: no Paganini checkout at '$PAGANINI_SRC'." >&2
    echo "       Set PAGANINI_SRC=/path/to/Paganini, or set PAGANINI_DIST to an" >&2
    echo "       already-unpacked binary release." >&2
    exit 1
fi

echo "── Building the binary-only surface (c-api + cli + bridge demo, release) ──"
( cd "$PAGANINI_SRC" && cargo build --release \
    -p paganini-c-api -p paganini-cli \
    -p paganini-example --bin paganini-example-bridge )

REL="$PAGANINI_SRC/target/release"
HDR="$PAGANINI_SRC/crates/paganini-c-api/include/paganini.h"

echo "── Assembling $DIST (binary-only; gitignored) ──"
rm -rf "$DIST"
mkdir -p "$DIST/lib" "$DIST/include" "$DIST/bin" "$DIST/docs"

cp "$REL/libpaganini.a"   "$DIST/lib/"
cp "$REL/$DYLIB"          "$DIST/lib/"
cp "$HDR"                 "$DIST/include/"
cp "$REL/paganini"        "$DIST/bin/"
# Bundled demo binary: the gpu-backtest plugin path (DISTRIBUTION.md §8 ships
# bin/paganini-example). Copied only if it built.
[ -f "$REL/paganini-example-bridge" ] && cp "$REL/paganini-example-bridge" "$DIST/bin/" || true
# Read-only docs that ship with the binary distribution (DISTRIBUTION.md §8).
for d in DISTRIBUTION.md getting_started.md; do
    [ -f "$PAGANINI_SRC/docs/$d" ] && cp "$PAGANINI_SRC/docs/$d" "$DIST/docs/" || true
done

echo
echo "✓ Binary-only dist ready at: $DIST"
echo
echo "  Add this to your shell (or run examples via scripts/run_all.sh):"
echo "      export PAGANINI_DIST=\"$DIST\""
echo
echo "  Contents:"
( cd "$DIST" && find . -type f | sort | sed 's/^/      /' )
