# TestFlight Build 23 Verification

## Scope

Goal: run a wider pre-TestFlight simulator smoke after the settings legal-sheet fix, bump the app build number, archive, upload, and verify App Store Connect/TestFlight processing state.

## Build Settings

Observed app target settings before archive:

- Bundle identifier: `com.acampbell.bookquotes`
- Marketing version: `1.0`
- Build number: `23`
- Team: `92XJSN32W4`
- Signing style: Automatic

The test targets kept their existing internal build numbers.

## Wider Simulator Smoke

Command:

```bash
xcodebuild test -quiet -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -only-testing:BookQuotesUITests/QuoteCaptureFlowTests/testExtractionReview_DisplaysExtractedQuotes \
  -only-testing:BookQuotesUITests/QuoteCaptureFlowTests/testQuoteEditor_CanEditText \
  -only-testing:BookQuotesUITests/CoverCaptureFlowTests/testCoverCapture_TestCoverButton_NavigatesToBookEdit \
  -only-testing:BookQuotesUITests/CoverCaptureFlowTests/testCoverCapture_CropAccept_DismissesReviewBeforeProcessing \
  -only-testing:BookQuotesUITests/BatchCaptureFlowTests/testBatchCapture_ThumbnailDetail_CanRemoveCapture \
  -only-testing:BookQuotesUITests/SearchFlowTests/testSearch_Query_ShowsResults \
  -only-testing:BookQuotesUITests/BookRegistrationFlowTests/testEditBook_ModifyTitle_SavesChanges \
  -only-testing:BookQuotesUITests/MarkingDefinitionsFlowTests/testSettingsRoot_PrivacyPolicySheet_OpensLegalContent \
  -only-testing:BookQuotesUITests/MarkingDefinitionsFlowTests/testSettingsRoot_TermsOfServiceSheet_OpensLegalContent \
  -only-testing:BookQuotesUITests/MarkingDefinitionsFlowTests/testSettingsRoot_ExportQuotesSheet_StillOpens
```

Result:

- Selected UI smoke passed.
- Test runtime: `213.717` seconds.
- Xcode emitted repeated `IDELaunchParametersSnapshot` debugger-version warnings; these did not fail the run.

Covered:

- Extraction review displays extracted quotes.
- Quote editor text editing.
- Cover capture test-cover route into book edit.
- Cover crop accept route dismisses review before processing.
- Batch capture thumbnail detail removal.
- Search results route.
- Book edit title save.
- Settings privacy, terms, and export sheets.

## Archive

Command:

```bash
xcodebuild archive -project BookQuotes.xcodeproj -scheme BookQuotes -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath artifacts/release/BookQuotes-1.0-23.xcarchive \
  -allowProvisioningUpdates
```

Result:

- Archive succeeded.
- Archive bundle identifier: `com.acampbell.bookquotes`
- Archive version: `1.0`
- Archive build: `23`

## Upload

Export options used:

```text
method = app-store-connect
destination = upload
teamID = 92XJSN32W4
signingStyle = automatic
uploadSymbols = true
manageAppVersionAndBuildNumber = false
```

Command:

```bash
xcodebuild -exportArchive \
  -archivePath artifacts/release/BookQuotes-1.0-23.xcarchive \
  -exportPath artifacts/release/export-23 \
  -exportOptionsPlist artifacts/release/ExportOptions-TestFlight.plist \
  -allowProvisioningUpdates
```

Result:

- App Store Connect analysis completed.
- Upload succeeded.
- Xcode reported: `Uploaded BookQuotes`.
- Xcode reported: `Uploaded package is processing.`
- Export succeeded.

## App Store Connect Verification

Command:

```bash
BUILD_NUMBER=23 node scripts/appstoreconnect_status.js --set-encryption-false
```

Result:

- App ID: `6758091579`
- Build ID: `3bad4149-6941-4626-89a5-4f6562f407b6`
- Processing state: `VALID`
- Encryption status: `usesNonExemptEncryption: false`
- Internal beta group `Test v1` has `hasAccessToAllBuilds: true`
- Alastair Campbell (`acampbell193@googlemail.com`) remains in the internal `Test v1` beta group

## Follow-On Refactor Block

After device-level TestFlight review, continue the large refactor block in this order:

1. Library tab characterization and modular extraction.
2. Onboarding view characterization and modular extraction.
3. Camera service/capture queue characterization and service-boundary cleanup.
