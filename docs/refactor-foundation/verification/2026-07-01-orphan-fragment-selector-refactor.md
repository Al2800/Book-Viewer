# 2026-07-01: Orphan Fragment Selector Refactor

## Scope

Issue 013 included real extraction output where a quote opened with a clipped OCR fragment, such as `gle particle...`, instead of the fuller printed line. This slice keeps the fix inside `QuoteMarkTextSelector`, which already owns mark-to-OCR-line selection for the on-device fallback.

The goal is narrow: when Vision supplies both a clipped fragment and a fuller OCR line on the same baseline, underline selection should prefer the fuller line without inventing missing text.

## Characterization

Added:

- `OnDeviceQuoteExtractorTests.testSelectorPrefersFullerSameBaselineLineOverOrphanFragment`

The test provides two OCR lines on the same baseline:

- `gle particle, which slowed that light beam`
- `single particle, which slowed that light beam`

The first red run returned the clipped fragment:

- Actual: `gle particle, which slowed that light beam to the unbelievably leisurely pace`
- Expected: `single particle, which slowed that light beam to the unbelievably leisurely pace`

## Implementation

- Replaced underline nearest-line tie-breaking with an explicit comparison helper.
- Preserved closest vertical-distance selection as the first rule.
- Added a same-baseline fuller-line rule: when one OCR line contains the clipped candidate text and is longer, it wins.
- Kept horizontal overlap as the fallback tie-breaker.
- Did not alter highlight, margin-line, candidate grouping, or model-assisted extraction.

## Verification

Focused red run before implementation:

```sh
xcodebuild test -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,id=AF90E17A-F07E-40FB-B32E-C52FFCA09DE7' \
  -only-testing:BookQuotesTests/OnDeviceQuoteExtractorTests/testSelectorPrefersFullerSameBaselineLineOverOrphanFragment
```

Result: failed as expected.

- 1 test executed.
- 1 failure.
- Result bundle: `/Users/user298279/Library/Developer/Xcode/DerivedData/BookQuotes-chdblwnjsdsclucdtkuelvsnfrxn/Logs/Test/Test-BookQuotes-2026.07.01_08-22-02-+0100.xcresult`

Focused green run after implementation:

```sh
xcodebuild test -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,id=AF90E17A-F07E-40FB-B32E-C52FFCA09DE7' \
  -only-testing:BookQuotesTests/OnDeviceQuoteExtractorTests/testSelectorPrefersFullerSameBaselineLineOverOrphanFragment
```

Result: passed.

- 1 test executed.
- 0 failures.
- Result bundle: `/Users/user298279/Library/Developer/Xcode/DerivedData/BookQuotes-chdblwnjsdsclucdtkuelvsnfrxn/Logs/Test/Test-BookQuotes-2026.07.01_08-22-43-+0100.xcresult`

Focused extraction and prompt-builder gate:

```sh
xcodebuild test -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,id=AF90E17A-F07E-40FB-B32E-C52FFCA09DE7' \
  -only-testing:BookQuotesTests/OnDeviceQuoteExtractorTests \
  -only-testing:BookQuotesTests/QuoteExtractionPromptBuilderTests
```

Result: passed.

- 23 tests executed.
- 0 failures.
- Result bundle: `/Users/user298279/Library/Developer/Xcode/DerivedData/BookQuotes-chdblwnjsdsclucdtkuelvsnfrxn/Logs/Test/Test-BookQuotes-2026.07.01_08-23-48-+0100.xcresult`

Final focused gate after helper cleanup:

```sh
xcodebuild test -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,id=AF90E17A-F07E-40FB-B32E-C52FFCA09DE7' \
  -only-testing:BookQuotesTests/OnDeviceQuoteExtractorTests \
  -only-testing:BookQuotesTests/QuoteExtractionPromptBuilderTests
```

Result: passed.

- 23 tests executed.
- 0 failures.
- Result bundle: `/Users/user298279/Library/Developer/Xcode/DerivedData/BookQuotes-chdblwnjsdsclucdtkuelvsnfrxn/Logs/Test/Test-BookQuotes-2026.07.01_08-24-49-+0100.xcresult`

## Residual Risk

- This covers same-baseline OCR duplicate fragments. It does not prove the hosted model will choose full quote windows in every real photo.
- It does not handle cases where Vision only returns the clipped fragment and no fuller same-baseline line exists.
- Issue 013 remains open for model quality, strict JSON guarantees, source tracking, small bracket/tick recognition, and real-photo reproduction of the missed vertical-line case.
