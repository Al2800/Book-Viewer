# Build 37 Checkpoint

Date: 2026-07-05

## Included Changes

- Merged `origin/cursor/book-aesthetic-design-pass-d69a` at `48adec4`.
- Includes Library/search fixes:
  - Library search index is synced from current books and quote counts.
  - Book detail screen supports in-book quote search.
  - In-book search matches quote text, margin notes, and personal notes.
  - In-book search is case- and diacritic-insensitive to mirror FTS-backed Library search.
  - New quote presentation unit coverage for search/filter behavior.
- App target build number is set to `37`.

## Review Notes

- No obvious release-blocking issue found in the Library/search code during diff review.
- The incoming branch attempted to roll `CURRENT_PROJECT_VERSION` back to `31` and delete prior release checkpoint docs. Those branch-drift changes were excluded from the merge before commit.

## Local Verification

- Simulator compile:
  - `xcodebuild build -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,id=AF90E17A-F07E-40FB-B32E-C52FFCA09DE7'`
  - Result: passed before the macOS user/directory service failure.
  - A later rerun was blocked by the same `DARWIN_USER_CACHE_DIR` / uid resolution failure affecting archive.
- Focused tests:
  - `BookQuotesTests/BookDetailQuotePresentationTests`
  - `BookQuotesTests/LibraryContentModeTests`
  - `BookQuotesTests/LibraryViewModeTests`
  - `BookQuotesTests/BatchCapturePageStoreTests`
  - `BookQuotesTests/ExtractionReviewProcessorTests`
  - `BookQuotesTests/ExtractionReviewQuoteStateTests`
  - `BookQuotesTests/PageQuoteEditorListTests`
  - `BookQuotesTests/TagRowPresentationTests`
  - `BookQuotesTests/CollectionModelTests`
  - `BookQuotesTests/TagModelTests`
  - Result: 35 tests, 0 failures.
  - Result bundle: `/Users/user298279/Library/Developer/Xcode/DerivedData/BookQuotes-chdblwnjsdsclucdtkuelvsnfrxn/Logs/Test/Test-BookQuotes-2026.07.05_15-11-04-+0100.xcresult`

## Compile Warnings To Follow Up

- Existing Swift 6 sendability warnings remain in search/capture services.
- AppIntents metadata extraction reports no AppIntents dependency; this is informational for the current app.

## Remaining Release Check

- Archive and export build 37.
  - Blocked locally.
  - `xcodebuild archive` aborts because macOS cannot resolve the current uid: `opendirectoryd not available`, `No user exists for uid 598`, and `Failed to get length of DARWIN_USER_CACHE_DIR`.
- Upload build 37 to App Store Connect.
  - Pending until the local macOS user/directory service issue is resolved.
- Confirm App Store Connect processing reaches `VALID`.
  - Pending.
- Confirm `usesNonExemptEncryption: false`.
  - Pending.
- Confirm TestFlight device smoke against the uploaded build.
  - Pending on a physical device.
