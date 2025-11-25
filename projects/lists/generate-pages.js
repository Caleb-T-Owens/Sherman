#!/usr/bin/env bun
import { readdirSync, statSync, writeFileSync } from "node:fs";
import { join, basename, relative, sep } from "node:path";

const pagesDir = join(import.meta.dir, "app/javascript/Pages");

function findPages(dir, baseDir = dir) {
  const entries = readdirSync(dir);
  const pages = [];

  for (const entry of entries) {
    const fullPath = join(dir, entry);
    const stat = statSync(fullPath);

    if (stat.isDirectory()) {
      pages.push(...findPages(fullPath, baseDir));
    } else if (entry.endsWith(".tsx")) {
      const relativePath = relative(baseDir, fullPath);
      const pathWithoutExt = relativePath.replace(/\.tsx$/, "");
      const name = pathWithoutExt.replace(
        new RegExp(sep.replace(/\\/g, "\\\\"), "g"),
        "/"
      );
      pages.push({ name, importPath: `./${join("Pages", pathWithoutExt)}` });
    }
  }

  return pages;
}

const pages = findPages(pagesDir);

let output = "// Auto-generated file - do not edit manually\n";
output += "// Run: bun generate-pages.js to regenerate\n\n";

for (const page of pages) {
  const importName = page.name.replace(/[\/\-]/g, "_");
  output += `import ${importName} from '${page.importPath}';\n`;
}

output += "\n";
output += "export const pages: Record<string, any> = {\n";
for (const page of pages) {
  const importName = page.name.replace(/[\/\-]/g, "_");
  output += `  '${page.name}': ${importName},\n`;
}
output += "};\n";

writeFileSync(join(import.meta.dir, "app/javascript/pages.ts"), output);
console.log(
  `✓ Generated pages.ts with ${pages.length} page(s): ${pages.map((p) => p.name).join(", ")}`
);
