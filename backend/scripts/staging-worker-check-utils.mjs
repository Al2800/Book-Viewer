const CONFIRMATION_VALUE = 'true';
const TEST_IMAGE_DATA = 'dGVzdA==';
const PRODUCTION_HOSTS = new Set([
  'api.bookquotes.uk',
  'bookquotes.uk',
  'www.bookquotes.uk',
]);

export function requireEnvironment(name) {
  const value = process.env[name]?.trim();
  if (!value) {
    throw new Error(`${name} is required`);
  }
  return value;
}

export function requireConfirmation(name) {
  if (process.env[name] !== CONFIRMATION_VALUE) {
    throw new Error(`${name}=true is required before this destructive staging check can run`);
  }
}

export function stagingURL(baseURL, path) {
  const root = new URL(ensureTrailingSlash(baseURL));

  if (!['http:', 'https:'].includes(root.protocol)) {
    throw new Error('STAGING_BASE_URL must use http or https');
  }
  if (root.username || root.password) {
    throw new Error('STAGING_BASE_URL must not include credentials');
  }
  if (PRODUCTION_HOSTS.has(root.hostname.toLowerCase())) {
    throw new Error('STAGING_BASE_URL must not target the production BookQuotes API');
  }

  const endpoint = new URL(path, root);
  if (endpoint.origin !== root.origin) {
    throw new Error('Staging endpoint path must remain on STAGING_BASE_URL');
  }

  return endpoint;
}

export function quoteExtractionBody() {
  return {
    contents: [{
      parts: [
        { text: 'Extract the marked quote from this staging test image.' },
        { inlineData: { mimeType: 'image/jpeg', data: TEST_IMAGE_DATA } },
      ],
    }],
  };
}

export async function responseSummary(response) {
  let code;
  try {
    const body = await response.json();
    if (body && typeof body === 'object' && typeof body.code === 'string') {
      code = body.code;
    }
  } catch {
    // Provider responses are intentionally not logged by staging verification scripts.
  }

  return { status: response.status, code };
}

function ensureTrailingSlash(value) {
  return value.endsWith('/') ? value : `${value}/`;
}
