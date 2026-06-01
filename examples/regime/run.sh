#!/usr/bin/env bash
# Run the BOCPD regime-detection example (ctypes) against the binary-only dist.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
exec "${PYTHON:-python3}" "$HERE/consumer.py"
