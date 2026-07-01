# 2026-07-01: Vertical Margin Mark Detector Refactor

## Scope

Issue 013 reported that real book pages with vertical margin lines were not being recognized reliably. The selector already had tests proving `.marginLine` marks can select adjacent paragraph lines, but `PageMarkDetector` only scanned horizontal row runs, so thin vertical graphite strokes could be missed before selection.

This slice keeps the work inside `PageMarkDetector`, which already owns bitmap mark detection.

## Characterization

Added:

- `OnDeviceQuoteExtractorTests.testDetectsGraphiteVerticalMarginLineBesideText`

Existing guard retained:

- `OnDeviceQuoteExtractorTests.testPlainPrintedTextIsNotTreatedAsMarkedQuote`

The first red run failed because the detector returned no `.marginLine` marks. A first implementation then failed the plain-text guard by classifying printed glyph stems as vertical marks. The final implementation requires sustained thin vertical runs and keeps the plain-text guard green.

## Implementation

- Added column-run scanning to `MarkBitmap`.
- Added `MarkColumnRun`.
- Added column-run merging to `PageMarkDetector`.
- Added `verticalMarginMark` classification for sustained thin colored or neutral vertical strokes.
- Left row-run underline/highlight detection unchanged.

## Verification

Focused detector guard:

```sh
xcodebuild test -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,id=AF90E17A-F07E-40FB-B32E-C52FFCA09DE7' \
  -only-testing:BookQuotesTests/OnDeviceQuoteExtractorTests/testDetectsGraphiteVerticalMarginLineBesideText \
  -only-testing:BookQuotesTests/OnDeviceQuoteExtractorTests/testPlainPrintedTextIsNotTreatedAsMarkedQuote
```

Result: passed.

- 2 tests executed.
- 0 failures.
- Result bundle: `/Users/user298279/Library/Developer/Xcode/DerivedData/BookQuotes-chdblwnjsdsclucdtkuelvsnfrxn/Logs/Test/Test-BookQuotes-2026.07.01_08-11-10-+0100.xcresult`.

Focused extraction gate:

```sh
xcodebuild test -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,id=AF90E17A-F07E-40FB-B32E-C52FFCA09DE7' -only-testing:BookQuotesTests/OnDeviceQuoteExtractorTests
```

Result: passed.

- 12 tests executed.
- 0 failures.
- Result bundle: `/Users/user298279/Library/Developer/Xcode/DerivedData/BookQuotes-chdblwnjsdsclucdtkuelvsnfrxn/Logs/Test/Test-BookQuotes-2026.07.01_08-11-26-+0100.xcresult`.

## Residual Risk

- This is a synthetic detector characterization, not a real-photo fixture from TestFlight.
- Issue 013 remains open for real-photo vertical-line fixtures, small bracket/tick recognition, line-wrap hyphenation cleanup, and hosted-model quality checks.
- Full XCUITest quote-capture smoke remains blocked by issue 081.
