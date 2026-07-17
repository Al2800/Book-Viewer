# Build 44 Camera Permission Startup Fix

## Scope

Build 44 retains the accepted Build 43 model-first extraction path and production provider
configuration. It changes only camera authorization startup behavior:

- An already-authorized user no longer sees a brief `Enable Camera Access` screen before the live
  preview appears.
- `CameraPermissionService` reads the current AVFoundation status before SwiftUI's first render.
- `CameraService` initializes its authorization state from the same shared policy.
- A genuinely first-time user still sees the explicit permission screen and must choose Enable
  Camera Access before iOS requests permission.

## Verification

- Camera authorization, permission, and service gate: 15 tests passed, 0 failures on iPhone 17 /
  iOS 26.5.
- `git diff --check` passed.
- Build 43 physical-device extraction remains accepted and was not changed for Build 44.
- Build 43 StoreKit product loading, GBP localization, and trial signup remain accepted.

## TestFlight Delivery

- Version: `1.0`.
- Build: `44`.
- Source commit: `737faaf` on `main`.
- Signed archive: `artifacts/release/BookQuotes-1.0-44.xcarchive`, arm64.
- Local App Store distribution export: passed.
- TestFlight upload: succeeded on 2026-07-17.
- App Store Connect build ID: `eea39a35-556e-4b3b-9546-323e03020a13`.
- Processing state: `VALID`.
- Encryption declaration: `usesNonExemptEncryption: false`.
- Internal group: `Test v1`, with access to all builds and one tester.
