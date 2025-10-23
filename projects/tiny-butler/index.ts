#!/usr/bin/env bun
import { Command } from "commander";

const program = new Command();

program
  .name("tiny-butler")
  .description("A CLI tool built with Bun and TypeScript")
  .version("0.1.0");

program
  .command("hello")
  .description("Say hello")
  .option("-n, --name <name>", "name to greet", "World")
  .action((options) => {
    console.log(`Hello, ${options.name}!`);
  });

program.parse();
