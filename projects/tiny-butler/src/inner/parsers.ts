import type {
  CommitId,
  TreeId,
  Commit,
  TreeEntry,
  Signature,
} from "@/src/inner/types";

export function parseCommit(id: CommitId, content: string): Commit {
  const lines = content.split("\n");
  let idx = 0;

  const parents: CommitId[] = [];
  let tree: TreeId | null = null;
  let author: Signature | null = null;
  let committer: Signature | null = null;
  const extraHeaders: [string, string][] = [];

  // Parse headers
  while (idx < lines.length) {
    const line = lines[idx];
    if (!line || line === "") break;

    const spaceIdx = line.indexOf(" ");
    if (spaceIdx === -1) break;

    const key = line.substring(0, spaceIdx);
    const value = line.substring(spaceIdx + 1);

    switch (key) {
      case "tree":
        tree = { type: "tree", value };
        break;
      case "parent":
        parents.push({ type: "commit", value });
        break;
      case "author":
        author = parseSignature(value);
        break;
      case "committer":
        committer = parseSignature(value);
        break;
      default:
        extraHeaders.push([key, value]);
    }
    idx++;
  }

  // Skip empty line
  idx++;

  // Rest is the message
  const message = lines.slice(idx).join("\n");

  if (!tree || !author || !committer) {
    throw new Error("Invalid commit format");
  }

  return {
    type: "commit",
    id,
    parents,
    tree,
    author,
    committer,
    extraHeaders,
    message,
  };
}

export function parseSignature(value: string): Signature {
  // Format: "Name <email> timestamp timezone"
  const match = value.match(/^(.+) <(.+)> (\d+) ([\+\-]\d{4})$/);
  if (!match || !match[1] || !match[2] || !match[3]) {
    throw new Error(`Invalid signature format: ${value}`);
  }

  return {
    name: match[1],
    email: match[2],
    timestamp: parseInt(match[3]),
  };
}

export function parseTreeEntries(
  buffer: Uint8Array,
  hashSize: number = 20,
): TreeEntry[] {
  const entries: TreeEntry[] = [];
  let offset = 0;

  while (offset < buffer.length) {
    // Read mode (ASCII digits until space)
    let modeEnd = offset;
    while (buffer[modeEnd] !== 0x20) modeEnd++;
    const mode = parseInt(
      new TextDecoder().decode(buffer.slice(offset, modeEnd)),
      8,
    );
    offset = modeEnd + 1;

    // Read name (UTF-8 string until null)
    let nameEnd = offset;
    while (buffer[nameEnd] !== 0x00) nameEnd++;
    const name = new TextDecoder().decode(buffer.slice(offset, nameEnd));
    offset = nameEnd + 1;

    // Read hash (20 bytes for SHA-1, 32 bytes for SHA-256)
    const sha = Array.from(buffer.slice(offset, offset + hashSize))
      .map((b) => b.toString(16).padStart(2, "0"))
      .join("");
    offset += hashSize;

    // Determine type based on mode
    const modeStr = mode.toString(8);
    let type: "blob" | "tree";
    if (modeStr.startsWith("40") || modeStr === "160000") {
      type = "tree";
    } else {
      type = "blob";
    }

    entries.push({
      permission: mode,
      id: { type, value: sha },
      name,
    });
  }

  return entries;
}
