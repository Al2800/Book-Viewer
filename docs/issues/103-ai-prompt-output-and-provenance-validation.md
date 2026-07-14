# 103 - Validate AI prompts, outputs, confidence, and provenance

Status: closed
Area: AI Extraction / Trust / UX
Priority: high (release blocker 12)

## Problem

Custom marking text is interpolated directly into prompts, decoded confidence and page values are not bounded, and the UI does not show whether a candidate came from model-assisted or on-device extraction. Remote failures silently fall back to local OCR.

## Acceptance Criteria

- [x] Custom marking fields have length limits and are encoded as untrusted data in prompts.
- [x] Empty/oversized quote text, invalid page numbers, and non-finite/out-of-range confidence are rejected or normalized.
- [x] Candidate count and response size are bounded.
- [x] Extraction source and fallback state are visible during review.
- [x] Provider/fallback errors use actionable, privacy-safe messaging.

## Verification

- Adversarial marking/prompt tests.
- Malformed and boundary-value model response tests.
- UI tests for remote, local fallback, and mixed-source review.

## Completed 2026-07-14

- Custom marking prompts now use bounded, normalized JSON reference data with an explicit instruction to treat it as untrusted data.
- Model responses have size and candidate limits; invalid quote text and page numbers are rejected, while finite confidence values are normalized to the supported range.
- Review displays each candidate's source and explains when an on-device fallback was used.
- Remote/provider details are no longer surfaced in reader-facing errors.
- Verified with `xcodebuild test -only-testing:BookQuotesTests` (602 tests, 1 skipped, 0 failures) and the remote-only, local-fallback, and mixed-source review UI tests (3 tests, 0 failures).
