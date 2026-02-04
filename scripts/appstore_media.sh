#!/usr/bin/env bash
set -euo pipefail

# BookQuotes App Store Media Runner
# Captures App Store screenshots and app preview videos on iPhone simulators.
#
# Usage:
#   ./scripts/appstore_media.sh                 # screenshots + previews
#   ./scripts/appstore_media.sh --screenshots   # screenshots only
#   ./scripts/appstore_media.sh --previews      # previews only
#
# Environment variables:
#   SCHEME                    - Xcode scheme (default: BookQuotes)
#   SCREENSHOT_TEST           - UI test to run for screenshots
#   PREVIEW_TEST              - UI test to run for previews
#   ARTIFACTS_DIR             - Output directory (default: artifacts/app-store)
#   RUN_ID                    - Run identifier (default: timestamp)
#   SCREENSHOT_DESTINATIONS   - '|' separated destinations
#   PREVIEW_DESTINATION       - Single destination for preview capture
#   APP_STORE_PREVIEW_STEP_DELAY - Seconds per preview step (set in test env)
#
# Example:
#   SCREENSHOT_DESTINATIONS="platform=iOS Simulator,name=iPhone 15 Pro Max|platform=iOS Simulator,name=iPhone 15 Pro" \
#   PREVIEW_DESTINATION="platform=iOS Simulator,name=iPhone 15 Pro Max" \
#   ./scripts/appstore_media.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT="$PROJECT_DIR/BookQuotes.xcodeproj"
SCHEME="${SCHEME:-BookQuotes}"
SCREENSHOT_TEST="${SCREENSHOT_TEST:-BookQuotesUITests/AppStoreScreenshotsTests/testAppStoreScreenshots}"
PREVIEW_TEST="${PREVIEW_TEST:-BookQuotesUITests/AppStorePreviewsTests/testPreview_LibraryToQuoteFlow}"
ARTIFACTS_DIR="${ARTIFACTS_DIR:-$PROJECT_DIR/artifacts/app-store}"
RUN_ID="${RUN_ID:-$(date +%Y%m%d_%H%M%S)}"
BASE_DIR="$ARTIFACTS_DIR/$RUN_ID"
SCREENSHOT_DESTINATIONS="${SCREENSHOT_DESTINATIONS:-platform=iOS Simulator,name=iPhone 15 Pro Max|platform=iOS Simulator,name=iPhone 15 Pro}"
PREVIEW_DESTINATION="${PREVIEW_DESTINATION:-platform=iOS Simulator,name=iPhone 15 Pro Max}"

RUN_SCREENSHOTS=true
RUN_PREVIEWS=true

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --screenshots)
      RUN_PREVIEWS=false
      shift
      ;;
    --previews)
      RUN_SCREENSHOTS=false
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

destination_device_name() {
  local destination="$1"
  local name="${destination#*name=}"
  name="${name%%,*}"
  echo "$name"
}

destination_slug() {
  local destination="$1"
  local name
  name="$(destination_device_name "$destination")"
  echo "$name" | tr ' ' '_' | tr -cd '[:alnum:]_-'
}

boot_simulator() {
  local destination="$1"
  local name
  name="$(destination_device_name "$destination")"
  local udid
  udid="$(xcrun simctl list devices available | grep -F "$name" | head -1 | grep -oE '[0-9A-F-]{36}' || true)"

  if [[ -n "$udid" ]]; then
    log_info "Booting simulator: $name ($udid)"
    xcrun simctl boot "$udid" 2>/dev/null || true
    xcrun simctl bootstatus "$udid" -b 2>/dev/null || true
  else
    log_warn "Simulator '$name' not found. Proceeding without explicit boot."
  fi
}

run_screenshots_for_destination() {
  local destination="$1"
  local slug
  slug="$(destination_slug "$destination")"
  local output_dir="$BASE_DIR/screenshots/$slug"
  local result_bundle="$output_dir/screenshots.xcresult"
  local log_file="$output_dir/screenshots.log"

  mkdir -p "$output_dir"

  log_info "Running screenshots on: $destination"
  UI_TEST_ARTIFACTS_DIR="$output_dir" \
  WRITE_UI_TEST_LOGS=1 \
  xcodebuild test \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -destination "$destination" \
    -only-testing:"$SCREENSHOT_TEST" \
    -resultBundlePath "$result_bundle" \
    2>&1 | tee "$log_file"

  log_info "Screenshots saved to: $output_dir/screenshots"
}

run_previews_for_destination() {
  local destination="$1"
  local slug
  slug="$(destination_slug "$destination")"
  local output_dir="$BASE_DIR/previews/$slug"
  local result_bundle="$output_dir/preview.xcresult"
  local log_file="$output_dir/preview.log"
  local video_file="$output_dir/app_preview.mov"

  mkdir -p "$output_dir"
  boot_simulator "$destination"

  log_info "Recording preview video: $video_file"
  xcrun simctl io booted recordVideo --codec=h264 "$video_file" &
  local record_pid=$!

  cleanup_recording() {
    if kill -INT "$record_pid" 2>/dev/null; then
      wait "$record_pid" || true
    fi
  }
  trap cleanup_recording RETURN

  UI_TEST_ARTIFACTS_DIR="$output_dir" \
  WRITE_UI_TEST_LOGS=1 \
  xcodebuild test \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -destination "$destination" \
    -only-testing:"$PREVIEW_TEST" \
    -resultBundlePath "$result_bundle" \
    2>&1 | tee "$log_file"

  log_info "Preview video saved to: $video_file"
}

main() {
  log_info "BookQuotes App Store Media"
  log_info "Run ID: $RUN_ID"

  if $RUN_SCREENSHOTS; then
    IFS='|' read -r -a DESTS <<< "$SCREENSHOT_DESTINATIONS"
    for destination in "${DESTS[@]}"; do
      run_screenshots_for_destination "$destination"
    done
  fi

  if $RUN_PREVIEWS; then
    run_previews_for_destination "$PREVIEW_DESTINATION"
  fi

  log_info "Done."
  log_info "Artifacts: $BASE_DIR"
}

main
