---
name: ui-tests
description: Headless UI tests for MetalGraphicsLib's retained-mode UI and for the whole app. A tree (UIHarness) or the app's real scenes and windows (HeadlessApp, DemoTests) run in an XCTest bundle with no window, synthetic mouse/key/scroll input, a fake clock, and offscreen Metal rendering compared against golden PNGs. The whole suite takes seconds. This is the default way to check or test any change to layout, hover/tap, focus, keys, text fields, scrolling, animation or rendering. Also use when asked to write, run or fix UI tests, snapshot tests or golden images. Use the drive-app skill instead only for the things listed under "When to launch the app instead".
---

# Headless UI tests

`MetalGraphicsLibTests` (an XCTest bundle with no host app, in `Tests/MetalGraphicsLibTests/`) runs the app's frame by hand:

- `UIContext.update` → `UIContext.render` → `Graphics2D.render(into:)`, drawing into an offscreen texture.
- No window, no screen, no Accessibility or screen-capture rights, and no real time. Nothing takes the mouse.
- It needs a Mac with Metal.
- A test takes ~10–100 ms.
- The bottleneck is compiling. Run only the class or test you are working on.

## Run

```bash
swift test --filter MetalGraphicsLibTests 2>&1 \
  | grep -E "error:|Test Case.*failed|Executed .* tests"
```

To run one class or test, narrow the filter: `--filter MetalGraphicsLibTests.InteractionTests` or `--filter InteractionTests/testHoverEntersAndLeaves`. `swift test` with no filter also runs `DemoTests` and the macro tests (`ReactiveUIMacrosTests`).

Failures print as `file:line: error: ... : XCTAssert... failed`.

## Write a test

New files go in `Tests/MetalGraphicsLibTests/`; SwiftPM picks them up, so there is nothing to register. A test class is `@MainActor final class ...: XCTestCase` with `@testable import MetalGraphicsLib` (or not `@MainActor`, when it drives harnesses on other threads).

```swift
func testSaveButtonSaves() {
  var saved = 0
  let h = UIHarness(size: float2(320, 240)) { Button("Save") { saved += 1 } }
  h.click(on: h.first(HittableView.self)!)
  XCTAssertEqual(saved, 1)
  XCTAssertNotNil(h.settle())            // the press fade finishes
}
```

`UIHarness` (`Tests/MetalGraphicsLibTests/Support/UIHarness.swift`):

| Call | Does |
|---|---|
| `UIHarness(size:pixelsPerPoint:) { tree }` | Mounts `tree` under a root `Frame` and steps one frame. Defaults: 320×240, 2×. |
| `step(dt)`, `step(frames:)`, `advance(seconds)` | Frames on the fake clock (1/60 s each). A frame draws only if the context needs it, as in the app. |
| `settle(maxFrames:)` | Steps until idle (no animation, nothing to draw). Returns the frames it took, or nil if it's still busy: assert it's not nil. |
| `move(to:)`, `click(at:)`, `click(on: hittable or focusable)`, `clickWithinOneFrame(at:)`, `scroll(by:at:)` | Mouse input, in points from the window's top left, y down. `click` is a down frame then an up frame. A scroll with positive y moves content down. |
| `press(.tab / .return / .delete / KeyEquivalent("a"), modifiers:)`, `type("text")` | Key down and up in one frame. `type` sends a frame per character. |
| `compose("かな", selected:)`, `commit("仮名")` | What an input method sends the focused text: marked text, then the committed text. |
| `all(T.self)`, `first(T.self)` | Finds elements in the tree in pre-order, e.g. `HittableView`, `FocusableElement`, `ScrollView`. |
| `context`, `input`, `graphics`, `root`, `now`, `renders` | The live pieces. `renders` counts the frames that drew. |
| `snapshot()`, `pixel(at:)` | The last frame as a `CGImage`, or one pixel's RGBA. |

**Things that trip tests up:**
- Setters animate only when given an animation: `el.setOpacity(0, h.context, animation: .linear(0.5))`. Inside `withAnimation { }`, pass `animation: UITransaction.animation`, which is what generated `@Component` code does.
- `TextField` and the other form controls are controlled: they edit only through a binding. `TextField("Name", text: Binding(get: { name }, set: { name = $0 }))`.
- The builder has no `for`. Build a list with an explicit `return`, e.g. `VStack { return (0..<20).map { _ in Rectangle(.blue).frame(height: 50) } }`, or use `VList`.
- Elements have no common `position`. Read one where the type has it: `Rectangle.position/size`, `HittableView.hitPosition/hitSize`, `FocusableElement.position/size`, `ScrollView.offset`, or `getSize()`.
- The root is a centre-aligned `Frame` the size of the window. A fixed-size child sits in the middle.
- The harness sizes its hit grid and render grid to its window, as the app's resize does, so a harness of any size draws and hits to its edges (`DamageTests.testAWindowPast500PointsDrawsToItsEdges`).

**Docking** (`DockingTests`, `DockLayoutTests`, `docs/Docking.md`): make a `DockSpace(name:kinds:persists: false) { layout }` and mount `DockArea(space, host: "main")`. Find tabs with `all(DockTabItem.self)`, groups with `all(DockTabsView.self)` (`rect`, `barRect`), floats with `all(DockFloatView.self)`, and the markers on `first(DockDropOverlay.self)!.markers`. Pick a panel up with `mouseDown` on its tab and a few `mouseDrag`s; a drag that undocks reflows the rest, so read a target's marker after it has undocked. A float being dragged is drawn by an offset (`dragOrigin`) and laid out on release. Between windows, run each area's harness on its own `WindowThread` (`DockWindowsTests`) and call the area's `remoteHover`/`remoteDrop` as `DockWindows` does from the main thread.

## Snapshots

```swift
assertSnapshot(h.snapshot(), named: "card-hovered", testCase: self)
```

Goldens are stored at `Tests/MetalGraphicsLibTests/__Snapshots__/<TestClass>/<name>.png`. Commit them.

- **First run, or a missing golden:** the test records the golden and fails on purpose. Read the PNG, check it looks right, then run again.
- **An intended look change:** re-record with `RECORD_SNAPSHOTS=1 swift test --filter ...`. Narrow `--filter` to the tests whose look changed, so no other golden is overwritten. Read the new PNGs before accepting them, and say in the summary that goldens were re-recorded and why.
- **A mismatch:** the failure prints the golden, actual and diff paths (`$TMPDIR/MetalGraphicsSnapshots/<TestClass>/`). Read the diff: differing pixels are red over a faded actual.
- **Tolerance:** by default, a pixel counts as different when a channel is off by more than 8, and the test fails when more than 0.2 % of pixels differ. That absorbs GPU antialiasing noise but catches a colour change or a 1 pt move. Keep trees small and fixed-size, e.g. 320×240 at 2×.
- **Checking colour, not the whole image:** use `h.pixel(at:)`.

## Rules

- Never sleep and never read real time. Time moves only through `step` / `advance` / `settle`.
- Tests run serially on the main thread (`swift test` runs serially unless given `--parallel`; never pass it). A harness belongs to the thread that made it, as a window's tree does: the main thread for most tests. `LayoutPass`, `TextScope` and `UITransaction` are per thread (`ThreadState`). `HorizontalAlignment.anyExplicit` is process-wide and never resets once set. A test that sets an explicit alignment guide changes the fast path for every test after it in the process, so give such tests their own class and expect them to affect others.
- Windows on threads of their own: `WindowThreadTests` makes each harness on its own `WindowThread` and runs blocks there with a helper that waits for them. That is how to test anything that crosses windows — a `@Model` written in one and read in another, a glyph baked by one and drawn by another. Keep such harnesses alive while the other thread writes to a model they read. Run those tests under Thread Sanitizer too: add `--sanitize=thread` to the test command.
- Tests run in the `xctest` process, so `UIStorage` and `UserDefaults.standard` belong to that process, not to the app.
- A change to UI behaviour or rendering comes with a test next to the existing ones: `InteractionTests`, `AnimationTests`, `LayoutTests` or `SnapshotTests`.
- Guard idleness where it matters: after `settle()`, `h.step(frames: 30)` must not change `h.renders` (see `AnimationTests.testIdleTreeStopsDrawing`).
- `settle()` stops while a wake (`UIContext.requestWake`, a caret's blink) is still in the future: `advance(seconds)` fires it. A focused `TextEditor` blinks for a minute after its last input.
- What a copy writes goes through `Pasteboard.write`: replace it in a test to see it (`TextEditorTests.testCopyCutAndPaste`).

## The whole app (`HeadlessApp`, `DemoTests`)

`DemoTests` is a second test bundle. It imports the app's module (`@testable import Demo`; SwiftPM leaves out its `@main`) and runs its scenes in a `HeadlessApp` (`docs/HeadlessApp.md`):
- the app's real scenes (`AppScenes.all`);
- every window stepped in turn on the test's thread;
- `openWindow(id:)`, dock windows, and storage kept across a relaunch.

Use it for a feature that crosses windows, opens them, uses the demos, or has to survive a relaunch. It is also where a finished feature gets its end-to-end test.

```bash
swift test --filter DemoTests 2>&1 \
  | grep -E "error:|Test Case.*failed|Executed .* tests"
```

```swift
final class SharedStateE2ETests: AppTestCase {        // launches the app; `main` is its Demos window
  func testCountingInOneWindowShowsInTheOther() throws {
    try self.main.tap("Windows")                      // a sidebar link, by its text
    try self.main.tap("Open Shared State window")     // its handler calls openWindow(id:)
    let shared = try XCTUnwrap(self.app.window(SharedStateWindow.id))
    try shared.tap("+")
    XCTAssertTrue(self.main.shows("Count: 1"))        // the other window, same step
  }
}
```

- New files go in `Tests/DemoTests/`, with `@testable import Demo` next to `@testable import MetalGraphicsLib`. A new app source file in `Sources/Demo/` is visible to the tests without anything to register.
- Every action on a `HeadlessWindow` steps the whole app. Use `app.step()`, `app.settle()` or `app.advance(_:)` to move time without input.
- Find by what the user reads: `tap("Form")`, `type("Ada", into: "Name")`, `toggle("Highlight")`, `control(labelled:)`, `panel(id)`, `shows("…")`. When a query finds nothing, it throws with every text the window shows. `window.describeTree()` prints the whole tree.
- `self.relaunch()` quits and relaunches: each window reopens from its scene storage, and dock layouts are kept.
- Docking: `panel(id).drag(toScreen:)` tears a tab out into a `"dock"` window, and dragging it over a group docks it back. Windows sit on a virtual screen; `window.origin` is the top left of the window's content.
- Snapshots work as above; `assertSnapshot` is shared by a symlink.
- Library tests of `HeadlessApp` itself are in `Tests/MetalGraphicsLibTests/HeadlessAppTests.swift`.

## When to launch the app instead (drive-app skill)

These are outside both harnesses:
- `NSEvent` → `InputEvent` translation in `RetainedLayerView`: real mouse and trackpad events, modifier edge cases, key repeat. What `Input.apply` makes of an `InputEvent` is testable here (`WindowInputTests`).
- Windowing: resizing by the edge, Retina scale changes, AppKit's key-window and first-click rules, SwiftUI's own window restoration and menu commands.
- Hot reload, and real frame pacing or idle CPU (with `top`, or Instruments).
- Real threads: `HeadlessApp` runs every window on one thread. Races between windows are tested with `WindowThread`s under TSan (`WindowThreadTests`, `DockWindowsTests`).

Do one final `drive-app` check when a feature is finished. Iterate with the tests.

## How it works (when the harness itself needs changing)

- `UIContext.clock` is what animations start and tick on. The harness points it at its fake `now`.
- `Graphics2D.render(into:pixelsPerPoint:_:)` is `context(in: FrameTarget)` without a drawable. It shares `encodeFrame` and `finishFrame` with the app's `drawData`.
- `Graphics2D.makeOffscreenTarget` and `readPixels` are in `Graphics/2D/Graphics2D+Offscreen.swift`.
- Every step ends the input frame with `input.endFrame()`, drawn or not, as `RootViewRenderer.frame(drawable:)` does.
