# Small Mark Prompt and Camera Framing Note - 2026-06-07

## Scope

- Tightened the quote extraction prompt for small brackets, short side ticks, braces, partial bracket hooks, and faint pencil marks.
- Added bounded line-wrap hyphenation guidance: repair obvious line-break splits only, preserve hard printed hyphens, and do not invent text.
- Logged camera preview framing and capture guidance as issue `014`.

## User Symptoms Captured

- Build 29 extraction is improving with the 72B model path, but small bracket marks can still be missed.
- The camera preview can feel unexpectedly zoomed in and does not guide the user clearly enough when framing marked passages.

## Verification

```bash
xcodebuild test -quiet -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' -only-testing:BookQuotesTests/QuoteExtractionPromptBuilderTests
git diff --check
```

Result:

- Passed.
- `git diff --check` clean.

Notes:

- Xcode emitted existing Swift concurrency warnings in unrelated services (`SearchDatabase`, `QuoteSaveService`, `BatchProcessingService`, `CaptureQueueManager`) and a retroactive conformance warning in `KeychainServiceTests`.
- No camera production code was changed in this slice. Camera framing remains a separate refactor issue because it needs characterization of real-device preview/capture behaviour before edits.

