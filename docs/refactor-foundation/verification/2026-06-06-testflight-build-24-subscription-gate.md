# TestFlight Build 24 Subscription Gate Follow-Up

## Scope

Build 24 correctly surfaced the quote-extraction failure that was previously hidden behind `No Quotes Found`.

Observed TestFlight message:

```text
Extraction Failed
A subscription is required to continue
```

The user is signed in but cannot start a subscription/trial at this stage, so the current backend policy blocks validation of real Gemini quote extraction.

## Finding

The production worker checks `hasActiveSubscription(userId, env)` before routing to either `/api/extract-cover` or `/api/extract-quotes`.

For a signed-in user without a stored active subscription/trial record, the worker returns:

```text
402 SUBSCRIPTION_REQUIRED
```

That response happens before request validation, rate limiting, or Gemini proxying. Therefore build 24 has not yet proved whether real quote extraction is functioning; it has proved that the subscription gate is the current blocker.

## Backend Change

Added an explicit backend policy flag:

```text
ALLOW_AUTHENTICATED_EXTRACTION=true
```

When enabled, authenticated users without an active subscription can reach extraction endpoints. Existing per-user/monthly and per-network rate limits still apply before the worker calls Gemini.

Production deploy configuration now sets:

```toml
[env.production]
vars = { ENVIRONMENT = "production", ALLOW_AUTHENTICATED_EXTRACTION = "true" }
```

This is intended as a beta/TestFlight policy while subscription purchase is not available for the tester.

## Verification

Red test:

```bash
npm test -- --run src/extraction-access.test.ts
```

Initial result:

- Failed with `expected 402 to be 200`, matching the TestFlight screenshot.

Focused green test:

```bash
npm test -- --run src/extraction-access.test.ts
```

Result:

- Passed.
- Covers authenticated beta extraction when explicitly enabled.
- Covers default subscription enforcement when the flag is absent.

Full backend verification:

```bash
npm test -- --run
npm run typecheck
```

Result:

- Backend tests passed: `3` files, `11` tests.
- TypeScript check passed.

## Deployment Status

Attempted production deploy:

```bash
npm run deploy:production
```

Result:

- Blocked locally because Wrangler has no `CLOUDFLARE_API_TOKEN` in this non-interactive shell.
- No existing Cloudflare token reference was found in the checked environment or common local dotfiles.

The code is ready to deploy, but build 24 will continue showing the subscription-required failure until the Cloudflare Worker is deployed with the new production env var.
