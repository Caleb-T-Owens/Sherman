// @ts-check
import { defineConfig } from "astro/config";

import mdx from "@astrojs/mdx";
import remarkMath from "remark-math";
import rehypeKatex from "rehype-katex";

// https://astro.build/config
export default defineConfig({
  integrations: [mdx()],
  prefetch: true,
  site: "https://cto.je",
  markdown: {
    shikiConfig: {
      themes: {
        light: "github-light",
      },
    },
    remarkPlugins: [remarkMath],
    rehypePlugins: [[rehypeKatex, {
      macros: {
        "\\sand": "\\cap",
        "\\sor": "\\cup"
      }
    }]],
  },
});
