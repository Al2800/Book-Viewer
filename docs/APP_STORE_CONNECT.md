# App Store Connect Runbook

This repo keeps App Store Connect credentials outside source control. Do not commit `.p8` private key material.

## Local Config

Expected local config:

```text
~/.appstoreconnect/config.json
```

Config shape:

```json
{
  "issuerId": "<issuer-id>",
  "keyId": "<key-id>",
  "privateKeyPath": "~/.appstoreconnect/private_keys/AuthKey_<key-id>.p8",
  "subject": "user"
}
```

`subject: "user"` is required for an Individual App Store Connect key. Team keys must omit `subject`; the 17 August Team key `XL86RSSVSY` is configured that way. Do not put `.p8` material in git.

Keep this file and its `.p8` private key outside the repository. The helper expands `~/` in both
the config location and `privateKeyPath`.

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

Status output intentionally omits local private-key paths and individual TestFlight tester data.

## Submission Helper

Inspect the App Store version, attached build, review metadata, subscriptions, and review
submissions without changing App Store Connect:

```bash
node scripts/appstoreconnect_submission.js
```

The helper only changes App Store Connect when an explicit mutation flag is supplied. Its review
submission path is idempotent once a version is already in review and will not select an unrelated
empty draft. Apple's first-subscription rule still requires the app version, subscription group,
and subscription products to be assembled into one review package in App Store Connect.

Create a new version, replace its inherited screenshots, and update its editable metadata:

```bash
ASC_VERSION=1.0.1 BUILD_NUMBER=46 node scripts/appstoreconnect_submission.js --create-version
ASC_VERSION=1.0.1 BUILD_NUMBER=46 node scripts/appstoreconnect_submission.js --replace-screenshots --update-metadata --update-review-notes
```

The screenshot helper reads ordered PNG files from
`Marketing/Video/Remotion/out/appstore/iphone` and
`Marketing/Video/Remotion/out/appstore/ipad`. It removes inherited legacy screenshot sets before
uploading the new iPhone and iPad sets.

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
| Photos or videos | Yes | No | App functionality | A marked-page image is sent only after Remote AI Processing consent |
| Other user content | Yes | No | App functionality | Remote extraction instructions and result text are sent only after consent |

Do not select tracking, advertising, analytics, or data sale/sharing. Local-only books, quotes,
tags, collections, and images are not cloud-synced. Google Books and Open Library receive only
the requested ISBN, never the BookQuotes account identifier or library. The configured remote AI
route uses Hugging Face Inference with the pinned Featherless AI provider for marked quote pages;
Remote AI Processing is optional and can be revoked in Settings. Book covers come from ISBN
catalogue metadata and are not sent to an AI provider.

## App Review Notes

No account is required to use the app's core on-device features. Reviewers can choose
**Continue Without an Account** during onboarding, then add and manage books, capture marked
pages with on-device OCR, search the local library, export quotes, and change Settings. Eligible,
consented subscribers use remote AI first for marked-page extraction. A remote failure is shown
explicitly with Retry AI, Use On-Device Instead, and manual-entry recovery choices.

Apple Sign In is requested only when the reviewer chooses an account-only feature: remote AI
processing or subscription purchase/restoration. Remote AI processing also requires a separate,
revocable image-sharing consent. Books, quotes, and captured images remain local to the device;
signing out or deleting a server account does not delete the local library.

## App Review Submission

Version 1.0 was submitted to App Review on 2026-07-20 at 09:21 BST as one complete review
package:

- Submission ID: `7a44e620-28b7-4ff2-b650-64d6a768d1d8`
- iOS App 1.0, Build 45
- Subscription group: `BookQuotes Premium`
- Subscription: `BookQuotes Monthly` (`com.bookquotes.monthly`)
- Subscription: `BookQuotes Yearly` (`com.bookquotes.yearly`)

App Store Connect and the App Store Connect API both reported all four items as
`WAITING_FOR_REVIEW` after submission. Version 1.0 is configured for automatic release after
approval (`AFTER_APPROVAL`).

On 2026-07-23, Apple rejected the app under an automated App Review guideline check because the
App Store description did not contain a functional Terms of Use link for its auto-renewable
subscriptions. The subscription group and both subscriptions were returned only because the
associated app was rejected. The app already includes in-app Terms of Service and the website has
a terms page, so no binary change is required. The App Store description now includes Apple's
standard EULA link:

`https://www.apple.com/legal/internet-services/itunes/dev/stdeula/`

The same four-item package was resubmitted on 2026-07-23 at 07:16 BST. App Store Connect and the
API confirmed the app version, subscription group, monthly subscription, and yearly subscription
are all `WAITING_FOR_REVIEW`. Build 45 remains attached and `VALID`; automatic release after
approval remains enabled.

On 2026-07-24, version 1.0 reached `READY_FOR_SALE` / `READY_FOR_DISTRIBUTION`. Build 45 remains
`VALID`, and both subscriptions are `APPROVED`. The public BookQuotes website is:

`https://bookquotes-by-al2800.jmc184.chatgpt.site`

Apple locks the live version's marketing, support, and privacy URLs after release, so version 1.0
retains its approved GitHub URLs. The submission helper is configured to use the website home,
`/support`, and `/privacy` for the next editable App Store version.

Version 1.0.1, Build 46 was submitted on 2026-07-27 at 11:42 BST:

- Submission ID: `285b1772-efe2-4a1e-8beb-5a112b3be4f3`
- Review state: `WAITING_FOR_REVIEW`
- Build state: `VALID` and `APP_STORE_ELIGIBLE`
- Encryption: `usesNonExemptEncryption: false`
- Screenshots: seven iPhone and seven iPad images, all `COMPLETE`
- Release: automatic after approval (`AFTER_APPROVAL`)

The update replaces the original simulator-heavy screenshots with rights-safe, stylised images
covering the complete flow: library, ISBN scan, capture, extraction, review, book detail, and
search. The approved monthly and yearly subscriptions remain unchanged.

## Latest TestFlight Verification

Build 45 was uploaded on 2026-07-17 and verified through Apple's build API:

- App: `BookQuotes`
- App ID: `6758091579`
- Bundle ID: `com.acampbell.bookquotes`
- Build ID: `2ebf7662-8840-4d6c-b5b6-dc42281e75db`
- Uploaded date: `2026-07-17T07:36:38-07:00`
- Processing state: `VALID`
- Encryption status: `usesNonExemptEncryption: false`

The internal `Test v1` group has `hasAccessToAllBuilds: true` and one tester, so Build 45 is
available without individual assignment. The focused session and purchase-restoration checks
passed, and Build 45 was submitted as the version 1.0 App Review binary on 2026-07-20.

## Build 44 Verification

Build 44 was uploaded on 2026-07-17 and verified through Apple's build API:

- App: `BookQuotes`
- App ID: `6758091579`
- Bundle ID: `com.acampbell.bookquotes`
- Build ID: `eea39a35-556e-4b3b-9546-323e03020a13`
- Uploaded date: `2026-07-17T06:52:00-07:00`
- Processing state: `VALID`
- Encryption status: `usesNonExemptEncryption: false`

The internal `Test v1` group has `hasAccessToAllBuilds: true` and one tester, so Build 44 is
available to that group without individual assignment. Build 44 retains the accepted Build 43
extraction and subscription behavior and fixes the misleading camera-permission flash for users
who already granted access.

## Build 43 Verification

Build 43 was uploaded on 2026-07-16 and verified through Apple's build API:

- App: `BookQuotes`
- App ID: `6758091579`
- Bundle ID: `com.acampbell.bookquotes`
- Build ID: `54d631bb-819e-4609-b68b-a29a830ac713`
- Uploaded date: `2026-07-16T09:06:55-07:00`
- Processing state: `VALID`
- Encryption status: `usesNonExemptEncryption: false`
- Audience: `APP_STORE_ELIGIBLE`

Alastair Campbell is in the internal `Test v1` beta group. That group has `hasAccessToAllBuilds: true`, so App Store Connect does not allow assigning individual builds to it manually.

Builds 40 through 42 remain release-stopped and must not be selected for App Review. Build 43 is
the replacement TestFlight candidate for camera framing, remote-AI, network-loss, explicit
on-device recovery, subscription, ISBN, queue, and account-deletion acceptance.

### Build 41 Subscription Availability Blocker

On 2026-07-16, StoreKit returned an empty product list in TestFlight. API and archive checks
confirmed the requested product IDs, UK/US availability, pricing, bundle ID, signing, and
In-App Purchase capability. The App Store Connect Business page showed the actual blocker:

- Paid Apps Agreement: `Pending User Info`
- Bank account: not added
- U.S. tax questionnaire: `Missing Tax Info`

The Account Holder must complete all three items. Apple TN3186 notes that sandbox/TestFlight
product changes and account updates can take up to one hour to propagate before retrying.

On 2026-07-16, both submitted US tax forms changed to `Active`. The bank account remains
`Processing`, with App Store Connect warning that banking updates may take up to 24 hours. The
Paid Apps Agreement remains `Pending User Info` until processing completes.

On 2026-07-17, the App Store Connect Business page confirmed that the Paid Apps Agreement, GBP
bank account, both submitted US tax forms, and Digital Services Act compliance all report
`Active`. The commerce-account blocker is resolved. StoreKit product loading, purchase, restore,
and entitlement reconciliation still require a fresh physical-device TestFlight acceptance run
after Apple's sandbox propagation completes.

Later on 2026-07-17, Build 43 successfully loaded the subscription products on the physical test
device and completed a trial signup. StoreKit localized the displayed price from USD to GBP for
the UK storefront. Product loading, storefront localization, and trial purchase are accepted.
The paid entitlement unlocked remote-AI extraction, and Apple's subscription-management flow was
also accepted on device. Delete Account completed successfully; signing back in worked and the
device's local books remained, matching the documented local-library behavior.

Production Worker version `ae5a598e-98e8-47c9-b48a-23d652aa697d` then removed the temporary
authenticated-TestFlight AI bypass. Build 44 does not need a new binary for this server-side
change. The subscribed tester subsequently completed another remote-AI extraction in Build 44,
accepting the real entitlement path with the bypass absent.

The Build 44 recovery pass accepted network-loss behavior: Airplane Mode produced an explicit
failure with an on-device option, and Retry AI succeeded after reconnection. StoreKit retained the
active subscription across a cold relaunch and AI worked after reauthentication. The same pass
found two app issues: the saved BookQuotes session was not restored at launch, and Restore
Purchases forced an unnecessary App Store account sync that ended with “Unable to complete
request” even though the entitlement was already visible.

Build 45 restores the saved account session at launch, preserves credentials across transient
launch-time failures, retries when the app foregrounds or reconnects, reconciles an existing
entitlement before requesting `AppStore.sync()`, and shows a clear restore-success confirmation.
It requires a focused TestFlight relaunch and Restore
Purchases acceptance before submission. Focused restoration verification passed 14 tests, and the
complete iPhone 17 unit target passed 656 tests with zero failures and one existing optional
local-photo fixture skip.

## Build 38 Verification

Build 38 was uploaded on 2026-07-12 and verified through the App Store Connect API:

- App: `BookQuotes`
- App ID: `6758091579`
- Bundle ID: `com.acampbell.bookquotes`
- Build ID: `b38a707f-19ec-404f-b9f7-68db7442e004`
- Uploaded date: `2026-07-12T06:48:13-07:00`
- Processing state: `VALID`
- Encryption status: `usesNonExemptEncryption: false`

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
2. Archive with `xcodebuild archive -allowProvisioningUpdates`.
3. Run a local distribution-export preflight with the tracked
   `scripts/ExportOptions-AppStore.plist`. It deliberately uses `destination = export`, so it
   verifies distribution signing without uploading anything.
4. Once all release gates are closed, copy that plist under ignored `artifacts/release/`, change
   its `destination` value to `upload`, then use `xcodebuild -exportArchive` for the deliberate
   TestFlight upload.
5. Use `scripts/appstoreconnect_status.js` to verify processing state, encryption status, and tester group visibility.
6. Record results in `docs/refactor-foundation/verification/`.

The local distribution preflight is:

```sh
mkdir -p artifacts/release

xcodebuild archive -project BookQuotes.xcodeproj -scheme BookQuotes \
  -configuration Release -destination 'generic/platform=iOS' \
  -archivePath artifacts/release/BookQuotes.xcarchive \
  -allowProvisioningUpdates

xcodebuild -exportArchive \
  -archivePath artifacts/release/BookQuotes.xcarchive \
  -exportPath artifacts/release/BookQuotes-app-store-export \
  -exportOptionsPlist scripts/ExportOptions-AppStore.plist \
  -allowProvisioningUpdates
```

This produces an IPA locally and does not contact App Store Connect for an upload. Do not change
the tracked plist to `destination = upload`; make that one-time change in an ignored copy only
after the TestFlight release decision.
