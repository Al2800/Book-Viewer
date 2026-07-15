# Signed App Store Release Preflight - 2026-07-15

## Scope

Validate that the current iOS source can produce a locally exported, App Store-distribution IPA
without uploading it or changing App Store Connect state.

## Provisioning Repair

An initial archive failed because the locally installed automatic profile did not contain the
required Sign in with Apple entitlement. The app already declares
`com.apple.developer.applesignin = Default` in
`BookQuotes/Resources/BookQuotes.entitlements`.

Rerunning the archive with `-allowProvisioningUpdates` refreshed the automatic profile and
succeeded:

```sh
xcodebuild archive -quiet -project BookQuotes.xcodeproj -scheme BookQuotes \
  -configuration Release -destination 'generic/platform=iOS' \
  -archivePath /tmp/BookQuotes-AppStoreProvisioned-2026-07-15.xcarchive \
  -allowProvisioningUpdates
```

The archive contains arm64 `com.acampbell.bookquotes`, version `1.0`, build `38`.

## Distribution Export

The tracked `scripts/ExportOptions-AppStore.plist` uses the `app-store-connect` export method
with `destination = export`. It intentionally produces an IPA without an upload.

```sh
xcodebuild -exportArchive -quiet \
  -archivePath /tmp/BookQuotes-AppStoreProvisioned-2026-07-15.xcarchive \
  -exportPath /tmp/BookQuotes-AppStoreExport-2026-07-15 \
  -exportOptionsPlist scripts/ExportOptions-AppStore.plist \
  -allowProvisioningUpdates
```

Result: passed. Xcode automatically managed the exported IPA to version `1.0`, build `39`.
The exported app was inspected and has:

- bundle identifier `com.acampbell.bookquotes`;
- `iPhone Distribution: Alastair Campbell (92XJSN32W4)` signature;
- `com.apple.developer.applesignin = Default`;
- `get-task-allow = false`.

## Remaining Gates

- This was a local export only; build `39` has not been uploaded or verified in App Store Connect.
- `scripts/appstoreconnect_status.js` cannot currently query build `39` because
  `~/.appstoreconnect/config.json` is absent and no `ASC_CONFIG_PATH` was supplied. Restore the
  API configuration before selecting and uploading the next TestFlight candidate.
- Cloudflare production still lacks `APPLE_IAP_KEY_ID`, `APPLE_IAP_ISSUER_ID`, and
  `APPLE_IAP_PRIVATE_KEY`; deploy only after they are provisioned.
- The guarded staging checks, real-device TestFlight matrix, App Privacy questionnaire, App
  Review Notes, and physical accessibility review remain required before App Review submission.
