# 103 - Validate AI prompts, outputs, confidence, and provenance

Status: open
Area: AI Extraction / Trust / UX
Priority: high (release blocker 12)

## Problem

Custom marking text is interpolated directly into prompts, decoded confidence and page values are not bounded, and the UI does not show whether a candidate came from model-assisted or on-device extraction. Remote failures silently fall back to local OCR.

## Acceptance Criteria

- [ ] Custom marking fields have length limits and are encoded as untrusted data in prompts.
- [ ] Empty/oversized quote text, invalid page numbers, and non-finite/out-of-range confidence are rejected or normalized.
- [ ] Candidate count and response size are bounded.
- [ ] Extraction source and fallback state are visible during review.
- [ ] Provider/fallback errors use actionable, privacy-safe messaging.

## Verification

- Adversarial marking/prompt tests.
- Malformed and boundary-value model response tests.
- UI tests for remote, local fallback, and mixed-source review.

