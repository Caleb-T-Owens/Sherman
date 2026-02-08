import {
  createContext,
  useContext,
  useState,
  useEffect,
  useCallback,
  type ReactNode,
} from 'react';
import type { AuthState, UserInfo } from '../../shared/types';

interface AuthContextValue extends AuthState {
  isLoading: boolean;
  error: Error | null;
  login: () => Promise<void>;
  logout: (userId: string) => Promise<void>;
  switchUser: (userId: string) => Promise<void>;
}

const AuthContext = createContext<AuthContextValue | null>(null);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [authState, setAuthState] = useState<AuthState>({
    activeUser: null,
    users: [],
  });
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  // Load initial auth state
  useEffect(() => {
    window.electron
      .getAuthState()
      .then(setAuthState)
      .catch((err) => setError(err instanceof Error ? err : new Error(String(err))))
      .finally(() => setIsLoading(false));
  }, []);

  // Subscribe to auth state changes from main process
  useEffect(() => {
    const unsubscribe = window.electron.onAuthStateChanged(setAuthState);
    return unsubscribe;
  }, []);

  const login = useCallback(async () => {
    setIsLoading(true);
    setError(null);
    try {
      await window.electron.login();
      // State will be updated via onAuthStateChanged
    } catch (err) {
      setError(err instanceof Error ? err : new Error(String(err)));
      throw err;
    } finally {
      setIsLoading(false);
    }
  }, []);

  const logout = useCallback(async (userId: string) => {
    setIsLoading(true);
    setError(null);
    try {
      await window.electron.logout(userId);
      // State will be updated via onAuthStateChanged
    } catch (err) {
      setError(err instanceof Error ? err : new Error(String(err)));
      throw err;
    } finally {
      setIsLoading(false);
    }
  }, []);

  const switchUser = useCallback(async (userId: string) => {
    setIsLoading(true);
    setError(null);
    try {
      await window.electron.setActiveUser(userId);
      // State will be updated via onAuthStateChanged
    } catch (err) {
      setError(err instanceof Error ? err : new Error(String(err)));
      throw err;
    } finally {
      setIsLoading(false);
    }
  }, []);

  const value: AuthContextValue = {
    ...authState,
    isLoading,
    error,
    login,
    logout,
    switchUser,
  };

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuthContext(): AuthContextValue {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuthContext must be used within an AuthProvider');
  }
  return context;
}
