import { getAuthService } from '../auth/AuthService';
import type {
  LinearUser,
  LinearTeam,
  LinearIssue,
  LinearProject,
  LinearCycle,
  LinearWorkflowState,
  LinearLabel,
  LinearComment,
  LinearQueryResult,
  CreateIssueInput,
  UpdateIssueInput,
  CreateCommentInput,
} from '../../shared/linear-types';

const LINEAR_API_URL = 'https://api.linear.app/graphql';

// Shared GraphQL field selections to reduce duplication
const ISSUE_FIELDS = `
  id
  identifier
  title
  description
  priority
  createdAt
  updatedAt
  state { id name color }
  team { id name key }
  assignee { id name avatarUrl }
  labels { nodes { id name color } }
`;

const VIEWER_FIELDS = `
  id
  name
  displayName
  email
  avatarUrl
`;

interface GraphQLResponse<T> {
  data?: T;
  errors?: Array<{ message: string }>;
}

/**
 * Direct GraphQL client for Linear API.
 * Runs in main process, returns serializable data.
 */
export class LinearGraphQLService {
  /**
   * Execute a GraphQL query/mutation for a specific user.
   */
  private async execute<T>(
    userId: string,
    query: string,
    variables?: Record<string, unknown>
  ): Promise<T> {
    const authService = getAuthService();

    // Ensure token is fresh
    await authService.refreshTokensIfNeeded(userId);

    // Get the user's token
    const users = authService.getAllUsersWithTokens();
    const user = users.find((u) => u.id === userId);

    if (!user) {
      throw new Error(`User ${userId} not found`);
    }

    const response = await fetch(LINEAR_API_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: user.accessToken,
      },
      body: JSON.stringify({ query, variables }),
    });

    if (!response.ok) {
      throw new Error(`Linear API error: ${response.status} ${response.statusText}`);
    }

    const result = (await response.json()) as GraphQLResponse<T>;

    if (result.errors?.length) {
      throw new Error(result.errors.map((e) => e.message).join(', '));
    }

    if (!result.data) {
      throw new Error('No data returned from Linear API');
    }

    return result.data;
  }

  /**
   * Execute a query for all users, returning results keyed by userId.
   */
  async executeForAll<T>(
    query: string,
    variables?: Record<string, unknown>
  ): Promise<LinearQueryResult<T>[]> {
    const authService = getAuthService();
    const users = authService.getAllUsersWithTokens();

    const results = await Promise.all(
      users.map(async (user) => {
        try {
          const data = await this.execute<T>(user.id, query, variables);
          return { userId: user.id, data };
        } catch (error) {
          console.error(`Query failed for user ${user.id}:`, error);
          throw error;
        }
      })
    );

    return results;
  }

  /**
   * Execute a query for specific users.
   */
  async executeForUsers<T>(
    userIds: string[],
    query: string,
    variables?: Record<string, unknown>
  ): Promise<LinearQueryResult<T>[]> {
    const results = await Promise.all(
      userIds.map(async (userId) => {
        const data = await this.execute<T>(userId, query, variables);
        return { userId, data };
      })
    );

    return results;
  }

  // Query methods

  async getViewer(userId: string): Promise<LinearUser> {
    const query = `
      query Viewer {
        viewer { ${VIEWER_FIELDS} }
      }
    `;
    const result = await this.execute<{ viewer: LinearUser }>(userId, query);
    return result.viewer;
  }

  async getViewerAll(): Promise<LinearQueryResult<LinearUser>[]> {
    const query = `
      query Viewer {
        viewer { ${VIEWER_FIELDS} }
      }
    `;
    const results = await this.executeForAll<{ viewer: LinearUser }>(query);
    return results.map((r) => ({ userId: r.userId, data: r.data.viewer }));
  }

  async getIssues(
    userId: string,
    args?: { first?: number; filter?: Record<string, unknown> }
  ): Promise<LinearIssue[]> {
    const query = `
      query Issues($first: Int, $filter: IssueFilter) {
        issues(first: $first, filter: $filter) {
          nodes { ${ISSUE_FIELDS} }
        }
      }
    `;
    const result = await this.execute<{ issues: { nodes: RawIssue[] } }>(userId, query, {
      first: args?.first ?? 50,
      filter: args?.filter,
    });
    return result.issues.nodes.map(transformIssue);
  }

  async getIssuesAll(
    args?: { first?: number; filter?: Record<string, unknown> }
  ): Promise<LinearQueryResult<LinearIssue[]>[]> {
    const query = `
      query Issues($first: Int, $filter: IssueFilter) {
        issues(first: $first, filter: $filter) {
          nodes { ${ISSUE_FIELDS} }
        }
      }
    `;
    const results = await this.executeForAll<{ issues: { nodes: RawIssue[] } }>(query, {
      first: args?.first ?? 50,
      filter: args?.filter,
    });
    return results.map((r) => ({
      userId: r.userId,
      data: r.data.issues.nodes.map(transformIssue),
    }));
  }

  async getIssue(userId: string, id: string): Promise<LinearIssue> {
    const query = `
      query Issue($id: String!) {
        issue(id: $id) { ${ISSUE_FIELDS} }
      }
    `;
    const result = await this.execute<{ issue: RawIssue }>(userId, query, { id });
    return transformIssue(result.issue);
  }

  async getTeams(userId: string, args?: { first?: number }): Promise<LinearTeam[]> {
    const query = `
      query Teams($first: Int) {
        teams(first: $first) {
          nodes { id name key }
        }
      }
    `;
    const result = await this.execute<{ teams: { nodes: LinearTeam[] } }>(userId, query, {
      first: args?.first ?? 50,
    });
    return result.teams.nodes;
  }

  async getProjects(userId: string, args?: { first?: number }): Promise<LinearProject[]> {
    const query = `
      query Projects($first: Int) {
        projects(first: $first) {
          nodes { id name description state }
        }
      }
    `;
    const result = await this.execute<{ projects: { nodes: LinearProject[] } }>(userId, query, {
      first: args?.first ?? 50,
    });
    return result.projects.nodes;
  }

  async getCycles(
    userId: string,
    args?: { first?: number; filter?: Record<string, unknown> }
  ): Promise<LinearCycle[]> {
    const query = `
      query Cycles($first: Int, $filter: CycleFilter) {
        cycles(first: $first, filter: $filter) {
          nodes { id name number startsAt endsAt }
        }
      }
    `;
    const result = await this.execute<{ cycles: { nodes: LinearCycle[] } }>(userId, query, {
      first: args?.first ?? 50,
      filter: args?.filter,
    });
    return result.cycles.nodes;
  }

  async getWorkflowStates(
    userId: string,
    args?: { first?: number }
  ): Promise<LinearWorkflowState[]> {
    const query = `
      query WorkflowStates($first: Int) {
        workflowStates(first: $first) {
          nodes { id name color type }
        }
      }
    `;
    const result = await this.execute<{ workflowStates: { nodes: LinearWorkflowState[] } }>(
      userId,
      query,
      { first: args?.first ?? 100 }
    );
    return result.workflowStates.nodes;
  }

  async getIssueLabels(userId: string, args?: { first?: number }): Promise<LinearLabel[]> {
    const query = `
      query IssueLabels($first: Int) {
        issueLabels(first: $first) {
          nodes { id name color }
        }
      }
    `;
    const result = await this.execute<{ issueLabels: { nodes: LinearLabel[] } }>(
      userId,
      query,
      { first: args?.first ?? 100 }
    );
    return result.issueLabels.nodes;
  }

  async searchIssues(userId: string, searchQuery: string): Promise<LinearIssue[]> {
    const query = `
      query SearchIssues($query: String!) {
        searchIssues(query: $query) {
          nodes { ${ISSUE_FIELDS} }
        }
      }
    `;
    const result = await this.execute<{ searchIssues: { nodes: RawIssue[] } }>(userId, query, {
      query: searchQuery,
    });
    return result.searchIssues.nodes.map(transformIssue);
  }

  // Mutation methods

  async createIssue(userId: string, input: CreateIssueInput): Promise<LinearIssue> {
    const query = `
      mutation CreateIssue($input: IssueCreateInput!) {
        issueCreate(input: $input) {
          success
          issue { ${ISSUE_FIELDS} }
        }
      }
    `;
    const result = await this.execute<{
      issueCreate: { success: boolean; issue: RawIssue };
    }>(userId, query, { input });

    if (!result.issueCreate.success) {
      throw new Error('Failed to create issue');
    }

    return transformIssue(result.issueCreate.issue);
  }

  async updateIssue(
    userId: string,
    id: string,
    input: UpdateIssueInput
  ): Promise<LinearIssue> {
    const query = `
      mutation UpdateIssue($id: String!, $input: IssueUpdateInput!) {
        issueUpdate(id: $id, input: $input) {
          success
          issue { ${ISSUE_FIELDS} }
        }
      }
    `;
    const result = await this.execute<{
      issueUpdate: { success: boolean; issue: RawIssue };
    }>(userId, query, { id, input });

    if (!result.issueUpdate.success) {
      throw new Error('Failed to update issue');
    }

    return transformIssue(result.issueUpdate.issue);
  }

  async createComment(userId: string, input: CreateCommentInput): Promise<LinearComment> {
    const query = `
      mutation CreateComment($input: CommentCreateInput!) {
        commentCreate(input: $input) {
          success
          comment {
            id
            body
            createdAt
            user { id name avatarUrl }
          }
        }
      }
    `;
    const result = await this.execute<{
      commentCreate: { success: boolean; comment: LinearComment };
    }>(userId, query, { input });

    if (!result.commentCreate.success) {
      throw new Error('Failed to create comment');
    }

    return result.commentCreate.comment;
  }
}

// Raw types from GraphQL (before transformation)
interface RawIssue {
  id: string;
  identifier: string;
  title: string;
  description: string | null;
  priority: number;
  createdAt: string;
  updatedAt: string;
  state: { id: string; name: string; color: string };
  team: { id: string; name: string; key: string };
  assignee: { id: string; name: string; avatarUrl: string | null } | null;
  labels: { nodes: Array<{ id: string; name: string; color: string }> };
}

function transformIssue(raw: RawIssue): LinearIssue {
  return {
    id: raw.id,
    identifier: raw.identifier,
    title: raw.title,
    description: raw.description,
    priority: raw.priority,
    createdAt: raw.createdAt,
    updatedAt: raw.updatedAt,
    state: raw.state,
    team: raw.team,
    assignee: raw.assignee,
    labels: raw.labels.nodes,
  };
}

// Singleton instance
let serviceInstance: LinearGraphQLService | null = null;

export function getLinearGraphQLService(): LinearGraphQLService {
  if (!serviceInstance) {
    serviceInstance = new LinearGraphQLService();
  }
  return serviceInstance;
}
