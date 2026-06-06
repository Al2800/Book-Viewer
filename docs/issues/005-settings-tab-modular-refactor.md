# Settings Tab Modular Refactor

Status: `closed`

Priority: medium

## Problem

`SettingsTab.swift` is 1287 LOC with a complexity proxy of 120. It mixes settings navigation, account/subscription presentation, storage/backup, support/app information, and reusable settings rows.

This is a high LOC and complexity target, but lower immediate workflow risk than capture/review.

## Acceptance Criteria

- [ ] Characterization assessment records current LOC, section inventory, navigation destinations, sheet/alert state, destructive actions, and service dependencies before production edits.
- [ ] Current settings behaviours and navigation are characterized before production edits with tests or simulator assertions for the paths touched.
- [ ] Simulator or UI acceptance covers every settings path touched by the slice.
- [ ] Extracted modules own cohesive settings behaviour, not shallow wrappers around single rows.
- [ ] `SettingsTab.swift` moves materially toward sub-500 LOC and extracted files remain focused, ideally under 500 LOC each.
- [ ] Account, subscription, storage/export, support, and app-info actions remain wired.
- [ ] Verification docs record tests, simulator status, LOC delta, and neutral behaviour notes.

## Initial Target

Separate settings navigation, account/subscription presentation, storage/backup, app information, and reusable settings rows into focused modules.

## Characterization Plan

Before production edits:

- inventory visible settings sections, buttons, sheets, alerts, navigation links, and any destructive flows;
- map dependencies used by settings, including auth/account, subscription, storage/export, support links, app metadata, and environment services;
- record the current settings LOC and candidate module split;
- identify existing UI tests for Settings and add missing acceptance coverage before moving touched behaviours.

## Proposed Module Boundaries

- `SettingsTab.swift`: parent navigation shell, environment dependencies, and high-level section composition.
- `SettingsAccountSection.swift`: account identity, sign-in/out, and subscription entry points.
- `SettingsStorageSection.swift`: storage, export, backup, cache, and destructive confirmation flows.
- `SettingsSupportSection.swift`: help, feedback, contact, and external-link actions.
- `SettingsAppInfoSection.swift`: version, legal, acknowledgements, and app metadata.
- `SettingsRows.swift`: reusable settings row/chip/toggle primitives only when they are genuinely shared across sections.

## TDD / Refactor Approach

- Red: add or run a focused UI acceptance for the first settings section being moved.
- Green: extract one cohesive section and keep all actions wired through the same parent state or explicit callbacks.
- Refactor: reduce parent state and duplicate row styling only after the moved section is covered.
- Repeat section-by-section, avoiding a broad rewrite that changes navigation and presentation state at the same time.

## Completion Notes

Closed on 2026-06-06.

The Settings root was split into focused modules:

- `SettingsTab.swift`: navigation shell and root section composition.
- `SettingsRows.swift`: shared settings row/card primitives.
- `SettingsAccountView.swift`: account, sign-in, sign-out, and subscription presentation.
- `SettingsStorageBackupView.swift`: storage, export, cache, and backup presentation.
- `SettingsAboutView.swift`: app information.
- `SettingsLegalViews.swift`: legal document data and display rows.

LOC moved from `SettingsTab.swift` at 1287 LOC before the slice to 234 LOC after the slice. All extracted production files remain below 500 LOC.

Acceptance covered:

- Settings root section and row visibility.
- Navigation to extracted Account, Storage & Backup, and About destinations.
- Legal rows remain visible and reachable by stable identifiers.
- Marking Definitions add-custom-marking flow still works from Settings after extraction.

Residual follow-up:

- Legal document sheet activation is tracked separately in `011-settings-legal-sheet-activation.md`.
