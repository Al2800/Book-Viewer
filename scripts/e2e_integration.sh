#!/usr/bin/env bash
set -euo pipefail

# BookQuotes Integration Test Runner
# Runs unit and integration tests with artifact collection
#
# Environment variables:
#   SCHEME          - Xcode scheme (default: BookQuotes)
#   DESTINATION     - Simulator destination (default: iPhone 15)
#   ARTIFACTS_DIR   - Output directory (default: artifacts/integration-tests)
#   ONLY_TESTING    - Specific test target to run (optional)
#   RETRY_COUNT     - Number of retries for flaky tests (default: 0)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT="$PROJECT_DIR/BookQuotes.xcodeproj"
SCHEME="${SCHEME:-BookQuotes}"
DESTINATION="${DESTINATION:-platform=iOS Simulator,name=iPhone 15}"
ARTIFACTS_DIR="${ARTIFACTS_DIR:-$PROJECT_DIR/artifacts/integration-tests}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
RESULT_BUNDLE="${ARTIFACTS_DIR}/integration-tests-${TIMESTAMP}.xcresult"
LOG_FILE="${ARTIFACTS_DIR}/integration-tests-${TIMESTAMP}.log"
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

# Setup
setup() {
  log_info "Setting up integration test run..."
  mkdir -p "$ARTIFACTS_DIR"

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
    xcrun xccov view --report "$RESULT_BUNDLE" > "${ARTIFACTS_DIR}/coverage-${TIMESTAMP}.txt" 2>/dev/null || true

    # Also generate JSON for programmatic access
    xcrun xccov view --report --json "$RESULT_BUNDLE" > "${ARTIFACTS_DIR}/coverage-${TIMESTAMP}.json" 2>/dev/null || true
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

    local END_TIME=$(date +%s)
    log_info "Duration: $((END_TIME - START_TIME))s"
    log_info "Logs: $LOG_FILE"
    log_info "Results: $RESULT_BUNDLE"
    exit 1
  fi
}

main
