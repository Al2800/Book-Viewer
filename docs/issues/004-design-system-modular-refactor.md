# Design System Modular Refactor

Status: `closed`

Priority: medium

## Problem

`DesignSystem.swift` is 1534 LOC with a complexity proxy of 96. It is the largest production file, but it has broad UI blast radius because most screens depend on its tokens and modifiers.

This should follow the capture/review refactors so behaviour-critical flows are already protected.

## Acceptance Criteria

- [ ] Characterization assessment records current LOC, public token/modifier/type surface, major call-site categories, and highest-risk visual dependencies before production edits.
- [ ] Compile-level characterization proves current public symbols are still available after extraction.
- [ ] Focused simulator smoke covers at least one screen from each high-use category touched by the slice: capture, library/search, book edit, and settings.
- [ ] Split only cohesive modules with clear locality; avoid one-file-per-token sprawl.
- [ ] Existing public names are preserved unless call sites are intentionally migrated in the same slice with no compatibility shim clutter.
- [ ] No visual behaviour changes are introduced unless explicitly documented as neutral and verified by simulator screenshots or UI smoke.
- [ ] `DesignSystem.swift` moves materially toward sub-500 LOC and extracted files remain focused, ideally under 500 LOC each.
- [ ] Verification docs record tests, simulator status, LOC delta, known residual risk, and any neutral visual notes.

## Initial Target

Split tokens, typography, colors, spacing, shadows, glass/paper modifiers, and preview/demo helpers into cohesive modules.

## Characterization Plan

Before production edits:

- run a public-surface scan for top-level `enum`, `struct`, `extension`, `ViewModifier`, static token groups, and custom modifiers in `DesignSystem.swift`;
- list dependent call-site clusters with `rg` for `Color.`, `Spacing.`, `Typography.`, `CornerRadius.`, `.paper`, `.glass`, `.elevation`, `.brand`, and app-specific modifiers;
- record the current design-system LOC and candidate module split;
- add compile-focused characterization where practical by exercising representative symbols from extracted modules.

## Proposed Module Boundaries

- `DesignSystemColors.swift`: app color aliases and semantic colour helpers.
- `DesignSystemSpacing.swift`: spacing, radius, sizing, and layout constants.
- `DesignSystemTypography.swift`: typography and text-style helpers.
- `DesignSystemEffects.swift`: shadows, elevation, glass, paper, chrome, and visual modifiers.
- `DesignSystemComponents.swift` or existing component files: only if repeated component styles are currently embedded in the design-system file.
- `DesignSystemPreviews.swift`: preview/demo-only content, if present.

## TDD / Refactor Approach

- Red: add characterization coverage or a compile gate for the first cohesive surface to extract.
- Green: move only that cohesive surface and preserve public names.
- Refactor: remove duplicate comments/demo code and keep the extracted file focused.
- Repeat in small slices rather than splitting all 1534 LOC in one pass.

## Completion Notes

Closed on 2026-06-06.

The first design-system slice was a mechanical extraction that preserved existing public names and avoided call-site migrations.

Extracted modules:

- `DesignSystem.swift`: base colors, typography, spacing, radius, stroke, overlay, shadow, and gradients.
- `DesignSystemChrome.swift`: elevation, glass, paper, camera chrome, and field chrome modifiers.
- `DesignSystemMotion.swift`: accessibility manager, animation/transition presets, entrance/staggered/shake modifiers.
- `DesignSystemFeedback.swift`: haptic feedback manager.
- `DesignSystemButtons.swift`: semantic button styles and `ButtonStyle` convenience accessors.
- `DesignSystemContextMenus.swift`: context menu modifiers and quote/book previews.
- `DesignSystemInteractionHelpers.swift`: conditional view helper, swipe-action helpers, and numeric keyboard toolbar.

LOC moved from `DesignSystem.swift` at 1534 LOC before the slice to 374 LOC after the slice. All extracted production files are below 500 LOC.

Acceptance covered:

- Compile gate for app target after extraction.
- Representative simulator smoke across capture, search/library, book edit, and settings routes.

Residual follow-up:

- No intentional visual changes were introduced. Any future design-system work should now target individual extracted modules rather than re-expanding `DesignSystem.swift`.
