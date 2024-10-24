import { $, env } from "bun";
import { z } from "zod";

const shermanDir = `${env.HOME}/sherman`;
const projectsDir = `${shermanDir}/projects`;

const cloneFile = `${projectsDir}/cloned.json`;
const clonedRaw = await $`cat ${cloneFile}`.text();
const clonedUnparsed = JSON.parse(clonedRaw);

const clonedSchema = z.record(
  z.string(),
  z.object({
    url: z.string(),
    deployable: z.optional(z.boolean()),
  })
);

const cloned = clonedSchema.parse(clonedUnparsed);

const gitignorePath = `${projectsDir}/.gitignore`;

let gitignore: string[] = [];

const { exitCode: gitignoreExists } =
  await $`[ -e ${gitignorePath} ]`.nothrow();
if (gitignoreExists === 0) {
  gitignore = await Array.fromAsync(await $`cat ${gitignorePath}`.lines());
}

for (const folderName of Object.keys(cloned)) {
  const gitignoreEntry = `${folderName}/`;
  if (!gitignore.includes(gitignoreEntry)) {
    gitignore.push(gitignoreEntry);
  }
}

const joinedGitignore = gitignore.join("\n");
await $`echo "${joinedGitignore}" > ${gitignorePath}`;

for (const [folderName, object] of Object.entries(cloned)) {
  if (env.SHERMAN_ENV === "deploy" && !object.deployable) {
    continue;
  }

  const folderPath = `${projectsDir}/${folderName}`;

  const { exitCode: projectExists } = await $`[ -e ${folderPath} ]`.nothrow();

  if (projectExists === 0) {
    console.log(`Project ${folderName} is already cloned`);
    continue;
  }

  console.log(`Cloning ${folderName}...`);

  const { exitCode: gitCloneStatus } =
    await $`git clone ${object.url} ${folderPath} --recurse-submodules`.nothrow();

  if (gitCloneStatus !== 0) {
    console.log("Failed to clone ${folderName}");
  }
}
