# Extraction Review Status Presentation Refactor - 2026-06-30

## Scope

- Extracted processing, no-quotes, extraction-failure, and no-selection presentation from `ExtractionReviewView.swift`.
- Added `Features/QuoteCapture/ExtractionReviewStatusViews.swift`.
- Kept quote state, selected page state, processing, persistence, save confirmation, milestone celebration, haptics, and dismissal orchestration in `ExtractionReviewView`.

## LOC Result

- `BookQuotes/Features/QuoteCapture/ExtractionReviewView.swift`: 537 LOC -> 467 LOC.
- `BookQuotes/Features/QuoteCapture/ExtractionReviewStatusViews.swift`: 124 LOC.

## Verification

Build:

```bash
xcodebuild build -quiet -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5'
```

Result:

- Passed.

Unit characterization:

```bash
xcodebuild test -quiet -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -only-testing:BookQuotesTests/ExtractionReviewQuoteStateTests
```

Result before edits:

- Passed.
- Runtime: `35.438` seconds.

Result after refactor:

- Passed.
- Runtime: `35.872` seconds.

Simulator UI characterization attempts:

```bash
xcodebuild test -quiet -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -only-testing:BookQuotesUITests/QuoteCaptureFlowTests/testExtractionReview_DisplaysExtractedQuotes \
  -only-testing:BookQuotesUITests/QuoteCaptureFlowTests/testQuoteEditor_CanEditText
```

Result:

- Failed before app assertions.
- XCTest runner failed to initialize UI testing with `Timed out waiting for AX loaded notification`.
- Reproduced across repeated runs and after `xcrun simctl shutdown all`.

Notes:

- Existing Swift 6 sendability, availability, and unreachable-catch warnings remain.
- No tests were changed to make this pass.

## Residual Risk

- UI behaviour for the extraction review route could not be re-verified in this environment because of the XCTest AX runner failure.
- The code change is presentation-only and build/unit coverage passed, but the next available simulator session should re-run the two `QuoteCaptureFlowTests` listed above.
