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

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT="$PROJECT_DIR/BookQuotes.xcodeproj"
SCHEME="${SCHEME:-BookQuotes}"
TEST_PLAN="${TEST_PLAN:-}"
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

RESULT_BUNDLE_BASE="${XCRESULTS_DIR}/ui-tests"
LOG_FILE_BASE="${LOGS_DIR}/ui-tests"
RESULT_BUNDLE=""
LOG_FILE=""
ONLY_TESTING="${ONLY_TESTING:-}"
RETRY_COUNT="${RETRY_COUNT:-1}"
TIMEOUT="${TIMEOUT:-1200}"

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
    echo "TEST_PLAN=$TEST_PLAN"
    echo "ONLY_TESTING=$ONLY_TESTING"
    echo "RETRY_COUNT=$RETRY_COUNT"
    echo "TIMEOUT=$TIMEOUT"
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

capture_failure_artifacts() {
  local attempt="$1"

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
  log_info "Setting up UI test run..."
  mkdir -p "$LOGS_DIR" "$XCRESULTS_DIR" "$REPORTS_DIR" "$SCREENSHOTS_DIR"
  write_diagnostics_header

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
    if timeout "$TIMEOUT" bash -c '"${@}"' _ "${CMD[@]}" 2>&1 | tee "$LOG_FILE"; then
      return 0
    fi

    local EXIT_CODE=$?
    if [[ $EXIT_CODE -eq 124 ]]; then
      log_error "Test run timed out after ${TIMEOUT}s"
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
