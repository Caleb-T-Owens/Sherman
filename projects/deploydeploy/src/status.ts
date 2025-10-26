import { readConfigs } from "./config";
import { dockerLs } from "./docker";

export async function status({ servicesPath }: { servicesPath: string }) {
  const configs = await readConfigs(servicesPath);
  const ls = await dockerLs();

  console.log("Registered services:");

  for (const c of configs) {
    const running = ls.some((ls) => ls.Name === c.name);
    console.log(`  - ${c.name}: ${running ? "up" : "down"}`);
  }

  console.log("\nOther services:");
  const others = ls.filter((ls) => !configs.some((c) => c.name === ls.Name));
  for (const o of others) {
    console.log(`  - ${o.Name}`);
  }
}
