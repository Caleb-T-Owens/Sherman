import { shell, BrowserWindow } from 'electron';
import { LinearClient } from '@linear/sdk';
import { EventEmitter } from 'node:events';
import { OAUTH_CONFIG } from './config';
import { TokenStorage } from './TokenStorage';
import {
  generateCodeVerifier,
  generateCodeChallenge,
  generateState,
} from './PKCEUtils';
import type {
  AuthState,
  UserInfo,
  StoredUser,
  OAuthTokenResponse,
} from './types';

const TOKEN_REFRESH_BUFFER_MS = 5 * 60 * 1000; // Refresh 5 minutes before expiry
const LOGIN_TIMEOUT_MS = 10 * 60 * 1000; // 10 minute timeout for login

interface PendingLogin {
  codeVerifier: string;
  state: string;
  resolve: (user: UserInfo) => void;
  reject: (error: Error) => void;
  timeoutId: NodeJS.Timeout;
}

export interface UserWithToken extends UserInfo {
  accessToken: string;
}

/**
 * Core authentication service orchestrating OAuth flow and token management.
 * Linear SDK is used in renderer process, not here.
 */
export class AuthService extends EventEmitter {
  private tokenStorage: TokenStorage;
  private mainWindow: BrowserWindow | null = null;
  private pendingLogin: PendingLogin | null = null;
  private refreshPromises = new Map<string, Promise<void>>();

  constructor() {
    super();
    this.tokenStorage = new TokenStorage();
  }

  setMainWindow(window: BrowserWindow): void {
    this.mainWindow = window;
  }

  getAuthState(): AuthState {
    const activeUser = this.tokenStorage.getActiveUser();
    return {
      activeUser: activeUser?.user || null,
      users: this.tokenStorage.getAllUserInfo(),
    };
  }

  private emitStateChanged(): void {
    this.emit('auth-state-changed', this.getAuthState());
    if (this.mainWindow && !this.mainWindow.isDestroyed()) {
      this.mainWindow.webContents.send('auth:state-changed', this.getAuthState());
    }
  }

  /**
   * Get all users with their access tokens for renderer-side SDK usage.
   */
  getAllUsersWithTokens(): UserWithToken[] {
    const users = this.tokenStorage.getAllUsers();
    return users.map((u) => ({
      ...u.user,
      accessToken: u.accessToken,
    }));
  }

  /**
   * Initiates the OAuth login flow.
   * Opens browser for authorization, returns promise that resolves when callback arrives.
   */
  async login(): Promise<UserInfo> {
    if (!OAUTH_CONFIG.clientId) {
      throw new Error(
        'LINEAR_CLIENT_ID not configured. Set the environment variable.'
      );
    }

    // Generate PKCE parameters
    const codeVerifier = generateCodeVerifier();
    const codeChallenge = generateCodeChallenge(codeVerifier);
    const state = generateState();

    // Build authorization URL
    const authParams = new URLSearchParams({
      client_id: OAUTH_CONFIG.clientId,
      redirect_uri: OAUTH_CONFIG.redirectUri,
      response_type: 'code',
      scope: OAUTH_CONFIG.scopes.join(','),
      state,
      code_challenge: codeChallenge,
      code_challenge_method: 'S256',
    });

    const authUrl = `${OAUTH_CONFIG.authUrl}?${authParams}`;

    // Create promise that will be resolved by handleOAuthCallback
    return new Promise<UserInfo>((resolve, reject) => {
      const timeoutId = setTimeout(() => {
        this.pendingLogin = null;
        reject(new Error('Login timed out - no response received'));
      }, LOGIN_TIMEOUT_MS);

      this.pendingLogin = { codeVerifier, state, resolve, reject, timeoutId };

      // Open browser for user authorization
      shell.openExternal(authUrl).catch((err) => {
        clearTimeout(timeoutId);
        this.pendingLogin = null;
        reject(err);
      });
    });
  }

  /**
   * Handles the OAuth callback from the custom protocol.
   * Called when the app receives a linear-client:// URL.
   */
  async handleOAuthCallback(callbackUrl: string): Promise<void> {
    if (!this.pendingLogin) {
      console.warn('Received OAuth callback but no login is pending');
      return;
    }

    const { codeVerifier, state: expectedState, resolve, reject, timeoutId } = this.pendingLogin;
    clearTimeout(timeoutId);
    this.pendingLogin = null;

    try {
      const url = new URL(callbackUrl);
      const code = url.searchParams.get('code');
      const state = url.searchParams.get('state');
      const error = url.searchParams.get('error');
      const errorDescription = url.searchParams.get('error_description');

      if (error) {
        throw new Error(errorDescription || error);
      }

      if (!code) {
        throw new Error('Missing authorization code');
      }

      if (state !== expectedState) {
        throw new Error('Invalid state parameter (possible CSRF attack)');
      }

      // Exchange code for tokens
      const tokens = await this.exchangeCodeForTokens(code, codeVerifier);

      // Create temporary client to fetch user info
      const tempClient = new LinearClient({ accessToken: tokens.access_token });
      const viewer = await tempClient.viewer;

      const userInfo: UserInfo = {
        id: viewer.id,
        name: viewer.name,
        email: viewer.email,
        displayName: viewer.displayName,
        avatarUrl: viewer.avatarUrl || null,
      };

      // Store user and tokens
      const storedUser: StoredUser = {
        accessToken: tokens.access_token,
        refreshToken: tokens.refresh_token,
        expiresAt: Date.now() + tokens.expires_in * 1000,
        user: userInfo,
        addedAt: Date.now(),
        lastUsedAt: Date.now(),
      };

      this.tokenStorage.addUser(storedUser, true);

      this.emitStateChanged();

      // Focus the app window
      if (this.mainWindow && !this.mainWindow.isDestroyed()) {
        if (this.mainWindow.isMinimized()) {
          this.mainWindow.restore();
        }
        this.mainWindow.focus();
      }

      resolve(userInfo);
    } catch (err) {
      reject(err instanceof Error ? err : new Error(String(err)));
    }
  }

  private async exchangeCodeForTokens(
    code: string,
    codeVerifier: string
  ): Promise<OAuthTokenResponse> {
    const response = await fetch(OAUTH_CONFIG.tokenUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: new URLSearchParams({
        grant_type: 'authorization_code',
        code,
        redirect_uri: OAUTH_CONFIG.redirectUri,
        client_id: OAUTH_CONFIG.clientId,
        code_verifier: codeVerifier,
      }),
    });

    if (!response.ok) {
      const error = await response.text();
      throw new Error(`Token exchange failed: ${error}`);
    }

    return response.json() as Promise<OAuthTokenResponse>;
  }

  async logout(userId: string): Promise<void> {
    this.tokenStorage.removeUser(userId);
    this.emitStateChanged();
  }

  setActiveUser(userId: string): void {
    this.tokenStorage.setActiveUserId(userId);
    this.emitStateChanged();
  }

  getActiveUser(): UserInfo | null {
    return this.tokenStorage.getActiveUser()?.user || null;
  }

  getAllUsers(): UserInfo[] {
    return this.tokenStorage.getAllUserInfo();
  }

  /**
   * Refreshes tokens for a user if needed.
   * Uses locking to prevent concurrent refreshes for the same user.
   */
  async refreshTokensIfNeeded(userId: string): Promise<void> {
    const user = this.tokenStorage.getUser(userId);
    if (!user) {
      throw new Error(`User ${userId} not found`);
    }

    // Check if token needs refresh
    if (user.expiresAt > Date.now() + TOKEN_REFRESH_BUFFER_MS) {
      return; // Token still valid
    }

    // If a refresh is already in progress for this user, wait for it
    const existingRefresh = this.refreshPromises.get(userId);
    if (existingRefresh) {
      return existingRefresh;
    }

    // Start refresh and track the promise
    const refreshPromise = this.refreshTokens(userId).finally(() => {
      this.refreshPromises.delete(userId);
    });
    this.refreshPromises.set(userId, refreshPromise);

    return refreshPromise;
  }

  private async refreshTokens(userId: string): Promise<void> {
    const user = this.tokenStorage.getUser(userId);
    if (!user) {
      throw new Error(`User ${userId} not found`);
    }

    const response = await fetch(OAUTH_CONFIG.tokenUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: new URLSearchParams({
        grant_type: 'refresh_token',
        refresh_token: user.refreshToken,
        client_id: OAUTH_CONFIG.clientId,
      }),
    });

    if (!response.ok) {
      const error = await response.text();
      // If refresh fails, remove the user (token is invalid)
      console.error(`Token refresh failed for user ${userId}:`, error);
      await this.logout(userId);
      throw new Error(`Token refresh failed: ${error}`);
    }

    const tokens = (await response.json()) as OAuthTokenResponse;

    this.tokenStorage.updateTokens(userId, {
      accessToken: tokens.access_token,
      refreshToken: tokens.refresh_token,
      expiresAt: Date.now() + tokens.expires_in * 1000,
    });

    // Emit state change so renderer can get updated tokens
    this.emitStateChanged();
  }
}

// Singleton instance
let authServiceInstance: AuthService | null = null;

export function getAuthService(): AuthService {
  if (!authServiceInstance) {
    authServiceInstance = new AuthService();
  }
  return authServiceInstance;
}
