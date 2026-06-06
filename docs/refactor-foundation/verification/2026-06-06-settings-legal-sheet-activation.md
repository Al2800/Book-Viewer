# Settings Legal Sheet Activation Verification

Date: 2026-06-06

Issue: `docs/issues/011-settings-legal-sheet-activation.md`

## Change

Settings Privacy Policy, Terms of Service, and Export Quotes rows now use concrete `Button` controls with stable accessibility identifiers. The existing single `SettingsPresentedSheet` enum remains the only sheet state for export and legal documents.

## Red

```sh
xcodebuild test -quiet -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -only-testing:BookQuotesUITests/MarkingDefinitionsFlowTests/testSettingsRoot_PrivacyPolicySheet_OpensLegalContent
```

Result before production fix: failed. The Privacy row existed in the accessibility tree but the test could not reliably tap it and observe legal content.

## Green

Focused issue acceptance:

```sh
xcodebuild test -quiet -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -only-testing:BookQuotesUITests/MarkingDefinitionsFlowTests/testSettingsRoot_PrivacyPolicySheet_OpensLegalContent \
  -only-testing:BookQuotesUITests/MarkingDefinitionsFlowTests/testSettingsRoot_TermsOfServiceSheet_OpensLegalContent \
  -only-testing:BookQuotesUITests/MarkingDefinitionsFlowTests/testSettingsRoot_ExportQuotesSheet_StillOpens
```

Result: passed in 36.690 seconds.

Broader Settings smoke:

```sh
xcodebuild test -quiet -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -only-testing:BookQuotesUITests/MarkingDefinitionsFlowTests/testSettingsRoot_DisplaysCoreSectionsAndRows \
  -only-testing:BookQuotesUITests/MarkingDefinitionsFlowTests/testSettingsRoot_NavigatesToExtractedDestinationsAndLegalSheets \
  -only-testing:BookQuotesUITests/MarkingDefinitionsFlowTests/testSettingsRoot_PrivacyPolicySheet_OpensLegalContent \
  -only-testing:BookQuotesUITests/MarkingDefinitionsFlowTests/testSettingsRoot_TermsOfServiceSheet_OpensLegalContent \
  -only-testing:BookQuotesUITests/MarkingDefinitionsFlowTests/testSettingsRoot_ExportQuotesSheet_StillOpens \
  -only-testing:BookQuotesUITests/MarkingDefinitionsFlowTests/testSettings_MarkingDefinitions_AddCustomMarking
```

Result: passed in 103.515 seconds.

## Behaviour Notes

No additional sheet modifiers were added to `SettingsView`.

Privacy Policy and Terms now open through the same visible row labels but with deterministic button activation. Export Quotes still opens from Settings after sharing the unified sheet state.
