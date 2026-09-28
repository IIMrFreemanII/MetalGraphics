# Threading

Every window runs on a thread of its own. Each window's frames — input, update, layout, render,
Metal encode — run on its `WindowThread`, so windows draw in parallel, and the main thread does
only AppKit and SwiftUI work.

## What runs where

| Thread | What runs there |
|---|---|
| Main | SwiftUI scenes and `RetainedView`; `RetainedLayerView`'s AppKit side: events, size, key status, occlusion, the cursor; `@SceneStorage`; `openWindow`; the pasteboard; hot reload's watchers; the system appearance, written to `ThemeStore.shared` (`AppearanceObserver`), which each window's thread then takes as its theme |
| A window's `WindowThread` | Everything of that window's tree: its elements, `UIContext`, `Input`, `Graphics2D`, `UISceneStorage`, `RootViewRenderer`. Its frames, driven by a `CAMetalDisplayLink` on the thread's run loop. And the windows of the presentations shown from it, each with a renderer and display link of its own |
| The shared bake queue | Glyph and icon bakes into the shared SDF atlas, and image uploads (`SharedGPUWork`) |

The main thread never waits for a window thread, and a window thread never waits for the main
thread. They post to each other:

- **Main → window:** `WindowHandle.send(_:)` queues an `InputEvent`, a value with no AppKit object
  in it, and `WindowHandle.post(_:)` runs a block with the window's renderer. Both are drained at
  the start of the window's next turn. A resize, an occlusion change, a scene storage restore, a
  hot reload and a shader reload all arrive this way.
- **Window → main:** a changed cursor, a copy to the pasteboard (`Pasteboard.write`),
  `openWindow(id:)` and a scene storage save go through `DispatchQueue.main.async`. ⌘V's text is
  read by the view on the main thread, with the key, and travels in the event.
- **Input methods** ask synchronously, on main, about text on the window's thread. The window
  publishes a `TextInputSnapshot` of its focused text after each frame that changed it; the view
  answers from it, moves it on itself for what it sends, and sends what the input method asks for
  as `TextInputAction`s, with the key or as `InputEvent.textInput` (`TextEditor.md`, *Input
  methods across threads*).

Main holds only a window's `WindowHandle`. The renderer is made, used and released on the
window's thread. A closed window's thread unmounts its tree, which unsubscribes it from shared
models, then ends; anything posted to it afterwards is dropped.

A presentation shown in a window of its own (`docs/Modals.md`) runs on the thread of the window
it was shown from, not on one of its own: its content is built by a closure that captures the
presenter, and writes its bindings. Its `WindowHandle` is a child of that window's
(`WindowHandle(childOf:name:)`): the same thread and mailbox, its own events and renderer.
Closing it tears down only its tree; closing the window tears down its children's too, in the
same turn. A frame that changes another tree on its thread — a presentation writing its
presenter's state — resumes that window's paused frames (`WindowHandle.wakeSurfaces`).

Docking's windows follow the same rules: an area posts what it asks of the windows to main,
which drags a window itself and posts back where the pointer is to the area under it
(`Docking.md`, *What runs where*).

## Rules for code in a tree

- **Touch only your own window.** An element, its context and its graphics belong to the thread
  that mounted them. Nothing checks this at compile time: the retained UI is not `@MainActor`, and
  its classes are not `Sendable`.
- **Share through a `@Model`.** A write updates the writer's window at once and every other
  window on its next frame (`CompileTimeState.md`, *Shared models*). A plain shared class read
  by two windows needs a lock of its own.
- **No AppKit from a tree.** Views, windows, `NSCursor`, `NSPasteboard` and SwiftUI actions belong
  to the main thread; post to it. CoreText, Metal and `NSImage` drawing into a bitmap are fine.
- **Per-pass state is per thread.** `TextScope`, `LayoutPass`, `LazyStackViewport` and
  `UITransaction` keep their state in `ThreadState`, so `withAnimation` in one window does not
  animate another's writes.

## Shared caches

| Cache | Shared how |
|---|---|
| `FontManager` (faces, glyph metrics) | One for the app, behind a lock. Each thread copies the glyphs it has seen into `ThreadState`, so a relayout takes the lock only for new glyphs |
| `SDFBaker` (glyph and icon atlas) | One atlas; regions are never freed. Bakes are queued under a lock and committed by `SharedGPUWork.flush` on its own queue, which signals a shared event; a frame waits on that event before it samples the atlas |
| `ImageManager`, `SVGIcon` | One for the app, behind a lock; uploads go through the same flush |
| `VectorBaker` (path atlas) | One per window, owned by its `Graphics2D`: tiles are freed and reused as paths come and go |
| `FrameProfiler` | One per window, owned by its `Graphics2D`, labelled with its scene id |

## Idle windows

A frame that finds nothing to draw and nothing animating pauses the window's display link.
Anything posted to the window — an event, a shared model's write, a resize — resumes it, and so
does the earliest wake an element asked for (`UIContext.requestWake(at:for:)`, a caret's blink),
through a timer on the thread's run loop. An idle
window costs no CPU, not even a wakeup per display refresh. An occluded window stays paused, and
catches up on whatever changed when it is visible again.

## Measuring

Code coverage instrumentation writes shared counters on every function call, so with several
windows animating their threads contend for those counters and every frame slows down many
times over. `swift build` and `swift test` leave coverage off, so their builds are not
instrumented; a test run opts in with `swift test --enable-code-coverage`. Never measure frame times
with a build made that way (see the `performance` skill).
