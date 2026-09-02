# TestFlight Release - Build 58 (v2.0.0) - 2026-09-02

## Overview

- **App Version (MARKETING_VERSION):** `2.0.0`
- **Build Number (CURRENT_PROJECT_VERSION):** `58`
- **Bundle Identifier:** `com.acampbell.bookquotes`
- **Delivery UUID / Build ID:** _pending upload_
- **Validation Status:** _pending_
- **Upload Status:** _pending_

## Changes in Build 58

Wrapper reshape after Build 57. Reading / Capture / Studio is the primary shell. Capture is quiet. Review is a stacked Passages sheet.

1. **Studio is the third tab.** Explore is not a primary tab. Settings opens from the Reading gear.
2. **Quiet capture:** no live AR overlay and no Image Review gate. A usable shutter opens Passages as a large sheet. Unusable frames show `Too blurry to read — tap to retake` for 6 seconds.
3. **Batch matches single-page Ink chrome.** Last-page 50×50 strip with a gilded count capsule. Done opens Passages, not a full-screen cream review. Save Draft stays on Cancel.
4. **Passages sheet:** title `Passages` with book subtitle, foil `Save to Library`, stacked quote cards, `Add a passage manually`. Multi-page groups use `PAGE n` and `View page`.
5. **Quote cards:** warm vellum, 3pt confidence bar (`>= 0.8` success, `>= 0.5` warning, else error). Delete lives in Passage actions. No selection ring or percentage badge.
6. **Reading headers** keep symbol + `sectionHeaderStyle()` for Continue Reading, Recent Passages, Organize, and Books.

`ImageReviewView`, `LibraryBookshelfView`, `IlluminatedPageOverlay`, and `PageListView` remain in the tree unused; they were not deleted.

## Verification

- Complete iPhone 17 unit test suite passed (`xcodebuild test`, 732 tests, 0 failures).
- Retargeted UI tests passed on iPhone 17: V2 shell, Studio, quiet capture → Passages, batch Done → Passages, batch View page, Save Draft via Cancel.
- Local archive, IPA export, Apple `altool` validation and upload: _pending_.

## Known gaps

- Cover capture still exists from Add Book, not as a Capture-tab mode card.
- Remotion PNG regeneration was not required for this bead; the screenshot list now points at quiet Capture, Passages, and Studio.
- Unused Swift files from earlier capture/review chrome were left in the tree on purpose.
