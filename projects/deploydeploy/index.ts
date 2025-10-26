#!/usr/bin/env bun
import { Command } from "commander";
import { status } from "./src/status";
import { $ } from "bun";
import path from "node:path";
import { up } from "./src/deploy";

const program = new Command();

program
  .name("deploydeploy")
  .description("A tool for managing docker compose instances")
  .version("0.1.0");

program
  .command("hello")
  .description("Say hello")
  .option("-n, --name <name>", "name to greet", "World")
  .action(async (options) => {
    console.log(`Hello, ${options.name}!`);
  });

program
  .command("status")
  .alias("st")
  .description("Get the current docker status")
  .option("-s, --services <path>", "path to the services folder")
  .action(async (options) => {
    const servicesPath = await getServicesPath(options);
    await status({ servicesPath });
  });

program
  .command("deploy")
  .alias("dp")
  .description("Re/deploy the services")
  .option("-s, --services <path>", "path to the services folder")
  .action(async (options) => {
    const servicesPath = await getServicesPath(options);
    await up({ servicesPath });
  });

program.parse();

async function getServicesPath(options: any): Promise<string> {
  if (!("services" in options)) throw new Error("Services path not provided");
  if (typeof options.services !== "string")
    throw new Error("Services path must be a string");
  const p = options.services.trim();
  if ((await $`test -d ${p}`.quiet().nothrow()).exitCode !== 0)
    throw new Error("Services path not found");
  const pwd = (await $`pwd`.text()).trim();
  return await path.resolve(pwd, options.services);
}
