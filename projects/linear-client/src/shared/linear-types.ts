/**
 * Serializable Linear data types for IPC transport.
 * These are plain objects with no methods or circular references.
 */

export interface LinearUser {
  id: string;
  name: string;
  displayName: string;
  email: string;
  avatarUrl: string | null;
}

export interface LinearTeam {
  id: string;
  name: string;
  key: string;
}

export interface LinearWorkflowState {
  id: string;
  name: string;
  color: string;
  type: string;
}

export interface LinearLabel {
  id: string;
  name: string;
  color: string;
}

export interface LinearIssue {
  id: string;
  identifier: string;
  title: string;
  description: string | null;
  priority: number;
  state: { id: string; name: string; color: string };
  team: { id: string; name: string; key: string };
  assignee: { id: string; name: string; avatarUrl: string | null } | null;
  labels: LinearLabel[];
  createdAt: string;
  updatedAt: string;
}

export interface LinearProject {
  id: string;
  name: string;
  description: string | null;
  state: string;
}

export interface LinearCycle {
  id: string;
  name: string | null;
  number: number;
  startsAt: string;
  endsAt: string;
}

export interface LinearComment {
  id: string;
  body: string;
  createdAt: string;
  user: { id: string; name: string; avatarUrl: string | null } | null;
}

// Query result wrapper for multi-user queries
export interface LinearQueryResult<T> {
  userId: string;
  data: T;
}

// Input types for mutations
export interface CreateIssueInput {
  title: string;
  teamId: string;
  description?: string;
  priority?: number;
  assigneeId?: string;
  stateId?: string;
  labelIds?: string[];
  projectId?: string;
  cycleId?: string;
}

export interface UpdateIssueInput {
  title?: string;
  description?: string;
  priority?: number;
  assigneeId?: string | null;
  stateId?: string;
  labelIds?: string[];
  projectId?: string | null;
  cycleId?: string | null;
}

export interface CreateCommentInput {
  issueId: string;
  body: string;
}

// Query operation types
export type LinearQueryOperation =
  | 'viewer'
  | 'issues'
  | 'issue'
  | 'teams'
  | 'projects'
  | 'cycles'
  | 'workflowStates'
  | 'issueLabels'
  | 'searchIssues';

export type LinearMutationOperation =
  | 'createIssue'
  | 'updateIssue'
  | 'createComment';

// IPC request/response types
export interface LinearQueryRequest {
  userIds?: string[]; // undefined = all users
  operation: LinearQueryOperation;
  args?: Record<string, unknown>;
}

export interface LinearMutationRequest {
  userId: string;
  operation: LinearMutationOperation;
  args: Record<string, unknown>;
}
