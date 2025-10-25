import { test, expect, beforeEach, afterEach } from "bun:test";
import { mkdtemp, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { GitRepo } from "./git";

let tempDir: string;

beforeEach(async () => {
  // Create a temporary directory for this test
  tempDir = await mkdtemp(join(tmpdir(), "tiny-butler-test-"));
});

afterEach(async () => {
  // Clean up the temporary directory
  await rm(tempDir, { recursive: true, force: true });
});

async function gitExec(repoPath: string, args: string[]): Promise<string> {
  const proc = Bun.spawn(["git", "-C", repoPath, ...args], {
    stdout: "pipe",
    stderr: "pipe",
  });
  const result = await new Response(proc.stdout).text();
  await proc.exited;
  return result.trim();
}

async function initRepo(repoPath: string): Promise<void> {
  await gitExec(repoPath, ["init"]);
  await gitExec(repoPath, ["config", "user.name", "Test User"]);
  await gitExec(repoPath, ["config", "user.email", "test@example.com"]);
}

async function createFile(
  repoPath: string,
  filename: string,
  content: string,
): Promise<void> {
  await Bun.write(join(repoPath, filename), content);
}

async function commitAll(repoPath: string, message: string): Promise<string> {
  await gitExec(repoPath, ["add", "."]);
  await gitExec(repoPath, ["commit", "-m", message]);
  return await gitExec(repoPath, ["rev-parse", "HEAD"]);
}

test("GitRepo can read a commit with exact values", async () => {
  await initRepo(tempDir);

  // Create a file and commit it
  await createFile(tempDir, "test.txt", "hello world\n");
  const commitSha = await commitAll(tempDir, "Initial commit");

  const repo = new GitRepo(tempDir);
  const commit = await repo.findCommit({
    type: "commit",
    value: commitSha,
  });

  // Verify exact commit properties
  expect(commit.type).toBe("commit");
  expect(commit.id.value).toBe(commitSha);
  expect(commit.id.type).toBe("commit");
  expect(commit.message).toBe("Initial commit\n");
  expect(commit.parents).toEqual([]);
  expect(commit.tree.type).toBe("tree");
  expect(commit.tree.value).toMatch(/^[0-9a-f]{40}$/);
  expect(commit.author.name).toBe("Test User");
  expect(commit.author.email).toBe("test@example.com");
  expect(commit.author.timestamp).toBeGreaterThan(0);
  expect(commit.committer.name).toBe("Test User");
  expect(commit.committer.email).toBe("test@example.com");
  expect(commit.committer.timestamp).toBeGreaterThan(0);
});

test("GitRepo can read a commit with multiple parents", async () => {
  await initRepo(tempDir);

  // Create initial commit
  await createFile(tempDir, "file1.txt", "content1\n");
  const commit1 = await commitAll(tempDir, "First commit");

  // Create a branch and commit there
  await gitExec(tempDir, ["checkout", "-b", "branch1"]);
  await createFile(tempDir, "file2.txt", "content2\n");
  await commitAll(tempDir, "Second commit");

  // Go back to main and make another commit
  await gitExec(tempDir, ["checkout", "master"]);
  await createFile(tempDir, "file3.txt", "content3\n");
  await commitAll(tempDir, "Third commit");

  // Merge branch1 to create a merge commit
  await gitExec(tempDir, ["merge", "branch1", "-m", "Merge branch1"]);
  const mergeSha = await gitExec(tempDir, ["rev-parse", "HEAD"]);

  const repo = new GitRepo(tempDir);
  const mergeCommit = await repo.findCommit({
    type: "commit",
    value: mergeSha,
  });

  // Verify merge commit has 2 parents
  expect(mergeCommit.parents.length).toBe(2);
  expect(mergeCommit.parents[0]?.type).toBe("commit");
  expect(mergeCommit.parents[0]?.value).toMatch(/^[0-9a-f]{40}$/);
  expect(mergeCommit.parents[1]?.type).toBe("commit");
  expect(mergeCommit.parents[1]?.value).toMatch(/^[0-9a-f]{40}$/);
  expect(mergeCommit.message).toBe("Merge branch1\n");
});

test("GitRepo can read a tree with exact entries", async () => {
  await initRepo(tempDir);

  // Create multiple files with known content
  await createFile(tempDir, "file1.txt", "content1\n");
  await createFile(tempDir, "file2.txt", "content2\n");
  await createFile(tempDir, "README.md", "# Test\n");
  const commitSha = await commitAll(tempDir, "Add files");

  const repo = new GitRepo(tempDir);
  const commit = await repo.findCommit({
    type: "commit",
    value: commitSha,
  });
  const tree = await repo.findTree(commit.tree);

  // Verify tree structure
  expect(tree.type).toBe("tree");
  expect(tree.id.value).toBe(commit.tree.value);
  expect(tree.entries.length).toBe(3);

  // Sort entries by name for predictable testing
  const sortedEntries = tree.entries.sort((a, b) =>
    a.name.localeCompare(b.name),
  );

  // Verify all entries have correct structure
  const readme = sortedEntries.find((e) => e.name === "README.md");
  expect(readme?.name).toBe("README.md");
  expect(readme?.id.type).toBe("blob");
  expect(readme?.permission).toBe(0o100644); // Regular file

  const file1 = sortedEntries.find((e) => e.name === "file1.txt");
  expect(file1?.name).toBe("file1.txt");
  expect(file1?.id.type).toBe("blob");
  expect(file1?.permission).toBe(0o100644);

  const file2 = sortedEntries.find((e) => e.name === "file2.txt");
  expect(file2?.name).toBe("file2.txt");
  expect(file2?.id.type).toBe("blob");
  expect(file2?.permission).toBe(0o100644);
});

test("GitRepo can read a tree with subdirectories", async () => {
  await initRepo(tempDir);

  // Create files in subdirectories
  await Bun.write(join(tempDir, "root.txt"), "root\n");
  await gitExec(tempDir, ["add", "root.txt"]);
  await gitExec(tempDir, ["commit", "-m", "Add root"]);

  // Create a subdirectory with files
  const subdir = join(tempDir, "subdir");
  await Bun.write(join(subdir, "nested.txt"), "nested\n");
  await gitExec(tempDir, ["add", "."]);
  await gitExec(tempDir, ["commit", "-m", "Add subdir"]);
  const commitSha = await gitExec(tempDir, ["rev-parse", "HEAD"]);

  const repo = new GitRepo(tempDir);
  const commit = await repo.findCommit({
    type: "commit",
    value: commitSha,
  });
  const tree = await repo.findTree(commit.tree);

  // Find the subdirectory entry
  const subdirEntry = tree.entries.find((e) => e.name === "subdir");
  expect(subdirEntry).toBeDefined();
  expect(subdirEntry?.id.type).toBe("tree");
  expect(subdirEntry?.permission).toBe(0o40000); // Directory mode

  // Read the subtree
  if (subdirEntry?.id.type === "tree") {
    const subtree = await repo.findTree(subdirEntry.id);
    expect(subtree.entries.length).toBe(1);
    expect(subtree.entries[0]?.name).toBe("nested.txt");
    expect(subtree.entries[0]?.id.type).toBe("blob");
  }
});

test("GitRepo can read a blob with exact content", async () => {
  await initRepo(tempDir);

  const expectedContent = "Hello, World!\nThis is a test file.\n";
  await createFile(tempDir, "test.txt", expectedContent);
  const commitSha = await commitAll(tempDir, "Add test file");

  const repo = new GitRepo(tempDir);
  const commit = await repo.findCommit({
    type: "commit",
    value: commitSha,
  });
  const tree = await repo.findTree(commit.tree);

  // Find the blob
  const blobEntry = tree.entries.find((e) => e.name === "test.txt");
  expect(blobEntry).toBeDefined();
  expect(blobEntry?.id.type).toBe("blob");

  if (blobEntry?.id.type === "blob") {
    const blob = await repo.findBlob(blobEntry.id);

    // Verify exact blob content
    expect(blob.type).toBe("blob");
    expect(blob.id.value).toBe(blobEntry.id.value);
    expect(blob.content).toBe(expectedContent);
  }
});

test("GitRepo can read a blob with special characters", async () => {
  await initRepo(tempDir);

  const specialContent = "Unicode: 你好世界\nEmoji: 🎉\nNull byte: \x00\n";
  await createFile(tempDir, "special.txt", specialContent);
  const commitSha = await commitAll(tempDir, "Add special file");

  const repo = new GitRepo(tempDir);
  const commit = await repo.findCommit({
    type: "commit",
    value: commitSha,
  });
  const tree = await repo.findTree(commit.tree);

  const blobEntry = tree.entries.find((e) => e.name === "special.txt");
  if (blobEntry?.id.type === "blob") {
    const blob = await repo.findBlob(blobEntry.id);
    expect(blob.content).toBe(specialContent);
  }
});

test("GitRepo findObj correctly delegates to specific types", async () => {
  await initRepo(tempDir);

  await createFile(tempDir, "file.txt", "content\n");
  const commitSha = await commitAll(tempDir, "Test commit");

  const repo = new GitRepo(tempDir);

  // Test commit type detection
  const commitObj = await repo.findObj({
    type: "commit",
    value: commitSha,
  });
  expect(commitObj.type).toBe("commit");
  if (commitObj.type === "commit") {
    expect(commitObj.tree).toBeDefined();
    expect(commitObj.author).toBeDefined();
    expect(commitObj.committer).toBeDefined();
    expect(commitObj.message).toBe("Test commit\n");
  }

  // Test tree type detection
  if (commitObj.type === "commit") {
    const treeObj = await repo.findObj(commitObj.tree);
    expect(treeObj.type).toBe("tree");
    if (treeObj.type === "tree") {
      expect(treeObj.entries.length).toBeGreaterThan(0);
    }

    // Test blob type detection
    const tree = await repo.findTree(commitObj.tree);
    const blobEntry = tree.entries.find((e) => e.id.type === "blob");
    if (blobEntry) {
      const blobObj = await repo.findObj(blobEntry.id);
      expect(blobObj.type).toBe("blob");
      if (blobObj.type === "blob") {
        expect(blobObj.content).toBe("content\n");
      }
    }
  }
});

test("GitRepo handles empty blob", async () => {
  await initRepo(tempDir);

  await createFile(tempDir, "empty.txt", "");
  const commitSha = await commitAll(tempDir, "Add empty file");

  const repo = new GitRepo(tempDir);
  const commit = await repo.findCommit({
    type: "commit",
    value: commitSha,
  });
  const tree = await repo.findTree(commit.tree);

  const blobEntry = tree.entries.find((e) => e.name === "empty.txt");
  if (blobEntry?.id.type === "blob") {
    const blob = await repo.findBlob(blobEntry.id);
    expect(blob.content).toBe("");
  }
});

test("GitRepo detects SHA-1 repositories correctly", async () => {
  await initRepo(tempDir);

  await createFile(tempDir, "test.txt", "test content\n");
  const commitSha = await commitAll(tempDir, "Test SHA-1");

  const repo = new GitRepo(tempDir);

  // SHA-1 hashes are 40 hex characters
  expect(commitSha.length).toBe(40);
  expect(commitSha).toMatch(/^[0-9a-f]{40}$/);

  const commit = await repo.findCommit({
    type: "commit",
    value: commitSha,
  });

  // Tree SHA should also be 40 characters for SHA-1
  expect(commit.tree.value.length).toBe(40);
  expect(commit.tree.value).toMatch(/^[0-9a-f]{40}$/);
});

test("GitRepo handles SHA-256 repositories", async () => {
  // Initialize a SHA-256 repository
  await gitExec(tempDir, ["init", "--object-format=sha256"]);
  await gitExec(tempDir, ["config", "user.name", "Test User"]);
  await gitExec(tempDir, ["config", "user.email", "test@example.com"]);

  await createFile(tempDir, "test.txt", "test content\n");
  const commitSha = await commitAll(tempDir, "Test SHA-256");

  const repo = new GitRepo(tempDir);

  // SHA-256 hashes are 64 hex characters
  expect(commitSha.length).toBe(64);
  expect(commitSha).toMatch(/^[0-9a-f]{64}$/);

  const commit = await repo.findCommit({
    type: "commit",
    value: commitSha,
  });

  // Verify commit properties with SHA-256
  expect(commit.type).toBe("commit");
  expect(commit.id.value).toBe(commitSha);
  expect(commit.message).toBe("Test SHA-256\n");
  expect(commit.tree.value.length).toBe(64);
  expect(commit.tree.value).toMatch(/^[0-9a-f]{64}$/);

  // Read the tree and verify entries use SHA-256
  const tree = await repo.findTree(commit.tree);
  expect(tree.entries.length).toBeGreaterThan(0);

  const fileEntry = tree.entries.find((e) => e.name === "test.txt");
  expect(fileEntry).toBeDefined();
  expect(fileEntry?.id.value.length).toBe(64);
  expect(fileEntry?.id.value).toMatch(/^[0-9a-f]{64}$/);

  // Read the blob
  if (fileEntry?.id.type === "blob") {
    const blob = await repo.findBlob(fileEntry.id);
    expect(blob.content).toBe("test content\n");
    expect(blob.id.value.length).toBe(64);
  }
});
