# TestFlight Release - Build 48 (v2.0.0) - 2026-08-30

## Overview

- **App Version (MARKETING_VERSION):** `2.0.0`
- **Build Number (CURRENT_PROJECT_VERSION):** `48`
- **Bundle Identifier:** `com.acampbell.bookquotes`
- **Upload Date:** `2026-08-30T05:39:35-07:00`
- **Build ID:** `6e3bd44c-6d0f-464a-9807-213b8ba35f05`
- **Processing State:** `VALID`
- **Encryption Exemption:** `usesNonExemptEncryption: false`

## Enhancements Delivered in Build 48

1. **True 3D Standing Hardcover Books (`ThreeDimensionalBookView`)**:
   - Realistic 3D perspective projection with 18-degree viewing angle (`rotation3DEffect`).
   - Page block fore-edge (cream paper stack with fine layer striations and inner gutter shadow).
   - Top paper edge thickness.
   - Spine hinge crease groove (French groove) and surface light sheen.
   - Deep ambient occlusion and contact shadows onto the wooden shelf surface.
   - Tactile spring press feedback animation.

2. **Procedural Classic Clothbound Hardcovers (`ProceduralClothboundCoverView`)**:
   - Open-source procedural clothbound jacket generator for books without scanned cover art.
   - 5 classic library cloth themes (*Oxford Navy*, *Forest Green*, *Burgundy Wine*, *Terracotta Cloth*, *Charcoal Linen*).
   - Tactile linen weave pattern overlay and double embossed gold foil borders (`✦` and `❖` ornaments).

3. **Rich Library Bookshelf Ledge**:
   - Warm mahogany/oak wood grain ledge with top surface reflection highlight and beveled front depth.

4. **Studio Canvas & Long Quote Auto-Fitting**:
   - Fixed the canvas viewport overflow bug with geometry-constrained aspect ratio calculations.
   - Dynamic proportional quote typography scaling based on quote length and aspect ratio (`Story 9:16`, `Square 1:1`, `Portrait 4:5`) so 300+ character passages fit cleanly without clipping or distorting the background.
   - Mini 3D book cover badge in attribution footer.
   - Interactive zoom/pan clamps with quick "Reset Transform" button.

5. **3-Tier Typography Standardization**:
   - Tier 1: Apple New York Serif for literary/display text (`serifTitleLarge`, `serifHeadline`, `quoteDisplay`, `quoteBody`, `bookTitle`, `authorName`).
   - Tier 2: Margin Script Italic for handwritten annotations (`marginScript`, `marginScriptSmall`).
   - Tier 3: SF Pro Sans for UI chrome and metadata (`sectionHeader`, `uiBadge`, `uiPill`, `bodyText`, `caption`).

## Verification & Status

- Full unit test suite passed.
- Local IPA export and validation via `altool` passed with zero errors.
- Uploaded and processed in App Store Connect (`VALID`).
- Available immediately in TestFlight for internal group `Test v1`.
