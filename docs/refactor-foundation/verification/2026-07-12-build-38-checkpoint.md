# Build 38 Checkpoint

Date: 2026-07-12

## Included Changes

- Merged and verified the Library foundation slice on `main`.
- Includes PR branch work through `830a802`:
  - `LibraryHomeSnapshot` computes the daily passage and total quote count in one pass per render.
  - Shared `SectionCard` migration covers Settings, capture landing, book edit, tags/collections editors, and export surfaces.
  - Registration first-book milestone now guards against double-save.
  - Library search and share-card rendering now refresh from current state.
  - Library accessibility helpers were aligned with the SectionCard migration for Mac runner verification.
- Current checkpoint commit before the build bump: `bc9ff1d`.
- App target build number is set to `38`.

## Local Verification

Focused Library unit gate:

```sh
xcodebuild test -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -only-testing:BookQuotesTests/LibraryContentModeTests \
  -only-testing:BookQuotesTests/LibraryHomeSnapshotTests \
  -only-testing:BookQuotesTests/LibrarySearchServicesTests \
  -only-testing:BookQuotesTests/LibraryViewModeTests \
  -only-testing:BookQuotesTests/LibrarySortOrderTests \
  -only-testing:BookQuotesTests/LibraryNavigationLookupTests
```

Result: passed.

Library/Search UI smoke:

```sh
xcodebuild test -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -only-testing:BookQuotesUITests/SearchFlowTests/testSearch_Query_ShowsResults \
  -only-testing:BookQuotesUITests/SearchFlowTests/testSearchResult_TapFirstCell_NavigatesToDetail \
  -only-testing:BookQuotesUITests/LibraryManagementTests/testBookDetail_ExportSheet_Available
```

Result: passed.

App Store screenshot and SectionCard path sweep:

```sh
xcodebuild test -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -only-testing:BookQuotesUITests/AppStoreScreenshotsTests/testAppStoreScreenshots \
  -only-testing:BookQuotesUITests/CollectionsTagsFlowTests/testCollectionSheet_CreateNew_ShowsNameField
```

Result: passed.

Final simulator compile:

```sh
xcodebuild build -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5'
```

Result: passed. Existing Swift 6/concurrency/deprecation warnings remain.

## Archive and Upload

Archive:

```sh
xcodebuild archive -project BookQuotes.xcodeproj -scheme BookQuotes \
  -configuration Release -destination 'generic/platform=iOS' \
  -archivePath artifacts/release/BookQuotes-38.xcarchive
```

Result: archive succeeded.

Archive metadata:

- `CFBundleShortVersionString`: `1.0`
- `CFBundleVersion`: `38`

Upload:

```sh
xcodebuild -exportArchive \
  -archivePath artifacts/release/BookQuotes-38.xcarchive \
  -exportPath artifacts/release/BookQuotes-38-export \
  -exportOptionsPlist artifacts/release/ExportOptions-TestFlight.plist
```

Result: export succeeded and uploaded `BookQuotes`.

## App Store Connect

Status command:

```sh
BUILD_NUMBER=38 node scripts/appstoreconnect_status.js
```

Encryption command:

```sh
BUILD_NUMBER=38 node scripts/appstoreconnect_status.js --set-encryption-false
```

Result:

- App ID: `6758091579`
- Bundle ID: `com.acampbell.bookquotes`
- Build ID: `b38a707f-19ec-404f-b9f7-68db7442e004`
- Uploaded date: `2026-07-12T06:48:13-07:00`
- Processing state: `VALID`
- Encryption status: `usesNonExemptEncryption: false`
- Internal beta group `Test v1` has `hasAccessToAllBuilds: true` and includes tester Alastair Campbell.

## TestFlight Checklist

Use build 38 to verify:

- Library home renders the same as build 37 while using the single-pass snapshot.
- Today passage and total quote counts remain correct with a populated library.
- Library search returns current results after library data changes.
- Book detail export sheet is still reachable from the Library path.
- SectionCard migrated screens remain visually equivalent: Settings, capture landing, book edit, tags/collections editors, and export.
- Capture and extraction remain unaffected by the Library foundation slice.

## Remaining Risk

- Physical-device TestFlight smoke is pending.
- Extraction quality tuning remains tracked separately under issues `012`, `013`, and `014`.
- Existing Swift 6/concurrency warnings are still visible during compile and should be handled as a separate hardening slice.
