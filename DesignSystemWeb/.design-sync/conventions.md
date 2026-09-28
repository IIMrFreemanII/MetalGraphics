# Building with MetalGraphics Frosted Glass

A macOS-style design system: frosted glass, light and dark, JetBrains Mono (with its ligatures) throughout,
macOS sizes. Components are `window.MG.*`.

## Wrap everything in `MGRoot`

`MGRoot` picks the appearance and sets the font, its ligatures and the label colour. Outside it, text falls
back to the browser's font and colour, and dark mode follows the viewer's OS instead of the design.

```jsx
<MG.MGRoot mode="light" surface="window">…</MG.MGRoot>   // mode: "light" | "dark" | "system"
```

`surface` paints the opaque background: `"content"` (editors, lists), `"grouped"` (settings: use with
`Form`), `"window"` (window chrome), `"card"`, or `"none"`. Draw every screen in light and in dark: render it
twice, once with `mode="light"` and once with `mode="dark"`.

## Style with the tokens, never literal colours

Every colour is a role variable that has one value in light and another in dark. Use them for your own layout
glue:

- Text: `--mg-color-label`, `--mg-color-secondary-label`, `--mg-color-tertiary-label`
- Tints: `--mg-color-accent`, `--mg-color-destructive`, `--mg-color-warning`, `--mg-color-success`
- Lines: `--mg-color-separator` (hairlines, 0.5px), `--mg-color-border`
- Fills and states: `--mg-color-fill`, `--mg-color-hover`, `--mg-color-selection`
- Surfaces text sits on: `--mg-color-content-background`, `--mg-color-grouped-background`, `--mg-color-card`,
  `--mg-color-window-background`
- Chrome: `--mg-color-sidebar-tint`, `--mg-color-bar-tint`
- Palette: `--mg-hue-blue` … `--mg-hue-gray`, `--mg-hue-folder`

Type is the `font` shorthand: `font: var(--mg-font-body)` (13), `--mg-font-callout` (12),
`--mg-font-headline` (13 semibold), `--mg-font-title` (22 bold), `--mg-font-subheadline` (11),
`--mg-font-footnote` (10), `--mg-font-mono` (code).

Spacing and radii: `--mg-space-xs` (6) through `--mg-space-xl` (20); `--mg-radius-sm` (5, rows and menu items),
`--mg-radius-md` (6, buttons and fields), `--mg-radius-lg` (10, cards and popovers), `--mg-radius-xl` (12,
sheets). Shadows: `--mg-shadow-popover`, `--mg-shadow-sheet`.

What text sits on is opaque. Glass is only for overlays and chrome: `Popover`, `Menu`, `Sheet`, `Alert`,
`Tooltip`, or `Glass role="floatingPanel"`, and only over something to blur.

## Where the truth lives

`styles.css` imports `_ds_bundle.css`, which holds every token (`--mg-*`, light then dark) followed by the
component classes. Each component's `.prompt.md` gives its props and what it mirrors in the Swift app.

## Example

```jsx
<MG.MGRoot mode="light" surface="grouped">
  <MG.Form>
    <MG.Section header="Editor" footer="Applies to every open file.">
      <MG.FormRow label="Show line numbers"><MG.Toggle defaultOn label="Show line numbers" /></MG.FormRow>
      <MG.FormRow label="Indent with">
        <MG.Picker pickerStyle="segmented" options={["Spaces", "Tabs"]} label="Indent with" />
      </MG.FormRow>
    </MG.Section>
  </MG.Form>
  <div style={{ display: "flex", justifyContent: "flex-end", gap: 8, padding: "0 20px 20px" }}>
    <MG.Button variant="bordered">Cancel</MG.Button>
    <MG.Button variant="prominent">Save</MG.Button>
  </div>
</MG.MGRoot>
```

Frame a screen in `Window`. Pick its bar:
- `bar="unified"` puts a 52pt toolbar in the title row;
- `bar="dock"` gives a 40pt tab row;
- `bar="title"` is a plain title;
- `bar="none"` lets a `Sidebar` run under the traffic lights (give it `paddingTop: 36`).

Never draw traffic lights by hand; use `Window`, `TitleBar` or `TrafficLights`.

For code:
- Use `CodeEditor`. `lines` holds `spans` with a `token` (keyword, type, function, string, number, comment,
  variable…); `currentLine`, `caret`, `selections`, `matches` and `squiggles` are ranges in characters.
- Its colours are the `--mg-editor-*` and `--mg-syntax-*` variables.
- Put `FindBar` above it and `StatusBar` below it. Completion goes in `CompletionList`, and problems are
  `ListRow` with `status` and `subtitle` at `height={38}`.

Forms take `ColorPicker` and `DatePicker` rows. Docking adds `FloatingPanel`, `DropMarkers` and `DropPreview`.
Alerts order their actions by `role` (cancel, destructive) and stack beyond two; `ConfirmationDialog` always stacks.

Lists use `ListRow` (with a `KindBadge` or `Icon` before the label). Tabs use `DockTabBar`
(`tabStyle="document"` for files, `"panel"` for tool panels). Navigation uses `Sidebar` + `SidebarLink` and
`NavigationBar`.
