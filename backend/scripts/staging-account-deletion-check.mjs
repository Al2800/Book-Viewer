import { randomUUID } from 'node:crypto';
import {
  quoteExtractionBody,
  requireConfirmation,
  requireEnvironment,
  responseSummary,
  stagingURL,
} from './staging-worker-check-utils.mjs';

requireConfirmation('STAGING_CONFIRM_ACCOUNT_DELETE');

const baseURL = requireEnvironment('STAGING_BASE_URL');
const sessionToken = requireEnvironment('STAGING_SESSION_TOKEN');
const headers = { Authorization: `Bearer ${sessionToken}` };

const deletion = await fetch(stagingURL(baseURL, 'api/auth/account'), {
  method: 'DELETE',
  headers,
});

if (!deletion.ok) {
  throw new Error(`Account deletion returned HTTP ${deletion.status}`);
}

const checks = await Promise.all([
  fetch(stagingURL(baseURL, 'api/usage'), { headers }),
  fetch(stagingURL(baseURL, 'api/subscription/sync'), {
    method: 'POST',
    headers: { ...headers, 'Content-Type': 'application/json' },
    body: JSON.stringify({}),
  }),
  fetch(stagingURL(baseURL, 'api/extract-quotes-hf'), {
    method: 'POST',
    headers: {
      ...headers,
      'Content-Type': 'application/json',
      'Idempotency-Key': randomUUID(),
    },
    body: JSON.stringify(quoteExtractionBody()),
  }),
]);

const results = await Promise.all(checks.map(responseSummary));
const allRevoked = results.every(
  (result) => result.status === 401 && result.code === 'AUTH_SESSION_REVOKED'
);

console.log(JSON.stringify({
  check: 'staging_account_deletion_revocation',
  deletionStatus: deletion.status,
  protectedEndpointResults: results,
}));

if (!allRevoked) {
  throw new Error('Deleted session retained access to at least one protected endpoint');
}
