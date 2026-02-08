#!/usr/bin/env bash
set -euo pipefail

PROJECT="BookQuotes.xcodeproj"
SCHEME="${1:-BookQuotes}"
DESTINATION="${DESTINATION:-}"
RUN_ID="${RUN_ID:-$(date +%Y%m%d_%H%M%S)}"
RESULT_DIR="${RESULT_DIR:-artifacts/coverage/$RUN_ID}"
RESULT_BUNDLE="${RESULT_DIR}/TestResults.xcresult"
THRESHOLDS="${THRESHOLDS:-scripts/coverage_thresholds.json}"

# Optional filters to keep coverage runs stable and focused.
# Use "|" to separate multiple entries, e.g.:
#   ONLY_TESTING="BookQuotesTests|BookQuotesUITests/AppStoreMediaTests" \
#   SKIP_TESTING="BookQuotesTests/MemoryPerformanceTests|BookQuotesTests/SearchPerformanceTests" \
#   ./scripts/coverage.sh
ONLY_TESTING="${ONLY_TESTING:-}"
SKIP_TESTING="${SKIP_TESTING:-BookQuotesTests/MemoryPerformanceTests|BookQuotesTests/SearchPerformanceTests}"

pick_default_sim_udid() {
  # Pick a stable, available iPhone simulator UDID:
  # 1) a Booted iPhone (any iOS runtime)
  # 2) iPhone 16 (prefer iOS 18.x)
  # 3) any available iPhone (prefer iOS 18.x)
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
    # Prefer newest iOS runtimes first.
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
preferred_runtimes = [rt for rt in ios_runtimes_sorted if runtime_rank(rt) <= 2]
fallback_runtimes = [rt for rt in ios_runtimes_sorted if runtime_rank(rt) > 2]

def iter_devs(runtimes):
    for rt in runtimes:
        for d in devices.get(rt, []) or []:
            yield rt, d

def is_available_iphone(d: dict) -> bool:
    name = (d.get("name") or "")
    return d.get("isAvailable") and ("iPhone" in name)

# 1) Booted iPhone (prefer newest runtimes only; older runtimes can be flaky).
for rt in preferred_runtimes:
    for d in devices.get(rt, []) or []:
        if is_available_iphone(d) and d.get("state") == "Booted" and d.get("udid"):
            print(d["udid"])
            sys.exit(0)

# 2) Prefer a modern iPhone model on a modern runtime.
for rt, d in iter_devs(preferred_runtimes):
    name = (d.get("name") or "")
    if is_available_iphone(d) and (("iPhone 17" in name) or ("iPhone Air" in name)) and d.get("udid"):
        print(d["udid"])
        sys.exit(0)

# 3) Any iPhone on a modern runtime.
for rt, d in iter_devs(preferred_runtimes):
    if is_available_iphone(d) and d.get("udid"):
        print(d["udid"])
        sys.exit(0)

# 4) Booted iPhone on older runtimes (fallback).
for rt in fallback_runtimes:
    for d in devices.get(rt, []) or []:
        if is_available_iphone(d) and d.get("state") == "Booted" and d.get("udid"):
            print(d["udid"])
            sys.exit(0)

# 5) iPhone 16 preferred on older runtimes (fallback).
for rt, d in iter_devs(fallback_runtimes):
    if is_available_iphone(d) and "iPhone 16" in (d.get("name") or "") and d.get("udid"):
        print(d["udid"])
        sys.exit(0)

# 6) Any iPhone (fallback).
for rt, d in iter_devs(fallback_runtimes):
    if is_available_iphone(d) and d.get("udid"):
        print(d["udid"])
        sys.exit(0)

print("")
PY
}

if [[ -z "${DESTINATION}" ]]; then
  DEFAULT_UDID="$(pick_default_sim_udid)"
  if [[ -n "${DEFAULT_UDID}" ]]; then
    DESTINATION="platform=iOS Simulator,id=${DEFAULT_UDID}"
  else
    # Fallback: keep an Xcode-style destination string if we fail to resolve a UDID.
    DESTINATION="platform=iOS Simulator,name=iPhone 15"
  fi
fi

mkdir -p "$RESULT_DIR"

CMD=(xcodebuild test)
CMD+=(-project "$PROJECT")
CMD+=(-scheme "$SCHEME")
CMD+=(-destination "$DESTINATION")
CMD+=(-enableCodeCoverage YES)
CMD+=(-resultBundlePath "$RESULT_BUNDLE")

if [[ -n "$ONLY_TESTING" ]]; then
  IFS='|' read -r -a ONLY_ARR <<< "$ONLY_TESTING"
  for t in "${ONLY_ARR[@]}"; do
    [[ -z "$t" ]] && continue
    CMD+=(-only-testing:"$t")
  done
fi

if [[ -n "$SKIP_TESTING" ]]; then
  IFS='|' read -r -a SKIP_ARR <<< "$SKIP_TESTING"
  for t in "${SKIP_ARR[@]}"; do
    [[ -z "$t" ]] && continue
    CMD+=(-skip-testing:"$t")
  done
fi

"${CMD[@]}"

xcrun xccov view --report "$RESULT_BUNDLE" > "${RESULT_DIR}/summary.txt"
xcrun xccov view --report --json "$RESULT_BUNDLE" > "${RESULT_DIR}/coverage_report.json"
xcrun xccov view --archive --json "$RESULT_BUNDLE" > "${RESULT_DIR}/coverage_archive.json"
python3 scripts/coverage_report.py \
  --report-json "${RESULT_DIR}/coverage_report.json" \
  --archive-json "${RESULT_DIR}/coverage_archive.json" \
  --lcov "${RESULT_DIR}/coverage.lcov" \
  --html "${RESULT_DIR}/coverage.html" \
  --thresholds "$THRESHOLDS"

echo "Coverage reports written to ${RESULT_DIR}"
