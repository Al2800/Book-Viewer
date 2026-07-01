# 2026-07-01: Book ISBN Confirmation Validation Refactor

## Changes

- Added `BookISBNConfirmationValidation` for deterministic ISBN confirmation title/author field validity.
- Added focused characterization tests.
- Updated `BookISBNConfirmationSheet` validation helpers to use the validation module.

## LOC

- `BookQuotes/Features/BookRegistration/BookISBNConfirmationSheet.swift`: 458 LOC.
- `BookQuotes/Features/BookRegistration/BookISBNConfirmationValidation.swift`: 18 LOC.
- `BookQuotesTests/Unit/BookRegistration/BookISBNConfirmationValidationTests.swift`: 38 LOC.

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
  -only-testing:BookQuotesTests/BookISBNConfirmationValidationTests \
  -only-testing:BookQuotesTests/BookISBNConfirmationDraftTests \
  -only-testing:BookQuotesTests/BookEditSaveDraftTests \
  -only-testing:BookQuotesTests/BookEditDraftTests
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

Simulator smoke should cover ISBN confirmation validation once CoreSimulator is available.
