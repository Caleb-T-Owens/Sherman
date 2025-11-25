#!/usr/bin/env bun
import { readdirSync, writeFileSync } from 'node:fs';
import { join, basename } from 'node:path';

const pagesDir = join(import.meta.dir, 'app/javascript/Pages');
const files = readdirSync(pagesDir);

let output = '// Auto-generated file - do not edit manually\n';
output += '// Run: bun generate-pages.js to regenerate\n\n';

const pageNames = [];

for (const file of files) {
  if (file.endsWith('.tsx')) {
    const name = basename(file, '.tsx');
    pageNames.push(name);
    output += `import ${name} from './Pages/${name}';\n`;
  }
}

output += '\n';
output += 'export const pages: Record<string, any> = {\n';
for (const name of pageNames) {
  output += `  ${name},\n`;
}
output += '};\n';

writeFileSync(join(import.meta.dir, 'app/javascript/pages.ts'), output);
console.log(`✓ Generated pages.ts with ${pageNames.length} page(s): ${pageNames.join(', ')}`);
