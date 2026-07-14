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
- [ ] Concurrent deletion/request race tests.
- [ ] Device end-to-end test against a deployed Worker.

## Implementation Notes

Every session JWT now carries a server-side session version. Account deletion increments the
stored version before deleting account records, invalidating all existing tokens. The version
record expires after eight days, longer than the maximum seven-day token lifetime, and a new Apple
sign-in receives a session at the current version.
