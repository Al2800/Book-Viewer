# TestFlight Release - Build 51 (v2.0.0) - 2026-08-31

## Overview

- **App Version (MARKETING_VERSION):** `2.0.0`
- **Build Number (CURRENT_PROJECT_VERSION):** `51`
- **Bundle Identifier:** `com.acampbell.bookquotes`
- **Upload Date:** `2026-08-31T05:28:11-07:00`
- **Delivery UUID / Build ID:** `207f7712-e4d6-45a5-b69a-f4ce0318b574`
- **Processing State:** `VALID`
- **Encryption Exemption:** `usesNonExemptEncryption: false`
- **Uploaded File Size:** `30.07 MB`
- **Validation Status:** `VERIFY SUCCEEDED with no errors`
- **Upload Status:** `UPLOAD SUCCEEDED with no errors`

## Merged pull requests

1. **#6 `fix(capture): restore Batch mode and saved draft access`**
   - Restores Batch capture and resumable draft access from the Capture tab after Build 50 opened directly into single-page capture.

2. **#7 `fix(camera): harden lifecycle, flash and ISBN scanning from Build 50`**
   - Hardens camera session lifecycle, flash controls, and ISBN scanning across quote, batch, and cover capture.

3. **#8 `fix(ui): correct library actions, review overlays and Studio exports`**
   - Fixes library actions, extraction-review overlays, and Studio export/canvas correctness.

## Verification & Status

- Focused unit tests passed: CaptureFlashMode, CameraService, ISBNScanner, LibraryBookshelfView, QuoteCardStudioView, QuoteStudioExportService, CaptureTab, CaptureFlowState.
- Local archive: `artifacts/release/BookQuotes-51.xcarchive`.
- Local IPA: `artifacts/release/BookQuotes-51-export/BookQuotes.ipa`.
- Apple `altool` validation and upload succeeded.
- Internal TestFlight group `Test v1` automatically receives access to Build 51.
