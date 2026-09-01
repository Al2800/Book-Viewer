# TestFlight Release - Build 57 (v2.0.0) - 2026-09-01

## Overview

- **App Version (MARKETING_VERSION):** `2.0.0`
- **Build Number (CURRENT_PROJECT_VERSION):** `57`
- **Bundle Identifier:** `com.acampbell.bookquotes`
- **Delivery UUID / Build ID:** `4cb77a13-780a-4f78-9264-03f0fa3f1708`
- **Validation Status:** `VERIFY SUCCEEDED with no errors`
- **Upload Status:** `UPLOAD SUCCEEDED with no errors`

## Fixes in Build 57

Follow-up to the Build 56 review. Capture stays dark after the shutter, and close controls are usable without the tab bar.

1. **Review Photo is dark:** `ImageReviewView` uses a black background and a dark navigation bar so Cancel is white on black, not white on cream.
2. **HUD close is 44pt:** The capture HUD X is a 44pt hit target. With the tab bar hidden, this is the primary exit from Capture.
3. **Batch capture uses the same HUD:** Batch mode shows the active-book HUD plus Done and the page counter, instead of the old session header.
4. **Continue Reading capture uses the HUD:** Capture from Reading hides the old header and overlays the same book HUD, including switch-book.
5. **Missing-book close is on-screen:** The empty-book capture screen has a 44pt close control because the navigation bar is hidden.
6. **Books heading matches other sections:** Reading uses `sectionHeaderStyle()` for Books as well as Continue Reading, Recent Passages, Daily Serendipity, and Organize.
7. **Store test isolation:** The pure-query unit test uses a private UserDefaults suite and no longer clears the real active-book ID.

`LibraryBookshelfView` remains in the tree unused; it was not deleted.

## Verification

- Complete iPhone 17 unit test suite passed (`xcodebuild test`).
- Local archive (`xcodebuild archive`) and IPA export succeeded.
- Apple `altool` validation and upload succeeded (`exit_code: 0`).
