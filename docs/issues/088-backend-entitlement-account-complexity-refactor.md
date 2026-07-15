# 088 - Backend entitlement and account complexity refactor

Status: closed
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
- [x] Entitlement/gate policy is separated from HTTP route orchestration where practical.
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

2026-07-15 extraction-access policy follow-up:

- Extracted the subscription-or-explicit-authenticated-beta extraction decision into
  `backend/src/extraction-access-policy.ts`. The module owns the complete allow/deny contract;
  `index.ts` only translates a denied decision into its existing HTTP response.
- Added direct policy tests for active subscription access, explicitly enabled authenticated beta
  access, and the unchanged subscription-required response. Existing request-level extraction
  tests continue to prove the Worker applies the policy before provider forwarding.
- Reduced `backend/src/index.ts` from 501 to 497 LOC without introducing a pass-through module.
  The full backend suite passed: 42 tests, 0 failures. TypeScript typecheck passed.

2026-07-15 closure verification:

- Re-ran the full backend test suite on the current branch: 42 tests passed, 0 failures.
  `npm run typecheck -- --pretty false` passed.
- Current source sizes remain `src/index.ts` 497 LOC, `src/subscription.ts` 929 LOC,
  `src/account-data.ts` 70 LOC, and `src/extraction-access-policy.ts` 46 LOC.
- Every acceptance criterion for this refactor is satisfied. Deployed-Worker deletion-race
  verification remains open under issue `099`; it is an operational release gate, not a missing
  refactor acceptance criterion here.

## Residual Risk

- `backend/src/subscription.ts` remains large because App Store verification, notification reconciliation, ownership, and client status mapping are still colocated. Extraction access policy is now separate; a future backend slice can isolate App Store API verification if feature work resumes.
- The previous stateless-session deletion risk is resolved by issue `099`: every JWT now carries
  a server-side session version, and account deletion increments that version before data cleanup.
  Concurrent deletion/request testing and deployed-Worker verification remain release gates in
  issue `099`.
