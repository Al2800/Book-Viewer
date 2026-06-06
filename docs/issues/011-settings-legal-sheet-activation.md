# 011 - Settings Legal Sheet Activation

Status: closed
Area: Settings
Priority: medium

## Problem

During the SettingsTab modular refactor, simulator acceptance could locate and tap the Privacy Policy and Terms of Service rows, but the expected legal sheet content did not appear reliably.

## Characterization

- `SettingsView` previously used two sheet modifiers on the same root view: one for export and one for legal documents.
- The refactor changed this to a single `SettingsPresentedSheet` enum so export and legal presentations share one sheet modifier.
- UI automation still failed to observe legal content after tapping the legal rows, even with stable accessibility identifiers.
- Account, Storage & Backup, and About destinations remain reachable in simulator acceptance.

## Acceptance Criteria

- A focused simulator test opens Privacy Policy from Settings and observes legal content.
- A focused simulator test opens Terms of Service from Settings and observes legal content.
- Export Quotes sheet still opens from Settings after the unified sheet state.
- Legal rows retain stable accessibility identifiers.
- No additional sheet modifiers are added to `SettingsView`; sheet presentation remains a single explicit state.

## Verification

- Run focused Settings UI tests on simulator.
- Manually verify Privacy Policy, Terms of Service, and Export Quotes from Settings before the next TestFlight push.

## Outcome

Closed on 2026-06-06.

The legal and export rows in `SettingsView` now use real `Button` controls with stable accessibility identifiers instead of gesture-wrapped rows. The single `SettingsPresentedSheet` state remains in place, so Settings still has one explicit sheet modifier for export and legal presentation.

Added focused simulator acceptance for:

- Privacy Policy opening and showing legal content.
- Terms of Service opening and showing legal content.
- Export Quotes opening and showing export controls or the no-quotes empty state.

The broader Settings smoke also passed after the fix.
