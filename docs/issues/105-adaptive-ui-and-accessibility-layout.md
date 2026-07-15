# 105 - Harden compact, Dynamic Type, rotation, and iPad layouts

Status: in progress
Area: UI / Accessibility / iPad
Priority: medium (release blocker 14)

## Problem

The phone library grid can compress cards to 100 points while retaining status and quote-count rows, causing truncation. Extraction Review combines fixed-width and fixed-height regions that leave little room for editing under larger text, rotation, or narrow split views. Other screens leave large unused regions, producing inconsistent density.

## Acceptance Criteria

- [x] Book cards remain legible without overlapping or clipped status/count text.
- [x] Extraction Review adapts its source image, page navigation, and editor by size class.
- [x] All core workflows support Accessibility text sizes without inaccessible controls.
- [x] Declared orientations and iPad split-view sizes are either supported or intentionally constrained.
- [ ] VoiceOver order, labels, and touch targets pass a manual audit.

## Verification

- [x] iPhone 17 UI tests at `UICTContentSizeCategoryAccessibilityXXXL` cover Library grid,
  Library list, and the compact extraction-review layout. The book presentations remain
  reachable at full width; the review uses a horizontal page selector and exposes its source
  image as an accessible action. On 2026-07-15, the compact review also rotated to landscape,
  scrolled to a fully visible quote row, and opened its editor (2 focused tests passed, 0 failed).
- [x] iPhone 17 UI tests at `UICTContentSizeCategoryAccessibilityXXXL` also cover Settings
  navigation (Remote AI Processing and Storage & Export) and the manual book-entry route. Both
  Settings actions and the title, publisher, and Add Book controls remain reachable; the form
  scrolls to fully visible optional fields when needed (2 focused tests passed, 0 failed on
  2026-07-15).
- [x] iPhone 17 UI tests at `UICTContentSizeCategoryAccessibilityXXXL` cover quote search,
  opening a result, and entering the quote editor. The result row, detail actions, and editor
  remain reachable (1 focused test passed, 0 failed on 2026-07-15).
- [x] iPhone 17 UI test at `UICTContentSizeCategoryAccessibilityXXXL` covers batch capture
  entry, book selection, capture, Done, and the captured-page thumbnail. Batch mode is
  reachable after scrolling at the largest text size (1 focused test passed, 0 failed on
  2026-07-15).
- [x] Manual book entry now places required book details above the optional cover panel, so its
  title field is immediately visible at accessibility text sizes. Edit and populated
  metadata-confirmation forms retain their cover-first order. The large-text regression,
  ordinary manual creation, and populated-cover navigation each passed on iPhone 17 / iOS 26.5
  (3 focused tests, 0 failures on 2026-07-15).
- [x] iPad Pro 13-inch UI test verifies the normal-text, side-by-side extraction-review layout.
- [x] A 2026-07-15 iPad Air 11-inch (M4) simulator rerun verified the regular-width,
  side-by-side extraction-review layout (1 focused test passed, 0 failed). The compact and
  regular layout branches cover the size-class behavior used by iPad split views; physical
  split-view interaction remains in the device matrix below.
- [x] The complete UI release target passed on both iPhone 17 Pro and iPad Air 11-inch (M4):
  101 tests, 0 failures, and 0 skips on each simulator. This covers all automated tablet
  workflows on revision `a5ed719`; physical accessibility and split-view checks remain below.
- [x] Accessibility XXXL onboarding now uses vertically scrollable steps, presents marking
  choices in one readable column, and reflows subscription cards so plan details and prices do
  not truncate. The local-only first-run path, accessibility subscription screen, normal marking
  setup, and normal subscription media screen passed 4 tests with no failures or skips.
- [x] Accessibility XXXL cover capture keeps its mode picker, shutter fixture, manual-entry
  fallback, and crop confirmation reachable through to the book form. The shared camera header
  now reflows at accessibility sizes, and the concise cover instruction remains fully readable.
  The focused iPhone 17 Pro journey passed with 0 failures on 2026-07-15; its screenshot was
  also visually inspected for clipping and overlap.
- [x] Accessibility XXXL Settings coverage now opens Marking Styles, reaches Add Custom
  Marking, and verifies the name, visual-description, and meaning fields plus the fixed Cancel
  and Save actions. The focused iPhone 17 Pro journey passed with 0 failures on 2026-07-15;
  list and editor screenshots were visually inspected for clipping and overlap.
- [x] Accessibility XXXL collection and tag coverage now creates both organization types,
  reaches their horizontally scrolling Library filters, and opens the quote assignment sheets.
  Quote organization actions reflow into full-width controls, and dismissing the collection
  sheet no longer prevents the tag sheet from opening. Three focused iPhone 17 Pro tests passed
  with 0 failures on 2026-07-15; the quote action screenshot was visually inspected for clipping
  and overlap.
- [x] Accessibility XXXL export coverage opens Export Quotes from Settings, selects JSON,
  reaches all option toggles and the updated preview, performs the export, and verifies that Save
  to Files and Share remain available. The focused iPhone 17 Pro journey passed with 0 failures
  on 2026-07-15; its options/preview screenshot was visually inspected for clipping and overlap.
- [x] Simulator screenshots were visually inspected for the iPhone accessibility-text and iPad
  review layouts. The focused Xcode commands completed successfully on 2026-07-14 and the
  2026-07-15 landscape/compact regression after replacing its zero-height nested quote list
  with a single vertical review scroll surface.
- [x] The Library home, Settings root, Remote AI settings, and Remote AI consent sheet pass
  Apple's reliable iOS 26 system audits for hit regions, element descriptions, clipped text,
  and accessibility traits. The audit drove a 44-point Sort Books target, removed silent
  truncation from the Daily Passage and attribution, and hid decorative SF Symbols whose
  internal names were being announced. A deterministic WCAG test also verifies primary and
  secondary text against card backgrounds in light and dark modes. The focused contrast,
  seeded-library, and system-audit checks passed with 0 failures on 2026-07-15.
  Apple's iOS 26 contrast pixel audit and OCR element detector are excluded because they produced
  reproducible unlocatable false positives despite compliant captured pixels and a hierarchy
  containing every visible app string; the retained checks and dedicated Accessibility XXXL
  workflows cover their reliable behavior.
- [ ] Complete the screenshot matrix for small phone, large phone, portrait, landscape, and
  iPad split view on a physical device.
- [ ] Complete VoiceOver and Reduce Motion device smoke, including source-image activation and
  page-selector order.
