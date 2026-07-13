# 089 - Website dependency and privacy readiness

Status: closed
Area: Website / App Store readiness
Priority: high

## Problem

The website now builds locally, but the dependency audit has production findings in the website stack. The website also carries App Store-facing privacy and account deletion copy, so it needs to remain buildable, accurate, and low-risk before submission.

## Acceptance Criteria

- [x] Website production dependency audit no longer reports known production vulnerabilities, or any unavoidable advisory is documented with an explicit mitigation.
- [x] Website build passes after dependency changes.
- [x] Privacy and account deletion copy still matches the app/backend behaviour: Hugging Face model-assisted extraction, Vision/on-device fallback, Gemini cover/fallback usage where applicable, and account deletion route.
- [x] Changes are limited to dependency/readiness work unless a copy mismatch is found.

## Characterization Plan

- Run the current website build and production audit before dependency edits.
- Upgrade the minimum necessary production dependencies.
- Re-run build and audit.

## Related Issues

- `086-capture-ship-readiness.md`

## Progress

2026-07-13:

- Upgraded website Next dependency to `16.2.10`.
- Moved the Google Fonts `@import` before Tailwind directives so Next 16/Turbopack production build succeeds.
- Confirmed website privacy copy still matches the current app/backend extraction and account deletion behaviour.
- `npm audit --omit=dev` still reports the Next-bundled `postcss <8.5.10` advisory. `npm audit fix --force` proposes downgrading to `next@9.3.3`, so the acceptable mitigation is to stay on the latest available Next and track the upstream advisory.
