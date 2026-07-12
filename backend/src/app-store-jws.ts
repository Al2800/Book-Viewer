import { X509Certificate } from 'node:crypto';
import * as jose from 'jose';

/**
 * Apple Root CA - G3 from Apple PKI.
 * https://www.apple.com/certificateauthority/AppleRootCA-G3.cer
 *
 * SHA-256 fingerprint:
 * 63:34:3A:BF:B8:9A:6A:03:EB:B5:7E:9B:3F:5F:A7:BE:7C:4F:5C:75:6F:30:17:B3:A8:C4:88:C3:65:3E:91:79
 */
const APPLE_ROOT_CA_G3_PEM = `-----BEGIN CERTIFICATE-----
MIICQzCCAcmgAwIBAgIILcX8iNLFS5UwCgYIKoZIzj0EAwMwZzEbMBkGA1UEAwwS
QXBwbGUgUm9vdCBDQSAtIEczMSYwJAYDVQQLDB1BcHBsZSBDZXJ0aWZpY2F0aW9u
IEF1dGhvcml0eTETMBEGA1UECgwKQXBwbGUgSW5jLjELMAkGA1UEBhMCVVMwHhcN
MTQwNDMwMTgxOTA2WhcNMzkwNDMwMTgxOTA2WjBnMRswGQYDVQQDDBJBcHBsZSBS
b290IENBIC0gRzMxJjAkBgNVBAsMHUFwcGxlIENlcnRpZmljYXRpb24gQXV0aG9y
aXR5MRMwEQYDVQQKDApBcHBsZSBJbmMuMQswCQYDVQQGEwJVUzB2MBAGByqGSM49
AgEGBSuBBAAiA2IABJjpLz1AcqTtkyJygRMc3RCV8cWjTnHcFBbZDuWmBSp3ZHtf
TjjTuxxEtX/1H7YyYl3J6YRbTzBPEVoA/VhYDKX1DyxNB0cTddqXl5dvMVztK517
IDvYuVTZXpmkOlEKMaNCMEAwHQYDVR0OBBYEFLuw3qFYM4iapIqZ3r6966/ayySr
MA8GA1UdEwEB/wQFMAMBAf8wDgYDVR0PAQH/BAQDAgEGMAoGCCqGSM49BAMDA2gA
MGUCMQCD6cHEFl4aXTQY2e3v9GwOAEZLuN+yRhHFD/3meoyhpmvOwgPUnPWTxnS4
at+qIxUCMG1mihDK1A3UT82NQz60imOlM27jbdoXt2QfyFMm+YhidDkLF1vLUagM
6BgD56KyKA==
-----END CERTIFICATE-----`;

const APPLE_ROOT_CA_G3 = new X509Certificate(APPLE_ROOT_CA_G3_PEM);

function derBase64ToPem(derBase64: string): string {
  const normalized = derBase64.replace(/\s+/g, '');
  const lines = normalized.match(/.{1,64}/g) ?? [normalized];
  return `-----BEGIN CERTIFICATE-----\n${lines.join('\n')}\n-----END CERTIFICATE-----`;
}

function assertTrustedAppleChain(certs: X509Certificate[]): void {
  if (certs.length < 2) {
    throw new Error('App Store JWS x5c chain is too short');
  }

  for (let index = 0; index < certs.length - 1; index += 1) {
    const subject = certs[index];
    const issuer = certs[index + 1];
    if (!subject.checkIssued(issuer) || !subject.verify(issuer.publicKey)) {
      throw new Error('App Store JWS certificate chain is invalid');
    }
  }

  const chainRoot = certs[certs.length - 1];
  if (chainRoot.fingerprint256 === APPLE_ROOT_CA_G3.fingerprint256) {
    if (!chainRoot.verify(chainRoot.publicKey)) {
      throw new Error('App Store JWS root certificate is not self-signed');
    }
    return;
  }

  if (!chainRoot.checkIssued(APPLE_ROOT_CA_G3) || !chainRoot.verify(APPLE_ROOT_CA_G3.publicKey)) {
    throw new Error('App Store JWS chain is not anchored to Apple Root CA - G3');
  }
}

/**
 * Verify an App Store Server API / Notifications V2 JWS and return its payload.
 * Validates the x5c chain against Apple Root CA - G3, then verifies the JWS signature.
 */
export async function verifyAndDecodeSignedPayload<T>(signedPayload: string): Promise<T> {
  if (!signedPayload || typeof signedPayload !== 'string') {
    throw new Error('App Store JWS payload is required');
  }

  const header = jose.decodeProtectedHeader(signedPayload);
  const x5c = header.x5c;
  if (!Array.isArray(x5c) || x5c.length === 0) {
    throw new Error('App Store JWS missing x5c certificate chain');
  }

  const alg = header.alg;
  if (!alg) {
    throw new Error('App Store JWS missing alg');
  }

  const certs = x5c.map((der) => new X509Certificate(derBase64ToPem(der)));
  assertTrustedAppleChain(certs);

  const leafPem = derBase64ToPem(x5c[0]);
  const key = await jose.importX509(leafPem, alg);
  const { payload } = await jose.compactVerify(signedPayload, key);
  return JSON.parse(new TextDecoder().decode(payload)) as T;
}
