#!/usr/bin/env bash
set -euo pipefail

# BookQuotes E2E Full Test Suite
# Runs all integration and UI tests with artifact collection
#
# Usage:
#   ./scripts/e2e_full.sh                    # Run all tests
#   ./scripts/e2e_full.sh --integration      # Integration tests only
#   ./scripts/e2e_full.sh --ui               # UI tests only

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

SCRIPT_SLUG="$(basename "${BASH_SOURCE[0]}" .sh)"
GIT_SHA="$(git -C "$PROJECT_DIR" rev-parse --short HEAD 2>/dev/null || echo nogit)"
RUN_ID="${RUN_ID:-$(date +%Y%m%d_%H%M%S)-$GIT_SHA}"
ARTIFACTS_BASE="${ARTIFACTS_BASE:-$PROJECT_DIR/artifacts}"
ARTIFACTS_DIR="${ARTIFACTS_DIR:-$ARTIFACTS_BASE/$SCRIPT_SLUG/$RUN_ID}"
SUITE_LOG="$ARTIFACTS_DIR/logs/suite.log"
REPORTS_DIR="$ARTIFACTS_DIR/reports"

RUN_INTEGRATION=true
RUN_UI=true

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --integration)
      RUN_UI=false
      shift
      ;;
    --ui)
      RUN_INTEGRATION=false
      shift
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
  echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
  echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

write_diagnostics_header() {
  log_info "Diagnostics:"
  log_info "  run_id: $RUN_ID"
  log_info "  git_sha: $GIT_SHA"
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
    echo "RUN_INTEGRATION=$RUN_INTEGRATION"
    echo "RUN_UI=$RUN_UI"
    echo "DESTINATION=${DESTINATION:-<auto>}"
    echo ""
    xcrun simctl list devices available 2>/dev/null || true
  } > "$diag_file" 2>&1 || true

  log_info "Diagnostics file: $diag_file"
}

pick_default_sim_udid() {
  python3 - <<'PY'
import json
import subprocess
import sys

try:
    raw = subprocess.check_output(["xcrun", "simctl", "list", "-j", "devices", "available"], text=True)
    data = json.loads(raw)
except Exception:
    print("")
    sys.exit(0)

devices = data.get("devices", {}) or {}
ios_runtimes = [rt for rt in devices.keys() if "SimRuntime.iOS-" in rt]

def runtime_rank(rt: str) -> int:
    if "SimRuntime.iOS-26-2" in rt:
        return 0
    if "SimRuntime.iOS-26-1" in rt:
        return 1
    if "SimRuntime.iOS-26-0" in rt:
        return 2
    if "SimRuntime.iOS-18-" in rt:
        return 3
    return 9

ios_runtimes_sorted = sorted(ios_runtimes, key=runtime_rank)

def iter_devs():
    for rt in ios_runtimes_sorted:
        for d in devices.get(rt, []) or []:
            yield rt, d

def is_available_iphone(d: dict) -> bool:
    return d.get("isAvailable") and ("iPhone" in (d.get("name") or ""))

for rt in ios_runtimes_sorted:
    for d in devices.get(rt, []) or []:
        if is_available_iphone(d) and d.get("state") == "Booted" and d.get("udid"):
            print(d["udid"])
            sys.exit(0)

for rt, d in iter_devs():
    if is_available_iphone(d) and "iPhone 16" in (d.get("name") or "") and d.get("udid"):
        print(d["udid"])
        sys.exit(0)

for rt, d in iter_devs():
    if is_available_iphone(d) and d.get("udid"):
        print(d["udid"])
        sys.exit(0)

print("")
PY
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
    xcrun simctl list devices available | grep -F "$name" | head -1 | grep -oE '[0-9A-F-]{36}' || true
    return 0
  fi

  echo ""
}

# Pre-test setup
setup() {
  log_info "Setting up test environment..."

  mkdir -p "$ARTIFACTS_DIR/logs" "$REPORTS_DIR"
  # Capture suite-level output for debugging. Child scripts emit their own logs too.
  exec > >(tee -a "$SUITE_LOG") 2>&1
  write_diagnostics_header

  # Boot simulator if needed
  if [[ -z "${DESTINATION:-}" ]]; then
    DEFAULT_UDID="$(pick_default_sim_udid)"
    if [[ -n "${DEFAULT_UDID}" ]]; then
      DESTINATION="platform=iOS Simulator,id=${DEFAULT_UDID}"
    else
      DESTINATION="platform=iOS Simulator,name=iPhone 17"
    fi
  fi

  SIMULATOR_UDID="$(destination_sim_udid "$DESTINATION")"

  if [[ -n "$SIMULATOR_UDID" ]]; then
    local max_attempts="${SIM_BOOT_RETRY_COUNT:-3}"
    local attempt=1

    log_info "Ensuring simulator is booted: $DESTINATION ($SIMULATOR_UDID) (max_attempts=$max_attempts)"
    while [[ $attempt -le $max_attempts ]]; do
      if [[ $attempt -gt 1 ]]; then
        log_warn "Simulator boot retry $attempt/$max_attempts..."
        sleep $((attempt * 2))
      fi

      xcrun simctl boot "$SIMULATOR_UDID" 2>/dev/null || true
      if xcrun simctl bootstatus "$SIMULATOR_UDID" -b 2>/dev/null; then
        break
      fi

      {
        echo "bootstatus failed (attempt=$attempt udid=$SIMULATOR_UDID destination=$DESTINATION time=$(date))"
        xcrun simctl list devices "$SIMULATOR_UDID" 2>/dev/null || true
      } > "${REPORTS_DIR}/sim-bootstatus-failure-attempt${attempt}.txt" 2>&1 || true

      attempt=$((attempt + 1))
    done
  else
    log_warn "Could not resolve simulator UDID for destination '$DESTINATION'; proceeding anyway."
  fi

  log_info "Setup complete"
}

# Run tests and return exit code
run_tests() {
  local EXIT_CODE=0

  setup

  if $RUN_INTEGRATION; then
    log_info "Running integration tests..."
    if RUN_ID="$RUN_ID" ARTIFACTS_BASE="$ARTIFACTS_BASE" DESTINATION="$DESTINATION" "$SCRIPT_DIR/e2e_integration.sh"; then
      log_info "Integration tests passed"
    else
      log_error "Integration tests failed"
      EXIT_CODE=1
    fi
  fi

  if $RUN_UI; then
    log_info "Running UI tests..."
    if RUN_ID="$RUN_ID" ARTIFACTS_BASE="$ARTIFACTS_BASE" DESTINATION="$DESTINATION" "$SCRIPT_DIR/e2e_ui.sh"; then
      log_info "UI tests passed"
    else
      log_error "UI tests failed"
      EXIT_CODE=1
    fi
  fi

  return $EXIT_CODE
}

# Main
main() {
  local START_TIME=$(date +%s)
  local EXIT_CODE=0

  log_info "BookQuotes E2E Test Suite"
  log_info "========================="

  if $RUN_INTEGRATION || $RUN_UI; then
    if run_tests; then
      log_info "All tests passed!"
    else
      log_error "Some tests failed"
      EXIT_CODE=1
    fi
  fi

  local END_TIME=$(date +%s)
  local DURATION=$((END_TIME - START_TIME))

  log_info "Total time: ${DURATION}s"
  log_info "Artifacts: $ARTIFACTS_DIR"

  exit $EXIT_CODE
}

main
