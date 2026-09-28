// Builds ds-artifact/project/: this system as a claude.ai Design System artifact, the form a design
// canvas installs. It repackages what /design-sync built (ds-bundle/: the bundle, its stylesheet, each
// component's compiled preview and API) with list-shaped tokens and the brand book.
//
//   node artifact.mjs   (after npm run build and a design-sync build into ds-bundle/)
//
// Publish ds-artifact/ to the artifact named in README.md; design-system.json goes last.
import fs from "node:fs";
import path from "node:path";
import { components as meta } from "./meta.mjs";

const root = path.dirname(new URL(import.meta.url).pathname);
const at = (...p) => path.join(root, ...p);
const bundle = at("ds-bundle");
const out = at("ds-artifact", "project");
const read = (p) => fs.readFileSync(p, "utf8");
const write = (rel, text) => {
  fs.mkdirSync(path.dirname(path.join(out, rel)), { recursive: true });
  fs.writeFileSync(path.join(out, rel), text);
};

fs.rmSync(at("ds-artifact"), { recursive: true, force: true });
const dtcg = JSON.parse(read(at("generated/tokens.json")));
const kebab = (s) => s.replace(/([a-z0-9])([A-Z])/g, "$1-$2").replace(/([a-z])([0-9])/g, "$1-$2").toLowerCase();
const hex = (v) => v.toLowerCase();

// ── tokens.json: lists, names equal to the CSS variables the bundle reads ──

const roleUsage = {
  label: "Primary text, on every surface.",
  secondaryLabel: "Secondary text: details, values, captions, placeholders.",
  tertiaryLabel: "Tertiary text: disabled labels, column captions.",
  placeholder: "Empty-field placeholder text.",
  accent: "The tint: prominent buttons, links, toggles on, selection, focus.",
  accentForeground: "Text and glyphs on the accent (and on kind badges).",
  destructive: "Destructive actions and errors.",
  warning: "Warnings and problem counts.",
  success: "Success states.",
  info: "Informational tint.",
  separator: "Hairlines between rows and around cards (0.5px).",
  border: "Field and pop-up button outlines (0.5px).",
  focusRing: "The 3.5px focus ring outside a focused field.",
  fill: "Bordered buttons, tracks, segmented and stepper backgrounds.",
  fillHover: "A bordered button under the pointer.",
  fillPressed: "A bordered button pressed.",
  controlBackground: "Text field background.",
  controlButton: "Pop-up button and stepper keys.",
  segmentSelected: "The selected segment of a segmented control.",
  controlKnob: "Toggle and slider knobs.",
  hover: "A row, tab or borderless button under the pointer.",
  pressed: "A pressed row or borderless button.",
  selection: "Selected rows, sidebar links, hovered menu items.",
  selectionInactive: "Selection in a window that is not key.",
  selectedTab: "The selected dock tab's pill.",
  contentBackground: "Editors, lists, tables: what text sits on.",
  groupedBackground: "Settings forms, behind section cards.",
  card: "Section cards and grouped content.",
  windowBackground: "Window chrome behind panels.",
  sidebarTint: "Sidebars, over the desktop blur.",
  barTint: "Toolbars and tab bars, over the desktop blur.",
  barOverContent: "A bar over the app's own content (table headers).",
  gapTint: "The 1px gap between docked panels.",
  scrim: "Behind a sheet or alert.",
  scrollIndicator: "Scroll bar thumbs.",
  shadow: "Rings around knobs and selected segments.",
};
const colors = [];
for (const role of Object.keys(dtcg.color.light)) {
  colors.push({
    name: `mg-color-${kebab(role)}`,
    value: { light: hex(dtcg.color.light[role].$value), dark: hex(dtcg.color.dark[role].$value) },
    usage: roleUsage[role] ?? `The ${role} role.`,
  });
}
for (const h of Object.keys(dtcg.hue.light)) {
  colors.push({
    name: `mg-hue-${kebab(h)}`,
    value: { light: hex(dtcg.hue.light[h].$value), dark: hex(dtcg.hue.dark[h].$value) },
    usage: h.startsWith("badge")
      ? `Kind badge background (${h.slice(5)}), under a white letter.`
      : h === "folder"
        ? "Folder icons in a file tree."
        : `Palette ${h}: tags, swatches, charts; told apart by hue.`,
  });
}
// The code editor's surfaces and syntax, from EditorTheme.
for (const key of Object.keys(dtcg.editor.light)) {
  const light = dtcg.editor.light[key], dark = dtcg.editor.dark[key];
  const isSyntax = key.startsWith("syntax.");
  const lc = isSyntax ? light.$value.color : light.$value, dc = isSyntax ? dark?.$value.color : dark?.$value;
  if (!lc || !dc) continue;
  const name = isSyntax ? `mg-syntax-${kebab(key.slice(7))}` : `mg-editor-${kebab(key)}`;
  colors.push({
    name,
    value: { light: hex(lc), dark: hex(dc) },
    usage: isSyntax ? `Code: ${key.slice(7)} tokens.` : `Code editor: ${key.replace(/([A-Z])/g, " $1").toLowerCase()}.`,
  });
}
const glassColors = [], glassOther = [];
for (const role of Object.keys(dtcg.glass.light)) {
  const g = (m) => dtcg.glass[m][role];
  const k = `mg-glass-${kebab(role)}`;
  for (const [part, what] of [["tint", "top tint"], ["tintBottom", "bottom tint"], ["rim", "rim, at the top"], ["rimBottom", "rim, at the bottom"], ["fallback", "colour where backdrop blur is unavailable"]]) {
    colors.push({
      name: `${k}-${kebab(part)}`,
      value: { light: hex(g("light")[part].$value), dark: hex(g("dark")[part].$value) },
      usage: `${role} glass: ${what}.`,
    });
  }
  glassOther.push({ name: `${k}-blur`, value: g("light").blur.$value, usage: `${role} glass: backdrop blur (the same in both themes).` });
  glassOther.push({ name: `${k}-saturation`, value: String(g("light").saturation.$value), usage: `${role} glass: backdrop saturation in light (dark: ${g("dark").saturation.$value}).` });
}

const typeStyles = Object.entries(dtcg.font)
  .filter(([k]) => k !== "family")
  .map(([name, t]) => ({
    name: `mg-font-${kebab(name)}`,
    fontSize: t.$value.fontSize,
    fontWeight: t.$value.fontWeight,
    usage: {
      largeTitle: "Page titles.", title: "Window and sheet titles.", title2: "Large section titles.", title3: "Section titles.",
      headline: "Panel titles, emphasized labels, navigation bar titles.", body: "Default text: controls, rows, fields.",
      callout: "Tabs, toolbars, list details, section headers.", subheadline: "Status bars, positions, footers.",
      footnote: "The smallest text.", mono: "Code.", monoSmall: "Small code, consoles.",
    }[name],
  }));

const fontFiles = [400, 500, 600, 700].map((w) => ({ family: "JetBrains Mono", file: `fonts/jetbrains-mono-latin-${w}-normal.woff2`, weight: String(w), style: "normal" }));
for (const f of fontFiles) {
  fs.mkdirSync(path.join(out, "fonts"), { recursive: true });
  fs.copyFileSync(path.join(bundle, f.file), path.join(out, f.file));
}

const shadowUsage = { control: "Knobs, selected segments and tabs.", popover: "Menus, popovers.", sheet: "Sheets, alerts.", float: "Floating dock panels." };
const shadowCss = (s) => `${s.offsetX} ${s.offsetY} ${s.blur} ${s.spread} ${hex(s.color)}`;
const tokens = {
  name: "MetalGraphics Frosted Glass",
  version: 1,
  color: { themes: [{ id: "light", name: "Light" }, { id: "dark", name: "Dark" }], tokens: colors },
  type: {
    fonts: fontFiles,
    families: { sans: dtcg.font.family.sans.$value, mono: dtcg.font.family.mono.$value },
    groups: [
      { name: "Text", family: "sans", styles: typeStyles.filter((s) => !s.name.includes("mono")) },
      { name: "Code", family: "mono", styles: typeStyles.filter((s) => s.name.includes("mono")) },
    ],
  },
  spacing: { tokens: Object.entries(dtcg.space).map(([k, v]) => ({ name: `mg-space-${k}`, value: v.$value, usage: `Spacing step ${k}.` })) },
  radius: {
    tokens: Object.entries(dtcg.radius).map(([k, v]) => ({
      name: `mg-radius-${k}`,
      value: v.$value,
      usage: { xs: "Badges.", sm: "Rows, menu items, segments.", md: "Buttons, fields, row highlights.", lg: "Cards, popovers, menus.", xl: "Sheets, alerts." }[k],
    })),
  },
  shadow: {
    tokens: Object.keys(dtcg.shadow.light).map((k) => ({
      name: `mg-shadow-${k}`,
      value: { light: shadowCss(dtcg.shadow.light[k].$value), dark: shadowCss(dtcg.shadow.dark[k].$value) },
      usage: shadowUsage[k],
    })),
  },
  glass: { note: "Backdrop blur and saturation per glass role; their colours are in Colors.", tokens: glassOther },
  meta: { source: "github", repo: "MetalGraphics", package: "DesignSystemWeb", paths: { tokens: ["DesignSystemWeb/generated/tokens.json"], fonts: ["@fontsource/jetbrains-mono"] }, synced: new Date().toISOString().slice(0, 10) },
};
write("tokens.json", JSON.stringify(tokens, null, 2) + "\n");

// ── The bundle, its stylesheet, per-component types, guides and previews ──

const js = read(path.join(bundle, "_ds_bundle.js")).replace(/^\/\* @ds-bundle: \{/, '/* @ds-bundle: {"format":4,');
if (/<\/script|<!--/i.test(js)) throw new Error("bundle.js contains </script or <!--");
write("components/bundle.js", js);
const css = read(path.join(bundle, "_ds_bundle.css"));
if (/<\/style/i.test(css)) throw new Error("bundle.css contains </style");
write("components/bundle.css", css);

const groupOf = {};
for (const g of fs.readdirSync(path.join(bundle, "components"))) {
  for (const c of fs.readdirSync(path.join(bundle, "components", g))) groupOf[c] = g;
}
const title = (g) => g[0].toUpperCase() + g.slice(1);
for (const c of meta) {
  const g = groupOf[c.name];
  const dir = path.join(bundle, "components", g, c.name);
  write(`components/${c.name}/${c.name}.d.ts`, read(path.join(dir, `${c.name}.d.ts`)));
  const doc = read(at("docs", `${c.name}.md`)).replace(/^---[\s\S]*?---\n+/, "");
  write(`components/${c.name}/README.md`, doc);

  const preview = read(path.join(bundle, "_preview", `${c.name}.js`)).replace(/<\/script/gi, "<\\/script").replace(/<!--/g, "<\\!--");
  const cells = (read(at(".design-sync/previews", `${c.name}.tsx`)).match(/^export const \w+/gm) ?? []).length;
  write(
    `components/${c.name}/preview.html`,
    `<!-- @dsCard group="${title(g)}" height=${Math.min(60 + cells * 80, 1200)} subtitle="Mirrors ${c.swift.split(/[ (,]/)[0].replace(/"/g, "")}" -->
<div id="root" style="display:flex;flex-direction:column;gap:16px;padding:16px"></div>
<script>
${preview}
(function () {
  var h = React.createElement, root = document.getElementById("root"), cells = window.__dsPreview || {};
  Object.keys(cells).filter(function (k) { return /^[A-Z]/.test(k) && typeof cells[k] === "function"; }).forEach(function (k) {
    var cell = document.createElement("section");
    cell.innerHTML = '<div style="font:600 11px var(--mg-font-family-sans);letter-spacing:.06em;text-transform:uppercase;color:var(--mg-color-secondary-label);margin-bottom:6px">' + k + "</div><div></div>";
    root.appendChild(cell);
    ReactDOM.createRoot(cell.lastChild).render(h(MG.MGRoot, { surface: "none" }, h(cells[k])));
  });
})();
</script>
`
  );
}

// ── README: the brand book ──

const conventions = read(at(".design-sync/conventions.md")).replace(/^# .*\n+/, "");
write(
  "README.md",
  `# MetalGraphics Frosted Glass

The design system of MetalGraphics, a Swift UI library drawn with Metal on macOS: frosted glass, light and
dark, macOS sizes. On the web it draws everything in JetBrains Mono with its ligatures. Its tokens are exported
from the Swift theme (\`Theme+Presets.swift\`) and its components are React versions that mirror the Swift ones
metric for metric, so a design made with them can be built in the app as drawn.

${conventions}
## Foundations

- **Colour is a role, not a value.** Every colour token has a light and a dark value. Name the role that says
  what a thing is for (\`mg-color-secondary-label\`, \`mg-color-selection\`), never a hue.
- **Opaque where text sits, glass for chrome and overlays.** Content, grouped backgrounds and cards are opaque.
  Sidebars and bars are translucent tints. Popovers, menus, sheets and tooltips are glass: the backdrop blurred
  and saturated under a tint, with a light rim along the top edge.
- **Hairlines, not borders.** Rows, cards and bars separate with 0.5px \`mg-color-separator\` lines. Shadows are
  reserved for what floats: knobs, popovers, sheets, floating panels.
- **Dense, macOS-sized.** Body text is 13px; rows are 24px; buttons and fields are 22–24px tall.

## Iconography

Nine glyphs, drawn in the current text colour: chevronRight, chevronDown, chevronLeft, upDown, checkmark,
folder, document, magnifier, xmark (\`MG.Icon\`). Folders take \`mg-hue-folder\`; symbols in lists take a
\`MG.KindBadge\` letter tile on a badge hue.

## Not synced

- Motion (hover 120ms, interaction 180ms, dock 160ms, navigation 300ms, a spring for presentation) lives in the
  bundle's stylesheet as \`--mg-motion-*\`; this format has no motion family.
- Glass grain (the app's \`noise\`) has no CSS equivalent.
- The Swift app draws SF; this system uses JetBrains Mono, which ships with it.
`
);

// ── The cover ──

write(
  "components/Cover/preview.html",
  `<!-- @dsCard height=312 -->
<div class="cover">
  <svg class="band" viewBox="0 0 960 112" width="960" height="112" aria-hidden="true">
    <!--
      blocks: mg-color-accent 312×112, mg-hue-indigo 176×112, mg-hue-teal 120×112 (bleeding off the right),
              mg-color-label 96×56 over a mg-glass-popover-tint 96×56 pair; sides are multiples of mg-space-sm (8).
      arrangement: a strip of unequal bands across the top, flush, as the app's dock bars stack.
      pattern: a dot grid at mg-space-md (12) cut from the accent block: "precise, technical, mono, a grid".
      steps and radii: 8/12/16 spacing; corners mg-radius-lg (10) on the glass pair, square elsewhere.
    -->
    <rect class="accent" x="0" y="0" width="312" height="112"/>
    <g class="dots">${Array.from({ length: 5 }, (_, r) => Array.from({ length: 8 }, (_, col) => `<circle cx="${192 + col * 12}" cy="${32 + r * 12}" r="1.5"/>`).join("")).join("")}</g>
    <rect class="indigo" x="320" y="0" width="176" height="112"/>
    <rect class="glass tile" x="504" y="0" width="96" height="56"/>
    <rect class="ink tile" x="504" y="56" width="96" height="56"/>
    <rect class="teal" x="608" y="0" width="360" height="112"/>
  </svg>
  <div class="text">
    <div class="name">MetalGraphics<br>Frosted Glass</div>
    <div class="tagline">Frosted glass, light and dark, macOS sizes, one font.</div>
  </div>
</div>
<style>
  .cover { width: 960px; height: 312px; box-sizing: border-box; background: var(--mg-color-window-background); position: relative; overflow: hidden; }
  .band { position: absolute; left: 0; top: 0; display: block; }
  .accent { fill: var(--mg-color-accent); }
  .indigo { fill: var(--mg-hue-indigo); }
  .teal { fill: var(--mg-hue-teal); }
  .glass { fill: var(--mg-glass-popover-fallback); }
  .ink { fill: var(--mg-color-label); }
  .tile { rx: var(--mg-radius-lg); }
  .dots circle { fill: var(--mg-color-accent-foreground); }
  .text { position: absolute; left: 32px; bottom: 28px; max-width: 900px; }
  .name { font: 700 64px/0.95 var(--mg-font-family-sans); color: var(--mg-color-label); font-feature-settings: var(--mg-font-features); }
  .tagline { margin-top: 12px; font: 400 13px var(--mg-font-family-sans); color: var(--mg-color-secondary-label); }
</style>
`
);

// ── The index, last ──

write(
  "design-system.json",
  JSON.stringify(
    {
      v: 3,
      layout: "files",
      createdOnFiles: { v: 1, at: new Date().toISOString() },
      title: "MetalGraphics Frosted Glass",
      namespace: "MG",
      libraries: [{ name: "react", version: "18" }, { name: "react-dom", version: "18" }],
      sections: {},
      groups: [],
      assetGroups: {},
      blobs: {},
      docs: { readme: "project/README.md", sections: [] },
      lastChange: { by: "Mykola", at: new Date().toISOString(), via: "Claude Code", note: "53 components: editor, window chrome, docking, colour and date pickers added." },
    },
    null,
    2
  ) + "\n"
);

const count = (d) => fs.readdirSync(d, { withFileTypes: true }).reduce((n, e) => n + (e.isDirectory() ? count(path.join(d, e.name)) : 1), 0);
console.log(`ds-artifact/project: ${count(out)} files, ${colors.length} colours, ${meta.length} components`);
