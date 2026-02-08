import { app, safeStorage } from 'electron';
import fs from 'node:fs';
import path from 'node:path';
import { AUTH_STORAGE_FILENAME } from './config';
import type { TokenStore, StoredUser, UserInfo } from './types';

/**
 * Encrypted token storage using Electron's safeStorage API.
 * Uses OS-level encryption: Keychain (macOS), DPAPI (Windows), libsecret (Linux).
 */
export class TokenStorage {
  private filePath: string;
  private store: TokenStore;

  constructor() {
    this.filePath = path.join(app.getPath('userData'), AUTH_STORAGE_FILENAME);
    this.store = this.load();
  }

  private createEmptyStore(): TokenStore {
    return {
      version: 1,
      activeUserId: null,
      users: {},
    };
  }

  private load(): TokenStore {
    try {
      if (!fs.existsSync(this.filePath)) {
        return this.createEmptyStore();
      }

      if (!safeStorage.isEncryptionAvailable()) {
        console.warn('Encryption not available, cannot load tokens');
        return this.createEmptyStore();
      }

      const encrypted = fs.readFileSync(this.filePath);
      const decrypted = safeStorage.decryptString(encrypted);
      const parsed = JSON.parse(decrypted) as TokenStore;

      // Basic validation
      if (parsed.version !== 1) {
        console.warn('Unknown token store version, resetting');
        return this.createEmptyStore();
      }

      return parsed;
    } catch (error) {
      console.error('Failed to load token store:', error);
      // Delete corrupted file so we start fresh
      try {
        if (fs.existsSync(this.filePath)) {
          fs.unlinkSync(this.filePath);
          console.log('Deleted corrupted token store file');
        }
      } catch {
        // Ignore deletion errors
      }
      return this.createEmptyStore();
    }
  }

  private save(): void {
    try {
      if (!safeStorage.isEncryptionAvailable()) {
        console.error('Encryption not available, cannot save tokens');
        return;
      }

      const json = JSON.stringify(this.store);
      const encrypted = safeStorage.encryptString(json);

      // Atomic write: write to temp file, then rename
      const tempPath = `${this.filePath}.tmp`;
      fs.writeFileSync(tempPath, encrypted);
      fs.renameSync(tempPath, this.filePath);
    } catch (error) {
      console.error('Failed to save token store:', error);
    }
  }

  getActiveUserId(): string | null {
    return this.store.activeUserId;
  }

  setActiveUserId(userId: string | null): void {
    if (userId !== null && !this.store.users[userId]) {
      throw new Error(`User ${userId} not found`);
    }

    this.store.activeUserId = userId;

    if (userId && this.store.users[userId]) {
      this.store.users[userId].lastUsedAt = Date.now();
    }

    this.save();
  }

  getUser(userId: string): StoredUser | null {
    return this.store.users[userId] || null;
  }

  getActiveUser(): StoredUser | null {
    if (!this.store.activeUserId) return null;
    return this.getUser(this.store.activeUserId);
  }

  getAllUsers(): StoredUser[] {
    return Object.values(this.store.users);
  }

  getAllUserInfo(): UserInfo[] {
    return Object.values(this.store.users).map((u) => u.user);
  }

  addUser(user: StoredUser, setActive = true): void {
    this.store.users[user.user.id] = user;

    if (setActive) {
      this.store.activeUserId = user.user.id;
    }

    this.save();
  }

  updateTokens(
    userId: string,
    tokens: {
      accessToken: string;
      refreshToken: string;
      expiresAt: number;
    }
  ): void {
    const user = this.store.users[userId];
    if (!user) {
      throw new Error(`User ${userId} not found`);
    }

    user.accessToken = tokens.accessToken;
    user.refreshToken = tokens.refreshToken;
    user.expiresAt = tokens.expiresAt;
    user.lastUsedAt = Date.now();

    this.save();
  }

  removeUser(userId: string): void {
    delete this.store.users[userId];

    if (this.store.activeUserId === userId) {
      // Switch to another user if available, otherwise null
      const remainingUsers = Object.keys(this.store.users);
      this.store.activeUserId = remainingUsers[0] || null;
    }

    this.save();
  }

  clear(): void {
    this.store = this.createEmptyStore();
    this.save();
  }
}
