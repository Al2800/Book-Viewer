# TestFlight Release - Build 53 (v2.0.0) - 2026-09-01

## Overview

- **App Version (MARKETING_VERSION):** `2.0.0`
- **Build Number (CURRENT_PROJECT_VERSION):** `53`
- **Bundle Identifier:** `com.acampbell.bookquotes`
- **Delivery UUID / Build ID:** `4535516e-46c0-4941-bf9f-e99b83c408f3`
- **Uploaded File Size:** `30.11 MB`
- **Validation Status:** `VERIFY SUCCEEDED with no errors`
- **Upload Status:** `UPLOAD SUCCEEDED with no errors`

## What testers will see

Build 53 turns the v2 product shell **on by default**:

- **Reading** — existing library home, titled Reading
- **Capture** — current active-book capture
- **Explore** — grounded search and revisit over saved passages

Studio is no longer a primary tab. Open a passage and use Design Quote Card. Settings is available from Explore (gear) or by turning the layout off.

A Settings toggle, **Reading, Capture & Explore**, restores the previous four-tab layout if needed.

UI tests still default to the legacy shell unless they pass `--product-experience-v2`.

## Verification

- `TabTests` passed, including legacy disable argument and default-on outside UI tests.
- Archive, IPA export, and Apple validation succeeded.
