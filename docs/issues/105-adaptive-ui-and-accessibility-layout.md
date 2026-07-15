# 105 - Harden compact, Dynamic Type, rotation, and iPad layouts

Status: in progress
Area: UI / Accessibility / iPad
Priority: medium (release blocker 14)

## Problem

The phone library grid can compress cards to 100 points while retaining status and quote-count rows, causing truncation. Extraction Review combines fixed-width and fixed-height regions that leave little room for editing under larger text, rotation, or narrow split views. Other screens leave large unused regions, producing inconsistent density.

## Acceptance Criteria

- [x] Book cards remain legible without overlapping or clipped status/count text.
- [x] Extraction Review adapts its source image, page navigation, and editor by size class.
- [ ] All core workflows support Accessibility text sizes without inaccessible controls.
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
  Settings actions and the title, publisher, and Add Book controls remain reachable after the
  form scrolls to fully visible fields (2 focused tests passed, 0 failed on 2026-07-15).
- [x] iPad Pro 13-inch UI test verifies the normal-text, side-by-side extraction-review layout.
- [x] A 2026-07-15 iPad Air 11-inch (M4) simulator rerun verified the regular-width,
  side-by-side extraction-review layout (1 focused test passed, 0 failed). The compact and
  regular layout branches cover the size-class behavior used by iPad split views; physical
  split-view interaction remains in the device matrix below.
- [x] Simulator screenshots were visually inspected for the iPhone accessibility-text and iPad
  review layouts. The focused Xcode commands completed successfully on 2026-07-14 and the
  2026-07-15 landscape/compact regression after replacing its zero-height nested quote list
  with a single vertical review scroll surface.
- [ ] Complete the screenshot matrix for small phone, large phone, portrait, landscape, and
  iPad split view on a physical device.
- [ ] Complete VoiceOver and Reduce Motion device smoke, including source-image activation and
  page-selector order.
