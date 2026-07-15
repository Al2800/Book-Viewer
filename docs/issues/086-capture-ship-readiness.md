# 086 - Capture ship readiness: queue unification and App Store blockers

Status: in_progress
Area: Capture / App Store
Priority: high

## Problem

After the foundation refactor, the next natural work was product/ship readiness:

1. Offline queue still used a legacy provider path instead of the shared `QuoteExtracting` seam.
2. Quote correction feedback was modeled but never recorded.
3. App Store blockers remained: missing Privacy Manifest, no account deletion, production subscription bypass flag, privacy copy drift.

## Changes

- `CaptureQueueItemProcessor` / `CaptureQueueManager` now use `ModelAssistedQuoteExtractor` (same as interactive review).
- `QuoteDetailEditDraft.apply` records `QuoteCorrection` rows for changed text, margin note, and page number.
- Added `BookQuotes/Resources/PrivacyInfo.xcprivacy` (UserDefaults CA92.1).
- Added `DELETE /api/auth/account` + Settings Delete Account flow.
- Production `ALLOW_AUTHENTICATED_EXTRACTION` removed from `wrangler.toml`.
- Website privacy page aligned with in-app Hugging Face / Vision disclosures, ISBN registration,
  and account deletion.

## Verification

- [x] Backend unit tests including account deletion KV cleanup
- [ ] Device TestFlight: queue processing with model-assisted path
- [ ] Device TestFlight: Delete Account end-to-end after Worker deploy
- [x] ASC App Privacy questionnaire publish (manual)
