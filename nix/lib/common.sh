# ============================================================================
# ontrack flake apps - shared library.
# NOTE: shellcheck SC2329 ("function never invoked") is excluded for these
# apps in flake.nix (excludeShellChecks): this file is a shared library and
# each app only calls a subset of its functions. A file-wide
# `# shellcheck disable=SC2329` was tried and does not reliably suppress the
# check in the assembled scripts, so the exclusion lives in the derivation.
#
# Inlined at the top of every `nix run .#<app>` script (see flake.nix).
# Provides: dependency verification, markdown report generation, safety
# checks (cargo-deny / cargo-audit), an lldb-dap breakpoint smoke test,
# and scratch-dir cleanup via an EXIT trap.
#
# Conventions: `ot_` prefix on all globals/functions. The report file
# (reports/<app>-<UTC timestamp>.md, gitignored) is the only persistent
# artifact an app leaves behind.
# ============================================================================

set -euo pipefail

# --- repo-root guard ----------------------------------------------------------
# Apps use paths relative to the ontrack checkout; refuse to run elsewhere.
if [ ! -f "Cargo.toml" ] || [ ! -d "crates" ]; then
    echo "FATAL: run from the ontrack repo root, e.g. 'nix run .#gates'." >&2
    exit 2
fi

# --- scratch space (always cleaned) -------------------------------------------
OT_SCRATCH="$(mktemp -d "${TMPDIR:-/tmp}/ot-flake-XXXXXX")"
ot_cleanup() {
    rm -rf "${OT_SCRATCH}"
}
trap ot_cleanup EXIT

OT_FAILED=0
OT_REPORT=""

# --- dependency verification --------------------------------------------------
# Every app declares its full dependency set up front. Missing tools fail
# fast and name the exact binary, so a red report always says WHY.
ot_check_deps() {
    local missing=""
    local dep
    for dep in "$@"; do
        if ! command -v "${dep}" >/dev/null 2>&1; then
            missing="${missing} ${dep}"
        fi
    done
    if [ -n "${missing}" ]; then
        echo "FATAL: missing required tools:${missing}" >&2
        echo "All app dependencies must come from the flake (pinned nixpkgs);" >&2
        echo "nothing is installed at runtime. Check docs/FLAKE.md." >&2
        exit 2
    fi
}

# --- report -------------------------------------------------------------------
ot_start_report() {
    local app="$1"
    mkdir -p reports
    OT_REPORT="reports/${app}-$(date -u +%Y%m%d-%H%M%S).md"
    {
        echo "# ontrack flake report: ${app}"
        echo
        echo "- date (UTC): $(date -u +%Y-%m-%dT%H:%M:%SZ)"
        echo "- repo: $(pwd)"
        echo "- commit: $(git rev-parse HEAD 2>/dev/null || echo unknown)"
        echo "- rustc: $(rustc --version 2>/dev/null || echo unknown)"
        echo "- lldb-dap: $(command -v lldb-dap 2>/dev/null || echo missing)"
        echo
    } >"${OT_REPORT}"
    # Snapshot the tree now; ot_verify_clean fails only on NEW dirt, so
    # pre-existing uncommitted work (e.g. the flake files themselves before
    # the first commit) never trips the check.
    git status --porcelain >"${OT_SCRATCH}/tree-before.txt" 2>/dev/null || true
}

ot_section() {
    {
        echo
        echo "## $1"
        echo
    } >>"${OT_REPORT}"
}

# ot_result <name> <PASS|FAIL|SKIP|WARN> <detail>
ot_result() {
    printf -- "- %s: **%s** %s\n" "$1" "$2" "$3" >>"${OT_REPORT}"
    echo "[$2] $1 $3"
}

# ot_step <label> <cmd...> - run, transcribe output to the report, latch failure.
ot_step() {
    local label="$1"
    shift
    {
        echo
        echo "### ${label}"
        echo
        echo '```'
    } >>"${OT_REPORT}"
    echo "==> ${label}"
    if "$@" >>"${OT_REPORT}" 2>&1; then
        echo '```' >>"${OT_REPORT}"
        ot_result "${label}" PASS ""
    else
        echo '```' >>"${OT_REPORT}"
        ot_result "${label}" FAIL "see transcript above"
        OT_FAILED=1
    fi
}

# --- safety checks -------------------------------------------------------------
# deny.toml is the single source of truth for accepted-risk advisories.
# cargo-audit does not read deny.toml, so translate its [advisories] ignore
# list (entries of the form { id = "RUSTSEC-...", reason = "..." }) into
# --ignore flags here. Anything NOT listed in deny.toml still fails the
# audit gate -- this hides nothing, it just makes the two tools agree.
ot_audit_ignores() {
    grep -oE '\{[[:space:]]*id[[:space:]]*=[[:space:]]*"RUSTSEC-[0-9-]+"' deny.toml 2>/dev/null \
        | grep -oE 'RUSTSEC-[0-9-]+' || true
}
ot_safety_checks() {
    ot_section "Safety checks"
    if command -v cargo-deny >/dev/null 2>&1; then
        ot_step "cargo deny check" cargo deny check
    else
        ot_result "cargo deny check" SKIP "cargo-deny not installed"
    fi
    if command -v cargo-audit >/dev/null 2>&1; then
        _ot_audit_flags=()
        _ot_id=""
        while IFS= read -r _ot_id; do
            [ -n "${_ot_id}" ] && _ot_audit_flags+=(--ignore "${_ot_id}")
        done < <(ot_audit_ignores)
        ot_step "cargo audit (deny.toml ignores applied)" cargo audit "${_ot_audit_flags[@]}"
        unset _ot_audit_flags _ot_id
    else
        ot_result "cargo audit" SKIP "cargo-audit not installed"
    fi
}

# --- lldb-dap breakpoint smoke test ---------------------------------------------
# Locate the ontrack-core lib unit-test binary across cargo output layouts:
# the classic shared target/debug/deps, and the per-unit
# target/debug/build/<crate>/<hash>/out layout (cargo 1.100-nightly+).
# Newest first, so a just-built binary wins over stale ones.
ot_find_testbin() {
    find target/debug/deps target/debug/build/ontrack-core \
        -type f -executable -name 'ontrack_core-*' ! -name '*.d' 2>/dev/null \
        | while IFS= read -r f; do
            printf '%s\t%s\n' "$(stat -c %Y "$f")" "$f"
        done | sort -rn | head -n 1 | cut -f2-
}

ot_debug_smoke() {
    ot_section "Debugger smoke test (lldb-dap)"
    echo "==> lldb-dap breakpoint smoke test"
    local py="${OT_SCRATCH}/dap_smoke.py"
    cat >"${py}" <<'PYEOF'
#!/usr/bin/env python3
"""lldb-dap smoke test: breakpoint -> launch test binary -> confirm hit.

lldb-dap quirks handled here (verified against lldb 21.1.8):
- the `initialized` event arrives AFTER `launch`, not after `initialize`;
- the debuggee does not run until the client answers `initialized`
  with `configurationDone`;
- setFunctionBreakpoints/setBreakpoints responses report verified=false
  until the target module loads; the breakpoint flips to resolved after
  launch. The verdict therefore rests on an actual stop, not on the
  set-response's verified flag.

Flow: initialize -> set breakpoints (function name + source line fallback)
-> launch one unit test -> on `initialized` send `configurationDone` ->
wait for stop-on-breakpoint -> stackTrace must show the target function.

Prints a one-line verdict FIRST, then detail lines.
Exit codes: 0 = PASS, 1 = FAIL, 3 = SKIP (environment/tooling problem).
Stdlib only.
"""
import json
import queue
import subprocess
import sys
import threading
import time

TIMEOUT_S = 120


def encode(msg):
    body = json.dumps(msg).encode("utf-8")
    return b"Content-Length: %d\r\n\r\n" % len(body) + body


class Reader(threading.Thread):
    def __init__(self, proc):
        super().__init__(daemon=True)
        self.proc = proc
        self.queue = queue.Queue()

    def run(self):
        stream = self.proc.stdout
        while True:
            headers = {}
            while True:
                line = stream.readline()
                if not line:
                    return
                line = line.strip()
                if not line:
                    break
                name, _, value = line.partition(b":")
                headers[name.strip().lower()] = value.strip()
            try:
                size = int(headers.get(b"content-length", b"0"))
            except ValueError:
                continue
            if size <= 0:
                continue
            body = stream.read(size)
            if not body:
                return
            try:
                self.queue.put(json.loads(body))
            except ValueError:
                continue


def main(argv):
    lldb_dap, testbin, funcname, testfilter, srcfile, srcline_raw = argv[1:7]
    try:
        srcline = int(srcline_raw)
    except ValueError:
        print("SKIP: could not locate `pub fn solve_tsp` source line")
        return 3
    try:
        proc = subprocess.Popen(
            [lldb_dap],
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
        )
    except OSError as exc:
        print("SKIP: cannot start lldb-dap: %s" % exc)
        return 3
    reader = Reader(proc)
    reader.start()
    seq = 0
    details = []

    def send(command, arguments=None):
        nonlocal seq
        seq += 1
        msg = {"seq": seq, "type": "request", "command": command}
        if arguments is not None:
            msg["arguments"] = arguments
        proc.stdin.write(encode(msg))
        proc.stdin.flush()
        return seq

    def stop(reason_text):
        print(reason_text)
        try:
            send("disconnect", {"terminateDebuggee": True})
        except (OSError, ValueError):
            pass
        try:
            proc.wait(timeout=10)
        except subprocess.TimeoutExpired:
            proc.kill()

    # 1. initialize: wait for the RESPONSE. lldb-dap sends `initialized`
    #    only after `launch`, so it is not awaited here.
    req = send("initialize", {
        "clientID": "ot-flake-dap-smoke",
        "adapterID": "lldb-dap",
        "pathFormat": "path",
        "linesStartAt1": True,
        "columnsStartAt1": True,
    })
    init_resp = None
    deadline = time.monotonic() + 30
    while time.monotonic() < deadline and init_resp is None:
        try:
            msg = reader.queue.get(timeout=1.0)
        except queue.Empty:
            continue
        if (msg.get("type") == "response"
                and msg.get("request_seq") == req):
            init_resp = msg
    if init_resp is None or not init_resp.get("success", False):
        stop("SKIP: lldb-dap initialize failed or timed out")
        return 3

    # 2. set breakpoints: by function name, plus a source-line fallback.
    #    Record lldb's verified claim, but do not gate on it: the verdict
    #    rests on an actual stop below.
    req = send("setFunctionBreakpoints", {"breakpoints": [{"name": funcname}]})
    deadline = time.monotonic() + 30
    while time.monotonic() < deadline:
        try:
            msg = reader.queue.get(timeout=1.0)
        except queue.Empty:
            continue
        if (msg.get("type") == "response"
                and msg.get("request_seq") == req):
            bps = (msg.get("body") or {}).get("breakpoints") or []
            claimed = bool(bps) and bool(bps[0].get("verified"))
            details.append(
                "detail: setFunctionBreakpoints(%r) claimed verified=%s"
                % (funcname, claimed))
            break
    req = send("setBreakpoints", {
        "source": {"path": srcfile},
        "breakpoints": [{"line": srcline}],
    })
    deadline = time.monotonic() + 30
    while time.monotonic() < deadline:
        try:
            msg = reader.queue.get(timeout=1.0)
        except queue.Empty:
            continue
        if (msg.get("type") == "response"
                and msg.get("request_seq") == req):
            bps = (msg.get("body") or {}).get("breakpoints") or []
            claimed = bool(bps) and bool(bps[0].get("verified"))
            details.append(
                "detail: setBreakpoints(%s:%d) claimed verified=%s"
                % (srcfile, srcline, claimed))
            break

    # 3. launch the test binary, then drive the session in one event loop:
    #    the launch RESPONSE, the `initialized` event (answered with
    #    `configurationDone` -- the debuggee does not run until then), and
    #    finally a stop-on-breakpoint or process exit, in whatever order.
    launch_seq = send("launch", {
        "program": testbin,
        "args": [testfilter, "--exact", "--nocapture"],
        "stopOnEntry": False,
    })
    launch_ok = None
    config_done = False
    config_deadline = time.monotonic() + 15
    stopped = None
    exited = False
    deadline = time.monotonic() + TIMEOUT_S
    while time.monotonic() < deadline:
        remaining = deadline - time.monotonic()
        try:
            msg = reader.queue.get(timeout=min(1.0, remaining))
        except queue.Empty:
            if proc.poll() is not None:
                break
            if not config_done and time.monotonic() > config_deadline:
                # `initialized` never arrived; try to unblock the debuggee.
                send("configurationDone", {})
                config_done = True
                details.append(
                    "detail: sent configurationDone without initialized "
                    "event (fallback)")
            continue
        mtype = msg.get("type")
        if mtype == "response" and msg.get("request_seq") == launch_seq:
            launch_ok = bool(msg.get("success", False))
            if not launch_ok:
                details.append("detail: launch error: %s"
                               % msg.get("message", "unknown"))
                break
        elif mtype == "event":
            ev = msg.get("event")
            if ev == "initialized" and not config_done:
                send("configurationDone", {})
                config_done = True
            elif (ev == "stopped" and msg.get("body", {}).get("reason")
                    in ("breakpoint", "function breakpoint")):
                stopped = msg
                break
            elif ev in ("exited", "terminated"):
                exited = True
                break

    if not launch_ok:
        stop("FAIL: launch request failed\n" + "\n".join(details))
        return 1
    if stopped is None:
        if exited:
            stop("FAIL: debuggee exited without hitting the breakpoint\n"
                 + "\n".join(details))
        else:
            stop("FAIL: timed out waiting for the breakpoint to hit\n"
                 + "\n".join(details))
        return 1
    thread_id = stopped.get("body", {}).get("threadId", 1)

    req = send("stackTrace", {"threadId": thread_id, "levels": 20})
    frames = []
    deadline = time.monotonic() + 30
    while time.monotonic() < deadline:
        try:
            msg = reader.queue.get(timeout=1.0)
        except queue.Empty:
            continue
        if (msg.get("type") == "response"
                and msg.get("request_seq") == req):
            frames = (msg.get("body") or {}).get("stackFrames") or []
            break
    hit = any(funcname in (f.get("name") or "") for f in frames)
    details.append("detail: top frames: %s"
                   % [f.get("name") for f in frames[:4]])
    if hit:
        stop("PASS: breakpoint hit at %s (thread %s)\n%s"
             % (funcname, thread_id, "\n".join(details)))
        return 0
    stop("FAIL: stopped on breakpoint but %s not on the stack\n%s"
         % (funcname, "\n".join(details)))
    return 1


if __name__ == "__main__":
    sys.exit(main(sys.argv))
PYEOF

    local testbin
    testbin="$(ot_find_testbin || true)"
    if [ -z "${testbin}" ]; then
        echo "==> building ontrack-core test binary"
        if ! cargo test -p ontrack-core --no-run --locked >>"${OT_REPORT}" 2>&1; then
            ot_result "debug smoke: build test binary" FAIL "cargo test -p ontrack-core --no-run failed"
            OT_FAILED=1
            return
        fi
        testbin="$(ot_find_testbin || true)"
    fi
    if [ -z "${testbin}" ]; then
        ot_result "debug smoke" SKIP "no ontrack-core test binary found after build"
        return
    fi
    local src_line
    src_line="$(grep -n "pub fn solve_tsp" crates/ontrack-core/src/solver.rs 2>/dev/null | head -n 1 | cut -d: -f1 || true)"
    local out="${OT_SCRATCH}/dap.log"
    local rc=0
    python3 "${py}" "$(command -v lldb-dap)" "${testbin}" \
        "ontrack_core::solver::solve_tsp" "solver::tests::solves_trivial_route" \
        "$(pwd)/crates/ontrack-core/src/solver.rs" "${src_line}" >"${out}" 2>&1 || rc=$?
    cat "${out}" >>"${OT_REPORT}"
    local verdict
    verdict="$(head -n 1 "${out}" 2>/dev/null || true)"
    if [ "${rc}" -eq 0 ]; then
        ot_result "debug smoke: breakpoint resolves and hits" PASS "${verdict}"
    elif [ "${rc}" -eq 3 ]; then
        ot_result "debug smoke" SKIP "${verdict}"
    else
        ot_result "debug smoke: breakpoint resolves and hits" FAIL "${verdict}"
        OT_FAILED=1
    fi
}

# --- cleanup verification -----------------------------------------------------
# Fail only on NEW dirt: compare the current tree against the snapshot taken
# in ot_start_report. Pre-existing uncommitted work never trips the check.
# reports/ (the report itself), target/ (cargo cache) and OT_CLEAN_EXTRAS
# dirs are always excluded from both sides.
ot_verify_clean() {
    ot_section "Cleanup verification"
    echo "==> verifying no new dirty paths (reports/, target/, extras excluded)"
    local pat='^.{3}(reports/|target/'
    local extra
    # shellcheck disable=SC2086 # intentional word-splitting of dir list
    for extra in ${OT_CLEAN_EXTRAS:-}; do
        pat="${pat}|${extra}/"
    done
    pat="${pat})"
    local before_f="${OT_SCRATCH}/tree-before-filtered.txt"
    local after_f="${OT_SCRATCH}/tree-after-filtered.txt"
    grep -vE "${pat}" "${OT_SCRATCH}/tree-before.txt" 2>/dev/null | sort >"${before_f}" || true
    git status --porcelain 2>/dev/null | grep -vE "${pat}" | sort >"${after_f}" || true
    local new
    new="$(comm -13 "${before_f}" "${after_f}" || true)"
    if [ -z "${new}" ]; then
        ot_result "worktree clean" PASS "no new dirty paths since run start"
    else
        printf '%s\n' "${new}" >>"${OT_REPORT}"
        ot_result "worktree clean" FAIL "new dirty paths since run start (listed above)"
        OT_FAILED=1
    fi
}
