# TestFlight Release - Build 54 (v2.0.0) - 2026-09-01

## Overview

- **App Version (MARKETING_VERSION):** `2.0.0`
- **Build Number (CURRENT_PROJECT_VERSION):** `54`
- **Bundle Identifier:** `com.acampbell.bookquotes`
- **Delivery UUID / Build ID:** `3f88d0b3-a873-4aed-9710-48f2da3e06fa`
- **Validation Status:** `VERIFY SUCCEEDED with no errors`
- **Upload Status:** `UPLOAD SUCCEEDED with no errors`

## Why Build 53 looked unchanged

Build 52 stored `product_experience_v2_enabled = false`. Build 53 defaulted the new shell on, but `AppStorage` kept the old persisted `false`, so testers stayed on Library / Capture / Studio / Settings.

## Fix in Build 54

- Rotated the preference key to `product_experience_prefer_v2`.
- Fresh installs and existing testers now get Reading / Capture / Explore by default.
- Settings still has a toggle to restore the previous four-tab layout.

## Verification

- `TabTests` passed, including the rotated preference key.
- Local archive and IPA export succeeded.
- Apple `altool` validation and upload succeeded.
