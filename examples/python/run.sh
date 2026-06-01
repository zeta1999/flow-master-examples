#!/usr/bin/env bash
# Run the Python ctypes consumer against the binary-only Paganini dist.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
PY="${PYTHON:-python3}"
exec "$PY" "$HERE/consumer.py"
