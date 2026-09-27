# Editor

`Editor` is the package's second app: a Swift code editor built on MetalGraphicsLib. Run it with
the folder to open:

```bash
swift run Editor ~/src/MyPackage
```

It opens the folder named on the command line, else `EDITOR_OPEN`, else the one open last.

| Target | What it holds |
|---|---|
| `EditorCore` (`Sources/EditorCore/`) | Foundation only, no UI: scanning a folder (`WorkspaceScanner`, `FileNode`), the navigator's rows (`FileNode.rows`), reading and writing text files (`TextFileIO`), column conversions (`TextPositions`). Tested by `EditorCoreTests`. |
| `Editor` (`Sources/Editor/`) | The app: its scene, dock space, panels and the glue between them. Tested end to end by `EditorTests`, in a `HeadlessApp` (`docs/HeadlessApp.md`). |

## The window

One window (`EditorScenes.ide`), whose root `IDERoot` is a `DockArea` over `IDE.space`. The
panels are:

- **Files** (`NavigatorPanel`): the folder's tree.
- **A tab per open file** (`FileEditorPanel`).
- **Welcome**: there until the first file opens.

Tabs are dock panels, so they split, float, and move to windows of their own like any other
(`docs/Docking.md`). The layout is saved, and open tabs come back after a relaunch.

SwiftUI shows the window as a `WindowGroup`, since a lone `Window` is not opened at launch. File ▸
New Window is replaced by Open Folder…, so there is only ever one window: two areas over the same
host would both take its drags. AppKit is told not to treat the folder argument as a document
(`NSTreatUnknownArgumentsAsOpen`), which would also keep the window from opening.

## Keys

| Keys | Does | Where |
|---|---|---|
| ⌘O | Open a folder | `IDERoot` |
| ⌘S | Save the file | its `FileEditorPanel` |
| ⌘⌥S | Save every file, in every window | `IDERoot`, `FileEditorPanel` |

The keys are handled in the tree with `.onKeyPress`, not as menu key equivalents. A menu would
take the key before the window saw it, and the headless tests cannot press a menu.

## Files

- **Opening a folder.** `IDE.openFolder` writes `WorkspaceModel.rootPath` and scans the folder in
  the background (`Services.background`). The scan leaves out names starting with a dot and
  `WorkspaceScanner.ignoredNames`, and stops after 50,000 entries. It then writes
  `WorkspaceModel.root`, which reaches every window as a `@Model` write does.
- **The navigator.** It subscribes to `root` by hand, because its rows are a `LazyVStack`'s
  `@State` array: a body cannot compute them from a model.
  - Its rows are rebuilt when the tree changes, or when a folder opens or closes.
  - Which folders are open is kept in its panel storage.
  - An expanded folder's row has an id of its own (`FileTreeRow.id`), so the list builds it again
    with its disclosure turned.
- **Opening a file.** `IDE.openFile(path)` selects the tab that already shows the file. Otherwise
  it makes a `file` panel with the path in its storage (`File.path`) and places it:
  - in the docked group holding the other files, or the welcome tab (which then closes);
  - else beside the navigator, taking 76% of the width.
- **A file's panel.** `FileEditorPanel` reads its file when it is made, synchronously on its window
  thread (`FileBinding`).
  - It picks the styler by extension: `SwiftStyler` for `.swift`, `MarkdownStyler` for `.md`.
  - A file that is not text, or cannot be read, shows empty and read-only, with the reason in the
    status line.
  - The file takes the keyboard when its tab shows.
  - It marks its row in the navigator (`WorkspaceModel.activeFile`).
- **Saving.**
  - A tab with unsaved edits is titled "● name". The title is written only when that flips.
  - Saving writes atomically, with the file's line endings (`stringWithOriginalLineEndings`),
    encoding and byte order mark.
  - Closing an unsaved tab from its × asks first: Save, Don't Save, Cancel. This is the panel's
    `shouldClose`.
- **Across windows.** A tab dragged to another window is made anew there. Its unsaved text goes
  with it through `OpenFiles`; its undo history does not.

## Tests

`EditorTests/Support/EditorAppTestCase.swift` launches the app over a small package it writes to
a temporary folder. The folder picker returns that folder, and scans run at once.
`NavigatorE2ETests` and `SaveE2ETests` drive it by label, as the user would: ⌘O, a tap on
`Sources`, typing, ⌘S. They then check the layout, the editor's text and the files on disk.

`drive-app` launches the real app (`uidrive --app Editor`) for what those cannot see.

## Cost

Everything here runs on a user action: a tap, a key, a scan finishing. Nothing runs per frame.

- A keystroke adds one listener call, and at most one title change: the first edit after a save.
- The navigator's rows are made in O(rows shown) when the tree or a folder changes, and only the
  rows in view are built.
- An idle window draws nothing. The real app measured 0.2% CPU idle with a file open.

## Limits, for now

- **Dirty tracking.** Any edit marks a file unsaved, even one undone back to the saved text.
- **Quitting.** The app quits without asking about unsaved files. The tabs reopen from disk.
- **Detached windows.** Closing one closes its tabs without asking.
- **Changes on disk.** A file changed on disk is not reloaded, and the tree is not rescanned: open
  the folder again.
- **Planned next:**
  - find and replace, go to line, quick open, bracket matching and smart indent;
  - build and run with a console and compiler diagnostics;
  - an outline and folding from swift-syntax;
  - sourcekit-lsp: completion, hover, definitions, live diagnostics.
