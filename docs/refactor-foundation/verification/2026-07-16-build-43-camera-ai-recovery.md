# Build 43 Camera and AI Recovery

## Scope

Build 43 addresses the real-device issues reported against Build 42:

- The camera now freezes and displays the exact still returned by iOS before quality analysis.
- Capture controls remain unavailable while focus and lighting checks are running.
- Image-quality review uses the standard thresholds and labels an override as `Use Anyway`.
- Remote AI no longer silently falls back to on-device extraction.
- Remote failures expose `Retry AI Extraction` and `Use On-Device Instead` as separate choices.
- A valid remote response with zero quotes completes as `No Quotes Found`.
- Production AI routing is pinned to the supported Featherless AI provider for
  `Qwen/Qwen2.5-VL-72B-Instruct`.
- Provider errors are normalized into bounded, user-safe responses without logging page content.

## Production Service Verification

- The Cloudflare Worker backend suite passed: 50 tests across 11 files.
- Backend TypeScript checking passed.
- A non-user-data probe against the pinned provider returned HTTP 200 with valid JSON.
- Production Worker version `8ec979f7-d85a-44fb-a37a-8a36ffec3b86` is deployed.
- The temporary signed-in TestFlight AI-access window remains limited to its documented expiry.

## App Verification

- Complete `BookQuotesTests`: 651 passed, 1 fixture-dependent test skipped, 0 failed.
- Focused camera, extraction, recovery, and model-assisted tests: 62 passed, 1 fixture-dependent
  test skipped, 0 failed.
- `QuoteCaptureFlowTests`: 16 passed, 0 failed on the iPhone 17 Pro iOS 26.5 simulator.
- Website privacy-page production build passed.
- `git diff --check` passed.

## Device Acceptance Check

After Build 43 finishes TestFlight processing, verify on the connected iPhone that:

1. Pressing the shutter immediately transitions to the captured still and clearly shows the
   focus-and-lighting check.
2. A visibly blurred page is rejected or clearly requires `Use Anyway`.
3. The same marked page used for Build 42 produces a `Model-assisted` result with no OCR fragments.
4. With networking disabled, extraction fails explicitly and does not silently display an
   `On-device` result.
5. `Retry AI Extraction` succeeds after connectivity returns, and `Use On-Device Instead` only
   runs when deliberately selected.

## TestFlight Delivery

- Source commit: `ff352fd` on `main`.
- Signed archive: version `1.0`, build `43`, arm64.
- Local App Store distribution export: passed.
- TestFlight upload: succeeded on 2026-07-16.
- App Store Connect build ID: `54d631bb-819e-4609-b68b-a29a830ac713`.
- Processing state: `VALID`.
- Encryption declaration: `usesNonExemptEncryption: false`.
- Internal group: `Test v1`, with access to all builds and one tester.
