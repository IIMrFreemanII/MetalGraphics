---
name: ui-tests
description: Headless UI tests for MetalGraphicsLib's retained-mode UI. The tree runs in an XCTest bundle with no window, synthetic mouse/key/scroll input, a fake clock, and offscreen Metal rendering compared against golden PNGs. The whole suite takes seconds. This is the default way to check or test any change to layout, hover/tap, focus, keys, text fields, scrolling, animation or rendering. Also use when asked to write, run or fix UI tests, snapshot tests or golden images. Use the drive-app skill instead only for the things listed under "When to launch the app instead".
---

# Headless UI tests

`MetalGraphicsLibTests` (an XCTest bundle with no host app, in `MetalGraphicsLibTests/`) runs the app's frame by hand:

- `UIContext.update` → `UIContext.render` → `Graphics2D.render(into:)`, drawing into an offscreen texture.
- No window, no screen, no Accessibility or screen-capture rights, and no real time. Nothing takes the mouse.
- It needs a Mac with Metal.
- A test takes ~10–100 ms.
- The bottleneck is compiling. Run only the class or test you are working on.

## Run

```bash
xcodebuild test -project MetalGraphics.xcodeproj -scheme GPURayMarching \
  -destination 'platform=macOS' -only-testing:MetalGraphicsLibTests 2>&1 \
  | grep -E "error:|Test Case.*failed|Executed .* tests|\*\* "
```

To run one class or test, narrow the filter: `-only-testing:MetalGraphicsLibTests/InteractionTests` or `.../InteractionTests/testHoverEntersAndLeaves`.

Failures print as `file:line: error: ... : XCTAssert... failed`.

## Write a test

New files go in `MetalGraphicsLibTests/`. The folder is synchronized, so there is no project file to edit. A test class is `@MainActor final class ...: XCTestCase` with `@testable import MetalGraphicsLib`.

```swift
func testSaveButtonSaves() {
  var saved = 0
  let h = UIHarness(size: float2(320, 240)) { Button("Save") { saved += 1 } }
  h.click(on: h.first(HittableView.self)!)
  XCTAssertEqual(saved, 1)
  XCTAssertNotNil(h.settle())            // the press fade finishes
}
```

`UIHarness` (`MetalGraphicsLibTests/Support/UIHarness.swift`):

| Call | Does |
|---|---|
| `UIHarness(size:pixelsPerPoint:) { tree }` | Mounts `tree` under a root `Frame` and steps one frame. Defaults: 320×240, 2×. |
| `step(dt)`, `step(frames:)`, `advance(seconds)` | Frames on the fake clock (1/60 s each). A frame draws only if the context needs it, as in the app. |
| `settle(maxFrames:)` | Steps until idle (no animation, nothing to draw). Returns the frames it took, or nil if it's still busy: assert it's not nil. |
| `move(to:)`, `click(at:)`, `click(on: hittable or focusable)`, `clickWithinOneFrame(at:)`, `scroll(by:at:)` | Mouse input, in points from the window's top left, y down. `click` is a down frame then an up frame. A scroll with positive y moves content down. |
| `press(.tab / .return / .delete / KeyEquivalent("a"), modifiers:)`, `type("text")` | Key down and up in one frame. `type` sends a frame per character. |
| `all(T.self)`, `first(T.self)` | Finds elements in the tree in pre-order, e.g. `HittableView`, `FocusableElement`, `ScrollView`. |
| `context`, `input`, `graphics`, `root`, `now`, `renders` | The live pieces. `renders` counts the frames that drew. |
| `snapshot()`, `pixel(at:)` | The last frame as a `CGImage`, or one pixel's RGBA. |

**Things that trip tests up:**
- Setters animate only when given an animation: `el.setOpacity(0, h.context, animation: .linear(0.5))`. Inside `withAnimation { }`, pass `animation: UITransaction.animation`, which is what generated `@Component` code does.
- `TextField` and the other form controls are controlled: they edit only through a binding. `TextField("Name", text: Binding(get: { name }, set: { name = $0 }))`.
- The builder has no `for`. Build a list with an explicit `return`, e.g. `VStack { return (0..<20).map { _ in Rectangle(.blue).frame(height: 50) } }`, or use `VList`.
- Elements have no common `position`. Read one where the type has it: `Rectangle.position/size`, `HittableView.hitPosition/hitSize`, `FocusableElement.position/size`, `ScrollView.offset`, or `getSize()`.
- The root is a centre-aligned `Frame` the size of the window. A fixed-size child sits in the middle.

## Snapshots

```swift
assertSnapshot(h.snapshot(), named: "card-hovered", testCase: self)
```

Goldens are stored at `MetalGraphicsLibTests/__Snapshots__/<TestClass>/<name>.png`. Commit them.

- **First run, or a missing golden:** the test records the golden and fails on purpose. Read the PNG, check it looks right, then run again.
- **An intended look change:** re-record with `TEST_RUNNER_RECORD_SNAPSHOTS=1 xcodebuild test ...`. xcodebuild passes only `TEST_RUNNER_`-prefixed variables to the test process, with the prefix stripped; a plain `RECORD_SNAPSHOTS=1` is silently ignored. Narrow `-only-testing` to the tests whose look changed, so no other golden is overwritten. Read the new PNGs before accepting them, and say in the summary that goldens were re-recorded and why.
- **A mismatch:** the failure prints the golden, actual and diff paths (`$TMPDIR/MetalGraphicsSnapshots/<TestClass>/`). Read the diff: differing pixels are red over a faded actual. The images are also attached to the xcresult.
- **Tolerance:** by default, a pixel counts as different when a channel is off by more than 8, and the test fails when more than 0.2 % of pixels differ. That absorbs GPU antialiasing noise but catches a colour change or a 1 pt move. Keep trees small and fixed-size, e.g. 320×240 at 2×.
- **Checking colour, not the whole image:** use `h.pixel(at:)`.

## Rules

- Never sleep and never read real time. Time moves only through `step` / `advance` / `settle`.
- Tests run serially on the main actor (the scheme marks the bundle as not parallelizable). Global statics exist: `LayoutPass`, `UITransaction`, and `HorizontalAlignment.anyExplicit`, which never resets once set. A test that sets an explicit alignment guide changes the fast path for every test after it in the process, so give such tests their own class and expect them to affect others.
- Tests run in the `xctest` process, so `UIStorage` and `UserDefaults.standard` belong to that process, not to the app.
- A change to UI behaviour or rendering comes with a test next to the existing ones: `InteractionTests`, `AnimationTests`, `LayoutTests` or `SnapshotTests`.
- Guard idleness where it matters: after `settle()`, `h.step(frames: 30)` must not change `h.renders` (see `AnimationTests.testIdleTreeStopsDrawing`).

## When to launch the app instead (drive-app skill)

These are outside the harness:
- `NSEvent` → `Input` translation in `MyMTKView`: real mouse and trackpad events, modifier edge cases, key repeat.
- Windowing: resizing, Retina scale changes, key-window hover tracking.
- Hot reload, and real frame pacing or idle CPU (with `top`, or Instruments).
- `@Component` demos in the `GPURayMarching` app target. The tests link only `MetalGraphicsLib`, so they build trees by hand.

Do one final `drive-app` check when a feature is finished. Iterate with the tests.

## How it works (when the harness itself needs changing)

- `UIContext.clock` is what animations start and tick on. The harness points it at its fake `now`.
- `Graphics2D.render(into:pixelsPerPoint:_:)` is `context(in: MTKView)` without a view. It shares `encodeFrame` and `finishFrame` with the app's `drawData`.
- `Graphics2D.makeOffscreenTarget` and `readPixels` are in `Graphics/2D/Graphics2D+Offscreen.swift`.
- `Graphics2D.endFrame` ends the input frame. A step that doesn't draw calls `input.endFrame()` itself, as `TestViewRenderer.draw(in:)` does.
