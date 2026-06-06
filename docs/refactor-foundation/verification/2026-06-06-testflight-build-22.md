# TestFlight Build 22 Verification

## Scope

Issue: `book-quote-release-build-22`

Goal: checkpoint the refactor foundation, bump the app build number above TestFlight build 21, run focused release checks, archive, and upload the next build to App Store Connect for TestFlight processing.

## Checkpoint Commit

Foundation checkpoint:

```text
9138a4f Refactor capture and book edit foundations
```

The checkpoint includes the completed capture/book-edit refactor foundation, characterization tests, simulator verification docs, architecture updates, and exported Beads issue state.

## Build Settings

Observed app target settings after the release bump:

- Bundle identifier: `com.acampbell.bookquotes`
- Marketing version: `1.0`
- Build number: `22`
- Team: `92XJSN32W4`
- Signing style: Automatic

The test targets still use their existing internal build number and are not relevant to App Store Connect upload.

## Release Gate Tests

Command:

```bash
xcodebuild test -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -only-testing:BookQuotesTests/BookEditDraftTests \
  -only-testing:BookQuotesTests/BookEditSaveDraftTests \
  -only-testing:BookQuotesTests/CoverMetadataNormalizerTests \
  -only-testing:BookQuotesTests/CoverExtractionOrchestratorTests \
  -only-testing:BookQuotesTests/CoverCropGeometryTests \
  -only-testing:BookQuotesTests/CoverOCRHeuristicsTests \
  -only-testing:BookQuotesTests/CaptureFlowStateTests \
  -only-testing:BookQuotesUITests/BookRegistrationFlowTests/testManualEntry_CreateBook_WithRequiredFields \
  -only-testing:BookQuotesUITests/BookRegistrationFlowTests/testManualEntry_CreateThenEditBook_UpdatesTitle \
  -only-testing:BookQuotesUITests/CoverCaptureFlowTests/testCoverCapture_TestCoverButton_NavigatesToBookEdit \
  -only-testing:BookQuotesUITests/CoverCaptureFlowTests/testCoverCapture_TestCoverButton_CanSaveBook
```

Result:

- Unit characterization: 26 tests, 0 failures.
- Simulator acceptance: 4 tests, 0 failures.
- Overall selected test session: succeeded.
- Xcode result bundle: `~/Library/Developer/Xcode/DerivedData/BookQuotes-chdblwnjsdsclucdtkuelvsnfrxn/Logs/Test/Test-BookQuotes-2026.06.06_14-23-40-+0100.xcresult`

Simulator acceptance covered:

- Manual book create with required fields.
- Create-then-edit persisted title.
- Cover capture test-cover navigation into book edit.
- Cover capture test-cover save into a created book.

## Archive

Command:

```bash
xcodebuild archive -project BookQuotes.xcodeproj -scheme BookQuotes -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath artifacts/release/BookQuotes-1.0-22.xcarchive \
  -allowProvisioningUpdates
```

Result:

- Archive succeeded.
- Archive bundle identifier: `com.acampbell.bookquotes`
- Archive version: `1.0`
- Archive build: `22`

Note:

- Archive metadata reported Apple Development signing, but the App Store Connect export/upload step completed successfully afterward.

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
  -archivePath artifacts/release/BookQuotes-1.0-22.xcarchive \
  -exportPath artifacts/release/export-22 \
  -exportOptionsPlist artifacts/release/ExportOptions-TestFlight.plist \
  -allowProvisioningUpdates
```

Result:

- App Store Connect analysis completed.
- Upload succeeded.
- Xcode reported: `Uploaded BookQuotes`.
- Xcode reported: `Uploaded package is processing.`
- Export succeeded.

## API Key Check

No raw Gemini API key is shipped in the iOS app. The app uses `AuthService.proxyBaseURL` and `GeminiService` sends authorized requests to the BookQuotes proxy. The backend expects `GEMINI_API_KEY` as a Cloudflare Worker secret.

## TestFlight Group Assignment

Status: verified through the App Store Connect API.

Observed:

- The provided team key ID `6JS7J77LTP` does not have a matching local private key file. The only local `.p8` file found is `~/.appstoreconnect/private_keys/AuthKey_2DTSJAJ0SZB9.p8`.
- The local key `2DTSJAJ0SZB9` authenticates as an individual App Store Connect key when the JWT includes `sub: "user"`.
- BookQuotes app ID: `6758091579`.
- Today's uploaded build 22 ID: `5748fdc4-4c6e-4c68-bc7b-44d4ec082a6f`.
- Build 22 processing state: `VALID`.
- Build 22 encryption status was set and verified as `usesNonExemptEncryption: false`.
- Alastair Campbell (`acampbell193@googlemail.com`) is in the internal `Test v1` beta group.
- The internal `Test v1` beta group has `hasAccessToAllBuilds: true`, so App Store Connect does not allow explicitly assigning individual builds to it.

## Remaining Work

After TestFlight processing, manually confirm build 22 appears in App Store Connect/TestFlight and run device-level smoke checks. The next planned engineering slice remains `book-quote-capture-tab-root-modular-followup`.
