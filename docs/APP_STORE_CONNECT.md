# App Store Connect Runbook

This repo keeps App Store Connect credentials outside source control. Do not commit `.p8` private key material.

## Local Config

Expected local config:

```text
~/.appstoreconnect/config.json
```

Current working shape:

```json
{
  "issuerId": "45e5d092-22b3-47d7-95f5-04dbb8c6ca94",
  "keyId": "2DTSJAJ0SZB9",
  "privateKeyPath": "/Volumes/Macintosh_HD/Users/user298279/.appstoreconnect/private_keys/AuthKey_2DTSJAJ0SZB9.p8",
  "subject": "user"
}
```

`subject: "user"` is required for the local individual App Store Connect key. Without it, direct REST calls return `401 NOT_AUTHORIZED`.

The team key ID `6JS7J77LTP` was provided, but the matching local private key file was not found. Use that key ID only if `AuthKey_6JS7J77LTP.p8` is also available.

## Status Helper

Check BookQuotes build and TestFlight group status:

```bash
node scripts/appstoreconnect_status.js
```

Check a specific build number:

```bash
BUILD_NUMBER=22 node scripts/appstoreconnect_status.js
```

Set the latest matching build's encryption flag to false, then print status:

```bash
BUILD_NUMBER=22 node scripts/appstoreconnect_status.js --set-encryption-false
```

The helper reads `~/.appstoreconnect/config.json` by default. Override with:

```bash
ASC_CONFIG_PATH=/path/to/config.json node scripts/appstoreconnect_status.js
```

## App Privacy Questionnaire

The checked-in privacy manifest is the source of truth for the data categories below. Before
submission, enter the same selections in App Store Connect and have the submitted values reviewed
against `BookQuotes/Resources/PrivacyInfo.xcprivacy` and the in-app Privacy Policy.

| Data category | Linked to user | Tracking | Purpose | Evidence |
| --- | --- | --- | --- | --- |
| User ID | Yes | No | App functionality | Apple Sign-In session and subscription ownership |
| Email address | Yes | No | App functionality | Optional Apple-provided sign-in email is received during authentication |
| Purchase history | Yes | No | App functionality | StoreKit entitlement and App Store transaction reconciliation |
| Other usage data | Yes | No | App functionality | Monthly extraction count and last-updated time for service limits |
| Photos or videos | Yes | No | App functionality | Page or cover image is sent only after Remote AI Processing consent |
| Other user content | Yes | No | App functionality | Remote extraction instructions and result text are sent only after consent |

Do not select tracking, advertising, analytics, or data sale/sharing. Local-only books, quotes,
tags, collections, and images are not cloud-synced. Google Books and Open Library receive only
the requested ISBN or title/author lookup query, never the BookQuotes account identifier or
library. The configured remote providers are Hugging Face Inference for quote pages and Google
Gemini for covers; Remote AI Processing is optional and can be revoked in Settings.

## Latest TestFlight Verification

Build 38 was uploaded on 2026-07-12 and verified through the App Store Connect API:

- App: `BookQuotes`
- App ID: `6758091579`
- Bundle ID: `com.acampbell.bookquotes`
- Build ID: `b38a707f-19ec-404f-b9f7-68db7442e004`
- Uploaded date: `2026-07-12T06:48:13-07:00`
- Processing state: `VALID`
- Encryption status: `usesNonExemptEncryption: false`

Alastair Campbell is in the internal `Test v1` beta group. That group has `hasAccessToAllBuilds: true`, so App Store Connect does not allow assigning individual builds to it manually.

## Build 29 Verification

Build 29 was uploaded on 2026-06-07 and verified through the App Store Connect API:

- App: `BookQuotes`
- App ID: `6758091579`
- Bundle ID: `com.acampbell.bookquotes`
- Build ID: `65b974ff-5ef7-4db9-9c05-54621fc92e2e`
- Uploaded date: `2026-06-07T07:09:10-07:00`
- Processing state: `VALID`
- Encryption status: `usesNonExemptEncryption: false`

Alastair Campbell is in the internal `Test v1` beta group. That group has `hasAccessToAllBuilds: true`, so App Store Connect does not allow assigning individual builds to it manually.

## Build 28 Verification

Build 28 was uploaded on 2026-06-07 and verified through the App Store Connect API:

- App: `BookQuotes`
- App ID: `6758091579`
- Bundle ID: `com.acampbell.bookquotes`
- Build ID: `502cb29c-d3f5-47f3-bf2a-95c51a46f440`
- Uploaded date: `2026-06-07T06:27:35-07:00`
- Processing state: `VALID`
- Encryption status: `usesNonExemptEncryption: false`

Alastair Campbell is in the internal `Test v1` beta group. That group has `hasAccessToAllBuilds: true`, so App Store Connect does not allow assigning individual builds to it manually.

## Build 27 Verification

Build 27 was uploaded on 2026-06-07 and verified through the App Store Connect API:

- App: `BookQuotes`
- App ID: `6758091579`
- Bundle ID: `com.acampbell.bookquotes`
- Build ID: `07ac82c4-64e1-449c-8ff1-460c32d94dac`
- Processing state: `VALID`
- Encryption status: `usesNonExemptEncryption: false`

Alastair Campbell is in the internal `Test v1` beta group. That group has `hasAccessToAllBuilds: true`, so App Store Connect does not allow assigning individual builds to it manually.

## Build 26 Verification

Build 26 was uploaded on 2026-06-07 and verified through the App Store Connect API:

- App: `BookQuotes`
- App ID: `6758091579`
- Bundle ID: `com.acampbell.bookquotes`
- Build ID: `fbcb1763-7d08-4151-86e1-d22b2d47ced7`
- Processing state: `VALID`
- Encryption status: `usesNonExemptEncryption: false`

Alastair Campbell is in the internal `Test v1` beta group. That group has `hasAccessToAllBuilds: true`, so App Store Connect does not allow assigning individual builds to it manually.

## Build 25 Verification

Build 25 was uploaded on 2026-06-07 and verified through the App Store Connect API:

- App: `BookQuotes`
- App ID: `6758091579`
- Bundle ID: `com.acampbell.bookquotes`
- Build ID: `67d7c7df-1e1a-4cbb-8d2e-4c0ac6fd1095`
- Processing state: `VALID`
- Encryption status: `usesNonExemptEncryption: false`

Alastair Campbell is in the internal `Test v1` beta group. That group has `hasAccessToAllBuilds: true`, so App Store Connect does not allow assigning individual builds to it manually.

## Build 24 Verification

Build 24 was uploaded on 2026-06-06 and verified through the App Store Connect API:

- App: `BookQuotes`
- App ID: `6758091579`
- Bundle ID: `com.acampbell.bookquotes`
- Build ID: `c31545d4-d867-454c-b501-e6efa5ffc5bf`
- Processing state: `VALID`
- Encryption status: `usesNonExemptEncryption: false`

Alastair Campbell is in the internal `Test v1` beta group. That group has `hasAccessToAllBuilds: true`, so App Store Connect does not allow assigning individual builds to it manually.

## Build 23 Verification

Build 23 was uploaded on 2026-06-06 and verified through the App Store Connect API:

- App: `BookQuotes`
- App ID: `6758091579`
- Bundle ID: `com.acampbell.bookquotes`
- Build ID: `3bad4149-6941-4626-89a5-4f6562f407b6`
- Processing state: `VALID`
- Encryption status: `usesNonExemptEncryption: false`

Alastair Campbell is in the internal `Test v1` beta group. That group has `hasAccessToAllBuilds: true`, so App Store Connect does not allow assigning individual builds to it manually.

## Build 22 Verification

Build 22 was uploaded on 2026-06-06 and verified through the App Store Connect API:

- App: `BookQuotes`
- App ID: `6758091579`
- Bundle ID: `com.acampbell.bookquotes`
- Build ID: `5748fdc4-4c6e-4c68-bc7b-44d4ec082a6f`
- Processing state: `VALID`
- Encryption status: `usesNonExemptEncryption: false`

Alastair Campbell is in the internal `Test v1` beta group. That group has `hasAccessToAllBuilds: true`, so App Store Connect does not allow assigning individual builds to it manually.

## Release Notes

Detailed build evidence is logged in:

```text
docs/refactor-foundation/verification/2026-07-12-build-38-checkpoint.md
docs/refactor-foundation/verification/2026-07-05-build-37-checkpoint.md
docs/refactor-foundation/verification/2026-07-05-build-36-checkpoint.md
docs/refactor-foundation/verification/2026-07-05-build-35-checkpoint.md
docs/refactor-foundation/verification/2026-07-05-build-34-checkpoint.md
docs/refactor-foundation/verification/2026-07-04-build-33-checkpoint.md
docs/refactor-foundation/verification/2026-07-04-build-32-checkpoint.md
docs/refactor-foundation/verification/2026-07-04-testflight-build-31.md
docs/refactor-foundation/verification/2026-06-07-testflight-build-29.md
docs/refactor-foundation/verification/2026-06-07-testflight-build-28.md
docs/refactor-foundation/verification/2026-06-07-testflight-build-27.md
docs/refactor-foundation/verification/2026-06-07-testflight-build-26.md
docs/refactor-foundation/verification/2026-06-07-testflight-build-25.md
docs/refactor-foundation/verification/2026-06-06-testflight-build-24.md
docs/refactor-foundation/verification/2026-06-06-testflight-build-23.md
docs/refactor-foundation/verification/2026-06-06-testflight-build-22.md
```

When uploading a future build, use the same release pattern:

1. Run focused unit and simulator acceptance checks.
2. Archive with `xcodebuild archive`.
3. Upload with `xcodebuild -exportArchive`.
4. Use `scripts/appstoreconnect_status.js` to verify processing state, encryption status, and tester group visibility.
5. Record results in `docs/refactor-foundation/verification/`.
