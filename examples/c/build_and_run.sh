#!/usr/bin/env bash
# Compile consumer.c against the binary-only Paganini dist and run it.
# Demonstrates BOTH a dynamic link (default) and a static link.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
DIST="${PAGANINI_DIST:-$(cd "$HERE/../../dist" && pwd)}"
INC="$DIST/include"
LIB="$DIST/lib"

if [ ! -d "$LIB" ]; then
    echo "ERROR: $LIB not found. Run ../../scripts/setup.sh first." >&2
    exit 1
fi

CC="${CC:-cc}"
OUT="$(mktemp -d)"

echo "── dynamic link (libpaganini.dylib/.so) ──"
"$CC" -std=c11 -Wall -Wextra -I "$INC" "$HERE/consumer.c" \
      -L "$LIB" -lpaganini -lm -o "$OUT/consumer_dyn"
DYLD_LIBRARY_PATH="$LIB" LD_LIBRARY_PATH="$LIB" "$OUT/consumer_dyn"

echo
echo "── static link (libpaganini.a) ──"
# Static archive needs the system libs Rust's std depends on.
case "$(uname -s)" in
    Darwin) SYSLIBS="-framework CoreFoundation -framework Security -lc++ -liconv" ;;
    *)      SYSLIBS="-lpthread -ldl -lm" ;;
esac
# shellcheck disable=SC2086
"$CC" -std=c11 -Wall -Wextra -I "$INC" "$HERE/consumer.c" \
      "$LIB/libpaganini.a" $SYSLIBS -lm -o "$OUT/consumer_static"
"$OUT/consumer_static"
