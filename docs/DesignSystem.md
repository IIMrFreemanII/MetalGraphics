# Design system: frosted glass

One theme for MetalGraphicsLib, the Demo and the Editor, in light and dark, following the
system appearance. Window chrome lets the desktop through, blurred by macOS; popovers, menus,
sheets, tooltips and floating dock panels are the library's own glass over the app; what text
sits on is opaque. The visual reference is the design canvas "MetalGraphics Frosted Glass".

Code: `Sources/MetalGraphicsLib/RetainedModeUI/Theme/` (`Theme.swift`, `Theme+Presets.swift`,
`ThemeStore.swift`, `AppearanceObserver.swift`).

## Elevation

Bottom to top:

| Level | What | How it is drawn |
|---|---|---|
| Desktop | behind a translucent window | the system's `NSVisualEffectView` (`.sidebar`), one per window |
| Chrome | sidebars, bars, tab bars, dock gaps | `.sidebarTint`, `.barTint`, `.gapTint`: translucent tints over the system blur |
| Content | code, console, forms, pages | opaque: `.contentBackground`, `.groupedBackground`, `.card` |
| Popover, menu | completion, pickers, `.popover` | `.glass(.popover)` / `.menu`: in-app blur, tint gradient, rim, `shadow` |
| Sheet, alert | modals, quick open | `.glass(.sheet)` over `.scrim` |
| Tooltip | hover info | `.glass(.tooltip)`, nearly opaque |

## Tokens

A `Theme` (`Theme.light`, `Theme.dark`) holds:

- `colors`: one colour per `ThemeColor` role. Labels are alpha-based (`label` is black or white
  at 85%) so they read on glass.
  - Text: `label`, `secondaryLabel`, `tertiaryLabel`, `placeholder`.
  - Tints: `accent` (#007AFF / #0A84FF), `accentForeground`, `destructive`, `warning`, `success`, `info`.
  - Lines: `separator`, `border`, `focusRing`.
  - Controls: `fill`, `fillHover`, `fillPressed`, `controlBackground`, `controlButton`,
    `segmentSelected`, `controlKnob`.
  - Interaction: `hover`, `pressed`, `selection` (every selected row), `selectionInactive`, `selectedTab`.
  - Surfaces: `contentBackground`, `groupedBackground`, `card`, `windowBackground`.
  - Chrome: `sidebarTint`, `barTint`, `barOverContent`, `gapTint`.
  - Overlays: `scrim`, `scrollIndicator`, `shadow`.
- `palette`: hues for badges and swatches.
- `materials`: a `GlassMaterial` per `ThemeMaterial` (`popover`, `menu`, `tooltip`, `sheet`,
  `floatingPanel`, `dropMarker`, `bar`).
- `typography`: JetBrains Mono throughout, with its ligatures, as the design canvas and the web
  mirror draw it. largeTitle 26, title 22, title2 17, title3 15, headline 13 semibold, body 13,
  callout 12, subheadline 11, footnote 10, mono 12.5. The same in light and dark, so switching
  appearance never lays anything out.
- **Type.** `.system` fonts and the text styles draw in JetBrains Mono, which the library
  bundles (`Resources/Fonts`, SIL OFL 1.1) in four weights: regular, medium, semibold and bold;
  lighter weights draw regular and heavier bold. It keeps SF's line box, its glyphs centred in
  it as the web's `line-height` places them, so rows, buttons and fields keep their heights;
  only the widths of text change. `.rounded` and `.serif` stay SF's, and
  `TextFont.systemFamily = .sanFrancisco`, set before the first window, makes `.system` SF.
- `spacing` (2 to 32), `radii` (xs 3 badges, sm 5 rows, md 6 buttons and fields, lg 10 cards
  and popovers, xl 12 sheets), `shadows`, `motion`.
- `editor`: the `EditorTheme` a `TextEditor` shows unless it was given one.

## Using it

**Roles as colours.** A role is a `float4` (`float4.role(.secondaryLabel)`, or by name:
`.secondaryLabel`), so anything that takes a colour takes one, reactive setters included:

```swift
Text("Build succeeded").foregroundStyle(.secondaryLabel)
row.background(self.selected ? .selection : .clear, in: .rect(cornerRadius: 5))
Rectangle(.separator).frame(height: 0.5)
```

A role is resolved when drawn (`Graphics2D.resolve`), so it follows the appearance with nothing
rebuilt. It carries its own alpha (`.accent.withAlpha(0.18)`); an opacity scales it as any alpha.
Colour arithmetic needs a plain colour: `renderer.resolve(color)` in drawing code,
`Theme.current.resolve(color)` elsewhere. Between two roles a colour animates through what they
are in the current theme, then lands on the role.

**Palette hues as colours.** `.hue(.teal)`, `.hue(.badgeStruct)`, `.hue(.folder)`: a
`ThemePalette` entry, resolved when drawn like a role, for colours told apart by hue alone.

**Glass by role.** `.glass(.popover, in: .rect(cornerRadius: 10))` draws the theme's material.

**Drawing code** reads `renderer.theme`. **Building code** (an `init`) reads `Theme.current`,
this thread's window's theme; only use it for what does not differ between light and dark
(type, radii, spacing).

**More than colours.** An element that keeps more of the theme conforms to `ThemeObserving` and
registers with `UIContext.addThemeObserver` on mount (see `TextEditor`).

**Custom themes.** `ThemeStore.shared.setThemes(light: Theme.light.with { $0.colors[.accent] = ... }, dark: ...)`.
`ThemeStore.shared.appearanceOverride = .dark` forces an appearance.

**In components.** `@Bindable let themes: ThemeStore = .shared` reads the theme reactively.

**A subtree in another appearance.** `.colorScheme(.dark)` draws an element and everything in it
with the store's dark theme whatever its window shows; `.theme(_:)` with a theme of its own
(`ThemeScopeElement`). The render loop carries the nearest scope per drawn element and swaps the
renderer's theme where one starts or ends, so nothing is rebuilt; popovers shown from inside a
scope, shadows, text editors and role animations take its theme too. A window without scopes pays
nothing per frame. What is read from `Theme.current` while building (type, metrics) stays the
window's, so a scope's theme should share its typography, as light and dark do; a presentation in
a window of its own does not inherit a scope. The Storybook's side by side is two scopes.

## Components

The shapes the design canvas draws, in the library. Each has a story in the Storybook
(`swift run Storybook`, `docs/Storybook.md`), with the same props as its web version:

- **`ListRow`**: every row of a sidebar, tree, outline, problems list, quick open or completion
  list. A fixed height (24 by default), inset 8 from the sides, a rounded `.hover` highlight
  and a `.selection` one with the label medium weight; `selectionStyle: .prominent` fills with
  the accent instead (completion, quick open). Hover is tracked by the row and only redraws.
- **`KindBadge("S", color: .hue(.badgeStruct))`**: a symbol's kind, 16 pt, white letter.
- **`Image(icon: .folder)`**: the design's glyphs (`ThemeIcon`: chevrons, folder, document,
  magnifier, cross, up-down arrows, check), SVGs baked once into the atlas and tinted like text.
- **`AnimatedIcon(.folder)`**: the 63 animated glyphs (`AnimatedGlyph`) of the Claude Design
  template "Animated icons": its 56 (chevrons, folder, document, trash, bell, lock, eye,
  play/pause, sort, splits, sidebars, the Swift and file-type documents, language badges…) and
  seven in its manner (calendar, clock, color, slider, toggle, code, dock). Each is its own box,
  the static `ThemeIcon`'s size at `.scale(1)` (`.iconSize(n)` fits the longer side to n). Its
  host (the nearest `HittableView`: a `ListRow`, a `Button`, any `.onHover`) plays it as the
  template's host does: a one-shot as the pointer enters, a pose held while it stays, a squash
  while pressed (a host that takes no press itself, a row tapped on mouse down, still tells its
  icons the button is down: `HittableView.isPointerDown`). `active: Bool?` holds a state (nil for none: the checkmark drawn, sort
  unsorted); `loop` repeats a motion; `mount` plays an entrance, `replay` again. Each glyph is
  its markup and CSS as the template writes them (`AnimatedGlyph+Template.swift`), read by
  `AnimatedGlyphStyle` and evaluated as a browser would: matching rules, transitions (the
  template's spring, `spring(210, .38)`, settling in 1.338 s), keyframe animations over them;
  the same source is exported to `DesignSystemWeb/generated/animated-icons.json`. Shapes are
  baked once per window and shared; a part moves by its vector item's transform. It draws only
  while something moves; loops and the spinner step on timed wakes at 30 Hz. Caps and joins are
  round, as every vector stroke here is; the web draws the template's butt caps and miters. The
  components draw their glyphs with it: `DisclosureGroup`'s chevron (`.chevronRight` turned),
  `Picker`'s arrows and checks (and `Menu`'s items'), `Stepper`'s keys (`.stepperMinus`,
  `.stepperPlus`, active at the end of the range), `TextField.leadingIcon`, `SidebarLink`'s icon,
  `FindBar`'s and `CalendarView`'s ‹ ›, a menu button's ⌄, a dock tab's document and close cross,
  and the code editor's fold marks (`AnimatedIcon.draw`, without motion). A `ThemeIcon` maps to
  the glyph of the same name.
- **Buttons** fill `.fillHover`/`.hover` while hovered and `.fillPressed` while pressed;
  prominent ones lighten and darken their tint.
- **Forms** are a column at most 600 wide, centred, of outlined cards; section headers are 12 pt
  semibold, footers 11 pt; a labelled text field in a row is 240 wide at its trailing edge.
  `.navigationBackground(.groupedBackground)` draws a page on the grouped background edge to edge.
- **A text field** can show an icon before its text: `.leadingIcon(.magnifier)`.
- **A menu picker** ends in an accent tile with up-down arrows.
- **Dock tabs** come in two styles, `.panel` and `.document` (`docs/Docking.md`, Tabs).
- **The code editor** of the theme is JetBrains Mono 12.5 on 20 pt lines with a 52 pt gutter
  (`EditorTheme.lineHeight`, `.minGutterWidth`).
- **`ListRow(label, subtitle:, detail:, status:)`**: a row with its label, a second line in the
  secondary colour, a detail at the trailing edge and a severity square (`ListRowStatus`); the
  Problems list's 38 pt rows. `KindBadge.color(forLetter:)` gives a kind's hue.
- **Editor chrome** (`TextEditor/Chrome/`): `FindBar` (query, count, ‹ ›, `ToggleChip` Aa / Word /
  .*, replace, Done; controlled like a text field), `CompletionList` (`CompletionItem` rows on
  menu glass with the selected one's detail), `StatusBar` (24 pt: position, problem, file). The
  Editor's file tab is built from them.
- **Surfaces** (`Presentation/`): `Tooltip` (one line, or `multiline` a 420 pt hover card) and
  `.help(_:)`, which shows one after a 0.6 s rest; `Menu`, `MenuItem`, `MenuSeparator`,
  `MenuPanel` and `.contextMenu { }` (a right click); `Popover`, `Sheet`, `SheetLayout`, `Alert`
  (`AlertLayout`) and `ConfirmationDialog` shown in place, on the cards the presentations use
  (`CardChrome`); `Scrim`.
- **Pickers**: `ColorWell`, `ColorPickerPanel`, `CalendarView` and `TimePanel`, what a
  `ColorPicker` and a `DatePicker` open; `Picker.menuIndicator(.hidden)` for a pill.
- **Navigation**: `Sidebar(title:)`, `SidebarTitle`, `SidebarLink`, `NavigationBar` in place, and
  `.toolbar(leading:trailing:)` for a page's items in its stack's bar, in the title bar's row
  when the bar is at the window's top.
- **Window and docking chrome** (`Docking/DockChrome.swift`): `TrafficLights`, `TitleBar`,
  `FloatingPanel`, `DropMarkers`, `DropPreview`, `DockTab`, `DockTabBar`, `DockGap`, drawn by the
  pieces a `DockArea` uses.
- **Lists**: `InsertionLine` (a reorder's 2 pt capsule), `ScrollIndicator`.
- **Debug**: `.layoutOutline()` frames everything laid out; `ElementInspector.snapshot(of:)` lists
  a tree's elements with their frames.

## Building new UI

Start from the canvas board it belongs on and the components above; `.claude/skills/design-system/SKILL.md`
is the checklist. Reuse a library component before writing one; a shape the design system has
and the library lacks goes into the library, with a story in the Storybook. Colours are roles or
palette hues, never written out: `DesignLintTests` reads `Sources/MetalGraphicsLib/RetainedModeUI`,
`Sources/Editor`, `Sources/Storybook` and `Sources/Demo` and fails on an RGB
or hex literal, or on `.white`/`.black`/`.red`… passed as a colour in the library or the Editor.
The token files (`Theme/`, `EditorTheme.swift`) are exempt, and a deliberate exception keeps its
literal with `// design: <reason>` on the same line (the traffic lights in `DockViews.swift`, a
`ColorPicker`'s starting value). A missing token is added to `Theme.light` and `Theme.dark`
both, and to Tokens above.

## Switching appearance

The main thread observes `NSApp.effectiveAppearance` (`AppearanceObserver`, started with the
first window) and writes it to `ThemeStore.shared`. Each window hears of it once, on its own
thread (`ThemeSubscriber`, subscribed before its tree is built), and calls
`UIContext.setTheme`. That invalidates `.render` only, tells the `ThemeObserving` elements, and
the next frame shades every pixel once. Then the window goes idle again.

Headless: `HeadlessApp` starts in light whatever the machine's appearance is;
`app.setAppearance(.dark)` switches it. `UIHarness` tests call `h.context.setTheme(.dark)`.

## Window chrome

`RetainedScene(..., chrome: .translucent)` (both apps use it): a transparent title bar
(`fullSizeContentView`, hidden title), a non-opaque `CAMetalLayer`, one `NSVisualEffectView`
filling the window under the content, and `Graphics2D.background = .clear`. Detached dock
windows are translucent too; a popover in a window of its own is the system's `.popover`
material, rounded.

**Content under the title bar.** The tree fills the window, title bar included, as the canvas
draws it: a sidebar runs to the top with the traffic lights on it, and the top bar shares the
title bar's row.

- `RetainedLayerView` measures `TitleBarInsets(top:leading:)` (the title bar's height, and past
  the traffic lights) on the main thread when the window is set up, resized, or enters or leaves
  full screen (zero then), and posts it like the size. `UIContext.setTitleBar` lays out again.
- Layout reads `TitleBarInsets.current`. `NavigationSidebar` starts its content 52 down; a
  `NavigationBar` at the window's top is 52 tall and keeps clear of the traffic lights; a dock
  area's top groups take the row (`docs/Docking.md`, Tabs). An element sizes from where it was
  last placed and lays out once more if that changed (`TitleBarPlacement`).
- **Dragging the window.** Those views report the row's empty parts with
  `TitleBarInsets.addDragRegion` during layout. After a layout that changes them they reach the
  main thread (`WindowHandle.titleBarDragRegions`), and `RetainedLayerView.mouseDown` drags the
  window from there (`performDrag`), or zooms it on a double click; the tree never hears of that
  press. Everything else in the row takes clicks as usual.
- A headless translucent window has `TitleBarInsets.standard` (32, 78); `HeadlessWindow` counts
  presses on the drag regions (`titleBarPresses`).

- A dock panel kind says what its content sits on: `DockPanelKind(..., background: .sidebarTint)`
  for a navigator or an outline; the default is the opaque `.contentBackground`.
- A headless window draws opaque, on `.windowBackground`, so snapshots do not depend on the desktop.
- Limits: AppKit vibrancy (text blended with the blur) is not reproduced; labels use alpha
  instead. In-app glass cannot see the desktop: where its backdrop is transparent it shows the
  material's `fallback`.

## Glass

`GlassMaterial`: `blurRadius`, `tint` and `tintBottom` (a vertical gradient), `saturation`,
`noise`, `rim` (a light inner edge, strongest at the top, `rimBottom` of it at the bottom),
`rimWidth`, `fallback`. Cost and caching: `docs/CompileTimeState.md`, Glass.

## Testing

Goldens are recorded in light. When a token changes, re-record with
`RECORD_SNAPSHOTS=1 swift test --filter <Class>` and look at every diff. `ThemeTests`,
`TranslucencyTests` and `GlassDamageTests` cover the theme, the transparent output, the rim and
fallback, and the backdrop cache; `AppearanceE2ETests` the switch across the app's windows;
`TitleBarTests` the title bar's row, `ListRow` and the form's column; `DockTabStyleTests` the
two tab styles, the close button on hover and a tab's decorations; `ThemeScopeTests` a subtree in
another appearance; `DesignComponentsTests`, `MenuAndSurfaceTests` and `DockChromeTests` the
components shown in place; `DesignLintTests` that no colour is written out. The Storybook's
`ComponentGoldenTests` keep a golden of every component, light and dark, and `ParityTests` check
that every web component has a Swift story. `AnimatedIconTests` cover the animated glyphs: every one at rest
and held active, the spring against the template's samples, hover, press, the three states,
draw-on and off, entrances, loops and the spinner on wakes, the eye following the pointer and
the play/pause morph.

## On the web (claude.ai/design)

`DesignSystemWeb/` is this system for Claude Design, synced to the "MetalGraphics Frosted Glass" design-system
project with `/design-sync`.

- **Tokens:** `DesignTokenExportTests` writes the theme to `DesignSystemWeb/generated/`: `tokens.json` (Design
  Tokens format), `tokens.css` (`--mg-color-<role>`, light and dark) and `icons.json`. It fails when those files
  are stale; re-record them with `RECORD_TOKENS=1 swift test --filter DesignTokenExportTests`.
- **Editor tokens:** the export also carries the code editor's `EditorTheme` as `--mg-editor-*` (surfaces, caret,
  selection, gutter, matches, diagnostics) and `--mg-syntax-*` (one per `TextToken`).
- **Components:** 53 React versions that mirror the Swift ones metric for metric. They include `MG.Button`,
  `MG.ListRow`, `MG.Form`, `MG.DockTabBar`, `MG.Popover`, the pickers (`MG.ColorPicker`, `MG.DatePicker`), window
  chrome (`MG.Window`, `MG.TrafficLights`), docking (`MG.FloatingPanel`, `MG.DropMarkers`) and the Editor's pieces
  (`MG.CodeEditor`, `MG.FindBar`, `MG.CompletionList`, `MG.StatusBar`). After changing a component here, change its
  web version too.
- **Type:** both draw JetBrains Mono, with its ligatures; the app keeps SF's line heights, as the
  web's `line-height` does.

See `DesignSystemWeb/README.md`.
