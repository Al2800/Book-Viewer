#!/usr/bin/env bash
set -euo pipefail

# BookQuotes UI Test Runner
# Runs UI tests with screenshot capture and detailed logging
#
# Environment variables:
#   SCHEME          - Xcode scheme (default: BookQuotes)
#   TEST_PLAN       - Test plan name (optional; only passed if set)
#   DESTINATION     - Simulator destination (default: iPhone 17)
#   ARTIFACTS_DIR   - Output directory (default: artifacts/ui-tests)
#   ONLY_TESTING    - Specific test target to run (optional)
#   RETRY_COUNT     - Number of retries for flaky tests (default: 1)
#   TIMEOUT         - Test timeout in seconds (default: 1200)
#   DESTINATION_TIMEOUT - Destination discovery timeout in seconds (default: 60)
#   UI_TEST_RUNTIME_TRACK - "stable" (default) prefers iOS 18.6 sims for better AX stability,
#                           "latest" prefers iOS 26.2 sims.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT="$PROJECT_DIR/BookQuotes.xcodeproj"
SCHEME="${SCHEME:-BookQuotes}"
TEST_PLAN="${TEST_PLAN:-}"
DESTINATION="${DESTINATION:-}"

SCRIPT_SLUG="$(basename "${BASH_SOURCE[0]}" .sh)"
GIT_SHA="$(git -C "$PROJECT_DIR" rev-parse --short HEAD 2>/dev/null || echo nogit)"
RUN_ID="${RUN_ID:-$(date +%Y%m%d_%H%M%S)-$GIT_SHA}"
ARTIFACTS_BASE="${ARTIFACTS_BASE:-$PROJECT_DIR/artifacts}"
ARTIFACTS_DIR="${ARTIFACTS_DIR:-$ARTIFACTS_BASE/$SCRIPT_SLUG/$RUN_ID}"

LOGS_DIR="$ARTIFACTS_DIR/logs"
XCRESULTS_DIR="$ARTIFACTS_DIR/xcresults"
REPORTS_DIR="$ARTIFACTS_DIR/reports"
SCREENSHOTS_DIR="$ARTIFACTS_DIR/screenshots"

RESULT_BUNDLE_BASE="${XCRESULTS_DIR}/ui-tests"
LOG_FILE_BASE="${LOGS_DIR}/ui-tests"
RESULT_BUNDLE=""
LOG_FILE=""
ONLY_TESTING="${ONLY_TESTING:-}"
RETRY_COUNT="${RETRY_COUNT:-1}"
TIMEOUT="${TIMEOUT:-1200}"
UI_TEST_RUNTIME_TRACK="${UI_TEST_RUNTIME_TRACK:-stable}"

# Default simulator selection (only if DESTINATION is not provided).
pick_default_sim_udid() {
  python3 - <<'PY'
import json
import subprocess
import sys

try:
    p = subprocess.run(
        ["xcrun", "simctl", "list", "-j", "devices", "available"],
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        timeout=30,
    )
    data = json.loads(p.stdout)
except Exception:
    # Fallback: use text output and grab the first iPhone UDID we can find.
    try:
        import re

        p2 = subprocess.run(
            ["xcrun", "simctl", "list", "devices", "available"],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            timeout=30,
        )
        for line in (p2.stdout or "").splitlines():
            if "iPhone" not in line:
                continue
            m = re.search(r"([0-9A-F-]{36})", line)
            if m:
                print(m.group(1))
                sys.exit(0)
    except Exception:
        pass

    print("")
    sys.exit(0)

devices = data.get("devices", {}) or {}
ios_runtimes = [rt for rt in devices.keys() if "SimRuntime.iOS-" in rt]

track = (__import__("os").environ.get("UI_TEST_RUNTIME_TRACK") or "stable").strip().lower()

def runtime_rank(rt: str) -> int:
    # UI tests are often more reliable on older runtimes on hosted CI/MacInCloud.
    # Prefer iOS 18.6 unless explicitly asked for "latest".
    if track != "latest":
        if "SimRuntime.iOS-18-6" in rt:
            return 0
        if "SimRuntime.iOS-18-" in rt:
            return 1
        if "SimRuntime.iOS-26-2" in rt:
            return 2
        if "SimRuntime.iOS-26-1" in rt:
            return 3
        if "SimRuntime.iOS-26-0" in rt:
            return 4
        return 9

    if "SimRuntime.iOS-26-2" in rt:
        return 0
    if "SimRuntime.iOS-26-1" in rt:
        return 1
    if "SimRuntime.iOS-26-0" in rt:
        return 2
    if "SimRuntime.iOS-18-6" in rt:
        return 3
    if "SimRuntime.iOS-18-" in rt:
        return 4
    return 9

ios_runtimes_sorted = sorted(ios_runtimes, key=runtime_rank)
preferred_runtimes = [rt for rt in ios_runtimes_sorted if runtime_rank(rt) <= 2]
fallback_runtimes = [rt for rt in ios_runtimes_sorted if runtime_rank(rt) > 2]

def iter_devs(runtimes):
    for rt in runtimes:
        for d in devices.get(rt, []) or []:
            yield rt, d

def is_available_iphone(d: dict) -> bool:
    return d.get("isAvailable") and ("iPhone" in (d.get("name") or ""))

for rt in preferred_runtimes:
    for d in devices.get(rt, []) or []:
        if is_available_iphone(d) and d.get("state") == "Booted" and d.get("udid"):
            print(d["udid"])
            sys.exit(0)

for rt, d in iter_devs(preferred_runtimes):
    name = (d.get("name") or "")
    if is_available_iphone(d) and (("iPhone 17" in name) or ("iPhone Air" in name) or ("iPhone 16" in name)) and d.get("udid"):
        print(d["udid"])
        sys.exit(0)

for rt, d in iter_devs(preferred_runtimes):
    if is_available_iphone(d) and d.get("udid"):
        print(d["udid"])
        sys.exit(0)

for rt in fallback_runtimes:
    for d in devices.get(rt, []) or []:
        if is_available_iphone(d) and d.get("state") == "Booted" and d.get("udid"):
            print(d["udid"])
            sys.exit(0)

for rt, d in iter_devs(fallback_runtimes):
    if is_available_iphone(d) and "iPhone 16" in (d.get("name") or "") and d.get("udid"):
        print(d["udid"])
        sys.exit(0)

for rt, d in iter_devs(fallback_runtimes):
    if is_available_iphone(d) and d.get("udid"):
        print(d["udid"])
        sys.exit(0)

print("")
PY
}

if [[ -z "${DESTINATION}" ]]; then
  # Prefer a filesystem-derived simulator UDID to avoid hanging on simctl when CoreSimulator is wedged.
  DEFAULT_UDID="$(python3 - <<'PY'
import glob
import os
import plistlib

wanted = [
    "iPhone 17 Pro",
    "iPhone 17 Pro Max",
    "iPhone Air",
    "iPhone 17",
    "iPhone 16 Pro",
    "iPhone 16",
]

track = (os.environ.get("UI_TEST_RUNTIME_TRACK") or "stable").strip().lower()

def runtime_rank(runtime: str) -> int:
    # Same rationale as pick_default_sim_udid(): older runtimes can be more AX-stable on hosted Macs.
    if track != "latest":
        if "SimRuntime.iOS-18-6" in runtime:
            return 0
        if "SimRuntime.iOS-18-" in runtime:
            return 1
        if "SimRuntime.iOS-26-2" in runtime:
            return 2
        if "SimRuntime.iOS-26-1" in runtime:
            return 3
        if "SimRuntime.iOS-26-0" in runtime:
            return 4
        return 9

    if "SimRuntime.iOS-26-2" in runtime:
        return 0
    if "SimRuntime.iOS-26-1" in runtime:
        return 1
    if "SimRuntime.iOS-26-0" in runtime:
        return 2
    if "SimRuntime.iOS-18-6" in runtime:
        return 3
    if "SimRuntime.iOS-18-" in runtime:
        return 4
    return 9

best = None  # (runtime_rank, booted_rank, name_rank, udid)
paths = glob.glob(os.path.expanduser("~/Library/Developer/CoreSimulator/Devices/*/device.plist"))
for path in paths:
    try:
        with open(path, "rb") as f:
            pl = plistlib.load(f)
    except Exception:
        continue

    name = (pl.get("name") or "").strip()
    if not name:
        continue
    if "iPhone" not in name:
        continue

    runtime = (pl.get("runtime") or "").strip()
    rr = runtime_rank(runtime)

    state = pl.get("state")
    booted_rank = 0 if state == 3 else 1

    for rank, pat in enumerate(wanted):
        if pat in name:
            udid = os.path.basename(os.path.dirname(path))
            cand = (rr, booted_rank, rank, udid)
            if best is None or cand < best:
                best = cand
            break

if best:
    print(best[3])
else:
    print("")
PY
)"
  if [[ -z "${DEFAULT_UDID}" ]]; then
    DEFAULT_UDID="$(pick_default_sim_udid)"
  fi
  if [[ -n "${DEFAULT_UDID}" ]]; then
    DESTINATION="platform=iOS Simulator,id=${DEFAULT_UDID}"
  else
    DESTINATION="platform=iOS Simulator,name=iPhone 17"
  fi
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
  echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
  echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

run_with_timeout() {
  local timeout_s="$1"
  shift

  if command -v timeout >/dev/null 2>&1; then
    timeout "$timeout_s" "$@"
    return $?
  fi

  if command -v gtimeout >/dev/null 2>&1; then
    gtimeout "$timeout_s" "$@"
    return $?
  fi

  # macOS does not always ship `timeout`. Use a small Python wrapper as a fallback.
  python3 - "$timeout_s" "$@" <<'PY'
import selectors
import subprocess
import sys
import time

timeout = float(sys.argv[1])
cmd = sys.argv[2:]

proc = subprocess.Popen(
    cmd,
    stdout=subprocess.PIPE,
    stderr=subprocess.STDOUT,
    text=True,
    bufsize=1,
)

sel = selectors.DefaultSelector()
assert proc.stdout is not None
sel.register(proc.stdout, selectors.EVENT_READ)

start = time.monotonic()
timed_out = False

while True:
    if time.monotonic() - start > timeout:
        timed_out = True
        break

    events = sel.select(timeout=0.25)
    for key, _ in events:
        line = key.fileobj.readline()
        if not line:
            continue
        sys.stdout.write(line)
        sys.stdout.flush()

    if proc.poll() is not None:
        # Drain remaining output.
        remaining = proc.stdout.read()
        if remaining:
            sys.stdout.write(remaining)
            sys.stdout.flush()
        break

if timed_out:
    try:
        proc.terminate()
        proc.wait(timeout=5)
    except Exception:
        try:
            proc.kill()
        except Exception:
            pass
    sys.exit(124)

sys.exit(proc.returncode or 0)
PY
}

write_diagnostics_header() {
  log_info "Diagnostics:"
  log_info "  run_id: $RUN_ID"
  log_info "  git_sha: $GIT_SHA"
  log_info "  scheme: $SCHEME"
  log_info "  destination: $DESTINATION"
  log_info "  artifacts: $ARTIFACTS_DIR"

  local diag_file="${REPORTS_DIR}/diagnostics.txt"
  {
    echo "run_id=$RUN_ID"
    echo "script=$SCRIPT_SLUG"
    echo "project_dir=$PROJECT_DIR"
    echo "git_sha=$GIT_SHA"
    echo ""
    echo "xcode_select=$(xcode-select -p 2>/dev/null || true)"
    echo ""
    xcodebuild -version 2>/dev/null || true
    echo ""
    sw_vers 2>/dev/null || true
    echo ""
    echo "SCHEME=$SCHEME"
    echo "DESTINATION=$DESTINATION"
    echo "TEST_PLAN=$TEST_PLAN"
    echo "ONLY_TESTING=$ONLY_TESTING"
    echo "RETRY_COUNT=$RETRY_COUNT"
    echo "TIMEOUT=$TIMEOUT"
    echo ""
    run_with_timeout 30 xcrun simctl list devices available 2>/dev/null || true
  } > "$diag_file" 2>&1 || true

  log_info "Diagnostics file: $diag_file"
}

destination_sim_udid() {
  local destination="$1"

  if [[ "$destination" == *"id="* ]]; then
    local id="${destination#*id=}"
    id="${id%%,*}"
    echo "$id"
    return 0
  fi

  if [[ "$destination" == *"name="* ]]; then
    local name="${destination#*name=}"
    name="${name%%,*}"
    /usr/bin/find "$HOME/Library/Developer/CoreSimulator/Devices" -maxdepth 2 -name device.plist -print 2>/dev/null | while IFS= read -r plist; do
      dn=$(/usr/bin/plutil -extract name raw -o - "$plist" 2>/dev/null || true)
      [[ -z "$dn" ]] && continue
      if [[ "$dn" == "$name" ]] || [[ "$dn" == *"$name"* ]]; then
        basename "$(dirname "$plist")"
        break
      fi
    done
    return 0
  fi

  echo ""
}

normalize_destination_to_udid() {
  # Normalize name-based destinations into an explicit UDID. xcodebuild sometimes fails to resolve
  # simulator names even when simctl can, but it generally works when given an id= destination.
  if [[ "$DESTINATION" == *"platform=iOS Simulator"* ]] && [[ "$DESTINATION" == *"name="* ]] && [[ "$DESTINATION" != *"id="* ]]; then
    local udid
    udid="$(destination_sim_udid "$DESTINATION")"
    if [[ -n "$udid" ]]; then
      DESTINATION="platform=iOS Simulator,id=${udid}"
    fi
  fi
}

boot_simulator_with_retries() {
  local udid="$1"
  local max_attempts="${SIM_BOOT_RETRY_COUNT:-3}"
  local bootstatus_timeout_s="${SIM_BOOTSTATUS_TIMEOUT:-}"
  local attempt=1

  if [[ -z "$udid" ]]; then
    return 0
  fi

  # Default bootstatus timeout: older iOS runtimes can take longer to reach a "terminal" boot state
  # on hosted Macs. Prefer a more patient default on the stable track.
  if [[ -z "${bootstatus_timeout_s}" ]]; then
    if [[ "${UI_TEST_RUNTIME_TRACK}" == "latest" ]]; then
      bootstatus_timeout_s=120
    else
      bootstatus_timeout_s=180
    fi
  fi

  log_info "Ensuring simulator is booted: $udid (max_attempts=$max_attempts)"

  while [[ $attempt -le $max_attempts ]]; do
    if [[ $attempt -gt 1 ]]; then
      log_warn "Simulator boot retry $attempt/$max_attempts..."
      sleep $((attempt * 2))
    fi

    run_with_timeout 20 xcrun simctl boot "$udid" 2>/dev/null || true
    if run_with_timeout "$bootstatus_timeout_s" xcrun simctl bootstatus "$udid" -b 2>/dev/null; then
      return 0
    fi

    {
      echo "bootstatus failed (attempt=$attempt udid=$udid destination=$DESTINATION time=$(date))"
      run_with_timeout 30 xcrun simctl list devices "$udid" 2>/dev/null || true
    } > "${REPORTS_DIR}/sim-bootstatus-failure-attempt${attempt}.txt" 2>&1 || true

    attempt=$((attempt + 1))
  done

  return 1
}

ensure_destination_simulator_booted() {
  local udid
  udid="$(destination_sim_udid "$DESTINATION")"
  [[ -z "$udid" ]] && return 0
  boot_simulator_with_retries "$udid"
}

recover_simulator_for_retry() {
  local udid
  udid="$(destination_sim_udid "$DESTINATION")"
  [[ -z "$udid" ]] && return 0

  log_warn "Attempting simulator recovery for retry (udid=$udid)..."

  # Best-effort: restart Simulator + CoreSimulator if the runtime is wedged.
  # AX flake (XCTDaemonErrorDomain 18/19) is often only recoverable by restarting CoreSimulatorService.
  killall Simulator 2>/dev/null || true
  killall com.apple.CoreSimulator.CoreSimulatorService 2>/dev/null || true
  killall -9 Simulator 2>/dev/null || true
  killall -9 com.apple.CoreSimulator.CoreSimulatorService 2>/dev/null || true
  sleep 3

  open -a Simulator --args -CurrentDeviceUDID "$udid" >/dev/null 2>&1 || true
  run_with_timeout 20 xcrun simctl shutdown "$udid" 2>/dev/null || true
  run_with_timeout 20 xcrun simctl boot "$udid" 2>/dev/null || true
  run_with_timeout "${SIM_BOOTSTATUS_TIMEOUT:-90}" xcrun simctl bootstatus "$udid" -b 2>/dev/null || true
}

create_fresh_simulator() {
  # Non-destructive: creates a new simulator device and returns its UDID.
  # This can work around cases where an existing device becomes permanently flaky with AX init.
  local runtime_id=""
  local device_type_id=""
  if [[ "${UI_TEST_RUNTIME_TRACK}" == "latest" ]]; then
    runtime_id="${FRESH_SIM_RUNTIME_ID:-com.apple.CoreSimulator.SimRuntime.iOS-26-2}"
    device_type_id="${FRESH_SIM_DEVICE_TYPE_ID:-com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro-Max}"
  else
    runtime_id="${FRESH_SIM_RUNTIME_ID:-com.apple.CoreSimulator.SimRuntime.iOS-18-6}"
    device_type_id="${FRESH_SIM_DEVICE_TYPE_ID:-com.apple.CoreSimulator.SimDeviceType.iPhone-16-Pro}"
  fi
  local name="BookQuotes-UITest-$(date +%Y%m%d-%H%M%S)"

  # IMPORTANT: write logs to stderr so the caller can capture stdout as a clean UDID.
  log_warn "Creating a fresh simulator device (runtime=$runtime_id device=$device_type_id name=$name)..." >&2

  local udid
  udid="$(run_with_timeout 30 xcrun simctl create "$name" "$device_type_id" "$runtime_id" 2>/dev/null || true)"
  udid="$(echo "$udid" | tr -d '\r\n' | tail -n 1)"
  if [[ -z "$udid" ]]; then
    log_warn "Failed to create fresh simulator (simctl create returned empty)." >&2
    echo ""
    return 1
  fi

  echo "$udid"
  return 0
}

maybe_switch_to_fresh_simulator() {
  # If AX init is repeatedly failing, create a new simulator and switch DESTINATION to it.
  local attempt="$1"
  local max_attempts="$2"
  local enabled="${FRESH_SIM_ON_AX_FAILURE:-1}"

  [[ "$enabled" == "1" ]] || return 0

  # Only switch once we have at least 2 failures, and still have retries left.
  if [[ "$attempt" -lt 2 ]] || [[ "$attempt" -ge "$max_attempts" ]]; then
    return 0
  fi

  local new_udid
  new_udid="$(create_fresh_simulator)"
  if [[ -n "$new_udid" ]]; then
    DESTINATION="platform=iOS Simulator,id=${new_udid}"
    log_warn "Switched destination to fresh simulator: $DESTINATION"
    open -a Simulator >/dev/null 2>&1 || true
    ensure_destination_simulator_booted || true
  fi
}

is_accessibility_init_failure() {
  local log_file="$1"
  [[ -f "$log_file" ]] || return 1
  grep -Eq "XCTDaemonErrorDomain.*Code=(18|19)|AX loaded notification|AXDisableAccessibilityOnTermination" "$log_file"
}

capture_failure_artifacts() {
  local attempt="$1"

  local udid
  udid="$(destination_sim_udid "$DESTINATION")"
  if [[ -z "$udid" ]]; then
    udid="booted"
  fi

  # Best-effort: grab a screenshot and some diagnostics. These may fail if the simulator isn't booted.
  run_with_timeout 15 xcrun simctl io "$udid" screenshot "${SCREENSHOTS_DIR}/failure-attempt${attempt}.png" 2>/dev/null || true
  run_with_timeout 30 xcrun simctl diagnose "$udid" > "${REPORTS_DIR}/simctl-diagnose-attempt${attempt}.txt" 2>&1 || true
  run_with_timeout 30 xcrun simctl spawn "$udid" log collect --output "${REPORTS_DIR}/simulator-logs-attempt${attempt}.logarchive" --last 5m 2>/dev/null || true
}

# Setup
setup() {
  log_info "Setting up UI test run..."
  mkdir -p "$LOGS_DIR" "$XCRESULTS_DIR" "$REPORTS_DIR" "$SCREENSHOTS_DIR"
  normalize_destination_to_udid
  write_diagnostics_header
  # Keeping Simulator open (and selecting the destination) tends to reduce first-run accessibility flake.
  local udid
  udid="$(destination_sim_udid "$DESTINATION")"
  if [[ -n "$udid" ]]; then
    open -a Simulator --args -CurrentDeviceUDID "$udid" >/dev/null 2>&1 || true
  else
    open -a Simulator >/dev/null 2>&1 || true
  fi
  ensure_destination_simulator_booted || log_warn "Simulator bootstatus did not succeed; proceeding anyway."

  # Intentionally avoid destructive cleanup steps here.
}

# Run tests with retry logic
run_tests() {
  local attempt=1
  local max_attempts=$((RETRY_COUNT + 1))

  while [[ $attempt -le $max_attempts ]]; do
    if [[ $attempt -gt 1 ]]; then
      log_warn "Retry attempt $attempt of $max_attempts..."
      # On retry, don't erase simulator - may have useful state
      recover_simulator_for_retry
      sleep 5
    fi

    log_info "Running UI tests (attempt $attempt)..."

    # Set environment for test artifacts
    export UI_TEST_ARTIFACTS_DIR="$ARTIFACTS_DIR"
    export CAPTURE_UI_TEST_CHECKPOINTS=1
    export WRITE_UI_TEST_LOGS=1

    RESULT_BUNDLE="${RESULT_BUNDLE_BASE}-attempt${attempt}.xcresult"
    LOG_FILE="${LOG_FILE_BASE}-attempt${attempt}.log"

    local CMD=(
      xcodebuild test
      -project "$PROJECT"
      -scheme "$SCHEME"
      -destination "$DESTINATION"
      -destination-timeout "${DESTINATION_TIMEOUT:-60}"
      -resultBundlePath "$RESULT_BUNDLE"
    )

    if [[ -n "$TEST_PLAN" ]]; then
      CMD+=(-testPlan "$TEST_PLAN")
    fi

    if [[ -n "$ONLY_TESTING" ]]; then
      CMD+=(-only-testing:"$ONLY_TESTING")
    fi

    # Save the exact invocation for reproducibility.
    printf '%q ' "${CMD[@]}" > "${REPORTS_DIR}/xcodebuild-command-attempt${attempt}.txt"
    echo "" >> "${REPORTS_DIR}/xcodebuild-command-attempt${attempt}.txt"

    # Run with timeout
    if run_with_timeout "$TIMEOUT" "${CMD[@]}" 2>&1 | tee "$LOG_FILE"; then
      return 0
    fi

    local EXIT_CODE=$?
    if [[ $EXIT_CODE -eq 124 ]]; then
      log_error "Test run timed out after ${TIMEOUT}s"
    fi

    # Capture per-attempt artifacts; wedged sims can change after recovery.
    capture_failure_artifacts "$attempt"

    # If we hit the common AX initialization flake, do an immediate recovery before retrying.
    if is_accessibility_init_failure "$LOG_FILE"; then
      log_warn "Detected accessibility init failure in attempt $attempt; forcing simulator recovery..."
      recover_simulator_for_retry
      sleep 5

      # If it's failing repeatedly, try a fresh simulator device (non-destructive create).
      maybe_switch_to_fresh_simulator "$attempt" "$max_attempts"
    fi

    attempt=$((attempt + 1))
  done

  return 1
}

# Extract screenshots from xcresult
extract_screenshots() {
  if [[ -d "$RESULT_BUNDLE" ]]; then
    log_info "Extracting screenshots from test results..."

    # Use xcresulttool to extract attachments
    xcrun xcresulttool get --path "$RESULT_BUNDLE" --format json > "${REPORTS_DIR}/results.json" 2>/dev/null || true

    # Copy any screenshots captured during test
    if [[ -d "$SCREENSHOTS_DIR" ]] && [[ "$(ls -A "$SCREENSHOTS_DIR" 2>/dev/null)" ]]; then
      log_info "Screenshots saved to: $SCREENSHOTS_DIR"
    fi
  fi
}

# Extract test summary
extract_summary() {
  if [[ -f "$LOG_FILE" ]]; then
    log_info "Test summary:"
    grep -E "(Test Suite|Executed|passed|failed|Failing tests)" "$LOG_FILE" | tail -20 || true
  fi
}

# Generate failure report
generate_failure_report() {
  if [[ -f "$LOG_FILE" ]]; then
    local FAILURE_REPORT="${REPORTS_DIR}/failures.txt"

    log_info "Generating failure report..."

    {
      echo "UI Test Failure Report"
      echo "======================"
      echo "Timestamp: $(date)"
      echo ""
      echo "Failed Tests:"
      grep -A 5 "failed" "$LOG_FILE" || echo "No failures found in log"
      echo ""
      echo "Errors:"
      grep -i "error:" "$LOG_FILE" | head -20 || echo "No errors found in log"
    } > "$FAILURE_REPORT"

    log_info "Failure report: $FAILURE_REPORT"
  fi
}

# Cleanup old artifacts
cleanup_old_artifacts() {
  log_warn "Skipping artifact cleanup to avoid deleting files without approval."
}

# Main
main() {
  local START_TIME=$(date +%s)

  setup

  if run_tests; then
    log_info "UI tests passed!"
    extract_screenshots
    extract_summary
    cleanup_old_artifacts

    local END_TIME=$(date +%s)
    log_info "Duration: $((END_TIME - START_TIME))s"
    log_info "Artifacts: $ARTIFACTS_DIR"
    exit 0
  else
    log_error "UI tests failed!"
    extract_screenshots
    extract_summary
    generate_failure_report
    capture_failure_artifacts "$((RETRY_COUNT + 1))"

    local END_TIME=$(date +%s)
    log_info "Duration: $((END_TIME - START_TIME))s"
    log_info "Logs: $LOG_FILE"
    log_info "Screenshots: $SCREENSHOTS_DIR"
    log_info "Results: $RESULT_BUNDLE"
    exit 1
  fi
}

main
