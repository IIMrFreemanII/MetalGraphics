# Text editor

`TextEditor` is multi-line, styled, editable text: the base of the Code Editor, Markdown and
Console demos (`GPURayMarching/CodeEditorDemo.swift`, `MarkdownEditorDemo.swift`,
`ConsoleDemo.swift`). The code is in `RetainedModeUI/TextEditor/`, with the line shaper in
`Graphics/2D/Text/LineLayout.swift` and input methods in `TextInput/TextInput.swift`.

```swift
// A string, through a binding: rebuilt and handed back on every edit. Fine for short texts.
TextEditor(text: $notes)

// A document, edited in place: a keystroke costs the same in 100k lines as in 10.
let document = TextDocument(source)
TextEditor(document: document)
  .styler(SwiftStyler())                 // or MarkdownStyler(), or your own TextStyler
  .lineNumbers(true)
  .lineWrapping(self.wrap ? .soft : .none)
  .editorTheme(self.dark ? .dark : .light)
  .searchQuery(self.query)               // highlights every match
  .diagnostics(self.problems)            // [TextDiagnostic]: squiggles by severity
  .attachmentProvider(self.attachments)  // elements inside the text
  .followsTail(true)                     // a log: stays at the end as text arrives there
  .onCommand { command in … }            // sees every command first; true takes it over
  .editFilter { transaction, state in … } // sees every user edit first; may rewrite or refuse it
  .onSelectionChange { selection in … }
  .font(.system(size: 13, design: .monospaced))
```

## Layers

Each can be tested alone (`MetalGraphicsLibTests/TextEditor/`).

| Layer | Types | What it does |
|---|---|---|
| Model | `TextDocument`, `GapBuffer`, `LineTree`, `ChangeSet`, `TextMarks` | The text, its lines and their heights, edits, ranges that move with edits |
| State | `EditorState`, `EditorSelection`, `UndoHistory`, `EditorCommand` | Selection (several ranges), commands, undo, input method composition |
| Styling | `TextStyler`, `EditorStyling`, `EditorTheme`, `SwiftStyler`, `MarkdownStyler` | Tokens per line, restyled incrementally; search and diagnostics over them |
| Layout | `EditorLayout`, `LineLayout`, `shapeLine` | Lines shaped on demand and cached; caret, hit test, selection rects |
| View | `TextEditor`, `EditorContentView`, `EditorGutterView`, `EditorAttachmentLayer` | Draws the lines in view; hosts attachments |
| Input | `EditorKeyBindings`, `TextInputSnapshot`, `TextInputAction` | Keys, pointer, clipboard, input methods |

### Indexing

Every position is a UTF-16 offset (`Int` in the document, `Int32` columns in a line), as in
`NSString`, CoreText and `NSTextInputClient`, so none of them needs converting. Commands never
leave a caret inside a user-perceived character (`TextBoundaries`): a surrogate pair, combining
marks, an emoji sequence. Lines end in `\n`; text coming in with `\r\n` or `\r` is converted, and
`lineEnding` remembers which it had.

### Lines and heights

`LineTree` holds, per line, its length and its height, in leaves of a few hundred lines with
running totals: finding a line by offset or by y, or a line's start or top, is O(leaves + leaf
size). Each line's record carries an id that changes whenever its text does, which is what the
layout cache and the styler's states are keyed by, so nothing is rekeyed when a newline moves every
line below it.

Lines not shaped yet have estimated heights: a row of the base font, times the rows a wrapped line
is guessed to take. As lines are shaped their measured heights replace the estimates, and the view
stays still: `EditorContentView` remembers the first line in view (its **anchor**) and where its
top was, and when lines above it change height the scroll offset moves by as much
(`ScrollView.contentSizeDidChange(_:offsetBy:)`).

The editor sits in a `ScrollView`, which is a **relayout boundary** for it: when the text grows or
shrinks, the scroll view sizes its content again on its own (O(1): the totals of the line tree)
instead of asking for a layout pass of the whole window. A keystroke is `.render`, plus
`.hitGrid` when the content size changed or attachments moved; never `.layout`.

### Styling

A `TextStyler` sees one line at a time, with the state the line above left, and returns the state
it leaves (`StyleState`, 64 bits it packs as it likes: inside a block comment, a fenced block).
`EditorStyling` keeps each line's start state in the line tree and knows them right up to a
**frontier**. An edit moves the frontier back to the edited line; styling goes forward from there,
and stops as soon as it reaches a state a line had before, past the lines the edit changed: from
there on nothing can differ. Typing in a function restyles its line; opening `/*` restyles until
the states agree again.

Lines far past the frontier (more than 2,000 lines, say after ⌘↓ in a new document) are styled
provisionally, from the state they had or the initial one. Background work — a wake each frame,
4,000 lines at a time — then catches up, reshapes any line in view it finds styled wrong, and
stops: the window goes idle.

`EditorTheme` maps each `TextToken` to a `SpanStyle`: colour, background, weight, italic, size,
underline (single, thick, squiggle), strikethrough. Only weight, italic, size and single
underlines change the shape of a line; colours are drawn over it. Tokens can also be stored with
the text (`TextDocument.append(_:token:)`, a console's output); they win over the styler's.

Search matches and diagnostics are drawn over tokens when a line is shaped. Diagnostics are
`TextMarks` on the document and move with the text.

### Attachments

- **Inline**: a U+FFFC with a mark in `document.attachments` (`TextEditor.insertAttachment`,
  `TextDocument.insertAttachment(_:at:)`). Its line reserves the size the
  `TextAttachmentProvider` gives it with a `CTRunDelegate`, and the element sits on the baseline.
- **Block**: what a styler's `blocks` puts below a line (a markdown image); the line grows by its
  height, and the caret skips it.

`EditorAttachmentLayer` builds the elements of the attachments on lines in view, mounts and
unmounts them as they scroll, like a lazy stack's rows, and keeps the last 64 it retired. The
reserved size is the provider's, not what the element measures: the text is laid out once.
Deleting an attachment's character removes its mark; undo brings the character back but not the
mark.

## Input

- **Keys** go through the input method (below) when there is one; its commands arrive as
  `NSResponder` selector names (`EditorCommand(selector:)`), so the Emacs keys and the user's
  `DefaultKeyBinding.dict` work. Without an input method — tests, and the frame before the view
  learns the editor has focus — `EditorKeyBindings` maps them the same way.
- **Pointer**: a click places the caret, a double click selects a word, a triple click a line,
  and a drag extends by what the press selected. A drag held outside the text scrolls it, a step
  per frame, by a wake. A click in the gutter selects lines.
- **Clipboard**: copies go through `Pasteboard.write`, posted to the main thread (a
  `HeadlessApp` captures them in `app.pasteboard`); ⌘V's text is read on the main thread with the
  key, in `KeyPress.pasteboard`.
- **Undo** coalesces typing and deleting runs (same kind, no caret move, within 2 s). An app's
  edits (`origin: .program`) are not recorded, and move the history around them. Undo never
  changes read-only text: a step that would drops the history.

### Input methods across threads

Input methods ask `NSTextInputClient` questions synchronously on the main thread, about text that
lives on the window's thread, and the main thread never waits for it. So:

1. After every frame that changed the focused text, its selection or its caret's place, the window
   thread publishes a `TextInputSnapshot` (selection, marked range, the text around them, the
   caret's rect) to `RetainedLayerView` (`RootViewRenderer.showTextInput`).
2. A key goes to `inputContext.handleEvent`, which calls `insertText`, `setMarkedText`,
   `unmarkText` and `doCommand(by:)` back at once. The view collects them as `TextInputAction`s and
   sends them with the key. Picks from the accent menu, dictation and the character viewer arrive
   outside a key and go as `InputEvent.textInput`.
3. The view answers questions from its snapshot, which it moves on itself with each action it sends
   (`TextInputSnapshot.applying`, the same rules the editor follows). A snapshot published before
   the thread applied what the view last sent is ignored (`appliedSequence`).
4. A composition that ends on the window's side — a click elsewhere, focus moving, a refused edit —
   shows as a snapshot without marked text, and the view discards the input method's.

`TextField` takes the same path: marked text shows underlined at its caret until committed.

The composition is part of the text but never of the history: the text it replaces is deleted as a
step, the marked text goes in and out unrecorded, and what is committed goes in as a step.

## Caret blink and wakes

`UIContext.requestWake(at:for:)` runs a `WakeTarget` at a time without keeping frames coming: an
idle window pauses its display link, and `RootViewRenderer` arms a run-loop timer for the earliest
wake. The caret blinks this way — two frames a second while focused, solid while typing, and solid
for good a minute after the last input, when nothing is left to wake for. Background styling and
drag autoscroll use wakes too. In tests they fire as the fake clock passes them.

## Performance

| Situation | Work per frame | Invalidation |
|---|---|---|
| Idle, or a minute after input | none | none |
| Caret blinking | two frames a second: the renderables re-emitted, no shaping; the GPU re-shades the caret's cell | `.render` from a wake |
| Keystroke | gap buffer O(1), line tree O(leaf), restyle until the states agree (usually one line), reshape one line | `.render`; `.hitGrid` if the content size changed |
| Scroll | shape the lines newly in view; mount and unmount attachments | `.hitGrid`, `.render` (the scroll view's) |
| Background styling | 4,000 lines a frame until done | `.render` for lines in view styled wrong |
| Resizing with soft wrap | every line's height estimated again, O(lines); lines in view reshaped | `.layout` (a resize anyway) |

Cost follows what is in view, not the document: a Release build keeps a 100k-line document at
under 2 ms of CPU a frame while scrolling, jumping to its end and typing there, and a blink frame at
about 0.5 ms with one dirty grid cell. Memory is 2–3 bytes a character (UTF-16 with a gap), a few
dozen bytes a line, and shaped layouts for at most 2,000 lines.

- The grid shades at most 512 shapes per 50-point cell, dropping the bottom ones — backgrounds —
  past that. 13-point code files about 25 in the densest cell; `FrameProfiler`'s `maxPerCell`
  shows it (`METALGRAPHICS_PROFILE=1`).
- A string binding is O(length) per edit, and so are `document.string`, select all and copy.
- A `TextDocument` belongs to the window thread that shows it, like the elements of its tree. A
  panel moved to another window is rebuilt there: keep its text in a model or storage.
- Scroll offsets are `Float`: past 16 million points, near a million lines, they lose sub-point
  precision.

## Limits

- Colour emoji have no outline and are not drawn (as in `Text`).
- Selection rects assume left-to-right text.
- `MarkdownStyler` has no setext headings (they need the line after), no emphasis inside
  emphasis, no reference links.
- Multiple cursors are in the model (`EditorSelection`, every command maps over its ranges); the
  pointer does not make them yet.

## Tests

- `UIHarness` (`MetalGraphicsLibTests/Support/UIHarness.swift`): `compose(_:selected:)` and
  `commit(_:)` send what an input method would; `advance` fires blinks and background styling.
- `HeadlessWindow`: `compose`, `commit`, `textInput` (the snapshot the view would have), and
  `app.pasteboard` for what was copied.
- The demos' end-to-end tests: `GPURayMarchingTests/CodeEditorDemoE2ETests.swift`,
  `MarkdownDemoE2ETests.swift`, `ConsoleDemoE2ETests.swift`.
