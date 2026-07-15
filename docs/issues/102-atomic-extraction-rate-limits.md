# 102 - Make extraction usage and abuse limits atomic

Status: in_progress
Area: Backend / Abuse Prevention / Billing
Priority: high (release blocker 11)

## Problem

Monthly usage and per-minute limits use Cloudflare KV read-modify-write operations. Concurrent requests can observe the same value and overwrite each other, allowing limits and cost controls to be bypassed.

## Acceptance Criteria

- [x] Counters use an atomic coordinator such as a Durable Object or equivalent serialized service.
- [x] Per-user and per-IP limits are enforced before provider calls.
- [x] Successful usage is charged exactly once, including retry/idempotency handling.
- [x] Provider failures and client cancellations have an explicit charging policy.
- [x] Limit decisions are observable without logging prompts or images.

## Verification

- [x] Concurrent request tests proving limits cannot be exceeded.
- [x] Idempotency and retry tests.
- [ ] Load test against a staging deployment.

For staging load verification, use `npm run verify:staging-rate-limit` with a disposable account,
`STAGING_CONFIRM_RATE_LIMIT_LOAD=true`, and a staging Worker URL/session token. The guarded check
sends 31 concurrent quote requests by default and fails unless it observes at least one
`429 RATE_LIMIT` response. It reports aggregate status/code counts only, never the token or image.

## Implementation Notes

Named SQLite-backed Durable Objects coordinate the user and network counters separately,
while the user object owns monthly usage and idempotency state. A monthly slot is reserved
before a provider call, finalized once on a successful provider response, and released on
validation or provider failure. The short per-minute attempt slot is intentionally retained
after failure to prevent failed requests from bypassing abuse protection. Reservations expire
after five minutes if a Worker is interrupted; completed idempotency records expire after 24
hours. Existing KV monthly usage is read during the one-way migration, and account deletion
removes both legacy KV and Durable Object usage state.
