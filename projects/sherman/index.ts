import { $ } from "bun";
import { z } from "zod";

/**
 * Read file by `cat`ing it. There is no way this could be problematic
 *
 * Returns undefined if the file can't be found
 */
async function readFile(path: string): Promise<string | undefined> {
  const shellResponse = await $`cat ${path}`.nothrow();
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
function parseJsonString<Schema extends z.ZodType>(
  subject: string,
  schema: Schema
): Schema["_type"] {
  const parsedJSON: unknown = JSON.parse(subject);
  const verifiedObject = schema.parse(parsedJSON);

  return verifiedObject;
}

const currentWorkingDirectory = await $`pwd`.text();
const shermanFilePath = `${currentWorkingDirectory}/sherman.json`;

const shermanFileSchema = z.object({
  platforms: z.record(
    z.string(),
    z.object({
      entries: z.array(z.string()),
      profiles: z.record(
        z.string(),
        z.object({
          requires: z.string(),
          commands: z.array(z.string()),
        })
      ),
    })
  ),
  layers: z.record(
    z.string(),
    z.object({
      hooks: z.record(z.string(), z.string()),
      dependencies: z.array(z.string()),
    })
  ),
});

const shermanFileString = await readFile(shermanFilePath);
if (!shermanFileString) {
  throw new Error("sherman.json not found in current directory.");
}
const shermanFile = parseJsonString(shermanFileString);

console.log("Hello via Bun!");
