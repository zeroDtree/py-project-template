import fs from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

import * as esbuild from "esbuild";

const docsDir = path.dirname(fileURLToPath(import.meta.url));
const mermaidDist = path.resolve(docsDir, "node_modules/mermaid/dist");

// Mermaid 12 loads diagram types and ELK with dynamic import(). Those paths
// point at files inside the package and 404 on GitHub Pages. Bind every
// relative import into the one file the page loads.
const inlineDynamicImports = {
  name: "inline-mermaid-dynamic-imports",
  setup(build) {
    build.onLoad({ filter: /\.mjs$/ }, async (args) => {
      if (args.path !== mermaidDist && !args.path.startsWith(mermaidDist + path.sep)) {
        return null;
      }
      const original = await fs.readFile(args.path, "utf8");
      const specs = [
        ...new Set([...original.matchAll(/import\("(\.\/[^"]+\.mjs)"\)/g)].map((match) => match[1])),
      ];
      if (specs.length === 0) {
        return null;
      }
      let contents = original;
      const header = specs
        .map((spec, index) => {
          const id = `__mermaidDyn${index}`;
          contents = contents.replaceAll(`import("${spec}")`, `Promise.resolve(${id})`);
          return `import * as ${id} from "${spec}";`;
        })
        .join("\n");
      return {
        contents: `${header}\n${contents}`,
        loader: "js",
        resolveDir: path.dirname(args.path),
      };
    });
  },
};

await esbuild.build({
  absWorkingDir: docsDir,
  entryPoints: ["mermaid-entry.js"],
  bundle: true,
  format: "iife",
  platform: "browser",
  target: ["es2022"],
  minify: true,
  legalComments: "none",
  outfile: "assets/mermaid.js",
  define: {
    "process.env.NODE_ENV": '"production"',
  },
  plugins: [inlineDynamicImports],
});
