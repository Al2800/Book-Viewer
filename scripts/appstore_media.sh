#!/usr/bin/env bash
set -euo pipefail

# BookQuotes App Store Media Runner
# Captures App Store screenshots and app preview videos on iPhone and iPad simulators.
#
# Usage:
#   ./scripts/appstore_media.sh                 # screenshots + previews
#   ./scripts/appstore_media.sh --screenshots   # screenshots only
#   ./scripts/appstore_media.sh --previews      # previews only
#
# Failure diagnostics:
# - If `xcodebuild test` fails, this script captures simulator diagnostics (`simctl diagnose`)
#   and a recent log archive (`log collect --last 5m`) to help debug iOS 26 accessibility/AX flakiness.
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
# Device matrix (App Store Connect)
#
# iPhone screenshots:
# - Required: 6.9" OR 6.5" set (ASC allows downscaling). Recommend capturing 6.9".
#   Mapping: iPhone 17 Pro Max (OS=latest) -> 1320x2868 screenshots
#
# iPad screenshots (this app targets iPad too: TARGETED_DEVICE_FAMILY=1,2):
# - Required: 13" iPad Pro set (ASC allows downscaling). Recommend capturing 13".
#   Mapping: iPad Pro 13-inch (M5) (OS=latest) -> 2064x2752 screenshots
#
# Previews:
# - App preview videos are uploaded separately in App Store Connect. This script records a `.mov`
#   while running a deterministic UI test flow.
#
# Example:
#   SCREENSHOT_DESTINATIONS="platform=iOS Simulator,OS=latest,name=iPhone 17 Pro Max|platform=iOS Simulator,OS=latest,name=iPad Pro 13-inch (M5)" \
#   PREVIEW_DESTINATION="platform=iOS Simulator,OS=latest,name=iPhone 17 Pro Max" \
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
SCREENSHOT_DESTINATIONS="${SCREENSHOT_DESTINATIONS:-platform=iOS Simulator,OS=latest,name=iPhone 17 Pro Max|platform=iOS Simulator,OS=latest,name=iPad Pro 13-inch (M5)}"
PREVIEW_DESTINATION="${PREVIEW_DESTINATION:-platform=iOS Simulator,OS=latest,name=iPhone 17 Pro Max}"

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

destination_sim_udid() {
  local destination="$1"

  if [[ "$destination" == *"id="* ]]; then
    local id="${destination#*id=}"
    id="${id%%,*}"
    echo "$id"
    return 0
  fi

  if [[ "$destination" == *"name="* ]]; then
    local name
    name="$(destination_device_name "$destination")"
    xcrun simctl list devices available | grep -F "$name" | head -1 | grep -oE '[0-9A-F-]{36}' || true
    return 0
  fi

  echo ""
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
  udid="$(destination_sim_udid "$destination")"

  if [[ -n "$udid" ]]; then
    log_info "Booting simulator: $name ($udid)"
    xcrun simctl boot "$udid" 2>/dev/null || true
    xcrun simctl bootstatus "$udid" -b 2>/dev/null || true
  else
    log_warn "Simulator '$name' not found. Proceeding without explicit boot."
  fi
}

capture_failure_artifacts() {
  local destination="$1"
  local output_dir="$2"
  local phase="$3" # screenshots|previews

  local reports_dir="$output_dir/reports"
  mkdir -p "$reports_dir"

  local udid
  udid="$(destination_sim_udid "$destination")"
  [[ -z "$udid" ]] && udid="booted"

  log_warn "Capturing failure diagnostics ($phase) for udid=$udid"

  xcrun simctl diagnose "$udid" > "${reports_dir}/simctl-diagnose.txt" 2>&1 || true
  xcrun simctl spawn "$udid" log collect --output "${reports_dir}/simulator-logs.logarchive" --last 5m 2>/dev/null || true

  # Quick, grep-friendly extract for common iOS 26 UI-test daemon/accessibility issues.
  xcrun simctl spawn "$udid" log show --style compact --last 5m \
    --predicate '(eventMessage CONTAINS[c] "AX" OR eventMessage CONTAINS[c] "accessibility" OR eventMessage CONTAINS[c] "XCTDaemon" OR eventMessage CONTAINS[c] "Mach" OR subsystem CONTAINS[c] "com.apple.Accessibility")' \
    > "${reports_dir}/accessibility_log_last5m.txt" 2>&1 || true
}

run_screenshots_for_destination() {
  local destination="$1"
  local slug
  slug="$(destination_slug "$destination")"
  local output_dir="$BASE_DIR/screenshots/$slug"
  local result_bundle="$output_dir/screenshots.xcresult"
  local log_file="$output_dir/screenshots.log"
  local cmd_file="$output_dir/reports/xcodebuild-command.txt"

  mkdir -p "$output_dir"
  mkdir -p "$output_dir/reports"

  log_info "Running screenshots on: $destination"
  {
    printf '%q ' xcodebuild test \
      -project "$PROJECT" \
      -scheme "$SCHEME" \
      -destination "$destination" \
      -only-testing:"$SCREENSHOT_TEST" \
      -resultBundlePath "$result_bundle"
    echo ""
  } > "$cmd_file" 2>&1 || true

  set +e
  UI_TEST_ARTIFACTS_DIR="$output_dir" \
    WRITE_UI_TEST_LOGS=1 \
    xcodebuild test \
      -project "$PROJECT" \
      -scheme "$SCHEME" \
      -destination "$destination" \
      -only-testing:"$SCREENSHOT_TEST" \
      -resultBundlePath "$result_bundle" \
      2>&1 | tee "$log_file"
  local ec=${PIPESTATUS[0]}
  set -e

  if [[ $ec -ne 0 ]]; then
    capture_failure_artifacts "$destination" "$output_dir" "screenshots"
    return $ec
  fi

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
  local cmd_file="$output_dir/reports/xcodebuild-command.txt"

  mkdir -p "$output_dir"
  mkdir -p "$output_dir/reports"
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

  {
    printf '%q ' xcodebuild test \
      -project "$PROJECT" \
      -scheme "$SCHEME" \
      -destination "$destination" \
      -only-testing:"$PREVIEW_TEST" \
      -resultBundlePath "$result_bundle"
    echo ""
  } > "$cmd_file" 2>&1 || true

  set +e
  UI_TEST_ARTIFACTS_DIR="$output_dir" \
    WRITE_UI_TEST_LOGS=1 \
    xcodebuild test \
      -project "$PROJECT" \
      -scheme "$SCHEME" \
      -destination "$destination" \
      -only-testing:"$PREVIEW_TEST" \
      -resultBundlePath "$result_bundle" \
      2>&1 | tee "$log_file"
  local ec=${PIPESTATUS[0]}
  set -e

  if [[ $ec -ne 0 ]]; then
    capture_failure_artifacts "$destination" "$output_dir" "previews"
    return $ec
  fi

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
