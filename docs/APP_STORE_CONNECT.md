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

## Latest TestFlight Verification

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
docs/refactor-foundation/verification/2026-06-06-testflight-build-23.md
docs/refactor-foundation/verification/2026-06-06-testflight-build-22.md
```

When uploading a future build, use the same release pattern:

1. Run focused unit and simulator acceptance checks.
2. Archive with `xcodebuild archive`.
3. Upload with `xcodebuild -exportArchive`.
4. Use `scripts/appstoreconnect_status.js` to verify processing state, encryption status, and tester group visibility.
5. Record results in `docs/refactor-foundation/verification/`.
