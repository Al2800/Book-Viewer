# Book ISBN Confirmation Draft Refactor Verification

Date: 2026-06-30

## Commands

```sh
xcodebuild test -quiet -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' -only-testing:BookQuotesTests/BookISBNConfirmationDraftTests
```

Result: passed.

```sh
xcodebuild test -quiet -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' -only-testing:BookQuotesTests/BookISBNConfirmationDraftTests -only-testing:BookQuotesTests/BookEditSaveDraftTests -only-testing:BookQuotesTests/BookEditDraftTests -only-testing:BookQuotesTests/CoverMetadataNormalizerTests -only-testing:BookQuotesTests/CoverExtractionOrchestratorTests -only-testing:BookQuotesTests/CoverCropGeometryTests
```

Result: passed.

```sh
xcodebuild build -quiet -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5'
```

Result: passed.

## Notes

No UI smoke was run for this slice because the changed behavior is deterministic `Book` construction and the simulator UI runner has recently failed before app assertions. The simulator build confirms the sheet and project wiring compile.
