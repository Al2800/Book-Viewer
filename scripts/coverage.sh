#!/usr/bin/env bash
set -euo pipefail

PROJECT="BookQuotes.xcodeproj"
SCHEME="${1:-BookQuotes}"
DESTINATION="${DESTINATION:-platform=iOS Simulator,name=iPhone 15}"
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
