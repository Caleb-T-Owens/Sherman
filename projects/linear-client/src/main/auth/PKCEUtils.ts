import crypto from 'node:crypto';

/**
 * PKCE (Proof Key for Code Exchange) utilities for secure OAuth flows.
 * Required for desktop apps which cannot securely store client secrets.
 */

/**
 * Generates a cryptographically random code verifier (43-128 characters).
 * Uses base64url encoding per RFC 7636.
 */
export function generateCodeVerifier(): string {
  // 32 bytes = 43 base64url characters (minimum allowed)
  const buffer = crypto.randomBytes(32);
  return base64UrlEncode(buffer);
}

/**
 * Generates a code challenge from the verifier using SHA256.
 * The challenge is sent in the authorization request, while the
 * verifier is sent in the token exchange request.
 */
export function generateCodeChallenge(verifier: string): string {
  const hash = crypto.createHash('sha256').update(verifier).digest();
  return base64UrlEncode(hash);
}

/**
 * Generates a cryptographically random state parameter for CSRF protection.
 */
export function generateState(): string {
  return crypto.randomBytes(16).toString('hex');
}

/**
 * Base64url encoding per RFC 4648 (URL-safe, no padding).
 */
function base64UrlEncode(buffer: Buffer): string {
  return buffer
    .toString('base64')
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=+$/, '');
}
