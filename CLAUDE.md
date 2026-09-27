## graphify

This project has a knowledge graph at graphify-out/ with god nodes, community structure, and cross-file relationships.

Rules:
- For codebase questions, first run `graphify query "<question>"` when graphify-out/graph.json exists. Use `graphify path "<A>" "<B>"` for relationships and `graphify explain "<concept>"` for focused concepts. These return a scoped subgraph, usually much smaller than GRAPH_REPORT.md or raw grep output.
- If graphify-out/wiki/index.md exists, use it for broad navigation instead of raw source browsing.
- Read graphify-out/GRAPH_REPORT.md only for broad architecture review or when query/path/explain do not surface enough context.
- After modifying code, run `graphify update .` to keep the graph current (AST-only, no API cost).

## Build

One SwiftPM package (`Package.swift`), no Xcode project: `swift build`, `swift run Demo` (the demo app, a bare executable), `swift run Editor` (the Swift editor), `swift test`. Targets live in `Sources/` (`MetalGraphicsLib`, `Demo`, `Editor`, `EditorCore`, `SwiftCodeModel`, `ReactiveUI`, `ReactiveUIMacrosPlugin`) and `Tests/`; `Tools/` holds `uidrive` and `layoutchecks`. The `MetalShaders` plugin (`Plugins/`) compiles `Sources/MetalGraphicsLib/Shaders/*.metal` into the library's `Bundle.module`; the demo's images are plain files in `Sources/Demo/Resources/`, loaded with `Image(name, bundle: .module)`. Opening `Package.swift` in Xcode works too.

## Performance

Before implementing or changing any feature in MetalGraphicsLib, Demo or ReactiveUIMacros, load the `performance` skill (`.claude/skills/performance/SKILL.md`) and apply its checklist. Report the change's per-frame cost (section 8 of the skill) in the final summary.

## Hot reload

Debug builds reload Swift (via InjectionNext), shaders and the ReactiveUI macros live, and restore the selected tab from `UIStorage`. Setup, limits and what still needs a relaunch: `docs/HotReload.md`.

## Threading

Every window runs its frames on a thread of its own; the main thread does AppKit and SwiftUI only. What runs where, how the two post to each other, and the rules for code in a tree: `docs/Threading.md`.

## Docking

Panels dock, split, tab and float in a `DockArea`, and become windows of their own when dragged out (`DockSpace`, `DockWindows`). The model, what runs where, what survives a move between windows, and the two window looks: `docs/Docking.md`.

## UI tests

Check UI changes with the headless tests (the `ui-tests` skill, `.claude/skills/ui-tests/SKILL.md`): no window, synthetic input, fake clock, golden PNGs, seconds per run. `MetalGraphicsLibTests` tests trees with `UIHarness`. `DemoTests` runs the whole app in memory with `HeadlessApp`: its real scenes, several windows, `openWindow`, dock windows and relaunch, driven by label (`tap("Form")`). See `docs/HeadlessApp.md`. Give a feature an end-to-end test there. Launch the app with `drive-app` only for what neither covers (real `NSEvent`s, AppKit windowing, real threads, hot reload, frame pacing) and for a final check.

## Editor app

`Editor` (`swift run Editor [folder]`) is a Swift code editor on the library: a navigator, a tab per file (dock panels), open and save, find and replace, quick open, go to line, brackets, pairs and indentation, build/run/test with a console and a Problems list, files reloaded as they change on disk, an outline and folding from swift-syntax (`SwiftCodeModel`, the only target linking its parser), and sourcekit-lsp: completion, hover, go to definition, live diagnostics (`EditorCore/LSP`, `EDITOR_SLOW_TESTS=1` runs it against the real server). `EditorCore` holds its UI-free model (Foundation only, `EditorCoreTests`); `EditorTests` drives the app headlessly over a temporary package. `uidrive --app Editor` drives the real one. Structure, keys, limits: `docs/Editor.md`.

## Text editor

`TextEditor` is multi-line, styled, editable text on a `TextDocument`: code (with `SwiftStyler`), markdown, a console. Only the lines in view are shaped and drawn; input methods work across the window's thread. The layers, indexing, incremental styling, attachments, wakes and costs: `docs/TextEditor.md`.
