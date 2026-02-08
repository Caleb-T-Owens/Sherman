import { useAuthContext } from './AuthContext';

/**
 * Convenience hook for auth operations and state.
 */
export function useAuth() {
  const {
    activeUser,
    users,
    isLoading,
    error,
    login,
    logout,
    switchUser,
  } = useAuthContext();

  return {
    // State
    isAuthenticated: activeUser !== null,
    activeUser,
    users,
    isLoading,
    error,

    // Actions
    login,
    logout: () => {
      if (activeUser) {
        return logout(activeUser.id);
      }
      return Promise.resolve();
    },
    logoutUser: logout,
    switchUser,

    // Multi-user helpers
    hasMultipleUsers: users.length > 1,
    canAddUser: true,
  };
}
