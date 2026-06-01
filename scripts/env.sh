# env.sh — `source` this to point a shell at the binary-only Paganini dist.
#
#   source scripts/env.sh
#
# It exports PAGANINI_DIST (defaulting to ./dist produced by setup.sh) and
# adds the library dir to the dynamic loader path + the CLI to PATH, so the
# examples and the `paganini` binary "just work" in this shell.

_env_root="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")/.." && pwd)"
export PAGANINI_DIST="${PAGANINI_DIST:-$_env_root/dist}"

if [ ! -d "$PAGANINI_DIST/lib" ]; then
    echo "warning: $PAGANINI_DIST/lib not found — run ./scripts/setup.sh first" >&2
fi

case "$(uname -s)" in
    Darwin) export DYLD_LIBRARY_PATH="$PAGANINI_DIST/lib:${DYLD_LIBRARY_PATH:-}" ;;
    *)      export LD_LIBRARY_PATH="$PAGANINI_DIST/lib:${LD_LIBRARY_PATH:-}" ;;
esac
export PATH="$PAGANINI_DIST/bin:$PATH"

echo "PAGANINI_DIST=$PAGANINI_DIST"
