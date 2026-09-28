---
name: design-system
description: Frosted-glass design system checklist for MetalGraphics. Use before building or restyling any UI — a new element, control, panel, page, row, bar, popover or demo in MetalGraphicsLib, the Demo or the Editor — and when reviewing UI, so it uses the theme's roles, hues, type, radii and glass, reuses the existing components, matches the design canvas in light and dark, and is tested for it.
---

# The design system in MetalGraphics

One theme draws everything: frosted glass, light and dark, following the system. The visual
reference is the design canvas **"MetalGraphics Frosted Glass"**
(https://claude.ai/artifact/27FDcRBjxHEG9urVj5gKKV): an **Editor**, a **Demo** and a
**Components** board, each in light and dark. The tokens and how they reach the screen are in
`docs/DesignSystem.md`; read the section a rule points at when it applies.

## 1. Before writing: find the board and the component

- Find what you are building on the canvas (read it with the Artifact tool's `read` action) and
  note its sizes, states and colours. If it is not there, say so, and for a new component offer to
  draw it on the Components board first so the user can review it before it is built.
- Reuse before writing. Most UI is one of these:

  | You need | Use |
  |---|---|
  | a row in a sidebar, tree, outline, list, results, completion | `ListRow` (`Layout/ListRow.swift`); `.prominent` for a menu-like list |
  | a symbol kind's letter tile | `KindBadge("S", color: .hue(.badgeStruct))` |
  | a small glyph (chevron, folder, document, magnifier, cross, check) | `Image(icon:)` with a `ThemeIcon`; add a case there for a new one |
  | a button | `Button` with `.buttonStyle(.bordered / .borderedProminent / .borderless / .plain)`, never a tappable `Rectangle` |
  | a text field with an icon | `TextField(...).leadingIcon(.magnifier)` |
  | settings, a form | `Form` / `Section`: the 600 pt column, outlined cards, 240 pt fields |
  | a sidebar and a detail | `NavigationSplitView`; a page's background with `.navigationBackground(_:)` |
  | tabs of panels or documents | a `DockArea` with `DockPanelKind(..., tabStyle: .panel / .document)`; `setEdited`, `setBadge`, `setIcon` |
  | a popover, menu, tooltip, sheet, floating surface | `.glass(.popover / .menu / .tooltip / .sheet / .floatingPanel, in:)` |
  | code or styled text | `TextEditor`; its look is `Theme.editor` |

- A new shared shape goes into the library (`RetainedModeUI/`), not copied into each app, and
  gets a line in `docs/DesignSystem.md` ▸ Components.

## 2. Tokens only

- **Colours are roles or palette hues.** `.label`, `.secondaryLabel`, `.tertiaryLabel`,
  `.separator`, `.border`, `.fill`, `.hover`, `.pressed`, `.selection`, `.accent`,
  `.accentForeground`, `.destructive`, `.warning`, `.success`, `.contentBackground`,
  `.groupedBackground`, `.card`, `.sidebarTint`, `.barTint`, `.shadow`… (the full list is
  `ThemeColor` in `Theme/Theme.swift`). Colours told apart by hue alone — swatches, badges, file
  types, charts — are `.hue(.orange)` (`ThemeHue`). Never `float4(0.6, 0.6, 0.63, 1)`,
  `float4(hex:)` or `.white`/`.black` for UI. `DesignLintTests` fails on them.
- A role carries its alpha: `.accent.withAlpha(0.18)`. Colour arithmetic (mixing, brightening)
  needs the plain colour: `renderer.resolve(color)` in drawing code.
- A colour that is not a token on purpose (the macOS traffic lights, a `ColorPicker`'s value)
  keeps its literal with `// design: <reason>` on the same line.
- **Missing token?** Add it rather than a literal: a `ThemeColor` case or a `ThemePalette` hue
  in `Theme.swift`, with a value in **both** `Theme.light` and `Theme.dark`
  (`Theme+Presets.swift`), and a line in `docs/DesignSystem.md` ▸ Tokens. Take the value from the
  canvas's token objects, and add it there too if it is new.
- **Type** from `theme.typography` (`body` 13, `callout` 12, `subheadline` 11, `headline` 13
  semibold, `mono` 12.5…), **radii** from `theme.radii` (xs 3 badges, sm 5, md 6 rows, buttons,
  fields, lg 10 cards and popovers, xl 12 sheets), **spacing** from `theme.spacing`,
  **shadows** from `theme.shadows`, **motion** from `theme.motion` (hover 0.12 s ease-out).
  Build-time code reads `Theme.current`, and only for what is the same in light and dark;
  drawing code reads `renderer.theme`.

## 3. Sizes: the canvas's, as named constants

The numbers the boards use, already in the code — reuse them, and put a new one in the metrics
enum of its component, not as a literal in a view:

- rows 24 (lists) and 26 (sidebar links), inset 8 (10 in a sidebar), radius 6
- hairlines 0.5 pt in `.separator`; control borders 0.5 pt in `.border`
- bars: 30 (panel tabs), 40 (document tabs, the dock's title-bar row), 52 (a bar sharing the
  title bar), 38 (a navigation bar below the top), 24 (status bar), 34–36 (toolbars, find bar)
- sidebar 232 wide; form column ≤ 600, fields 240
- `NavigationMetrics`, `FormMetrics`, `DockTabMetrics`, `TitleBarInsets`, `ListRow`'s init.

## 4. States

- Everything interactive has the Components board's states: rest, **hover** (`.hover`, or
  `.fillHover` on a bordered control), **pressed** (`.pressed` / `.fillPressed`), **selected**
  (`.selection` with the label medium weight; `.accent` fill with `.accentForeground` text in a
  prominent list), **disabled**, and a **focus ring** (`.focusRing`) on what takes keys.
- Selected tabs and segments: `.selectedTab` / `.segmentSelected` with the `control` shadow.
- Hover and press only redraw: change a flag, invalidate `.render`, and skip the write when it
  is unchanged (performance skill §2). A weight change is a layout.
- Secondary text is `.secondaryLabel`, placeholder `.placeholder`, never a dimmed `.label`.

## 5. Light and dark, glass and the title bar

- Check both appearances. A role or hue is resolved when drawn, so an appearance switch
  rebuilds nothing; anything that keeps a resolved colour must be a `ThemeObserving` element.
- What text sits on is opaque (`.contentBackground`, `.groupedBackground`, `.card`); glass is for
  surfaces over content (§1 table) and chrome tints (`.sidebarTint`, `.barTint`).
- In a translucent window the tree runs under the title bar. Anything that can sit at the
  window's top makes room for it and marks its empty parts draggable: read
  `TitleBarInsets.current`, use `TitleBarPlacement`, call `TitleBarInsets.addDragRegion`
  (docs/DesignSystem.md ▸ Window chrome).

## 6. Verify

- A `UIHarness` test for the sizes and states that matter (see `TitleBarTests`,
  `DockTabStyleTests`), and a golden in light and in dark (`h.context.setTheme(.dark)`) — the
  `ui-tests` skill.
- `swift test --filter DesignLintTests` passes (the full suite runs it too).
- For a visible change, a screenshot of the real app (`drive-app` skill) in light and dark, next
  to the board.

## 7. Before finishing

State in the summary:

- which board (and part of it) the change matches, or that it has none yet;
- the components and tokens it reused, and any token or component it added (in both
  appearances, and in `docs/DesignSystem.md`);
- any deliberate departure from the canvas, and why;
- whether the canvas should be updated to match (offer it; do not change it unasked).
