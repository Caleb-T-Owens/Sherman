import type {
  Repository,
  CommitId,
  TreeId,
  BlobId,
  ObjId,
  Commit,
  Tree,
  Blob,
  Obj,
} from "@/src/inner/types";
import { parseCommit, parseTreeEntries } from "@/src/inner/parsers";

export type HashAlgorithm = "sha1" | "sha256";

export class GitRepo implements Repository {
  private hashSize: number | null = null;
  private hashAlgorithm: HashAlgorithm | null = null;

  constructor(private path: string) {}

  private async detectHashAlgorithm(): Promise<HashAlgorithm> {
    if (this.hashAlgorithm !== null) {
      return this.hashAlgorithm;
    }

    // Check git config for extensions.objectFormat
    const proc = Bun.spawn(
      ["git", "-C", this.path, "config", "--get", "extensions.objectFormat"],
      {
        stdout: "pipe",
        stderr: "pipe",
      },
    );

    await proc.exited;

    if (proc.exitCode === 0) {
      const result = await new Response(proc.stdout).text();
      const format = result.trim();
      if (format === "sha256") {
        this.hashAlgorithm = "sha256";
        this.hashSize = 32;
        return "sha256";
      }
    }

    // Default to SHA-1 if not configured or config not found
    this.hashAlgorithm = "sha1";
    this.hashSize = 20;
    return "sha1";
  }

  private async getHashSize(): Promise<number> {
    if (this.hashSize !== null) {
      return this.hashSize;
    }
    await this.detectHashAlgorithm();
    return this.hashSize!;
  }

  async findBlob(id: BlobId): Promise<Blob> {
    const proc = Bun.spawn(
      ["git", "-C", this.path, "cat-file", "blob", id.value],
      {
        stdout: "pipe",
      },
    );
    const result = await new Response(proc.stdout).text();
    return {
      type: "blob",
      id,
      content: result,
    };
  }

  async findTree(id: TreeId): Promise<Tree> {
    const hashSize = await this.getHashSize();
    const proc = Bun.spawn(
      ["git", "-C", this.path, "cat-file", "tree", id.value],
      {
        stdout: "pipe",
      },
    );
    const result = await new Response(proc.stdout).arrayBuffer();
    const entries = parseTreeEntries(new Uint8Array(result), hashSize);
    return {
      type: "tree",
      id,
      entries,
    };
  }

  async findCommit(id: CommitId): Promise<Commit> {
    const proc = Bun.spawn(
      ["git", "-C", this.path, "cat-file", "commit", id.value],
      {
        stdout: "pipe",
      },
    );
    const result = await new Response(proc.stdout).text();
    return parseCommit(id, result);
  }

  async findObj(id: ObjId): Promise<Obj> {
    const proc = Bun.spawn(
      ["git", "-C", this.path, "cat-file", "-t", id.value],
      {
        stdout: "pipe",
      },
    );
    const type = await new Response(proc.stdout).text();
    const objType = type.trim() as "commit" | "tree" | "blob";

    switch (objType) {
      case "commit":
        return this.findCommit({ type: "commit", value: id.value });
      case "tree":
        return this.findTree({ type: "tree", value: id.value });
      case "blob":
        return this.findBlob({ type: "blob", value: id.value });
      default:
        throw new Error(`Unknown git object type: ${objType}`);
    }
  }
}
