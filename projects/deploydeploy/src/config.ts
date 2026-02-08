import { $ } from "bun";

export type Config = {
  artifacts: Record<string, string>;
};

export type Project = {
  name: string;
  config?: Config;
};

export async function readConfigs(servicesPath: string): Promise<Project[]> {
  const serviceFolders = (
    await $`find ${servicesPath} -maxdepth 1 -mindepth 1 -type d`.text()
  )
    .trim()
    .split("\n")
    .filter((line) => line.length > 0);
  const out = [];
  for await (const s of serviceFolders) {
    let config: Config | undefined;
    if ((await $`test -f ${s}/config.json`.quiet().nothrow()).exitCode === 0) {
      config = JSON.parse(await $`cat ${s}/config.json`.text());
    }

    out.push({
      name: s.split("/").at(-1)!,
      config,
    });
  }

  return out;
}
