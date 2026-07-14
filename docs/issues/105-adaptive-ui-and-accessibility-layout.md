# 105 - Harden compact, Dynamic Type, rotation, and iPad layouts

Status: open
Area: UI / Accessibility / iPad
Priority: medium (release blocker 14)

## Problem

The phone library grid can compress cards to 100 points while retaining status and quote-count rows, causing truncation. Extraction Review combines fixed-width and fixed-height regions that leave little room for editing under larger text, rotation, or narrow split views. Other screens leave large unused regions, producing inconsistent density.

## Acceptance Criteria

- [ ] Book cards remain legible without overlapping or clipped status/count text.
- [ ] Extraction Review adapts its source image, page navigation, and editor by size class.
- [ ] All core workflows support Accessibility text sizes without inaccessible controls.
- [ ] Declared orientations and iPad split-view sizes are either supported or intentionally constrained.
- [ ] VoiceOver order, labels, and touch targets pass a manual audit.

## Verification

- Screenshot matrix for small phone, large phone, iPad, portrait, landscape, and split view.
- Dynamic Type UI tests at default and accessibility sizes.
- VoiceOver and Reduce Motion device smoke.

