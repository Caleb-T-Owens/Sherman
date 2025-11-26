import path from "path";
import fs from "fs";
import { spawn } from "child_process";
import { promisify } from "util";

const execAsync = promisify(spawn);

const config = {
  sourcemap: "external",
  entrypoints: ["app/javascript/application.tsx"],
  outdir: path.join(process.cwd(), "app/assets/builds"),
  target: "browser",
};

const generatePages = async () => {
  const proc = spawn("bun", ["generate-pages.js"], {
    stdio: "inherit",
    cwd: process.cwd(),
  });

  return new Promise((resolve, reject) => {
    proc.on("close", (code) => {
      if (code === 0) resolve();
      else reject(new Error(`generate-pages.js exited with code ${code}`));
    });
  });
};

const build = async (config) => {
  // Generate pages registry before building
  await generatePages();

  const result = await Bun.build(config);

  if (!result.success) {
    if (process.argv.includes("--watch")) {
      console.error("Build failed");
      for (const message of result.logs) {
        console.error(message);
      }
      return;
    } else {
      throw new AggregateError(result.logs, "Build failed");
    }
  }
};

(async () => {
  await build(config);

  if (process.argv.includes("--watch")) {
    fs.watch(
      path.join(process.cwd(), "app/javascript"),
      { recursive: true },
      (eventType, filename) => {
        if (filename === "pages.ts") return;
        console.log(`File changed: ${filename}. Rebuilding...`);
        build(config);
      }
    );
  } else {
    process.exit(0);
  }
})();
