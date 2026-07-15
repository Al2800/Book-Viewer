import { randomUUID } from 'node:crypto';
import {
  quoteExtractionBody,
  requireConfirmation,
  requireEnvironment,
  responseSummary,
  stagingURL,
} from './staging-worker-check-utils.mjs';

const attempts = Number.parseInt(process.env.EXTRACTION_LOAD_ATTEMPTS ?? '31', 10);

if (!Number.isInteger(attempts) || attempts < 2 || attempts > 200) {
  throw new Error('EXTRACTION_LOAD_ATTEMPTS must be an integer between 2 and 200');
}

requireConfirmation('STAGING_CONFIRM_RATE_LIMIT_LOAD');

const baseURL = requireEnvironment('STAGING_BASE_URL');
const sessionToken = requireEnvironment('STAGING_SESSION_TOKEN');
const endpoint = stagingURL(baseURL, 'api/extract-quotes-hf');

const results = await Promise.all(
  Array.from({ length: attempts }, async () => {
    try {
      const response = await fetch(endpoint, {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${sessionToken}`,
          'Content-Type': 'application/json',
          'Idempotency-Key': randomUUID(),
        },
        body: JSON.stringify(quoteExtractionBody()),
      });
      return responseSummary(response);
    } catch {
      return { status: 0, code: 'NETWORK_ERROR' };
    }
  })
);

const summary = results.reduce((counts, result) => {
  const key = `${result.status}:${result.code ?? 'NO_CODE'}`;
  counts[key] = (counts[key] ?? 0) + 1;
  return counts;
}, {});
const rateLimitResponses = results.filter(
  (result) => result.status === 429 && result.code === 'RATE_LIMIT'
).length;

console.log(JSON.stringify({
  check: 'staging_extraction_rate_limit',
  attempts,
  rateLimitResponses,
  summary,
}));

if (rateLimitResponses === 0) {
  throw new Error('Expected at least one 429 RATE_LIMIT response from the staging Worker');
}
