# Headless app

`HeadlessApp` (`Sources/MetalGraphicsLib/Headless/`) runs the whole app in memory, in a test:

- its windows, opened from the app's own scene declarations;
- their trees, frames and input;
- what they ask of the main thread;
- their storage.

It uses no `NSWindow`, view, display link or real time. Tests drive it as a user would, with taps by label and typing into fields, then check text, state or pixels. A test takes tens of milliseconds, and nothing takes over the mouse.

`UIHarness` in `MetalGraphicsLibTests` tests one tree. `HeadlessApp` tests the app:
- several windows over one `@Model`;
- `openWindow(id:)`;
- dock windows torn out and docked back;
- scene storage across a relaunch.

## The scenes

The app declares its windows once, as `RetainedScene` values (`Sources/Demo/AppScenes.swift`). The SwiftUI app shows them with `RetainedWindowGroup(scene)` and `RetainedWindow(scene)`, and a `HeadlessApp` opens the same ones:

```swift
static let demos = RetainedScene("Demos", id: "main", defaultSize: CGSize(width: 960, height: 680)) { scene in
  Demos(scene: scene)
}
// App.body: RetainedWindowGroup(AppScenes.demos)
// A test:   HeadlessApp(scenes: AppScenes.all).launch()
```

A scene's `kind` is `.group` (any number open, like `WindowGroup`) or `.single` (at most one open, like `Window`).

## What runs where

Every window runs on the thread that made the app, which is the test's main thread. Windows run one after another, in the order they opened. Each window has a `WindowHandle` with no thread (`WindowHandle(threadlessNamed:)`), and its executor is a mailbox that the app drains itself.

`app.step()` does this, in order:

1. Moves the fake clock on by one frame.
2. Runs what was posted to the main thread: `openWindow(id:)`, and dock window requests. These reach the app's own mailbox through `MainQueue.post` instead of the main queue.
3. For each window, in the order they opened:
   1. Makes the window's mailbox the thread's executor (`ThreadState.executor`).
   2. Runs what was posted to the window: model deliveries, `withArea` posts, a resize.
   3. Runs its frame through `RootViewRenderer.runFrame`, the same code the display link runs, drawing into an offscreen texture.
4. Runs the main thread's mailbox again, so a window a handler opened exists when the step returns.

Switching the executor is what makes one thread act as many. `ModelObservers` and `DockSpace` tell windows apart by `ThreadState.current.executor`. A write in one window therefore updates that window at once, and updates the others when their mailboxes drain later in the same step, as it does across threads. Between steps, the test's code runs as the main thread. A model the test writes reaches every window on the next step.

Nothing happens between steps. The same script gives the same frames and the same pixels every run (`HeadlessAppTests.testTheSameScriptGivesTheSameFrames`).

## Input

A `HeadlessWindow` sends the `InputEvent`s that a `RetainedLayerView` would, through `WindowHandle.send` and `Input.apply`. Points are the window's own: from the content's top left, with y down.

- **Mouse and scroll.** `move(to:)`, `click(at:)`, `doubleClick`, `rightClick`, `mouseDown`/`mouseDrag`/`mouseUp` and `drag(from:to:)`. `drag(from:toScreen:)` drags out of the window, or moves a dock window with it. `scroll(by:at:)` and `pointerExit()`.
- **Keys.** `press(key, modifiers:)` sends real key codes and the modifier flag changes. With command held it sends no key-up, as AppKit does. `type(_:)` sends one frame per character, and `paste(_:)` sends ⌘V with the pasteboard's text in the event. `compose(_:selected:)` and `commit(_:)` send what an input method would, and `textInput` is the snapshot of the focused text the view would answer it from. A copy goes to `app.pasteboard`, never the real one.
- **Window.** `resize(to:)` and `close()`.
- **Key window.** Any input on a window makes it key first, as clicking one does. The window that was key before gets `.resignKey`, and the new one gets `.becomeKey`.
- **Steps.** Every action steps the whole app as many frames as the real events would take. A click takes a press frame and then a release frame.

## Queries

These live in `HeadlessQuery.swift`. The labels they match are the `Text`s a user reads, so no identifiers need adding to the app.

| Call | Finds |
|---|---|
| `find(text:)`, `element(text:)` | A `Text` showing exactly that. `element` takes the first one shown, and prefers one inside something pressable. |
| `find(id:)`, `element(id:)` | An element tagged `.id(_:)`. |
| `find(T.self, where:)` | Elements by type. |
| `control(labelled:)` | The `FormControl` whose label is that text, or the text field whose prompt is. |
| `panel(_ id:)` | A dock panel's tab. |
| `tap(_:)`, `type(_:into:)`, `toggle(_:)` | The query, then the action. |
| `shows(_:)`, `shownTexts`, `describeTree()` | What is on screen. |

An element counts as shown when:
- it is mounted and not hidden;
- it has a size;
- it lies inside the window and inside every scroll view around it.

A query that finds nothing throws `HeadlessError`. The error lists every text the window shows.

An `ElementRef` taps with real input at the centre of its hit rect. If something covers that point, the tap lands on what covers it, as it would in the app.

## Docking

`app.manageDocking(space)` does in memory what `DockWindows.manage` does with `NSWindow`s:

- It opens a window for each detached host, with the scene id `"dock"`.
- It shows and hides those windows while an area the app placed is shown.
- It drags a window when an area asks with `.tearOut` or `.drag`. On each move it calls `remoteHover` on the area under the pointer, and it calls `remoteDrop` on release.
- It closes a window whose host went away.

Windows sit on a virtual screen, in points from its top left. A host's `screenFrame` is in those coordinates.

## Presentations

A presentation in a window of its own (`docs/Modals.md`) opens a `HeadlessWindow` of scene id
`"presentation"`. `HeadlessPresentedWindows`, which stands in for `PresentedWindows`, puts it
where AppKit would put the window:

- an attached sheet, alert or dialog hangs from the top of its window, centred;
- a floating one is centred over its window;
- a popover sits by its source;
- a cover lies over its window, or fills the screen.

Its tree runs on its window's thread, which here is the test's, and steps with the rest.

- `app.presentation(over: window)` is the one shown last from a window.
- A click or a right click on a window that has a presentation over it goes to the presentation,
  as a click outside it, and the window gets nothing. A scroll there dismisses a popover.
- Keys pressed on such a window go to the topmost presentation over it, as they would to AppKit's
  key window.
- `close()` on a presentation's window is its close button: it asks the binding.
- When it closes, the keyboard goes back to the window it was shown from.

`relaunch` and `close` close presentations' windows first, without asking their bindings; a
relaunch reopens none.

## Storage and relaunch

`UIStorage.defaults` points at a private, empty `UserDefaults` suite for the app's life. `DockSpace` saves its layouts through `UIStorage.defaults`, so dock layouts go there too. `close()` deletes the suite and puts back the globals the app swapped: `Windows`' opener, `MainQueue`, the executor and the defaults. Only one app can be live at a time, and a new one closes any that was left open.

`relaunch(prepare:)` quits and relaunches in memory:

1. Every window closes as it does when the app quits: trees unmount, panels save, and layouts are written.
2. `prepare` runs. In it, the app makes afresh what a new process would, which for this app is `AppScenes.resetForTesting()` and `manageDocking`.
3. The windows reopen in the same order, each restored from its own scene storage.

## What it does not cover

- **`NSEvent` → `InputEvent`** translation in `RetainedLayerView` (see `WindowInputTests`).
- **Real threads and their races.** `WindowThreadTests` and `DockWindowsTests` cover them, under TSan.
- **SwiftUI menus and commands.** Call `app.open(id:)` instead.
- **Real window behaviour.** SwiftUI's own window restoration, AppKit's key-window and first-click rules, window chrome, Retina changes.
- **Frame pacing and idle CPU.** Use the `drive-app` skill for these.
