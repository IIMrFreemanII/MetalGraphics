# Storybook

`swift run Storybook` opens a gallery of every design-system component, as Storybook is for the
web: each component's stories, the args they are drawn with, controls to edit them live, the
callbacks they make, the Swift for them, their element tree, and play functions that drive them.
It is an executable target on the library (`Sources/Storybook`), tested headlessly
(`Tests/StorybookTests`).

## The window

- **Sidebar**: the components by the design system's groups (Foundations, Controls, Pickers,
  Lists, Forms, Surfaces, Navigation, Docking, Window, Editor). A component's row opens and closes
  its stories; the search keeps the components and stories whose names have it.
- **Toolbar**, in the title bar's row, with the story's name between its items:
  - Canvas or Docs.
  - Auto (the window's appearance), Light, Dark, or Both: light and dark side by side, each a
    `.colorScheme` scope.
  - The background: content, grouped, window, card, or a wallpaper for glass to blur.
  - The width: fit, or 320 to 1024.
  - The zoom, 50–200 %. Zoomed, the story is drawn scaled and takes no input, since hit testing
    works on the layout.
  - Outline: a hairline round everything laid out (`.layoutOutline()`).
  - Reset: back to the story's own args.
- **Dock area**: the canvas over the addon panels, tabbed at the bottom. They can be moved,
  split or torn out into windows of their own, as any `DockArea`'s, and the layout is kept.
  - **Controls**: a form made from the component's arg types (text, a list, a toggle, a number, an
    option, a date, a colour). An edit redraws the story.
  - **Actions**: what the story's callbacks reported, newest first, up to 200.
  - **Source**: the Swift that makes the story with its args, highlighted by `SwiftStyler`.
  - **Inspector**: the story's elements with their types, texts and frames.
  - **Interactions**: the story's play function, each step passed or why it failed, and Run.
- **Docs**: the component's summary, its file, a props table, and every story in light and dark
  with its Swift.

The story, the canvas settings and each story's edited args are kept in the window's storage,
so a relaunch or a hot reload opens where it was.

### Keys

| Keys | |
|---|---|
| ⌥⌘↓ ⌥⌘↑ | Next and previous story |
| ⌘1 ⌘2 | Canvas, Docs |
| ⇧⌘L | Next appearance |
| ⌘= ⌘- ⌘0 | Zoom in, out, actual size |
| ⌥⌘O | Outline |
| ⌥⌘R | Reset args |
| ⌘K | Clear actions |

## Writing a story

A component's stories are one `ComponentStories` value in its group's file under
`Sources/Storybook/Stories`, listed in `StoryRegistry.catalog()`:

```swift
static let toggleChip = ComponentStories(
  .controls, "ToggleChip", summary: "A small on/off chip: a find bar's Aa, Word, .* options.",
  source: "Sources/MetalGraphicsLib/RetainedModeUI/Form/ToggleChip.swift",
  args: [
    ArgType("title", .text, .text("Aa"), "Its label."),
    ArgType("isOn", .bool, .bool(true), "On or off: a binding."),
  ],
  stories: [
    Story("On", play: [.click("Aa"), .expectArg("isOn", .bool(false))]),
    Story("Off", ["isOn": .bool(false)]),
  ],
  render: { args, context in ToggleChip(args.string("title"), isOn: context.bool("isOn")) },
  snippet: { args in "ToggleChip(\(swiftString(args.string("title"))), isOn: $caseSensitive)" }
)
```

- **Arg types** name each prop, its control, its default and what it does: the Controls panel and
  the Docs table are made from them.
- **Stories** name a state: the args they change, how they sit on the canvas (`.centered`,
  `.padded`, `.fullscreen`), and optionally a play function.
- **`render`** builds the component from the args. `context.action("tapped")` makes a callback
  that logs to Actions. `context.bool("isOn")` (and `text`, `number`, `option`, `date`,
  `color`) is a two-way binding: what the component writes goes back to the args and shows in
  Controls, without redrawing the story.
- **`snippet`** is the Swift the story stands for, in the Source panel and the Docs.
- **`web:`** names the component in `DesignSystemWeb/meta.mjs`, when that name is not its own.

A play function's steps are `.click(label)` and `.hover(label)`, which send the window's own
pointer events to the middle of the story's text `label`; and `.expect(text)`,
`.expectArg(name, value)` and `.expectAction(name)`, which check what the story shows, wrote back
and reported. A failure stops the run.

Stories draw with fixed values (`StoryFixtures`: a date, and `CalendarView`'s today), so their
goldens never follow the wall clock.

## Tests

- `StorybookSmokeTests`: every story builds and lays out, in light and in dark.
- `StorybookE2ETests` drives the window:
  - the sidebar and the search;
  - editing a control; a story writing its args back; Actions and Source;
  - side by side, Docs and the Inspector;
  - play functions, and a relaunch.
- `ComponentGoldenTests`: every component's first story, light and dark, cropped to the story.
  Re-record with `RECORD_SNAPSHOTS=1 swift test --filter ComponentGoldenTests` and look at each
  diff.
- `ParityTests`: every component in `DesignSystemWeb/meta.mjs` has a story here, every story's
  file exists, and stories set only their component's args.

## Costs

The Storybook rebuilds one story's subtree per edit or story picked, two side by side, never per
frame. The panels rebuild when what they show changes, once per burst of model writes. The
Inspector reads the tree after that layout. With nothing changing the window goes idle; a
resting `.help` is timed by a wake, not an animation.
