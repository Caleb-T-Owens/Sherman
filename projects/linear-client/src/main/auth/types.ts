export interface UserInfo {
  id: string;
  name: string;
  email: string;
  displayName: string;
  avatarUrl: string | null;
}

export interface StoredUser {
  accessToken: string;
  refreshToken: string;
  expiresAt: number; // Unix timestamp (ms)
  user: UserInfo;
  addedAt: number;
  lastUsedAt: number;
}

export interface TokenStore {
  version: 1;
  activeUserId: string | null;
  users: Record<string, StoredUser>;
}

export interface AuthState {
  activeUser: UserInfo | null;
  users: UserInfo[];
}

export interface OAuthTokenResponse {
  access_token: string;
  refresh_token: string;
  token_type: string;
  expires_in: number;
  scope: string;
}

export interface OAuthCallbackResult {
  code: string;
  state: string;
}
