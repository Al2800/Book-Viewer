# TestFlight Release - Build 50 (v2.0.0) - 2026-08-30

## Overview

- **App Version (MARKETING_VERSION):** `2.0.0`
- **Build Number (CURRENT_PROJECT_VERSION):** `50`
- **Bundle Identifier:** `com.acampbell.bookquotes`
- **Upload Date:** `2026-08-30T14:20:20-07:00` (22:20 UTC)
- **Delivery UUID / Build ID:** `3006de22-7232-47ee-a65e-b45d0ce588eb`
- **Processing State:** `VALID`
- **Encryption Exemption:** `usesNonExemptEncryption: false`
- **Uploaded File Size:** `29.96 MB`
- **Validation Status:** `VERIFY SUCCEEDED with no errors`
- **Upload Status:** `UPLOAD SUCCEEDED with no errors`

## Scope of Changes in Build 50 (v2.0.0)

1. **Complete V2 Design System & Visual Polish**:
   - Tactile luxury paper palettes: `warmVellum`, `darkLinen`, `editorialMonochrome`.
   - Gold foil accents (`gildedAccent`, `goldFoil`, `foilAccent` gradient) and spine depth shaders.
   - Editorial serif typography (`serifTitleLarge`, `serifHeadline`, `quoteDisplay`, `quoteLarge`) and handwritten `marginScript`.

2. **Commonplace Library & 3D Hardcovers**:
   - Interactive 3D hardcovers (`ThreeDimensionalBookView`) with page block fore-edges, spine hinge grooves, and contact shadows.
   - Procedural classic clothbound hardcovers (*Oxford Navy*, *Forest Green*, *Burgundy Wine*, *Terracotta*, *Charcoal Linen*).
   - Rich mahogany wood grain bookshelf ledge with surface lighting sheen.
   - Redesigned Daily Serendipity epigraph passage card with gold foil bookmark ribbon.
   - Category filter pills with fluid spring animations and haptic feedback.

3. **Smart AR Capture HUD & Active Reading**:
   - Zero-click active reading session capture with floating `ActiveBookHUDView` and book switcher sheet.
   - Real-time Apple Vision line detection with glowing amber bounding overlays (`LiveARMarkOverlay`).
   - Safe-area inset adaptation for Dynamic Island and sensor housing.

4. **Synchronized Extraction Review Studio**:
   - Split visual provenance tethering captured photo bounding boxes to editable cards with glowing illumination.
   - Handwritten margin notes in organic script.
   - Removable AI-suggested topic tag pills.

5. **Typographic Quote Card Studio**:
   - Dedicated 4th tab in Liquid Glass navigation.
   - Interactive canvas with touch gestures (pan, pinch-to-scale, alignment guides, reset transform).
   - 5 editorial themes and 3 aspect ratio presets (Story `9:16`, Square `1:1`, Portrait `4:5`).
   - Rich export workflows: Photos library save (with async permissions guard), image clipboard copy, Obsidian Markdown, and Notion Callout Markdown.

## Verification & Status

- Local archive created: `artifacts/release/BookQuotes-50.xcarchive`.
- Local IPA export created: `artifacts/release/BookQuotes-50-export/BookQuotes.ipa`.
- Validation via Apple `altool` passed with 0 errors.
- App Store Connect upload succeeded under Delivery UUID `3006de22-7232-47ee-a65e-b45d0ce588eb`.
- Processing state transitioned to `VALID` and encryption exemption set to `false`.
- Internal TestFlight group `Test v1` automatically receives access to Build 50.
