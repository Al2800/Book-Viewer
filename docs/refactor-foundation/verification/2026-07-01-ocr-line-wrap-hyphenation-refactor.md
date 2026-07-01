# 2026-07-01: OCR Line-Wrap Hyphenation Refactor

## Scope

Issue 013 included real TestFlight examples where selected quote text contained line-wrap OCR fragments such as `unbeliev- ably`. This slice keeps the fix inside the on-device candidate selection seam, after marked lines have already been selected.

The intent is narrow: repair obvious soft hyphenation caused by a printed word split across OCR lines, without inventing text or removing hard printed hyphens.

## Characterization

Added:

- `OnDeviceQuoteExtractorTests.testSelectorRepairsObviousLineWrapHyphenationAfterSelection`

The characterization uses selected underline lines containing:

- `to the unbeliev-`
- `ably leisurely pace of`
- `well-known physics`

The first red run failed because the selector returned `to the unbeliev- ably leisurely pace of well-known physics`.

## Implementation

- Replaced raw selected-line whitespace joining in `QuoteMarkTextSelector` with a small OCR line joiner.
- Joined only when the current selected text ends with `-` and the character before the hyphen plus the first character of the next OCR line are both lowercase.
- Preserved hard hyphens inside one OCR line, such as `well-known`.
- Kept cleanup after candidate selection so it cannot expand the quote window or invent missing text.

## Verification

Focused red run before implementation:

```sh
xcodebuild test -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,id=AF90E17A-F07E-40FB-B32E-C52FFCA09DE7' \
  -only-testing:BookQuotesTests/OnDeviceQuoteExtractorTests/testSelectorRepairsObviousLineWrapHyphenationAfterSelection
```

Result: failed as expected.

- Expected: `to the unbelievably leisurely pace of well-known physics`
- Actual: `to the unbeliev- ably leisurely pace of well-known physics`
- Result bundle: `/Users/user298279/Library/Developer/Xcode/DerivedData/BookQuotes-chdblwnjsdsclucdtkuelvsnfrxn/Logs/Test/Test-BookQuotes-2026.07.01_08-13-16-+0100.xcresult`

Focused green run after implementation:

```sh
xcodebuild test -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,id=AF90E17A-F07E-40FB-B32E-C52FFCA09DE7' \
  -only-testing:BookQuotesTests/OnDeviceQuoteExtractorTests/testSelectorRepairsObviousLineWrapHyphenationAfterSelection
```

Result: passed.

- 1 test executed.
- 0 failures.
- Result bundle: `/Users/user298279/Library/Developer/Xcode/DerivedData/BookQuotes-chdblwnjsdsclucdtkuelvsnfrxn/Logs/Test/Test-BookQuotes-2026.07.01_08-14-01-+0100.xcresult`

Focused extraction gate:

```sh
xcodebuild test -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,id=AF90E17A-F07E-40FB-B32E-C52FFCA09DE7' \
  -only-testing:BookQuotesTests/OnDeviceQuoteExtractorTests
```

Result: passed.

- 13 tests executed.
- 0 failures.
- Result bundle: `/Users/user298279/Library/Developer/Xcode/DerivedData/BookQuotes-chdblwnjsdsclucdtkuelvsnfrxn/Logs/Test/Test-BookQuotes-2026.07.01_08-16-47-+0100.xcresult`

Focused extraction and prompt-builder gate:

```sh
xcodebuild test -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,id=AF90E17A-F07E-40FB-B32E-C52FFCA09DE7' \
  -only-testing:BookQuotesTests/OnDeviceQuoteExtractorTests \
  -only-testing:BookQuotesTests/QuoteExtractionPromptBuilderTests
```

Result: passed.

- 21 tests executed.
- 0 failures.
- Result bundle: `/Users/user298279/Library/Developer/Xcode/DerivedData/BookQuotes-chdblwnjsdsclucdtkuelvsnfrxn/Logs/Test/Test-BookQuotes-2026.07.01_08-17-59-+0100.xcresult`

Low-confidence review characterization:

```sh
xcodebuild test -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,id=AF90E17A-F07E-40FB-B32E-C52FFCA09DE7' \
  -only-testing:BookQuotesTests/OnDeviceQuoteExtractorTests/testOnDeviceExtractorReturnsLowConfidenceMarkedCandidatesForReview
```

Result: passed.

- 1 test executed.
- 0 failures.
- Result bundle: `/Users/user298279/Library/Developer/Xcode/DerivedData/BookQuotes-chdblwnjsdsclucdtkuelvsnfrxn/Logs/Test/Test-BookQuotes-2026.07.01_08-19-55-+0100.xcresult`

Final focused extraction and prompt-builder gate:

```sh
xcodebuild test -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,id=AF90E17A-F07E-40FB-B32E-C52FFCA09DE7' \
  -only-testing:BookQuotesTests/OnDeviceQuoteExtractorTests \
  -only-testing:BookQuotesTests/QuoteExtractionPromptBuilderTests
```

Result: passed.

- 22 tests executed.
- 0 failures.
- Result bundle: `/Users/user298279/Library/Developer/Xcode/DerivedData/BookQuotes-chdblwnjsdsclucdtkuelvsnfrxn/Logs/Test/Test-BookQuotes-2026.07.01_08-20-13-+0100.xcresult`

## Residual Risk

- This is deterministic OCR cleanup, not proof that the hosted model catches every marked line in real photos.
- It does not yet solve partial orphan fragments at quote starts/ends.
- It does not replace the need for real photographed fixtures covering vertical margin marks, small brackets, and short ticks.
- Full XCUITest quote-capture smoke remains blocked by issue 081.
