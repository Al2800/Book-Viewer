# TestFlight Release - Build 59 (v2.0.0) - 2026-09-02

## Overview

- **App Version (MARKETING_VERSION):** `2.0.0`
- **Build Number (CURRENT_PROJECT_VERSION):** `59`
- **Bundle Identifier:** `com.acampbell.bookquotes`
- **Delivery UUID / Build ID:** `676cb49c-9b45-4301-b547-49ffb7228822`
- **Processing state:** `VALID`
- **Encryption status:** `usesNonExemptEncryption: false`
- **Validation Status:** `VERIFY SUCCEEDED with no errors`
- **Upload Status:** `UPLOAD SUCCEEDED with no errors`

## Changes in Build 59

Reshape hardening after the Build 58 physical walk (`book-quote-v2-reshape-hardening-vnek`). Testers still on Build 58 would hit capture/Passages product bugs; this binary is the tester-visible fix.

1. **Batch save returns to quiet single-page camera**, not an empty batch session.
2. **Passages Cancel/Close only dismisses.** Save still uses `onComplete`; Close no longer jumps to Reading as if save succeeded.
3. **PAGE headers use capture order** (`PAGE 1`, `PAGE 2`) while quote cards keep OCR `p. n`.
4. **Batch HUD keeps the mode menu.** Book-detail HUD switches books. SessionHeader Done matches HUD Done.
5. **Blurry retake no longer leaves a fake last-page strip thumbnail.** Marking type is editable in the Passages editor sheet. Confidence bar fills the card. HUD title uses `.authorName`.
6. Capture/batch/App Store UI tests now drive the v2 Reading shell.

`ImageReviewView`, `CaptureModeSelectionView`, `PageQuoteEditor`, `IlluminatedPageOverlay`, `PageListView`, and related leftover types remain in the tree unused; they were not deleted.

## Verification

- Complete iPhone 17 Pro unit test suite passed (`xcodebuild test`, 733 tests, 1 skipped, 0 failures).
- Focused UI tests passed on iPhone 17 Pro: quiet capture → Passages, Passages Cancel returns to live camera, extracted quotes, low-confidence retake, batch Done → Passages, PAGE headers + View page, App Store screenshots on Reading.
- Local archive (`xcodebuild archive`) and IPA export succeeded. Archive `CFBundleVersion` is `59`.
- Apple `altool` validation and upload succeeded (`exit_code: 0`).
- App Store Connect status: Build 59 `processingState: VALID`, `usesNonExemptEncryption: false`. Internal group Test v1 has `hasAccessToAllBuilds: true`.

## Known gaps

- Cover capture still exists from Add Book, not as a Capture-tab mode card.
- Unused Swift files from earlier capture/review chrome were left in the tree on purpose (`book-quote-v2-reshape-hardening-vnek.12`).
