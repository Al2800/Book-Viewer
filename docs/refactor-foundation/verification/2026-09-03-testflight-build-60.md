# TestFlight Release - Build 60 (v2.0.0) - 2026-09-03

## Overview

- **App Version (MARKETING_VERSION):** `2.0.0`
- **Build Number (CURRENT_PROJECT_VERSION):** `60`
- **Bundle Identifier:** `com.acampbell.bookquotes`
- **Delivery UUID / Build ID:** `6ac47c3b-b250-464b-900b-cc77f8bcf8e0`
- **Processing state:** `VALID`
- **Encryption status:** `usesNonExemptEncryption: false`
- **Validation Status:** `VERIFY SUCCEEDED with no errors`
- **Upload Status:** `UPLOAD SUCCEEDED with no errors`

## Changes in Build 60

Includes PR #11 (Concept 2 & 4 redesign: 3D Multi-Tier Bookshelves, Studio Book Search & Carousel, and Theme Contrast Polish):

1. **Studio Theme Contrast & Palette Fixes:**
   - High-contrast text colors across quote cards for legibility on light and dark backgrounds.
   - New luxury themes `.terracotta` and `.midnightNavy` alongside `.darkLinen`, `.warmVellum`, `.monochrome`, `.editorialNewsprint`, and `.gilded` (7 themes total).
   - Refined secondary text and subtle card borders.

2. **Quote Studio Book Search & Carousel Filter (Concept 2):**
   - Real-time search bar in Studio to filter passages by text, author, title, or margin note.
   - Interactive mini 3D hardcover bookshelf carousel at the top of the passage picker with 1-tap book filtering and an "All Books" shortcut.

3. **Library Multi-Tier 3D Bookshelves (Concept 4):**
   - New `.shelves` primary `LibraryViewMode` alongside `.grid` and `.list`.
   - Tiered grouping: Currently Reading, Finished, and To Read shelves with physical 3D perspective projection and wood ledge depth.
   - Smooth 3-way view switcher menu in browse controls.

4. **Capture Simplicity Preserved:**
   - Viewfinder remains quiet and minimal with the single dark HUD capsule.

## Verification

- Complete iPhone 17 Pro unit test suite passed (`xcodebuild test`, 734 tests, 1 skipped, 0 failures).
- Local archive (`xcodebuild archive`) and IPA export succeeded. Archive `CFBundleVersion` is `60`.
- Apple `altool` validation and upload succeeded (`exit_code: 0`).
- App Store Connect verification: Build 60 `processingState: VALID`, `usesNonExemptEncryption: false`. Internal group Test v1 has `hasAccessToAllBuilds: true`.
