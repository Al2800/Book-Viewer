# 099 - Revoke all sessions when an account is deleted

Status: in_progress
Area: Authentication / Account Deletion / Backend
Priority: critical (release blocker 8)

## Problem

Account deletion removes KV records but does not invalidate existing seven-day JWTs. Any valid token can continue authenticating and receive refreshed tokens after deletion.

## Acceptance Criteria

- [x] Every authenticated request checks a server-side session/account version or revocation state.
- [x] Delete Account revokes all existing tokens before returning success.
- [x] Revoked tokens cannot refresh, sync subscriptions, or use extraction endpoints.
- [x] Re-authentication after deletion creates an intentionally new account/session state.
- [x] Revocation records have a documented retention and cleanup policy.

## Verification

- [x] Backend tests using a pre-deletion token after account deletion.
- [x] Concurrent deletion/request race tests.
- [ ] Device end-to-end test against a deployed Worker.

For staging deployment verification, use `npm run verify:staging-account-deletion` with a
disposable account and `STAGING_CONFIRM_ACCOUNT_DELETE=true`. The guarded check deletes the
account, then confirms its old session receives `401 AUTH_SESSION_REVOKED` from usage,
subscription sync, and quote extraction without exposing the token or image payload in output.
The staging URL helper rejects the production BookQuotes host, credential-bearing URLs, non-HTTP
URLs, and cross-origin endpoint paths before this destructive request is sent.

## Implementation Notes

Every session JWT now carries a server-side session version. Account deletion increments the
stored version before deleting account records, invalidating all existing tokens. The version
record expires after eight days, longer than the maximum seven-day token lifetime, and a new Apple
sign-in receives a session at the current version.

Request handling retains that validated version through the full request. The Worker rechecks it
immediately before subscription reconciliation and external extraction calls, then refreshes only
the original version. If deletion wins a race, the request is rejected, extraction reservations are
released, and no replacement session can become valid.

## Progress

2026-07-14:

- Added race tests that pause a pre-authorized extraction and subscription sync, delete the
  account, then prove neither provider forwarding nor entitlement reconciliation occurs.
- Added a refresh-token race test proving a session from the revoked revision remains invalid.
- Backend suite passed: 36 tests, 0 failures; TypeScript typecheck passed.

2026-07-15 staging-script safety follow-up:

- The destructive account-deletion verification helper now rejects the known production API host,
  credential-bearing URLs, non-HTTP URLs, and cross-origin endpoint paths before it can delete a
  disposable staging account.
- Shared staging-helper tests passed 5 tests, 0 failures. The complete backend suite passed 47
  tests, 0 failures, and TypeScript typecheck passed.
