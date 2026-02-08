import { ipcMain } from 'electron';
import { getAuthService } from '../auth/AuthService';
import { getLinearGraphQLService } from '../linear/LinearGraphQLService';
import type {
  LinearQueryOperation,
  LinearMutationOperation,
  CreateIssueInput,
  UpdateIssueInput,
  CreateCommentInput,
} from '../../shared/linear-types';

export const IPC_CHANNELS = {
  // Auth operations
  LOGIN: 'auth:login',
  LOGOUT: 'auth:logout',
  SET_ACTIVE_USER: 'auth:set-active-user',
  GET_AUTH_STATE: 'auth:get-auth-state',
  STATE_CHANGED: 'auth:state-changed',

  // Linear operations
  LINEAR_QUERY: 'linear:query',
  LINEAR_MUTATION: 'linear:mutation',
} as const;

interface QueryRequest {
  userIds?: string[];
  operation: LinearQueryOperation;
  args?: Record<string, unknown>;
}

interface MutationRequest {
  userId: string;
  operation: LinearMutationOperation;
  args: Record<string, unknown>;
}

/**
 * Registers all IPC handlers for auth and Linear operations.
 */
export function registerIpcHandlers(): void {
  const authService = getAuthService();
  const linearService = getLinearGraphQLService();

  // Auth: Login
  ipcMain.handle(IPC_CHANNELS.LOGIN, async () => {
    return authService.login();
  });

  // Auth: Logout
  ipcMain.handle(IPC_CHANNELS.LOGOUT, async (_event, userId: string) => {
    return authService.logout(userId);
  });

  // Auth: Set active user
  ipcMain.handle(IPC_CHANNELS.SET_ACTIVE_USER, async (_event, userId: string) => {
    authService.setActiveUser(userId);
  });

  // Auth: Get current state
  ipcMain.handle(IPC_CHANNELS.GET_AUTH_STATE, async () => {
    return authService.getAuthState();
  });

  // Linear: Query
  ipcMain.handle(IPC_CHANNELS.LINEAR_QUERY, async (_event, request: QueryRequest) => {
    const { userIds, operation, args } = request;

    // Determine which users to query
    // Use explicit undefined check - an empty array [] means "query no users"
    const targetUserIds = userIds !== undefined
      ? userIds
      : authService.getAllUsers().map((u) => u.id);

    // Execute the appropriate operation
    switch (operation) {
      case 'viewer':
        if (targetUserIds.length === 1) {
          const data = await linearService.getViewer(targetUserIds[0]);
          return [{ userId: targetUserIds[0], data }];
        }
        return linearService.getViewerAll();

      case 'issues':
        if (targetUserIds.length === 1) {
          const data = await linearService.getIssues(targetUserIds[0], args as { first?: number; filter?: Record<string, unknown> });
          return [{ userId: targetUserIds[0], data }];
        }
        return linearService.getIssuesAll(args as { first?: number; filter?: Record<string, unknown> });

      case 'issue': {
        const id = args?.id as string;
        if (!id) throw new Error('Issue ID required');
        const data = await linearService.getIssue(targetUserIds[0], id);
        return [{ userId: targetUserIds[0], data }];
      }

      case 'teams': {
        const results = await Promise.all(
          targetUserIds.map(async (userId) => ({
            userId,
            data: await linearService.getTeams(userId, args as { first?: number }),
          }))
        );
        return results;
      }

      case 'projects': {
        const results = await Promise.all(
          targetUserIds.map(async (userId) => ({
            userId,
            data: await linearService.getProjects(userId, args as { first?: number }),
          }))
        );
        return results;
      }

      case 'cycles': {
        const results = await Promise.all(
          targetUserIds.map(async (userId) => ({
            userId,
            data: await linearService.getCycles(userId, args as { first?: number; filter?: Record<string, unknown> }),
          }))
        );
        return results;
      }

      case 'workflowStates': {
        const results = await Promise.all(
          targetUserIds.map(async (userId) => ({
            userId,
            data: await linearService.getWorkflowStates(userId, args as { first?: number }),
          }))
        );
        return results;
      }

      case 'issueLabels': {
        const results = await Promise.all(
          targetUserIds.map(async (userId) => ({
            userId,
            data: await linearService.getIssueLabels(userId, args as { first?: number }),
          }))
        );
        return results;
      }

      case 'searchIssues': {
        const query = args?.query as string;
        if (!query) throw new Error('Search query required');
        const results = await Promise.all(
          targetUserIds.map(async (userId) => ({
            userId,
            data: await linearService.searchIssues(userId, query),
          }))
        );
        return results;
      }

      default:
        throw new Error(`Unknown query operation: ${operation}`);
    }
  });

  // Linear: Mutation
  ipcMain.handle(IPC_CHANNELS.LINEAR_MUTATION, async (_event, request: MutationRequest) => {
    const { userId, operation, args } = request;

    switch (operation) {
      case 'createIssue':
        return linearService.createIssue(userId, args as CreateIssueInput);

      case 'updateIssue': {
        const { id, input } = args as { id: string; input: UpdateIssueInput };
        return linearService.updateIssue(userId, id, input);
      }

      case 'createComment':
        return linearService.createComment(userId, args as CreateCommentInput);

      default:
        throw new Error(`Unknown mutation operation: ${operation}`);
    }
  });
}
