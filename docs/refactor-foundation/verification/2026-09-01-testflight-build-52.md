# TestFlight Release - Build 52 (v2.0.0) - 2026-09-01

## Overview

- **App Version (MARKETING_VERSION):** `2.0.0`
- **Build Number (CURRENT_PROJECT_VERSION):** `52`
- **Bundle Identifier:** `com.acampbell.bookquotes`
- **Delivery UUID / Build ID:** `5237886f-da23-4359-bf85-2156f03dd687`
- **Uploaded File Size:** `30.11 MB`
- **Validation Status:** `VERIFY SUCCEEDED with no errors`
- **Upload Status:** `UPLOAD SUCCEEDED with no errors`

## Merged pull requests

1. **#9 `docs(v2): establish product reset and engineering contracts`**
   - Adds the v2 product spec, architecture, delivery plan, agent contracts, and same-repository ADR. No runtime change.

2. **#10 `feat(v2): add default-off Reading, Capture and Explore shell`**
   - Introduces a reversible product-experience gate (`--product-experience-v2` or `product_experience_v2_enabled`).
   - Default remains the Build 51 four-tab shell: Library, Capture, Studio, Settings.
   - Flagged shell exposes Reading, Capture, and Explore. Studio stays contextual from passage detail. Settings is a secondary action from Explore.

## Verification

- `TabTests`: 9 tests passed, including default-off gate and v2 tab contract.
- `V2ProductShellTests`: UI smoke passed with `--product-experience-v2`.
- Local archive: `artifacts/release/BookQuotes-52.xcarchive`.
- Local IPA: `artifacts/release/BookQuotes-52-export/BookQuotes.ipa`.
- Apple `altool` validation and upload succeeded.
- Internal TestFlight group `Test v1` automatically receives access to Build 52.

## Tester note

This TestFlight build does **not** turn the new shell on by default. Testers see the current Library / Capture / Studio / Settings experience unless the v2 flag is enabled.
