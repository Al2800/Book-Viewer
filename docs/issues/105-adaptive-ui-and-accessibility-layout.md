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
- [ ] Declared orientations and iPad split-view sizes are either supported or intentionally constrained.
- [ ] VoiceOver order, labels, and touch targets pass a manual audit.

## Verification

- [x] iPhone 17 UI tests at `UICTContentSizeCategoryAccessibilityXXXL` cover Library grid,
  Library list, and the compact extraction-review layout. The book presentations remain
  reachable at full width; the review uses a horizontal page selector and exposes its source
  image as an accessible action.
- [x] iPad Pro 13-inch UI test verifies the normal-text, side-by-side extraction-review layout.
- [x] Simulator screenshots were visually inspected for the iPhone accessibility-text and iPad
  review layouts. The focused Xcode commands completed successfully on 2026-07-14.
- [ ] Complete the screenshot matrix for small phone, large phone, portrait, landscape, and
  iPad split view on a physical device.
- [ ] Complete VoiceOver and Reduce Motion device smoke, including source-image activation and
  page-selector order.
