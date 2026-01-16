#!/usr/bin/env bash
set -euo pipefail

PROJECT="BookQuotes.xcodeproj"
SCHEME="${1:-BookQuotes}"
DESTINATION="${DESTINATION:-platform=iOS Simulator,name=iPhone 15}"
RESULT_DIR="${RESULT_DIR:-artifacts/coverage}"
RESULT_BUNDLE="${RESULT_DIR}/TestResults.xcresult"
THRESHOLDS="${THRESHOLDS:-scripts/coverage_thresholds.json}"

mkdir -p "$RESULT_DIR"

xcodebuild test \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -destination "$DESTINATION" \
  -enableCodeCoverage YES \
  -resultBundlePath "$RESULT_BUNDLE"

xcrun xccov view --report "$RESULT_BUNDLE" > "${RESULT_DIR}/summary.txt"
xcrun xccov view --json "$RESULT_BUNDLE" > "${RESULT_DIR}/coverage.json"
python3 scripts/coverage_report.py \
  --input "${RESULT_DIR}/coverage.json" \
  --lcov "${RESULT_DIR}/coverage.lcov" \
  --html "${RESULT_DIR}/coverage.html" \
  --thresholds "$THRESHOLDS"

echo "Coverage reports written to ${RESULT_DIR}"
