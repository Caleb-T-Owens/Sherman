import { $ } from "bun";
import { readConfigs, type Project } from "./config";
import path from "node:path";

export async function up({ servicesPath }: { servicesPath: string }) {
  const projects = await readConfigs(servicesPath);

  for (const project of projects) {
    await upOne({ servicesPath, project });
  }
}

export async function upOne({
  servicesPath,
  project,
}: {
  servicesPath: string;
  project: Project;
}) {
  console.log(`Deploying ${project.name}...`);

  const projectPath = path.join(servicesPath, project.name);
  await runInstallScript(projectPath);
  await linkArtifacts(projectPath, project);

  console.log("Building and starting service...");
  const lines = $`cd ${projectPath} && docker compose up -d --build`.lines();
  for await (const l of lines) {
    console.log(l);
  }
}

export async function down({ servicesPath }: { servicesPath: string }) {
  const projects = await readConfigs(servicesPath);

  for (const project of projects) {
    await downOne({ servicesPath, project });
  }
}

export async function downOne({
  servicesPath,
  project,
}: {
  servicesPath: string;
  project: Project;
}) {
  console.log(`Shutting down ${project.name}...`);

  const projectPath = path.join(servicesPath, project.name);
  await linkArtifacts(projectPath, project);

  console.log("Building and starting service...");
  const lines = $`cd ${projectPath} && docker compose up -d --build`.lines();
  for await (const l of lines) {
    console.log(l);
  }
}

async function runInstallScript(projectPath: string) {
  const installScriptPath = path.join(projectPath, "install.sh");
  if ((await $`test -f ${installScriptPath}`.quiet().nothrow()).exitCode !== 0) {
    return;
  }

  console.log("Running install.sh...");
  const lines = $`cd ${projectPath} && bash ./install.sh`.lines();
  for await (const l of lines) {
    console.log(l);
  }
}

async function linkArtifacts(projectPath: string, project: Project) {
  const artifactsPath = path.join(projectPath, "artifacts");

  if ((await $`test -e ${artifactsPath}`.quiet().nothrow()).exitCode === 0) {
    console.log("Removing old artifacts directory");
    await $`rm -rf ${artifactsPath}`.quiet();
  }

  if (Object.entries(project.config?.artifacts || {}).length > 0) {
    console.log(`Linking artifacts...`);

    await $`mkdir ${artifactsPath}`.quiet();

    for (const [name, source] of Object.entries(project.config!.artifacts)) {
      if (
        (await $`test -e ${{ raw: source }}`.quiet().nothrow()).exitCode === 0
      ) {
        await $`ln -s ${{ raw: source }} ${path.join(artifactsPath, name)}`.quiet();
      } else {
        console.log(`Warning: artifact ${name} not found at ${source}`);
      }
    }
  }
}
