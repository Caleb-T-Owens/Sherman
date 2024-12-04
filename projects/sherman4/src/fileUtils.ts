import { $ } from "bun";
import type { z } from "zod";

/**
 * Read file by `cat`ing it. There is no way this could be problematic
 *
 * Returns undefined if the file can't be found
 */
export async function readFile(path: string): Promise<string | undefined> {
  const shellResponse = await $`cat ${path}`.nothrow().quiet();
  if (shellResponse.exitCode === 0) {
    return shellResponse.text();
  }
}

/**
 * Parses a JSON string and validates it against a zod schema
 *
 * @throws Failed to parse json
 * @throws Failed to validate schema
 */
export function parseJsonString<Schema extends z.ZodType>(
  subject: string,
  schema: Schema
): Schema["_type"] {
  const parsedJSON: unknown = JSON.parse(subject);
  const verifiedObject = schema.parse(parsedJSON);

  return verifiedObject;
}

export async function pwd(): Promise<string> {
  return (await $`pwd`.quiet().text()).trim();
}
