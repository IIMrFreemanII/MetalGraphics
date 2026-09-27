# Docking

Panels that dock, split, tab and float inside a window, and become windows of their own when
dragged out of it. Windows made that way dock back into any window the same way, and into each
other. The code is in `RetainedModeUI/Docking/`; the app's Workspace window
(`Sources/Demo/DockingDemo.swift`) uses all of it.

```swift
static let space = DockSpace(name: "workspace", kinds: [
  DockPanelKind("notes", title: "Notes") { panel in NotesPanel(panel: panel) },
  …
]) {
  var layout = DockLayout()
  let notes = layout.addPanel(kind: "notes", title: "Notes")
  layout.hosts = [DockHost(id: "main", root: .row([.group([notes]), …]))]
  return layout
}

RetainedWindow("Workspace", id: "workspace") { _ in DockArea(space, host: "main") }
DockWindows.manage(space)   // once, at launch: opens the panels' own windows
```

## The model

- **`DockLayout`** is a value: every host, what is docked in it, what floats over it, and each
  panel's kind, title and storage.
  - A **host** is one dock area: `DockArea(space, host:)` placed by the app, or a *detached* host
    with a window of its own.
  - Its docked content is a tree of splits (`DockNode.row`/`.column`, with fractions) whose leaves
    are tab groups (`DockNode.group`).
  - Floats (`DockFloat`) are more such trees, each at a frame over the docked content.
- Every change is `move(source, to: target)` or a small edit (`close`, `select`, `setFractions`,
  `setFrame`), then `normalize`:
  - no empty groups;
  - no split of one;
  - no split directly inside a split of the same axis;
  - no empty detached host.

  Sources and targets:

  | Source | What moves |
  |---|---|
  | `.panel` | one panel, out of its group |
  | `.node` | a group or a split, with all it holds |
  | `.host` | a whole window's content |

  | Target | Where it goes |
  |---|---|
  | a group's middle | joins as tabs |
  | a group's edge | splits it |
  | a host's edge | docks along the whole content |
  | a float | over a host |
  | a new detached host | a new window |
- **`DockSpace`** holds the layout, shared by every window's thread and the main thread under one
  lock.
  - A commit moves its generation on, and reaches each area as a `@Model` write does: the
    writer's window at once, every other window on its next turn.
  - It saves the layout to `UserDefaults` (`Dock.<name>`), once per burst of commits, and loads
    it when made.
  - `DockSpace.saveAllNow()` runs at quit, after the trees unmounted.
- **`DockPanel`** is a panel as one window shows it, handed to its kind's `make`.
  - Its `storage` is a `UISceneStorage` kept in the layout, so it follows the panel to every window
    and across relaunches.
  - Unlike a window's scene storage, it does not share values with other panels of its kind.

## Changing the layout from code

`DockSpace` has a method for each everyday change (`move`, `close`, `select`, `open`, …). For
anything else, `update { layout in … }` edits the layout as one commit, then normalizes it.
`DockLayout.place(_:at:)` puts new panels at any target, as a drop there would. The Editor app
opens a file this way, as a tab in the group holding the other files:

```swift
space.update { layout in
  let id = layout.addPanel(kind: "file", title: "main.swift")
  layout.panels[id]?.storage = encoded          // UISceneStorage(...).encoded, with the path
  layout.place(.group([id]), at: .node(filesGroup, .center))
}
```

A panel can refuse to close from its tab: `panel.shouldClose` is asked first, on the panel's
window thread, and returning false keeps it open while the panel asks the user itself (an
unsaved document's alert). `panel.close()` from code, and closing a detached window, do not ask.

## What survives a move

- **Within a window**, a panel keeps its element: the area's reconcile finds it by id and moves it,
  and a component's `@State` stays. Unselected tabs are kept too, unmounted.
- **To another window**, the panel's tree cannot follow: trees belong to their window's thread
  (`Threading.md`). The target window makes it anew from its kind. What must survive goes in
  `panel.storage`, or in a shared `@Model`. The Notes panel saves its text on unmount, which is
  when it leaves a window.

## What runs where

| | Where |
|---|---|
| Building a host's elements from the layout (`DockArea.reconcile`) | the area's window thread, on each commit |
| Picking up, moving a float, drop markers, sashes, resizing | the area's window thread; nothing shared is written until the drag ends |
| Opening, closing, styling, hiding detached windows (`DockWindows`) | main, on each commit and when a window the app placed opens or closes |
| Dragging a window (tear-out, moving a detached window, docking it) | main: the view that took the mouse down (the window, for a native title bar) keeps getting the drags and moves the window itself |

- **Pick-up.** A press on a tab, a group's bar, a float's grip or the custom look's title bar hands
  itself to the area (`HittableGrid2D.handOffPress`). Undocking then rebuilds the tab elsewhere
  without losing the press.
- **Moving a float.** The float is drawn at the pointer by an offset (`DockFloatView.dragOrigin`),
  so a move only redraws. It is laid out there once the drag commits.
- **Tear-out.** Out of the window, the float becomes a detached host (`.newHost`), and the area
  asks main to open its window under the pointer (`DockWindowRequest.tearOut`).
- **The window drag.** Main moves the window on every drag event and finds this app's window
  under the pointer, below the dragged one. It posts the point to that window's area
  (`remoteHover`), whose thread draws the markers. On release, that area docks the dragged host
  (`remoteDrop`), and the window closes as its host goes.

## Looks

`DockSpace.setWindowStyle(_:)` switches every detached window at once, keeping its frame.

- **`.native`**: the system title bar.
- **`.custom`**: a transparent, hidden title bar over the content. The window keeps its native
  edges, shadow, corners and Mission Control, and the area draws its own 28 pt title bar with
  close, minimise and zoom.

Either title bar is a window drag, so it docks the whole window. The custom one is the area's,
which asks main for the drag. The native one is taken over on main: `DockWindow` is not movable,
and its `sendEvent` keeps a press on the title bar, off its buttons, from the title bar view.
Past 3 pt, the press drags the window the same way. A double click does what the system
settings say (zoom by default). What the window server's own move did is lost in both looks:
tiling at a screen edge, dragging to another Space, and ⌘-dragging a window in the background.

## Windows

- **Showing.** A detached window shows while an area the app placed is in a window on screen. It
  hides while none is: closing or minimising the workspace hides its panels' windows, and
  reopening it brings them back where they were. A panel window the user minimised stays in the
  Dock.
- **Relaunch.** The app placed the Workspace window, so SwiftUI decides whether it reopens; the
  detached windows follow it.
- **Closing.** When the user closes a detached window, with its button or ⌘W, its panels close.
  Quitting keeps them in the layout for the next launch.

## Limits

- One area per host: two areas showing the same host would each think the drag is theirs.
- Hosts do not cross spaces: a window of one `DockSpace` does not dock into another's area.
