import { $ } from "bun";

export type DockerLsEntry = {
  Name: string;
  Status: string;
  ConfigFiles: string;
};

export async function dockerLs(): Promise<DockerLsEntry[]> {
  const output = JSON.parse(await $`docker compose ls --format=json`.text());
  return output;
}
