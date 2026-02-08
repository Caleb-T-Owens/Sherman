import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import type { UseQueryOptions, UseMutationOptions } from '@tanstack/react-query';
import type {
  LinearUser,
  LinearIssue,
  LinearTeam,
  LinearProject,
  LinearCycle,
  LinearWorkflowState,
  LinearLabel,
  LinearComment,
  LinearQueryResult,
  LinearQueryOperation,
  CreateIssueInput,
  UpdateIssueInput,
  CreateCommentInput,
} from '../../shared/linear-types';

// Factory for single-user queries that return arrays
function createArrayQuery<T>(operation: LinearQueryOperation) {
  return (
    userId: string,
    args?: Record<string, unknown>,
    options?: Omit<UseQueryOptions<T[], Error>, 'queryKey' | 'queryFn'>
  ) =>
    useQuery({
      queryKey: ['linear', operation, userId, args?.first, args?.filter],
      queryFn: async () => {
        const results = await window.electron.linearQuery<T[]>({
          userIds: [userId],
          operation,
          args,
        });
        return results[0]?.data ?? [];
      },
      enabled: !!userId && options?.enabled !== false,
      ...options,
    });
}

// Factory for single-user queries that return a single item
function createSingleQuery<T>(operation: LinearQueryOperation) {
  return (
    userId: string,
    args?: Record<string, unknown>,
    options?: Omit<UseQueryOptions<T | undefined, Error>, 'queryKey' | 'queryFn'>
  ) =>
    useQuery({
      queryKey: ['linear', operation, userId, args?.id],
      queryFn: async () => {
        const results = await window.electron.linearQuery<T>({
          userIds: [userId],
          operation,
          args,
        });
        return results[0]?.data;
      },
      enabled: !!userId && options?.enabled !== false,
      ...options,
    });
}

/**
 * Query all users' viewer info.
 */
export function useViewerAll(
  options?: Omit<UseQueryOptions<LinearQueryResult<LinearUser>[], Error>, 'queryKey' | 'queryFn'>
) {
  return useQuery({
    queryKey: ['linear', 'viewer', 'all'],
    queryFn: () => window.electron.linearQuery<LinearUser>({ operation: 'viewer' }),
    ...options,
  });
}

/**
 * Query a specific user's viewer info.
 */
export function useViewer(
  userId: string,
  options?: Omit<UseQueryOptions<LinearUser | undefined, Error>, 'queryKey' | 'queryFn'>
) {
  return useQuery({
    queryKey: ['linear', 'viewer', userId],
    queryFn: async () => {
      const results = await window.electron.linearQuery<LinearUser>({
        userIds: [userId],
        operation: 'viewer',
      });
      return results[0]?.data;
    },
    enabled: !!userId && options?.enabled !== false,
    ...options,
  });
}

/**
 * Query issues from all users.
 */
export function useIssuesAll(
  args?: { first?: number; filter?: Record<string, unknown> },
  options?: Omit<UseQueryOptions<LinearQueryResult<LinearIssue[]>[], Error>, 'queryKey' | 'queryFn'>
) {
  return useQuery({
    queryKey: ['linear', 'issues', 'all', args?.first, args?.filter],
    queryFn: () => window.electron.linearQuery<LinearIssue[]>({ operation: 'issues', args }),
    ...options,
  });
}

// Single-user query hooks using factories
export const useIssues = createArrayQuery<LinearIssue>('issues');
export const useTeams = createArrayQuery<LinearTeam>('teams');
export const useProjects = createArrayQuery<LinearProject>('projects');
export const useCycles = createArrayQuery<LinearCycle>('cycles');
export const useWorkflowStates = createArrayQuery<LinearWorkflowState>('workflowStates');
export const useIssueLabels = createArrayQuery<LinearLabel>('issueLabels');

/**
 * Query a single issue by ID.
 */
export function useIssue(
  userId: string,
  id: string,
  options?: Omit<UseQueryOptions<LinearIssue | undefined, Error>, 'queryKey' | 'queryFn'>
) {
  return useQuery({
    queryKey: ['linear', 'issue', userId, id],
    queryFn: async () => {
      const results = await window.electron.linearQuery<LinearIssue>({
        userIds: [userId],
        operation: 'issue',
        args: { id },
      });
      return results[0]?.data;
    },
    enabled: !!userId && !!id && options?.enabled !== false,
    ...options,
  });
}

/**
 * Search issues for a specific user.
 */
export function useSearchIssues(
  userId: string,
  query: string,
  options?: Omit<UseQueryOptions<LinearIssue[], Error>, 'queryKey' | 'queryFn'>
) {
  return useQuery({
    queryKey: ['linear', 'searchIssues', userId, query],
    queryFn: async () => {
      const results = await window.electron.linearQuery<LinearIssue[]>({
        userIds: [userId],
        operation: 'searchIssues',
        args: { query },
      });
      return results[0]?.data ?? [];
    },
    enabled: !!userId && !!query && query.length > 0 && options?.enabled !== false,
    ...options,
  });
}

// Mutation hooks

/**
 * Create an issue for a specific user.
 */
export function useCreateIssue(
  userId: string,
  options?: Omit<UseMutationOptions<LinearIssue, Error, CreateIssueInput>, 'mutationFn'>
) {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (input: CreateIssueInput) =>
      window.electron.linearMutation<LinearIssue>({
        userId,
        operation: 'createIssue',
        args: input,
      }),
    onSuccess: (data, variables, context) => {
      queryClient.invalidateQueries({ queryKey: ['linear', 'issues', userId] });
      options?.onSuccess?.(data, variables, context);
    },
    ...options,
  });
}

/**
 * Update an issue for a specific user.
 */
export function useUpdateIssue(
  userId: string,
  options?: Omit<
    UseMutationOptions<LinearIssue, Error, { id: string; input: UpdateIssueInput }>,
    'mutationFn'
  >
) {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({ id, input }: { id: string; input: UpdateIssueInput }) =>
      window.electron.linearMutation<LinearIssue>({
        userId,
        operation: 'updateIssue',
        args: { id, input },
      }),
    onSuccess: (data, variables, context) => {
      queryClient.invalidateQueries({ queryKey: ['linear', 'issues', userId] });
      queryClient.invalidateQueries({ queryKey: ['linear', 'issue', userId, variables.id] });
      options?.onSuccess?.(data, variables, context);
    },
    ...options,
  });
}

/**
 * Create a comment for a specific user.
 */
export function useCreateComment(
  userId: string,
  options?: Omit<UseMutationOptions<LinearComment, Error, CreateCommentInput>, 'mutationFn'>
) {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (input: CreateCommentInput) =>
      window.electron.linearMutation<LinearComment>({
        userId,
        operation: 'createComment',
        args: input,
      }),
    onSuccess: (data, variables, context) => {
      queryClient.invalidateQueries({ queryKey: ['linear', 'issue', userId, variables.issueId] });
      options?.onSuccess?.(data, variables, context);
    },
    ...options,
  });
}
