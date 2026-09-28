// Builds the package: what /design-sync converts into the claude.ai/design project.
//
//   dist/index.js        the components, an ES module importing `react`
//   dist/types/          their declarations (tsc), the API the design agent codes against
//   dist/styles.css      tokens.css (exported from the Swift theme) + the component styles
//   docs/<Name>.md       each component's usage doc, from meta.mjs (category = its group)
import * as esbuild from "esbuild";
import { execFileSync } from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import { components } from "./meta.mjs";

const root = path.dirname(new URL(import.meta.url).pathname);
const at = (...p) => path.join(root, ...p);

const tokens = at("generated", "tokens.css");
if (!fs.existsSync(tokens)) throw new Error(`${tokens} is missing: run RECORD_TOKENS=1 swift test --filter DesignTokenExportTests`);

fs.rmSync(at("dist"), { recursive: true, force: true });

await esbuild.build({
  entryPoints: [at("src/index.ts")],
  bundle: true,
  format: "esm",
  outfile: at("dist/index.js"),
  external: ["react", "react-dom"],
  target: "es2020",
  jsx: "transform",
  jsxFactory: "React.createElement",
  jsxFragment: "React.Fragment",
  legalComments: "none",
});

execFileSync(path.join(root, "node_modules/.bin/tsc"), ["-p", at("tsconfig.json")], { stdio: "inherit" });

fs.writeFileSync(
  at("dist/styles.css"),
  `${fs.readFileSync(tokens, "utf8")}\n${fs.readFileSync(at("src/styles.css"), "utf8")}`
);

fs.rmSync(at("docs"), { recursive: true, force: true });
fs.mkdirSync(at("docs"));
for (const c of components) {
  const props = c.props.length
    ? `| Prop | Type | |\n|---|---|---|\n${c.props.map(([n, t, d]) => `| \`${n}\` | ${t.replace(/\|/g, "\\|")} | ${d} |`).join("\n")}\n`
    : "No props of its own; `className` and `style` place it.\n";
  fs.writeFileSync(
    at("docs", `${c.name}.md`),
    `---
category: ${c.group}
---

# ${c.name}

${c.summary}

Mirrors \`${c.swift}\` in MetalGraphics.

## Props

${props}
Every component also takes \`className\` and \`style\`. Most take \`state\` (\`"hover" | "pressed" | "focused" | "disabled"\`) to draw a state without a pointer on it.

## Example

\`\`\`jsx
${c.jsx}
\`\`\`
`
  );
}

console.log(`dist/: index.js, types, styles.css; docs/: ${components.length} component docs`);
