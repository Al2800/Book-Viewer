#!/usr/bin/env bash
set -euo pipefail

# BookQuotes Integration Test Runner
# Runs unit and integration tests with artifact collection
#
# Environment variables:
#   SCHEME          - Xcode scheme (default: BookQuotes)
#   DESTINATION     - Simulator destination (default: iPhone 17)
#   ARTIFACTS_DIR   - Output directory (default: artifacts/integration-tests)
#   ONLY_TESTING    - Specific test target to run (optional)
#   RETRY_COUNT     - Number of retries for flaky tests (default: 0)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT="$PROJECT_DIR/BookQuotes.xcodeproj"
SCHEME="${SCHEME:-BookQuotes}"
DESTINATION="${DESTINATION:-platform=iOS Simulator,name=iPhone 17}"

SCRIPT_SLUG="$(basename "${BASH_SOURCE[0]}" .sh)"
GIT_SHA="$(git -C "$PROJECT_DIR" rev-parse --short HEAD 2>/dev/null || echo nogit)"
RUN_ID="${RUN_ID:-$(date +%Y%m%d_%H%M%S)-$GIT_SHA}"
ARTIFACTS_BASE="${ARTIFACTS_BASE:-$PROJECT_DIR/artifacts}"
ARTIFACTS_DIR="${ARTIFACTS_DIR:-$ARTIFACTS_BASE/$SCRIPT_SLUG/$RUN_ID}"

LOGS_DIR="$ARTIFACTS_DIR/logs"
XCRESULTS_DIR="$ARTIFACTS_DIR/xcresults"
REPORTS_DIR="$ARTIFACTS_DIR/reports"
SCREENSHOTS_DIR="$ARTIFACTS_DIR/screenshots"

RESULT_BUNDLE_BASE="${XCRESULTS_DIR}/integration-tests"
LOG_FILE_BASE="${LOGS_DIR}/integration-tests"
RESULT_BUNDLE=""
LOG_FILE=""
ONLY_TESTING="${ONLY_TESTING:-}"
RETRY_COUNT="${RETRY_COUNT:-0}"

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
    echo "ONLY_TESTING=$ONLY_TESTING"
    echo "RETRY_COUNT=$RETRY_COUNT"
    echo ""
    xcrun simctl list devices available 2>/dev/null || true
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
    xcrun simctl list devices available | grep -F "$name" | head -1 | grep -oE '[0-9A-F-]{36}' || true
    return 0
  fi

  echo ""
}

boot_simulator_with_retries() {
  local udid="$1"
  local max_attempts="${SIM_BOOT_RETRY_COUNT:-3}"
  local attempt=1

  if [[ -z "$udid" ]]; then
    return 0
  fi

  log_info "Ensuring simulator is booted: $udid (max_attempts=$max_attempts)"

  while [[ $attempt -le $max_attempts ]]; do
    if [[ $attempt -gt 1 ]]; then
      log_warn "Simulator boot retry $attempt/$max_attempts..."
      sleep $((attempt * 2))
    fi

    # boot may fail if already booted; ignore that and rely on bootstatus.
    xcrun simctl boot "$udid" 2>/dev/null || true
    if xcrun simctl bootstatus "$udid" -b 2>/dev/null; then
      return 0
    fi

    # Best-effort snapshot for debugging boot flake.
    {
      echo "bootstatus failed (attempt=$attempt udid=$udid destination=$DESTINATION time=$(date))"
      xcrun simctl list devices "$udid" 2>/dev/null || true
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

capture_failure_artifacts() {
  local attempt="$1"

  mkdir -p "$REPORTS_DIR" "$SCREENSHOTS_DIR"

  local udid
  udid="$(destination_sim_udid "$DESTINATION")"
  if [[ -z "$udid" ]]; then
    udid="booted"
  fi

  # Best-effort: grab a screenshot and some diagnostics. These may fail if the simulator isn't booted.
  xcrun simctl io "$udid" screenshot "${SCREENSHOTS_DIR}/failure-attempt${attempt}.png" 2>/dev/null || true
  xcrun simctl diagnose "$udid" > "${REPORTS_DIR}/simctl-diagnose-attempt${attempt}.txt" 2>&1 || true
  xcrun simctl spawn "$udid" log collect --output "${REPORTS_DIR}/simulator-logs-attempt${attempt}.logarchive" --last 5m 2>/dev/null || true
}

# Setup
setup() {
  log_info "Setting up integration test run..."
  mkdir -p "$LOGS_DIR" "$XCRESULTS_DIR" "$REPORTS_DIR" "$SCREENSHOTS_DIR"
  write_diagnostics_header
  ensure_destination_simulator_booted || log_warn "Simulator bootstatus did not succeed; proceeding anyway."

}

# Run tests
run_tests() {
  local attempt=1
  local max_attempts=$((RETRY_COUNT + 1))

  while [[ $attempt -le $max_attempts ]]; do
    if [[ $attempt -gt 1 ]]; then
      log_warn "Retry attempt $attempt of $max_attempts..."
      sleep 2
    fi

    log_info "Running integration tests (attempt $attempt)..."

    RESULT_BUNDLE="${RESULT_BUNDLE_BASE}-attempt${attempt}.xcresult"
    LOG_FILE="${LOG_FILE_BASE}-attempt${attempt}.log"

    local CMD=(
      xcodebuild test
      -project "$PROJECT"
      -scheme "$SCHEME"
      -destination "$DESTINATION"
      -resultBundlePath "$RESULT_BUNDLE"
      -enableCodeCoverage YES
    )

    if [[ -n "$ONLY_TESTING" ]]; then
      CMD+=(-only-testing:"$ONLY_TESTING")
    fi

    # Save the exact invocation for reproducibility.
    printf '%q ' "${CMD[@]}" > "${REPORTS_DIR}/xcodebuild-command-attempt${attempt}.txt"
    echo "" >> "${REPORTS_DIR}/xcodebuild-command-attempt${attempt}.txt"

    if "${CMD[@]}" 2>&1 | tee "$LOG_FILE"; then
      return 0
    fi

    attempt=$((attempt + 1))
  done

  return 1
}

# Generate coverage report
generate_coverage() {
  if [[ -d "$RESULT_BUNDLE" ]]; then
    log_info "Generating coverage report..."
    xcrun xccov view --report "$RESULT_BUNDLE" > "${REPORTS_DIR}/coverage.txt" 2>/dev/null || true

    # Also generate JSON for programmatic access
    xcrun xccov view --report --json "$RESULT_BUNDLE" > "${REPORTS_DIR}/coverage.json" 2>/dev/null || true
  fi
}

# Extract test summary
extract_summary() {
  if [[ -f "$LOG_FILE" ]]; then
    log_info "Test summary:"
    grep -E "(Test Suite|Executed|passed|failed)" "$LOG_FILE" | tail -10 || true
  fi
}

# Main
main() {
  local START_TIME=$(date +%s)

  setup

  if run_tests; then
    log_info "Integration tests passed!"
    generate_coverage
    extract_summary

    local END_TIME=$(date +%s)
    log_info "Duration: $((END_TIME - START_TIME))s"
    log_info "Artifacts: $ARTIFACTS_DIR"
    exit 0
  else
    log_error "Integration tests failed!"
    extract_summary
    capture_failure_artifacts "$((RETRY_COUNT + 1))"

    local END_TIME=$(date +%s)
    log_info "Duration: $((END_TIME - START_TIME))s"
    log_info "Logs: $LOG_FILE"
    log_info "Results: $RESULT_BUNDLE"
    exit 1
  fi
}

main
