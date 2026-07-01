# 2026-07-01: Add Tag To Quote Presentation Refactor

## Changes

- Added `AddTagToQuotePresentation` for deterministic available-tag filtering.
- Added focused characterization tests.
- Updated `AddTagToQuoteSheet.availableTags` to delegate to the presentation module.

## LOC

- `BookQuotes/Features/Tags/TagsView.swift`: 443 LOC.
- `BookQuotes/Features/Tags/AddTagToQuotePresentation.swift`: 9 LOC.
- `BookQuotesTests/Unit/Models/AddTagToQuotePresentationTests.swift`: 30 LOC.

## Static Verification

- Passed:
  - `git diff --check`
  - `plutil -lint BookQuotes.xcodeproj/project.pbxproj`
  - LOC check for touched files.

## Xcode Verification

Focused tests should run when the local Xcode runner is healthy:

```sh
xcodebuild test -quiet \
  -project BookQuotes.xcodeproj \
  -scheme BookQuotes \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -only-testing:BookQuotesTests/AddTagToQuotePresentationTests \
  -only-testing:BookQuotesTests/QuoteTagMutationTests \
  -only-testing:BookQuotesTests/TagsPresentationTests \
  -only-testing:BookQuotesTests/TagEditorDraftTests
```

Attempted on 2026-07-01 and blocked before compilation:

```text
DVTFilePathFSEvents: Failed to start fs event stream.
Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error".
```

Simulator smoke was also blocked because `xcrun simctl list devices` could not connect to `CoreSimulatorService`:

```text
Error Domain=NSPOSIXErrorDomain Code=61 "Connection refused"
Unable to lookup com.apple.CoreSimulator.CoreSimulatorService
```

Simulator smoke should cover quote-detail tag management once CoreSimulator is available.
