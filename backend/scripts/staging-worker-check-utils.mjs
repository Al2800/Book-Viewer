const CONFIRMATION_VALUE = 'true';
const TEST_IMAGE_DATA = 'dGVzdA==';

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
  return new URL(path, ensureTrailingSlash(baseURL));
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
