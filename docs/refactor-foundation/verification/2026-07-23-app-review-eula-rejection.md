# App Review EULA Rejection - 2026-07-23

## Rejection

Apple returned BookQuotes version 1.0 and its three subscription-related items on 2026-07-23.
Submission `7a44e620-28b7-4ff2-b650-64d6a768d1d8` changed to `UNRESOLVED_ISSUES`; the app and both
subscriptions changed to `REJECTED`.

Apple's automated review message identified one issue: the app offers auto-renewable
subscriptions but the App Store description did not contain a functional Terms of Use link. The
subscription group, monthly subscription, and yearly subscription were returned only because the
associated app was rejected.

## Resolution

The App Store description now ends with the standard Apple EULA link requested by App Review:

`Terms of Use: https://www.apple.com/legal/internet-services/itunes/dev/stdeula/`

The app already exposes Terms of Service in Settings and subscription legal controls, and the
BookQuotes website already has a Terms of Service page. This is therefore a metadata-only
correction; Build 45 remains the valid review binary and does not need to be replaced.
