# Settings Tab Modular Refactor Characterization

Date: 2026-06-06

## Scope

Issue: `docs/issues/005-settings-tab-modular-refactor.md`

Target file:

- `BookQuotes/App/SettingsTab.swift`: 1287 LOC before this slice.

## Current Structure

- `SettingsTab` (lines 5-50): tab shell, `RouterPath`, `SubscriptionService` creation, navigation destination mapping.
- `SettingsDestination` (lines 52-58): account, markings, storage, about.
- `SettingsView` (lines 60-200): Settings root scroll view, section composition, export sheet, legal document sheet, `@AppStorage` preferences.
- `SettingsView.settingsSectionCard` (lines 202-219): reusable card wrapper.
- `SettingsRow` (lines 221-277): reusable row styling.
- `SettingsToggleRow` (lines 279-327): reusable toggle row styling.
- `AccountView` (lines 329-608): account identity, sign in, sign out, subscription/paywall, restore purchases.
- `AboutView` and `InfoRow` (lines 622-706): app metadata and credits.
- `StorageBackupView` (lines 708-1051): storage counts, export backup, image cache clearing, file deletion helpers.
- `LegalDocument`, `LegalDocumentSection`, `LegalLinksRow`, `LegalDocumentView` (lines 1053-1277): legal content model, legal links, legal document presentation.

## Behaviour Inventory

Settings root visible sections:

- Account: account/subscription entry.
- Capture: Marking Definitions navigation and Auto-process Queue toggle.
- Display: Library View segmented picker and Haptic Feedback toggle.
- Data: Export Quotes sheet and Storage & Backup navigation.
- About: About navigation, Privacy Policy sheet, Terms of Service sheet.

Navigation destinations:

- `SettingsDestination.account` -> `AccountView`.
- `SettingsDestination.markings` -> `MarkingDefinitionsView`.
- `SettingsDestination.storage` -> `StorageBackupView`.
- `SettingsDestination.about` -> `AboutView`.

Sheets/dialogs/alerts:

- Settings root: export sheet, legal document sheet.
- Account: sign-in sheet, paywall sheet, sign-out confirmation, restore error alert.
- Storage: export options dialog, clear cache confirmation, export result alert, exporting overlay.
- Legal document: dismiss toolbar button.

State and dependencies:

- `AuthService` environment.
- `RouterPath` environment for settings navigation.
- `SubscriptionService` created by `SettingsTab`.
- `@Query` for quotes, books, and cache clearing queue items.
- `@AppStorage` keys: `libraryViewMode`, `autoProcessQueue`, `hapticFeedbackEnabled`.
- `ExportService`, `ExportFileWriter`, `CaptureQueueItem.queueDirectory`, `FileManager.default`, `HapticManager`.
- `AppReleaseConfiguration` controls subscription, cloud-sync copy, support email, and legal date.

## Characterization Coverage

- Existing: `MarkingDefinitionsFlowTests.testSettings_MarkingDefinitions_AddCustomMarking` covers Settings -> Marking Definitions navigation and custom marking creation.
- Added: `MarkingDefinitionsFlowTests.testSettingsRoot_DisplaysCoreSectionsAndRows` covers the Settings root title, visible section inventory, and major rows across scroll positions.

## First Extraction Plan

Start with low-risk structural extraction:

- `SettingsRows.swift`: `SettingsSectionCard`, `SettingsRow`, `SettingsToggleRow`, `SettingsInfoRow`.
- `SettingsLegalViews.swift`: `LegalDocument`, `LegalDocumentSection`, `LegalLinksRow`, `LegalDocumentView`.
- `SettingsAboutView.swift`: `AboutView`.
- `SettingsStorageBackupView.swift`: `StorageBackupView`.
- Leave `SettingsTab.swift` as the tab shell, destination mapping, root settings composition, and `AccountView` for the first pass.

This should materially reduce `SettingsTab.swift` while preserving the current settings root interface and navigation.

## Acceptance Notes

- Do not change visible labels or navigation destination names in this slice.
- Do not alter account/subscription state handling in the first pass.
- Keep extracted modules cohesive; do not create one-row pass-through files.
- Run the Settings root characterization and Marking Definitions acceptance test after extraction.
