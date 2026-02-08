export const OAUTH_CONFIG = {
  clientId: import.meta.env.VITE_LINEAR_CLIENT_ID || '',
  authUrl: 'https://linear.app/oauth/authorize',
  tokenUrl: 'https://api.linear.app/oauth/token',
  scopes: ['read', 'write', 'issues:create'],
  redirectUri: 'linear-client://callback',
} as const;

export const AUTH_STORAGE_FILENAME = 'auth-tokens.enc';
