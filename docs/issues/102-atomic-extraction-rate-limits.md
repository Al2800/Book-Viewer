# 102 - Make extraction usage and abuse limits atomic

Status: open
Area: Backend / Abuse Prevention / Billing
Priority: high (release blocker 11)

## Problem

Monthly usage and per-minute limits use Cloudflare KV read-modify-write operations. Concurrent requests can observe the same value and overwrite each other, allowing limits and cost controls to be bypassed.

## Acceptance Criteria

- [ ] Counters use an atomic coordinator such as a Durable Object or equivalent serialized service.
- [ ] Per-user and per-IP limits are enforced before provider calls.
- [ ] Successful usage is charged exactly once, including retry/idempotency handling.
- [ ] Provider failures and client cancellations have an explicit charging policy.
- [ ] Limit decisions are observable without logging prompts or images.

## Verification

- Concurrent request tests proving limits cannot be exceeded.
- Idempotency and retry tests.
- Load test against a staging deployment.

