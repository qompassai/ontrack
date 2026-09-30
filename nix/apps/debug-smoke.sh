# ot-debug-smoke: standalone lldb-dap breakpoint smoke test.
#
# Drives lldb-dap over DAP against the ontrack-core unit-test binary:
# sets a breakpoint on ontrack_core::solver::solve_tsp (source-line
# fallback), launches the single test that calls it, and confirms the
# breakpoint is hit with the function on the stack.
# Verdict is PASS / FAIL / SKIP - never faked.
ot_check_deps cargo python3 lldb-dap git
ot_start_report "debug-smoke"

ot_debug_smoke
ot_verify_clean

echo "report: ${OT_REPORT}"
if [ "${OT_FAILED}" -ne 0 ]; then
    echo "DEBUG-SMOKE FAILED - see ${OT_REPORT}" >&2
fi
exit "${OT_FAILED}"
