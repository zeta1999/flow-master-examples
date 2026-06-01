#!/usr/bin/env bash
#
# run_all.sh — the CI-grade gate behind TESTING.md.
#
# Ensures the binary-only dist exists (runs setup.sh if needed), then builds
# and runs every example, asserting the exact text each should print.
# Examples whose toolchain is absent are SKIPped (not failed). Prints a
# summary and exits non-zero iff any example FAILED.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

# 1. Ensure the binary-only dist.
export PAGANINI_DIST="${PAGANINI_DIST:-$REPO_ROOT/dist}"
if [ ! -d "$PAGANINI_DIST/lib" ]; then
    echo "── dist missing; running setup.sh ──"
    ./scripts/setup.sh
fi
case "$(uname -s)" in
    Darwin) export DYLD_LIBRARY_PATH="$PAGANINI_DIST/lib:${DYLD_LIBRARY_PATH:-}" ;;
    *)      export LD_LIBRARY_PATH="$PAGANINI_DIST/lib:${LD_LIBRARY_PATH:-}" ;;
esac

PASS=0 FAIL=0 SKIP=0
declare -a RESULTS

# run_check <label> <tool-to-require> <expect (';'-separated substrings)> <cmd...>
run_check() {
    local label="$1" tool="$2" expect="$3"; shift 3
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo "── SKIP $label (missing: $tool) ──"
        RESULTS+=("SKIP  $label (no $tool)"); SKIP=$((SKIP+1)); return
    fi
    echo "── $label ──"
    local out rc; out="$("$@" 2>&1)"; rc=$?
    echo "$out"
    if [ $rc -ne 0 ]; then
        RESULTS+=("FAIL  $label (exit $rc)"); FAIL=$((FAIL+1)); echo; return
    fi
    local miss="" tok
    local IFS=';'
    for tok in $expect; do
        [ -z "$tok" ] && continue
        grep -qF "$tok" <<<"$out" || miss="$miss [$tok]"
    done
    if [ -n "$miss" ]; then
        RESULTS+=("FAIL  $label (missing:$miss)"); FAIL=$((FAIL+1))
    else
        RESULTS+=("PASS  $label"); PASS=$((PASS+1))
    fi
    echo
}

# The numbers the four core FFI examples must produce (same libpaganini).
FFI="bid=99.3526;ask=100.6474;microprice=99.5000;variance=2.5000"

run_check "c"      cc       "$FFI" examples/c/build_and_run.sh
run_check "cpp"    c++      "$FFI" examples/cpp/build_and_run.sh
run_check "python" python3  "$FFI" examples/python/run.sh
run_check "go"     go       "$FFI" examples/go/run.sh

# Capability examples — each asserts its own output.
run_check "regime" python3 "shift_at=24;peak_index=24;peak_mass=1.0000" \
    examples/regime/run.sh
run_check "tss"    cc      "profile_len=5;profile[0]=0.0000;best_index=0;best_dist=0.0000" \
    examples/tss/build_and_run.sh
run_check "impact" go      "true_lambda=0.0500;estimated_lambda=0.0499" \
    examples/impact/run.sh

# CLI: separate assertion (it prints a version, not the FFI numbers).
if [ -x "$PAGANINI_DIST/bin/paganini" ]; then
    echo "── cli ──"
    out="$(examples/cli/run.sh 2>&1)"; rc=$?
    echo "$out"
    if [ $rc -eq 0 ] && grep -qE "paganini [0-9]" <<<"$out"; then
        RESULTS+=("PASS  cli"); PASS=$((PASS+1))
    else
        RESULTS+=("FAIL  cli"); FAIL=$((FAIL+1))
    fi
    echo
else
    RESULTS+=("SKIP  cli (no binary)"); SKIP=$((SKIP+1))
fi

echo "════════════════════════ SUMMARY ════════════════════════"
for r in "${RESULTS[@]}"; do echo "  $r"; done
echo "──────────────────────────────────────────────────────────"
echo "  PASS=$PASS  FAIL=$FAIL  SKIP=$SKIP"
echo

if [ "$FAIL" -eq 0 ]; then
    echo "ALL EXAMPLES PASSED"
    exit 0
else
    echo "SOME EXAMPLES FAILED"
    exit 1
fi
