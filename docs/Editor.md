# Editor

`Editor` is the package's second app: a Swift code editor built on MetalGraphicsLib. Run it with
the folder to open:

```bash
swift run Editor ~/src/MyPackage
```

It opens the folder named on the command line, else `EDITOR_OPEN`, else the one open last.

| Target | What it holds |
|---|---|
| `EditorCore` (`Sources/EditorCore/`) | Foundation only, no UI: scanning and watching a folder (`WorkspaceScanner`, `FileNode`, `DirectoryWatcher`), the navigator's rows (`FileNode.rows`), reading and writing text files (`TextFileIO`), column conversions (`TextPositions`), fuzzy matching (`FuzzyMatcher`), a language server client (`LSP/`: `JSON`, `LSPFraming`, `LSPConnection`, `LSPLanguageService` behind the `LanguageService` protocol, `SourceKitLSP`), and builds: running `swift build`/`run`/`test` (`SwiftPMBuildService`, `ProcessRunner`), their output (`BuildLog`), compiler diagnostics in it (`CompilerDiagnosticParser`), a package's executables (`PackageInfo`). Tested by `EditorCoreTests`. |
| `SwiftCodeModel` (`Sources/SwiftCodeModel/`) | The one target linking swift-syntax's parser: `CodeModel.analyze(source)` gives a file's outline (types, members, `// MARK:`s, with their depth) and what can fold (braces and block comments spanning lines), in UTF-16 offsets. A pure function, run in the background. Tested by `EditorCoreTests`. Linking it costs about a second on a clean build, since the macro plugin compiles swift-syntax from source anyway. |
| `Editor` (`Sources/Editor/`) | The app: its scene, dock space, panels and the glue between them. Tested end to end by `EditorTests`, in a `HeadlessApp` (`docs/HeadlessApp.md`). |

## The window

One window (`EditorScenes.ide`), whose root `IDERoot` is a `DockArea` over `IDE.space`. The
panels are:

- **Files** (`NavigatorPanel`): the folder's tree.
- **Outline** (`OutlinePanel`), under it: the declarations of the file in front.
- **A tab per open file** (`FileEditorPanel`).
- **Welcome**: there until the first file opens.
- **Console** and **Problems** (`BuildPanels.swift`): docked along the bottom by the first build.

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
| ⌘P | Open a file by name (`QuickOpenSheet`, `FuzzyMatcher`); Return opens the first, Escape closes | `IDERoot` |
| ⌘S | Save the file | its `FileEditorPanel` |
| ⌘⌥S | Save every file, in every window | `IDERoot`, `FileEditorPanel` |
| ⌘F | Find in the file: the selection, if it is on one line, is what to look for | `FileEditorPanel` |
| Return, ⌘G, ⇧⌘G | The next match, the next, the one before | the find field, `FileEditorPanel` |
| Escape | Close the find bar | `FileEditorPanel` |
| ⌘L | Go to a line, or `line:column` (`GoToLineSheet`) | `FileEditorPanel` |
| ⌥⌘←, ⌥⌘→ | Fold the innermost block around the caret, unfold it | the editor (`EditorKeyBindings`) |
| ⌃⌘J, ⌘-click | Go to the definition of the symbol at the caret, or clicked | `FileEditorPanel`, `LanguageAssist` |
| ↑ ↓, Return, Tab, Escape | In a completion list: pick, accept, close | `LanguageAssist` (through `onCommand`) |
| ⌘B, ⌘R, ⌘U | Build, run the chosen executable, test | `IDERoot` |
| ⌘. | Stop the build or run | `IDERoot` |

The keys are handled in the tree with `.onKeyPress`, not as menu key equivalents. A menu would
take the key before the window saw it, and the headless tests cannot press a menu. For the same
reason, SwiftUI's own File ▸ Print (⌘P) is removed.

## Find, and typing Swift

The find bar sits over the text while searching. It has:

- the query, with the match count ("3 of 12", from `onSearchChange`);
- ◀ ▶ for the previous and next match;
- option buttons for case, whole words and regular expressions (`.*`);
- a replacement, with Replace (the selected match, then the next) and All (one step to undo).

Closing it clears the highlights. A Swift file's editor also matches brackets, types `()`, `[]`,
`{}` and `""` in pairs, and indents inside blocks. See `docs/TextEditor.md`, *Typing code*.

## Files

- **Opening a folder.** `IDE.openFolder` writes `WorkspaceModel.rootPath` and scans the folder in
  the background (`Services.background`). The scan leaves out names starting with a dot and
  `WorkspaceScanner.ignoredNames` (`build`, `DerivedData` and others), and stops after 50,000 entries. It then writes
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
  - A tab with unsaved edits shows a dot after its name (`panel.setEdited`), written only when
    that flips. File tabs are `.document` tabs, with a document icon tinted by the file's type.
  - Saving writes atomically, with the file's line endings (`stringWithOriginalLineEndings`),
    encoding and byte order mark.
  - Closing an unsaved tab from its × asks first: Save, Don't Save, Cancel. This is the panel's
    `shouldClose`.
- **Across windows.** A tab dragged to another window is made anew there. Its unsaved text goes
  with it through `OpenFiles`; its undo history does not.

## The language server

sourcekit-lsp, from the selected Xcode (`xcrun --find sourcekit-lsp`, looked up at launch), runs
one per open folder (`LanguageClient`, `Sources/Editor/Language.swift`):

- **Lifetime.** Started when the first Swift file opens. Started again if it stops, up to three
  times. Shut down when another folder opens, and when the app quits.
- **Transport.** The protocol is `EditorCore`'s own: JSON-RPC over the process's pipes, one serial
  queue per connection, messages held back until `initialize` is answered. Positions are
  negotiated as UTF-16, which is what `TextDocument` counts in.
- **Sync.** Each Swift tab keeps a `LanguageDocument`: `didOpen` with its text, then each change set
  as `didChange` edits:
  - worked out in `willApply`, while the text is still as the ranges describe it;
  - sent last change first, so each range is still where it was;
  - past 50 changes at once, the whole text is sent instead.

  Saving sends `didSave`; closing the tab sends `didClose`.
- **Diagnostics.** They arrive on the server's queue and go into `LanguageModel`. The tab
  underlines them with the build's problems, with a dot in the gutter. Ones published for an
  older version than the text now are dropped: fresh ones follow every change.

`LanguageAssist` (`Sources/Editor/LanguageAssist.swift`) turns answers into what the tab shows,
over the text, in a `ZStack`:

- **Completion.**
  - It opens after `.`, or on a word's second letter, and asks once.
  - It then narrows what came back as typing goes on: what starts with the word first, then
    what matches it loosely, each in the server's order.
  - ↑ ↓ pick, Return or Tab accepts (one step to undo), Escape closes, a click accepts a row.
  - Typing past the word or moving out of it closes the list, and what was typed (a `.`) may open
    the next.
  - The list sits under the word, or above it at the bottom of the view.
- **Hover.** When the pointer rests on text for half a second, a tooltip shows the problem there,
  else what the server says of the symbol. It goes when the pointer moves.
- **Definitions.** ⌘-click or ⌃⌘J selects the definition, in this file or in its own tab
  (`IDE.reveal(_:line:character:)`).

Answers reach the tab through its window's executor. An answer older than the last question is
dropped.

## Outline and folding

A Swift file's tab keeps a `CodeModelSession` (`Sources/Editor/Outline.swift`), which parses the
file again 0.3 s after typing pauses (`Services.parseDelay`):

1. The text is copied on the window's thread.
2. It is parsed on a background queue (`Services.parseQueue`).
3. The result is posted back, and dropped if the text changed meanwhile, since another parse is
   already on its way.

With the result, the tab does two things:
- It gives the editor what can fold (`.foldingRanges`), so chevrons show in the gutter.
- If it is the tab in front, it publishes its symbols to `OutlineModel`, which the Outline shows.

A click on a symbol selects its name in the text (`IDE.reveal`, a `RevealRequest` with an
offset). Folding is the library's (`docs/TextEditor.md`, *Folding*):
- the chevron or ⌥⌘← folds;
- the "⋯", the chevron or ⌥⌘→ unfolds;
- an edit or the caret reaching into a fold unfolds it.

A layout saved before the Outline existed gets it as a tab beside Files
(`IDE.ensureOutlinePanel`). The first file opened with no other open goes to the right of Files
and the Outline together, above the console when it is there.

## Building and running

`BuildController` (`Sources/Editor/Build.swift`) runs one task at a time in the open folder:
`xcrun swift build`, `swift run <product>` or `swift test`.

1. **Save.** It saves every file first, each on its window's thread
   (`OpenFiles.saveAll(then:)`), and starts the process once the last is on disk.
2. **Stream.** What the process prints goes into the shared `BuildLog`, from the pipes' queues:
   - terminal escape codes are taken out: the compiler colours its output whatever `TERM` says;
   - each finished line is parsed for `path:line:column: error|warning|note: message`.
3. **Update.** At most every 50 ms (`Services.outputDelay`), `BuildModel.logVersion` moves on and
   `BuildModel.problems` is updated. Each window's console appends the chunks it has not shown to
   its own document, so a long build costs what it adds, not what the console holds.
4. **Stop.** ⌘. terminates the process, and kills it two seconds later if it is still running.

The package's executables come from `swift package describe`, read in the background when the
folder opens; Product ▾ in the console picks which one ⌘R runs.

- **Problems.** The list shows errors first, then warnings. A click opens the file with the
  caret at the problem, through `WorkspaceModel.reveal`, which the file's tab takes.
- **In the text.** Each open file underlines its problems (the word at the column), with a dot by
  the line number. Compilers count columns in UTF-8 bytes; they become UTF-16 offsets
  (`TextPositions`). A new build clears them.
- **Changes on disk.** `DirectoryWatcher` (FSEvents, 0.3 s latency) reports changes outside
  ignored folders. The tree is scanned again, and every open file checks its modification date:
  - a file without edits is read again (an app edit: not dirty, and the undo history moves
    over it);
  - one with edits keeps them, and its status line says it changed on disk.

  Saving here records the new date, so it does not read its own save back.
- **Another folder.** Opening one closes the tabs of files outside it (saving them first), and
  starts the console and problems over.

## Tests

`EditorTests/Support/EditorAppTestCase.swift` launches the app over a small package it writes to
a temporary folder. The folder picker returns that folder, and scans run at once.
Builds are a `FakeBuildService` printing canned compiler output, and the folder is not watched:
`IDE.filesChanged` is called instead. The language server is a `FakeLanguageService` that answers
at once, or holds completions back as a real one would, and keeps each file as the edits it was
sent make it. `LanguageE2ETests` compares that with the document after typing, many carets, and
300 random multi-change edits. `EditorCoreTests` runs the protocol client against a scripted
server in the process. With `EDITOR_SLOW_TESTS=1` it also runs against the real sourcekit-lsp
(`SourceKitLSPTests`, a few seconds): diagnostics, completion, hover, definition. `NavigatorE2ETests`, `SaveE2ETests`, `EditingE2ETests`,
`KeysE2ETests`, `BuildE2ETests`, `OutlineE2ETests` (parsing at once, on the test's thread) and
`LanguageE2ETests` drive it by label, as the user would: ⌘O, a tap on
`Sources`, typing, ⌘S. They then check the layout, the editor's text and the files on disk.

`drive-app` launches the real app (`uidrive --app Editor`) for what those cannot see.

## Cost

Everything here runs on a user action: a tap, a key, a scan finishing. Nothing runs per frame.

- A keystroke adds one listener call, and at most one title change: the first edit after a save.
- Build output reaches the windows at most 20 times a second, and each console appends only what
  is new. Parsing a line for a diagnostic is a prefix check for most lines.
- A keystroke in a Swift file also works out its edits for the server: O(changes), a
  position lookup each. Completion narrows O(items it got) on the window's thread, per keystroke
  while the list shows. A hover waits on a wake, never per frame.
- Parsing runs in the background, once per pause in typing, never per keystroke. A debug build
  parses 10,000 lines in under a second; a release build much faster.
- The navigator's rows are made in O(rows shown) when the tree or a folder changes, and only the
  rows in view are built.
- An idle window draws nothing. The real app measured 0.2% CPU idle with a file open.

## Limits, for now

- **Dirty tracking.** Any edit marks a file unsaved, even one undone back to the saved text.
- **Quitting.** The app quits without asking about unsaved files. The tabs reopen from disk.
- **Detached windows.** Closing one closes its tabs without asking.
- **Build output.** Problems are placed by line and column when the build reports them: edits
  made while it runs can shift them.
- **Run.** A program that reads standard input gets none; there is no terminal.
- **Language server.**
  - The Problems list shows the build's problems, not the server's; those show in the text.
  - Completions insert plain text, placeholders reduced to their names: no tab stops.
  - Results from other modules need the package's index, which sourcekit-lsp builds in the
    background after the folder opens.
