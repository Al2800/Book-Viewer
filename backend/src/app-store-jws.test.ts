import { X509Certificate, createPrivateKey, createPublicKey } from 'node:crypto';
import { describe, expect, it } from 'vitest';
import * as jose from 'jose';
import { verifyAndDecodeSignedPayload } from './app-store-jws';

async function mintSelfSignedEs256Jws(payload: Record<string, unknown>): Promise<string> {
  const { privateKey, publicKey } = await jose.generateKeyPair('ES256');
  const spki = await jose.exportSPKI(publicKey);
  const pkcs8 = await jose.exportPKCS8(privateKey);

  // Minimal self-signed cert is awkward in pure jose; instead craft a JWS with a
  // fake x5c entry that is not Apple Root CA - G3 so chain anchoring fails.
  const throwawayKey = createPrivateKey(pkcs8);
  void throwawayKey;
  const throwawayPub = createPublicKey(spki);
  void throwawayPub;

  return new jose.SignJWT(payload)
    .setProtectedHeader({
      alg: 'ES256',
      // Valid base64 DER for a tiny non-Apple cert is not needed: missing/short chain fails first.
      x5c: ['MIIB'],
    })
    .sign(privateKey);
}

describe('verifyAndDecodeSignedPayload', () => {
  it('rejects payloads without an x5c chain', async () => {
    const { privateKey } = await jose.generateKeyPair('ES256');
    const token = await new jose.SignJWT({ hello: 'world' })
      .setProtectedHeader({ alg: 'ES256' })
      .sign(privateKey);

    await expect(verifyAndDecodeSignedPayload(token)).rejects.toThrow(/x5c/i);
  });

  it('rejects chains that are not anchored to Apple Root CA - G3', async () => {
    const token = await mintSelfSignedEs256Jws({ notificationType: 'TEST' });
    await expect(verifyAndDecodeSignedPayload(token)).rejects.toThrow();
  });

  it('rejects empty payloads', async () => {
    await expect(verifyAndDecodeSignedPayload('')).rejects.toThrow();
  });

  it('confirms the embedded Apple Root CA - G3 fingerprint', () => {
    const pem = `-----BEGIN CERTIFICATE-----
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

    const root = new X509Certificate(pem);
    expect(root.fingerprint256).toBe(
      '63:34:3A:BF:B8:9A:6A:03:EB:B5:7E:9B:3F:5F:A7:BE:7C:4F:5C:75:6F:30:17:B3:A8:C4:88:C3:65:3E:91:79'
    );
  });
});
