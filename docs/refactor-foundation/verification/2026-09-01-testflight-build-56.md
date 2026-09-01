# TestFlight Release - Build 56 (v2.0.0) - 2026-09-01

## Overview

- **App Version (MARKETING_VERSION):** `2.0.0`
- **Build Number (CURRENT_PROJECT_VERSION):** `56`
- **Bundle Identifier:** `com.acampbell.bookquotes`
- **Delivery UUID / Build ID:** `1060047e-94ef-4049-844f-c15784849f53`
- **Validation Status:** `VERIFY SUCCEEDED with no errors`
- **Upload Status:** `UPLOAD SUCCEEDED with no errors`

## UI/UX & Architecture Fixes in Build 56

1. **Full-Bleed Capture Viewfinder & Floating Chrome**:
   - Eliminated `safeAreaInset` on `CoverCaptureView`, standardizing on floating overlays (`CoverCaptureHeader` and `CoverCaptureBottomControls` in `CaptureControlTray`).
   - Enabled `hidesTabBar: true` on `QuoteCaptureFlowView` and `BatchCaptureFlowView` in `CaptureTabRootView`, removing light tab bar bleed through at the bottom.
   - Updated `processingView` in `QuoteCaptureView` to full-bleed black background (`Color.black.ignoresSafeArea()`), eliminating the white flash after snapping photos.
   - Redesigned `MissingSelectedBookView` with full-bleed dark theme and golden foil CTA.

2. **Reading Tab ("The Reading Sanctuary") Polish**:
   - **Continue Reading Hero Card**: Refactored VoiceOver accessibility so the card navigation action ("Open [Book Title]") and 1-tap capture action ("Capture passage for [Book Title]") are independently accessible. Added accessible 44pt hit targets to the capture pill and open button.
   - **Daily Serendipity & Recent Passages**: Added deduplication in `LibraryHomeSnapshot` to prevent the same passage from showing redundantly in both sections.
   - **Books Section Controls**: Standardized `LibraryBrowseControls` on accessible 44pt touch targets for grid/list mode and sort order. Removed duplicate inline plus button to ensure identifier uniqueness with the navigation bar action.
   - **Responsive Organize Section**: Wrapped Collections and Tags cards with Dynamic Type awareness for accessibility.
   - **Filtered Empty State**: Redesigned `LibraryFilteredBooksEmptyCard` with warm vellum card styling.
   - **Cruft Removal**: Removed unused legacy components (`LibraryBrowseSection`, `LibrarySummaryCard`, `LibraryControlRow`, `LibraryActionRow`).

3. **State Side-Effect Elimination**:
   - Added pure non-mutating query `activeBook(from:)` to `ActiveReadingSessionStore` so `LibraryHomeSnapshot` initialization performs zero mutations/side effects.

## Verification

- Complete iPhone 17 unit test suite passed (`xcodebuild test`).
- Bugbot code review clean pass.
- Local archive (`xcodebuild archive`) and IPA export succeeded.
- Apple `altool` validation and upload succeeded (`exit_code: 0`).
