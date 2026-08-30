# TestFlight Release - Build 49 (v2.0.0) - 2026-08-30

## Overview

- **App Version (MARKETING_VERSION):** `2.0.0`
- **Build Number (CURRENT_PROJECT_VERSION):** `49`
- **Bundle Identifier:** `com.acampbell.bookquotes`
- **Upload Date:** `2026-08-30T15:27:11+01:00`
- **Delivery UUID:** `51c42fda-61ad-42f7-8b0c-93310b0595cc`
- **Uploaded File Size:** `29.94 MB`
- **Validation Status:** `VERIFY SUCCEEDED with no errors`
- **Upload Status:** `UPLOAD SUCCEEDED with no errors`

## Remediations & Polish Delivered in Build 49

1. **Fixed "Save to Photos" Crash (`book-quote-aseh.1`)**:
   - Added `NSPhotoLibraryAddUsageDescription` to `BookQuotes/Resources/Info.plist` explaining that BookQuotes saves beautifully designed quote cards to the Photos library.
   - Refactored `QuoteStudioExportService` to modern async/await `PHPhotoLibrary.shared().performChanges` with `PHPhotoLibrary.requestAuthorization(for: .addOnly)` guard, eliminating legacy `UIImageWriteToSavedPhotosAlbum` and unhandled exceptions.

2. **Resolved Capture HUD Overlap & Refactored Navigation (`book-quote-aseh.2`)**:
   - Eliminated redundant `CaptureHeaderBar` inside `QuoteCaptureView` and `BatchCaptureView` when embedded under `ActiveBookHUDView`.
   - Used safe-area top insets for `ActiveBookHUDView` to ensure clean spacing below Dynamic Island and sensor housing.
   - Refactored `MissingSelectedBookView` with a direct call-to-action to select an active book, and ensured cancelling capture does not lock the screen into an unrecoverable state.

3. **Studio Theme Swatches Hit Targets & Canvas Auto-Framing (`book-quote-aseh.3`)**:
   - Re-proportioned `StudioThemePicker` preview swatches to 58x42 with clean 66x64 full-surface touch targets (`contentShape(Rectangle())`).
   - Added high-contrast gilded active state selection rings.
   - Optimized `StudioTab` preview viewport height calculation to dynamically fit `Story (9:16)`, `Portrait (4:5)`, and `Square (1:1)` quote cards without overflowing or clipping the preset theme controls below.

4. **Universal 3D Hardcovers Across Library Grid (`book-quote-aseh.4`)**:
   - Integrated `ThreeDimensionalBookView` across all `BookCoverCard` items in the main Library grid.
   - For books with catalog / ISBN cover art, rendered in realistic 3D perspective with paper fore-edge block and spine hinge grooves.
   - For books without scanned cover art, procedurally rendered classic clothbound hardcovers (*Oxford Navy*, *Forest Green*, *Burgundy Wine*, *Terracotta*, *Charcoal Linen*) using a stable deterministic hash across app launches.

5. **Interactive 3D Hardcover Hero Showcase in Book Detail (`book-quote-aseh.5`)**:
   - Upgraded `BookHeaderView` in `BookDetailView` to showcase an interactive 3D hardcover hero book with tactile spring press animation.

## Verification & Test Suite

- Executed full unit test suite: **704 tests executed, 0 failures, 100% pass rate**.
- Tested deterministic clothbound jacket theme hashing and 3D cover rendering.
- Tested `CaptureFlowState` transitions and navigation edge cases.
- Validated archive and exported IPA via Apple `altool`.
- Uploaded cleanly to App Store Connect TestFlight.
