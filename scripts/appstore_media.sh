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
MAX_UI_TEST_RETRIES="${MAX_UI_TEST_RETRIES:-2}"
XCODEBUILD_TIMEOUT_SECONDS="${XCODEBUILD_TIMEOUT_SECONDS:-600}"
SIMCTL_LOG_TIMEOUT_SECONDS="${SIMCTL_LOG_TIMEOUT_SECONDS:-25}"
SIMCTL_LIST_TIMEOUT_SECONDS="${SIMCTL_LIST_TIMEOUT_SECONDS:-6}"

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

run_with_timeout_to_file() {
  local timeout_seconds="$1"
  local out_file="$2"
  shift 2

  python3 - "$timeout_seconds" "$out_file" "$@" <<'PY'
import subprocess
import sys

timeout = float(sys.argv[1])
out_path = sys.argv[2]
cmd = sys.argv[3:]

with open(out_path, "w", encoding="utf-8", errors="replace") as f:
    try:
        proc = subprocess.Popen(cmd, stdout=f, stderr=subprocess.STDOUT, text=True)
        proc.wait(timeout=timeout)
        sys.exit(proc.returncode)
    except subprocess.TimeoutExpired:
        try:
            proc.terminate()
            proc.wait(timeout=5)
        except Exception:
            try:
                proc.kill()
            except Exception:
                pass
        sys.exit(124)
PY
}

run_xcodebuild_with_timeout_and_tee() {
  local timeout_seconds="$1"
  local log_file="$2"
  shift 2

  python3 - "$timeout_seconds" "$log_file" "$@" <<'PY'
import selectors
import subprocess
import sys
import time

timeout = float(sys.argv[1])
log_path = sys.argv[2]
cmd = sys.argv[3:]

start = time.monotonic()
proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, bufsize=1)
sel = selectors.DefaultSelector()
sel.register(proc.stdout, selectors.EVENT_READ)

with open(log_path, "w", encoding="utf-8", errors="replace") as f:
    while True:
        if time.monotonic() - start > timeout:
            try:
                proc.terminate()
                proc.wait(timeout=5)
            except Exception:
                try:
                    proc.kill()
                except Exception:
                    pass
            msg = f"\n[TIMEOUT] xcodebuild exceeded {timeout:.0f}s\n"
            f.write(msg)
            sys.stdout.write(msg)
            sys.stdout.flush()
            sys.exit(124)

        if proc.poll() is not None:
            remaining = proc.stdout.read() if proc.stdout else ""
            if remaining:
                f.write(remaining)
                f.flush()
                sys.stdout.write(remaining)
                sys.stdout.flush()
            sys.exit(proc.returncode)

        events = sel.select(timeout=0.25)
        for key, _ in events:
            line = key.fileobj.readline()
            if not line:
                continue
            f.write(line)
            f.flush()
            sys.stdout.write(line)
            sys.stdout.flush()
PY
}

is_retryable_ui_test_failure() {
  local log_file="$1"
  [[ -f "$log_file" ]] || return 1

  # iOS 26 simulator flake: UI test runner fails to initialize due to AX not loading.
  if rg -q "Timed out waiting for AX loaded notification" "$log_file"; then
    return 0
  fi
  if rg -q "Failed to initialize for UI testing" "$log_file"; then
    return 0
  fi
  if rg -q "XCTDaemonErrorDomain Code=18" "$log_file"; then
    return 0
  fi
  # iOS simulator flake: simulator services die during launch/test bootstrap.
  if rg -q "NSMachErrorDomain" "$log_file"; then
    return 0
  fi
  if rg -q "Mach error -308" "$log_file"; then
    return 0
  fi
  if rg -q "server died" "$log_file"; then
    return 0
  fi

  return 1
}

reboot_simulator() {
  local destination="$1"
  local udid
  udid="$(destination_sim_udid "$destination")"
  [[ -z "$udid" ]] && return 0

  log_warn "Rebooting simulator udid=$udid"
  xcrun simctl shutdown "$udid" 2>/dev/null || true
  xcrun simctl boot "$udid" 2>/dev/null || true
  xcrun simctl bootstatus "$udid" -b 2>/dev/null || true
  sleep 3
}

destination_device_name() {
  local destination="$1"
  local name="${destination#*name=}"
  name="${name%%,*}"
  echo "$name"
}

simctl_list_devices_available() {
  python3 - "$SIMCTL_LIST_TIMEOUT_SECONDS" <<'PY'
import subprocess
import sys

timeout = float(sys.argv[1])
try:
    out = subprocess.check_output(
        ["xcrun", "simctl", "list", "devices", "available"],
        stderr=subprocess.STDOUT,
        timeout=timeout,
        text=True,
    )
    sys.stdout.write(out)
except Exception:
    # Best-effort: when CoreSimulator is wedged, callers should degrade gracefully.
    sys.stdout.write("")
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
    local name
    name="$(destination_device_name "$destination")"
    simctl_list_devices_available | grep -F "$name" | head -1 | grep -oE '[0-9A-F-]{36}' || true
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

  run_with_timeout_to_file "$SIMCTL_LOG_TIMEOUT_SECONDS" "${reports_dir}/simctl-diagnose.txt" \
    xcrun simctl diagnose "$udid" || true
  # log collect can be slow; best-effort and timeboxed.
  run_with_timeout_to_file "$SIMCTL_LOG_TIMEOUT_SECONDS" "${reports_dir}/log-collect.txt" \
    xcrun simctl spawn "$udid" log collect --output "${reports_dir}/simulator-logs.logarchive" --last 5m || true

  # Quick, grep-friendly extract for common iOS 26 UI-test daemon/accessibility issues.
  run_with_timeout_to_file "$SIMCTL_LOG_TIMEOUT_SECONDS" "${reports_dir}/accessibility_log_last5m.txt" \
    xcrun simctl spawn "$udid" log show --style compact --last 5m \
      --predicate '(eventMessage CONTAINS[c] "AX" OR eventMessage CONTAINS[c] "accessibility" OR eventMessage CONTAINS[c] "XCTDaemon" OR eventMessage CONTAINS[c] "Mach" OR subsystem CONTAINS[c] "com.apple.Accessibility")' \
    || true
}

run_screenshots_for_destination() {
  local destination="$1"
  local slug
  slug="$(destination_slug "$destination")"
  local output_dir="$BASE_DIR/screenshots/$slug"

  mkdir -p "$output_dir"
  mkdir -p "$output_dir/reports"
  boot_simulator "$destination"

  log_info "Running screenshots on: $destination"
  local attempt=1
  while [[ $attempt -le $MAX_UI_TEST_RETRIES ]]; do
    local result_bundle="$output_dir/screenshots_attempt${attempt}.xcresult"
    local log_file="$output_dir/screenshots_attempt${attempt}.log"
    local cmd_file="$output_dir/reports/xcodebuild-command_attempt${attempt}.txt"

    {
      printf '%q ' xcodebuild test \
        -project "$PROJECT" \
        -scheme "$SCHEME" \
        -destination "$destination" \
        -only-testing:"$SCREENSHOT_TEST" \
        -resultBundlePath "$result_bundle"
      echo ""
    } > "$cmd_file" 2>&1 || true

    if [[ $attempt -gt 1 ]]; then
      log_warn "Retrying screenshots (attempt $attempt/$MAX_UI_TEST_RETRIES): $destination"
      reboot_simulator "$destination"
    fi

    set +e
    UI_TEST_ARTIFACTS_DIR="$output_dir" \
      WRITE_UI_TEST_LOGS=1 \
      run_xcodebuild_with_timeout_and_tee "$XCODEBUILD_TIMEOUT_SECONDS" "$log_file" \
        xcodebuild test \
          -project "$PROJECT" \
          -scheme "$SCHEME" \
          -destination "$destination" \
          -only-testing:"$SCREENSHOT_TEST" \
          -resultBundlePath "$result_bundle"
    local ec=$?
    set -e

    if [[ $ec -eq 0 ]]; then
      # Export attachments from the xcresult bundle and materialize a stable PNG set for upload.
      # XCTest stores screenshots as attachments; exporting them avoids depending on test-runner FS access.
      local export_dir="$output_dir/attachments_attempt${attempt}"
      local screenshots_dir="$output_dir/screenshots"
      mkdir -p "$export_dir"
      mkdir -p "$screenshots_dir"

      xcrun xcresulttool export attachments \
        --path "$result_bundle" \
        --output-path "$export_dir" \
        >/dev/null 2>&1 || true

      local manifest="$export_dir/manifest.json"
      if [[ -f "$manifest" ]]; then
        local keys=(
          "01_library_grid"
          "02_book_detail"
          "03_quote_detail"
          "04_search_results"
          "05_add_book_isbn"
          "06_captured_page"
          "07_extraction_review"
        )

        for key in "${keys[@]}"; do
          local exported
          exported="$(jq -r --arg key "$key" '
            .[]?.attachments[]?
            | select(.suggestedHumanReadableName? and (.suggestedHumanReadableName | contains("_" + $key + "_")))
            | .exportedFileName
          ' "$manifest" 2>/dev/null | head -n 1)"

          if [[ -n "${exported:-}" ]] && [[ -f "$export_dir/$exported" ]]; then
            cp -f "$export_dir/$exported" "$screenshots_dir/$key.png" 2>/dev/null || true
          else
            log_warn "Could not locate exported screenshot for key=$key (see $manifest)"
          fi
        done
      else
        log_warn "No attachment manifest produced (xcresult export may have failed): $manifest"
      fi

      log_info "Screenshots saved to: $output_dir/screenshots"
      return 0
    fi

    if is_retryable_ui_test_failure "$log_file" && [[ $attempt -lt $MAX_UI_TEST_RETRIES ]]; then
      attempt=$((attempt + 1))
      continue
    fi

    capture_failure_artifacts "$destination" "$output_dir" "screenshots"
    return $ec
  done

  return 1
}

run_previews_for_destination() {
  local destination="$1"
  local slug
  slug="$(destination_slug "$destination")"
  local output_dir="$BASE_DIR/previews/$slug"

  mkdir -p "$output_dir"
  mkdir -p "$output_dir/reports"
  boot_simulator "$destination"

  local udid
  udid="$(destination_sim_udid "$destination")"
  [[ -z "$udid" ]] && udid="booted"

  local attempt=1
  while [[ $attempt -le $MAX_UI_TEST_RETRIES ]]; do
    local result_bundle="$output_dir/preview_attempt${attempt}.xcresult"
    local log_file="$output_dir/preview_attempt${attempt}.log"
    local video_file_attempt="$output_dir/app_preview_attempt${attempt}.mov"
    local cmd_file="$output_dir/reports/xcodebuild-command_attempt${attempt}.txt"

    {
      printf '%q ' xcodebuild test \
        -project "$PROJECT" \
        -scheme "$SCHEME" \
        -destination "$destination" \
        -only-testing:"$PREVIEW_TEST" \
        -resultBundlePath "$result_bundle"
      echo ""
    } > "$cmd_file" 2>&1 || true

    if [[ $attempt -gt 1 ]]; then
      log_warn "Retrying previews (attempt $attempt/$MAX_UI_TEST_RETRIES): $destination"
      reboot_simulator "$destination"
    fi

    log_info "Recording preview video: $video_file_attempt"
    xcrun simctl io "$udid" recordVideo --codec=h264 "$video_file_attempt" &
    local record_pid=$!

    set +e
    UI_TEST_ARTIFACTS_DIR="$output_dir" \
      WRITE_UI_TEST_LOGS=1 \
      run_xcodebuild_with_timeout_and_tee "$XCODEBUILD_TIMEOUT_SECONDS" "$log_file" \
        xcodebuild test \
          -project "$PROJECT" \
          -scheme "$SCHEME" \
          -destination "$destination" \
          -only-testing:"$PREVIEW_TEST" \
          -resultBundlePath "$result_bundle"
    local ec=$?
    set -e

    if kill -INT "$record_pid" 2>/dev/null; then
      wait "$record_pid" || true
    fi

    if [[ $ec -eq 0 ]]; then
      # Keep a stable filename for upload tooling.
      cp -f "$video_file_attempt" "$output_dir/app_preview.mov" 2>/dev/null || true
      log_info "Preview video saved to: $output_dir/app_preview.mov"
      return 0
    fi

    if is_retryable_ui_test_failure "$log_file" && [[ $attempt -lt $MAX_UI_TEST_RETRIES ]]; then
      attempt=$((attempt + 1))
      continue
    fi

    capture_failure_artifacts "$destination" "$output_dir" "previews"
    return $ec
  done

  return 1
}

main() {
  log_info "BookQuotes App Store Media"
  log_info "Run ID: $RUN_ID"

  local failures=0

  if $RUN_SCREENSHOTS; then
    IFS='|' read -r -a DESTS <<< "$SCREENSHOT_DESTINATIONS"
    for destination in "${DESTS[@]}"; do
      if ! run_screenshots_for_destination "$destination"; then
        failures=$((failures + 1))
      fi
    done
  fi

  if $RUN_PREVIEWS; then
    if ! run_previews_for_destination "$PREVIEW_DESTINATION"; then
      failures=$((failures + 1))
    fi
  fi

  log_info "Done."
  log_info "Artifacts: $BASE_DIR"

  if [[ $failures -gt 0 ]]; then
    log_error "Completed with $failures failure(s). See per-destination logs under $BASE_DIR."
    exit 1
  fi
}

main
