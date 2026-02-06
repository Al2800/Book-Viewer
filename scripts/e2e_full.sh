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

# Pre-test setup
setup() {
  log_info "Setting up test environment..."

  mkdir -p "$ARTIFACTS_DIR/logs"
  # Capture suite-level output for debugging. Child scripts emit their own logs too.
  exec > >(tee -a "$SUITE_LOG") 2>&1

  # Boot simulator if needed
  SIMULATOR_NAME="${SIMULATOR_NAME:-iPhone 17}"
  SIMULATOR_UDID=$(xcrun simctl list devices available | grep "$SIMULATOR_NAME" | head -1 | grep -oE '[0-9A-F-]{36}' || true)

  if [[ -n "$SIMULATOR_UDID" ]]; then
    log_info "Booting simulator: $SIMULATOR_NAME ($SIMULATOR_UDID)"
    xcrun simctl boot "$SIMULATOR_UDID" 2>/dev/null || true
  else
    log_warn "Simulator '$SIMULATOR_NAME' not found, will use default"
  fi

  log_info "Setup complete"
}

# Run tests and return exit code
run_tests() {
  local EXIT_CODE=0

  setup

  if $RUN_INTEGRATION; then
    log_info "Running integration tests..."
    if RUN_ID="$RUN_ID" ARTIFACTS_BASE="$ARTIFACTS_BASE" "$SCRIPT_DIR/e2e_integration.sh"; then
      log_info "Integration tests passed"
    else
      log_error "Integration tests failed"
      EXIT_CODE=1
    fi
  fi

  if $RUN_UI; then
    log_info "Running UI tests..."
    if RUN_ID="$RUN_ID" ARTIFACTS_BASE="$ARTIFACTS_BASE" "$SCRIPT_DIR/e2e_ui.sh"; then
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
