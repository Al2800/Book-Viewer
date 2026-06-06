# Design System Modular Refactor Characterization

Date: 2026-06-06

## Scope

Issue: `docs/issues/004-design-system-modular-refactor.md`

Target file:

- `BookQuotes/Components/DesignSystem.swift`: 1534 LOC before this slice.

## Public Surface Inventory

- Color and shape-style tokens: `Color.brand`, `Color.backgroundPrimary`, `Color.textPrimary`, `Color.success`, `Color.quoteBackground`, confidence colors, `ShapeStyle.adaptiveBackground`, and related semantic aliases.
- Typography: `Font.quoteDisplay`, `Font.quoteLarge`, `Font.quoteBody`, `Font.attribution`, `Font.bookTitle`, `Font.sectionHeader`, `View.quoteTextStyle()`.
- Layout tokens: `Spacing`, `CornerRadius`, `Stroke`, `Overlay`, `Color.scrim(_:)`.
- Effects and chrome: `Shadow`, `View.elevation(...)`, gradient presets, `glassCard`, `cameraChrome`, `glassButton`, `glassToolbar`, `glassTabBar`, `glassFloating`, `paperCard`, `fieldChrome`.
- Motion and accessibility: `AccessibilityManager`, `Animation` presets, `AnyTransition` presets, entrance/staggered/shake modifiers.
- Feedback: `HapticManager`.
- Buttons: `PressableButtonStyle`, `PrimaryButtonStyle`, `SecondaryButtonStyle`, `DestructiveButtonStyle`, `GhostButtonStyle`, `IconButtonStyle`, and `ButtonStyle` convenience accessors.
- General modifiers: conditional `View.if(...)`.
- Context menus: `PolishedContextMenuModifier`, `SimpleContextMenuModifier`, `polishedContextMenu(...)`, `ContextMenuPreview`, `QuoteContextMenuPreview`, `BookContextMenuPreview`.
- Swipe and keyboard helpers: `SwipeActionStyle`, `numericKeyboardDoneButton()`, `NumericKeyboardToolbarModifier`.

## Call-Site Categories

High-use categories found with `rg`:

- Capture and book registration: camera chrome, glass/paper cards, spacing, background and text colors, stroke tokens.
- Library/search/book detail: quote card typography, paper cards, field chrome, spacing, semantic colors, context previews.
- Book edit and quote detail: field chrome, paper cards, spacing, background/text colors.
- Settings/export: spacing, paper cards, field chrome, semantic row colors, haptic manager.
- Shared components: quote cards, tags, empty/error states, quality meter, button styles, transitions.

## Risk Notes

- The file has broad visual blast radius. The first slice should preserve all public names and avoid call-site migrations.
- `DesignSystem.swift` includes both pure tokens and feature-aware preview helpers that depend on `Quote` and `Book`. These should not live with base tokens after extraction.
- Haptic behavior is controlled by `UserDefaults` key `hapticFeedbackEnabled`; preserve the default-enabled behaviour.
- iOS 26 glass effect fallbacks are user-visible and should be moved without editing logic.

## First Extraction Plan

Split by cohesive surface while preserving the existing public interface:

- `DesignSystem.swift`: keep base color, typography, spacing, radius, stroke, overlay, shadow, and gradient token surface.
- `DesignSystemChrome.swift`: glass, camera chrome, paper card, field chrome, and elevation modifiers.
- `DesignSystemMotion.swift`: accessibility manager, animation/transition presets, entrance/staggered/shake modifiers.
- `DesignSystemFeedback.swift`: `HapticManager`.
- `DesignSystemButtons.swift`: button styles and `ButtonStyle` convenience accessors.
- `DesignSystemContextMenus.swift`: context menu modifiers and quote/book previews.
- `DesignSystemInteractionHelpers.swift`: conditional view modifier, swipe-action helpers, and numeric keyboard toolbar.

## Acceptance Notes

- Preserve public symbol names in this slice.
- Do not intentionally alter visual output.
- Run a compile gate after extraction.
- Run representative simulator smoke across Settings and at least one capture/library route already covered by existing UI tests where practical.
