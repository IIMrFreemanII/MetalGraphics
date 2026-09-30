# design-sync notes: MetalGraphics Frosted Glass

- **Run from `DesignSystemWeb/`.** This is the config home; the package is `@metalgraphics/frosted-glass`, global `MG`.
- **Build first:** `npm run build`. It writes `dist/index.js` (react external), `dist/types/` (tsc) and `dist/styles.css`
  (`generated/tokens.css` + `src/styles.css`, which is `cfg.cssEntry`), plus `docs/<Name>.md` from `meta.mjs`.
  `docs/` is `cfg.docsDir`; each doc's `category` front matter sets the component's group.
- **Tokens come from Swift.** `generated/*` is written by `DesignTokenExportTests` in the repo root. After a theme
  change: `RECORD_TOKENS=1 swift test --filter DesignTokenExportTests`, then `npm run build`, then re-sync.
- **Font:** the user chose JetBrains Mono, with ligatures (`--mg-font-features`), for all web text. The Swift app
  keeps SF. The font ships from `@fontsource/jetbrains-mono` (OFL) via `cfg.extraFonts`, weights 400 to 700.
  SF Pro can't ship (Apple license), so don't reintroduce it into the web stacks.
- **Render check / capture browser:** no Playwright browser cache on this Mac. Playwright is installed in `.ds-sync`
  with `PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1`, and validate/capture run with
  `DS_CHROMIUM_PATH="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"`.
- **Previews:** every preview draws its cells twice, light beside dark, through a local `Both` helper. So every
  component is `cardMode: "column"` in `cfg.overrides`; grid cells crop the pair.
- **Don't name files in `src/` after components** (the old `src/previews/Toggle.tsx`, etc.). The converter's
  fuzzy source-match picked them up as component sources and grouped them as "previews".
- **Doc examples are JSX** (`meta.mjs` `jsx`). The design agent writes React; canvas `x-import` markup doesn't belong there.
- **Guidelines:** `guidelinesGlob` points at a missing `guides/`. The default (`docs/*.md`) would duplicate every component
  doc as a guideline.

## Known render warns

None at the first sync.

## Re-sync risks

- `DockTabBar`'s Document cell shows two tabs. Three monospace titles overflow the half-width cell. Keep titles
  short if you edit it.
- Component metrics are copied by hand from the Swift sources (`src/styles.css` names each one). A Swift component
  change does not fail any test here, only a token change does. Re-check the matching web component after
  changing one in Swift.
- `generated/animated-icons.json` is the template's glyphs (markup, CSS, keyframes, the spring as `linear()`), from
  the Swift `AnimatedGlyph+Template.swift`; `AnimatedIcon` (`src/components/motion.tsx`) injects the CSS once and
  drives each svg's `data-*` flags as the template's `<mg-anim-icon>` does. A new glyph is a Swift case plus its
  source, re-recorded, then the `AnimatedGlyphName` union. The template's own script is kept in
  `.design-sync/reference/mg-anim-icons.js` to diff against when the Claude Design template changes.
- `generated/icons.json` must keep the nine `ThemeIcon` names. The `IconName` union in `src/components/foundation.tsx`
  fails to compile when they drift.
- The Design System artifact (https://claude.ai/artifact/MxLvtzovjjZmjCcsg5ntF7) is a copy built by
  `node artifact.mjs` from `ds-bundle/`, and the canvas (https://claude.ai/artifact/27FDcRBjxHEG9urVj5gKKV)
  holds a copy of that under `project/ds/mg/`. After a re-sync, rebuild and republish the artifact, then
  re-install it on the canvas, or both keep the old bundle.
- The Claude Design project was uploaded before `tokens.css` learned `[data-theme="dark"]`. The next re-sync
  uploads that change; nothing in the project depends on it.
- The editor pieces (CodeEditor, FindBar, CompletionList, StatusBar) mirror `Sources/Editor` too, not only the
  library. A change to `FileEditorPanel.swift` or `LanguageAssist.swift` needs its web version checked.
- CodeEditor positions selections, matches, squiggles and the caret in `ch` units. That only holds while the editor font
  is monospaced (JetBrains Mono); a proportional editor font would misplace them.
- Alert's automatic default (the first action without a role is prominent) applies only when no action sets a
  `variant`. Actions with explicit variants keep the old behaviour, so earlier mocks don't change.
- Wide components (FindBar, Window, CodeEditor, CompletionList) stack light above dark in their previews. The full
  FindBar with replace is about 700 wide, so its preview is scaled to 90%.
- `ColorPicker` / `DatePicker` carry their own label row (`mg-labeled`). Inside a `FormRow` they don't stretch (a canvas `x-import`'s `style` only reaches the slot), so in forms write `FormRow label="Due"` around a label-less `DatePicker`, or around a `ColorWell`.
