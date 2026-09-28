# DesignSystemWeb

The design system for the web, synced to Claude Design so its design agent builds with these components.

- **Package:** `@metalgraphics/frosted-glass` (`window.MG` once bundled).
- **Tokens:** exported from the Swift theme.
- **Components:** React versions of the Swift components.
- **Project:** "MetalGraphics Frosted Glass", https://claude.ai/design/p/da15bd76-150e-4be4-81fc-8050f1eac271.
- **Design System artifact:** the same system in the form a design canvas installs,
  https://claude.ai/artifact/MxLvtzovjjZmjCcsg5ntF7. It is installed on the "MetalGraphics Frosted Glass" canvas
  as `ds/mg/`.

It goes one way. `Theme+Presets.swift` and the Swift components are the source; nothing here flows back.

## Layout

| Path | What |
|---|---|
| `generated/` | `tokens.json`, `tokens.css`, `icons.json`. Written by `DesignTokenExportTests` from the Swift theme, including the code editor's `EditorTheme` (`--mg-editor-*`, `--mg-syntax-*`). Checked in; do not edit. |
| `src/styles.css` | The components' CSS. It uses `var(--mg-*)` only, never a colour written out, and each block names the Swift it mirrors. |
| `src/components/*.tsx` | The 53 components, exported from `src/index.ts`: foundations, controls (with the colour and date pickers), lists, forms, surfaces, navigation, docking, window chrome, and the editor's pieces (`CodeEditor`, `FindBar`, `CompletionList`, `StatusBar`). |
| `meta.mjs` | Each component's summary, props, Swift counterpart and JSX example. Becomes `docs/<Name>.md`, which the sync turns into the design agent's `<Name>.prompt.md`. |
| `build.mjs` | `npm run build` writes: `dist/index.js` (the ES module), `dist/types/` (declarations), `dist/styles.css` (tokens then components) and `docs/`. |
| `artifact.mjs` | `node artifact.mjs` repackages the design-sync build (`ds-bundle/`) as the Design System artifact's files in `ds-artifact/project/`, including list-shaped tokens, previews and a cover. Publish them to the artifact with `design-system.json` last. |
| `.design-sync/` | The sync's config, notes, the conventions header the design agent reads first, and one authored preview per component (`previews/<Name>.tsx`, light beside dark). Committed. |

## Updating it

After changing the theme, re-record the tokens. `swift test` fails while `generated/` is stale.

```bash
RECORD_TOKENS=1 swift test --filter DesignTokenExportTests
```

After changing a Swift component, change its web version too: `src/styles.css`, its `.tsx`, its `meta.mjs` entry and,
if its look changed, `.design-sync/previews/<Name>.tsx`.

Then rebuild and re-sync.

```bash
cd DesignSystemWeb && npm run build
```

Then run `/design-sync` from `DesignSystemWeb`. A re-sync re-verifies only the components that changed. Read
`.design-sync/NOTES.md` first. It notes that the render check runs on the installed Chrome (`DS_CHROMIUM_PATH`).

## Differences from the app

- **Type:** JetBrains Mono, with its ligatures, for all text (the user's choice for designs). The app draws SF,
  which Apple's license doesn't allow shipping.
- **Glass:** `backdrop-filter`, with no grain (`noise`). It falls back to the role's `fallback` colour where backdrop
  filters are missing.
- **Shadows:** a Swift shadow's radius is the Gaussian's standard deviation, so a CSS blur is twice it.
- **`KindBadge`:** radius 4, as `ListRow.swift` draws it, not the `xs` radius of 3 that the docs give badges.
- **The `presentation` spring:** sampled into a CSS `linear()` easing that lasts until it settles, 650 ms.
