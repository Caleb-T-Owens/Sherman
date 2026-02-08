/**
 * Types shared between main and renderer processes.
 */

import type {
  LinearQueryOperation,
  LinearMutationOperation,
  LinearQueryResult,
} from './linear-types';

export interface UserInfo {
  id: string;
  name: string;
  email: string;
  displayName: string;
  avatarUrl: string | null;
}

export interface AuthState {
  activeUser: UserInfo | null;
  users: UserInfo[];
}

/**
 * API exposed to renderer via preload script.
 */
export interface ElectronAPI {
  // Auth operations
  login(): Promise<UserInfo>;
  logout(userId: string): Promise<void>;
  setActiveUser(userId: string): Promise<void>;
  getAuthState(): Promise<AuthState>;
  onAuthStateChanged(callback: (state: AuthState) => void): () => void;

  // Linear operations
  linearQuery<T>(params: {
    userIds?: string[];
    operation: LinearQueryOperation;
    args?: Record<string, unknown>;
  }): Promise<LinearQueryResult<T>[]>;

  linearMutation<T>(params: {
    userId: string;
    operation: LinearMutationOperation;
    args: Record<string, unknown>;
  }): Promise<T>;
}

declare global {
  interface Window {
    electron: ElectronAPI;
  }
}
