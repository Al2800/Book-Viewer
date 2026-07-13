# 088 - Backend entitlement and account complexity refactor

Status: in_progress
Area: Backend / Subscription / Account deletion
Priority: high

## Problem

Backend complexity is explicitly in scope for the submission checkpoint. The largest production files are backend files:

- `backend/src/subscription.ts` is 984 LOC.
- `backend/src/index.ts` is 519 LOC.

These files own auth/session handling, entitlement checks, product metadata, App Store server notifications, account deletion, usage limits, and extraction gate policy. That is too much surface area in too few modules for a shipping-critical backend.

## Acceptance Criteria

- [x] Characterization tests pin the current subscription entitlement, beta/subscription extraction gate, usage, and account deletion behaviour before production edits.
- [x] Account deletion data removal is concentrated behind a small backend module interface.
- [ ] Entitlement/gate policy is separated from HTTP route orchestration where practical.
- [x] `backend/src/index.ts` moves below 500 LOC without creating pass-through modules.
- [x] `backend/src/subscription.ts` is reduced materially, or a documented follow-up explains why remaining size is cohesive.
- [x] Backend unit tests and typecheck pass after each slice.
- [x] Any remaining App Store compliance risk, such as stateless session validity after deletion, is documented explicitly.

## Characterization Plan

- Run backend tests before edits.
- Identify the public backend interface for account deletion and entitlement decisions.
- Add or extend tests through request-level helpers or exported backend functions rather than private implementation details.

## Related Issues

- `073-subscription-account-token-refactor.md`
- `077-subscription-sync-state-refactor.md`
- `078-subscription-product-id-refactor.md`
- `086-capture-ship-readiness.md`

## Progress

2026-07-13:

- Extracted Gemini request validation/proxy handling into `backend/src/gemini-proxy.ts`.
- Extracted subscription KV key schema into `backend/src/subscription-keys.ts`.
- Extracted account deletion cleanup into `backend/src/account-data.ts`.
- Added account deletion characterization for preserving ownership keys that belong to another user.
- Reduced `backend/src/index.ts` from 519 LOC to 355 LOC.
- Reduced `backend/src/subscription.ts` from 984 LOC to 929 LOC.
- Backend tests passed: 22 tests, 0 failures.
- Backend typecheck passed.

## Residual Risk

- `backend/src/subscription.ts` remains large because App Store verification, notification reconciliation, ownership, and client status mapping are still colocated. The next backend slice should separate entitlement/gate policy or App Store API verification if backend feature work resumes.
- Account deletion removes KV records but does not revoke already-issued stateless session JWTs before expiry.
