---
name: performance
description: Performance checklist for MetalGraphics. Use before implementing or modifying any feature — retained-mode UI elements, layout, animation, input, scrolling, rendering, Metal shaders or the ReactiveUI macros — and when reviewing a change, to keep per-frame work, allocations, invalidation and GPU cost minimal.
---

# Performance in MetalGraphics

Every feature here runs inside a frame. Decide what a change costs per frame *before* writing
it, follow the patterns the code already uses, and measure when unsure. The rules below point at
real code: read the cited symbol when a rule applies.

## 1. The frame

At 60–120 Hz the whole frame is 8–16 ms, CPU and GPU. One frame
(`MetalGraphicsLib/RootViewRenderer.swift`, `frame(drawable:)`, run by each open window on its own
thread, in parallel — `MetalGraphicsLib/docs/Threading.md`):

1. The input events queued since the last frame are applied to `Input`.
2. `UIContext.update` — hit-test (only on mouse input), `animator.tick`, layout (only if
   `.layout` is pending).
3. If `!uiContext.needsRender`, stop: nothing is encoded or presented.
4. `UIContext.render` walks `paintOrder` into `Graphics2D`, which bins shapes into a grid and
   runs one compute pass (`compute2D` in `Shaders/Shaders.metal`).
5. Nothing to draw and nothing animating (`UIContext.isIdle`): the window pauses its display
   link until something is posted to it.

**An idle app must do ~nothing.** Anything that invalidates `.render` every frame without a
visible change (a timer, a no-op setter, an animation that never ends) breaks this, and keeps
its window's display link running.

**Shared state is contended.** Windows run at once, so anything two windows touch per frame —
a static, a shared cache, a lock, a shared object's reference count — makes each slower the more
windows animate. Keep per-frame state in the window (`UIContext`, `Graphics2D`) or in
`ThreadState`; read shared caches through a per-thread front cache, as `FontManager` does.

## 2. Invalidation — name the narrowest effect

`UIContext.invalidate(_:)` expands a kind to what follows from it; callers name only the direct
effect.

- `.render` for paint-only changes (color, opacity). `.layout` for size, inset, spacing, text.
  `.treeOrder` only when mounting, or inserting/removing/reordering children. Never `.all`.
- Animated writes run every frame, so they must never cause `.treeOrder` — that re-walks the
  whole tree (see the comment in `invalidate(_:)`).
- A new element property gets a setter in `UIElement+ReactiveSetters.swift` following the
  existing pattern: a capture-free closure with `unsafeDowncast`, so generated code stays one
  direct call with no allocation. Register its argument spelling in `ElementCatalog.swift`.
- Skip the write when the value is unchanged, if the setter can be hit repeatedly (hover, drag).
- A `@Model` write reaches every subscribed component in every window, each through one
  `__modelDidChange` call, and it notifies no one when the value is unchanged. Another window
  gets one posted message per burst of writes, not one per write. Each read and write takes the
  model's lock. Keep model writes out of per-frame code, as with `@State`. A read of a computed property or method
  (`self.model.summary()`) subscribes to every write to the model: prefer reading stored
  properties in hot components.

## 3. Hot paths — per frame, or per element per frame

- **No heap allocation.** Reuse storage with `removeAll(keepingCapacity: true)` (as
  `Graphics2D.beginFrame`, `UIContext.rebuildTreeOrder`). No capturing closures, `String`
  building, `print`, `map`/`filter` producing throwaway arrays, or boxing into `any P`.
- **Flat arrays + indices over pointer chasing.** `effectOrder`/`effectParents` and
  `clipOrder`/`clipParents` resolve parents-first in one linear pass instead of each node walking
  its ancestors. Copy that shape for any new inherited per-node state.
- **Cast once, not per frame.** `UIContext.collect` does `as?` checks when the tree order is
  rebuilt; the per-frame loops then work on concrete arrays.
- **Work proportional to change, not tree size.** Gate on `pending` flags; cache and rebuild on
  invalidation only (`rebuildTreeOrder`, `rebuildHitGrid`). Hit-testing runs only on mouse input,
  and once more when content moved under a still pointer comes to rest (the re-hover at the end
  of `UIContext.update`): never once per frame of an animation or a scroll.
- **Cull early.** Empty clips skip their draws; `Graphics2D.mapToGrid` does not file shapes
  clipped away entirely, which is what keeps long scrolled content cheap. New drawables must
  report tight bounds and respect the clip.
- **Drags move by offset, commit once.** Something that follows the pointer is drawn there by
  an effect offset and laid out when the drag ends (`DockFloatView.dragOrigin`), so a move is
  `.render` only. Shared state — a `@Model`, a `DockSpace` — is written on release, never per
  move.
- ARC: don't shuffle element references through temporaries or arrays in tight loops;
  `unowned` or indices where lifetime is guaranteed (`ListRows.stack`, `LayoutPass.context`).

## 4. GPU and Metal (`Graphics2D.swift`, `Shaders/Shaders.metal`)

- Append into the existing per-type arrays and the single `ShapeArgBuffer`. No per-shape
  encoders, command buffers, pipelines or `makeBuffer` calls.
- `MTLBuffer`s grow with slack only when the count exceeds capacity (see the
  `circleBufferCount` growth in `Graphics2D`); never reallocate every frame.
- Textures are created and uploaded once (`ImageManager`), then referenced by index through the
  texture table.
- In `compute2D` the cost is pixels × shapes per grid cell. Keep a new shape's SDF cheap and its
  bounding box tight (bounds decide how many cells it lands in); avoid data-dependent loops and
  divergent branches per pixel.
- Keep Swift and Metal struct layouts matched; prefer packed/`simd` types already in use.

## 5. Layout and text

- `calcSize`/`calcPosition` should be O(children). Measure a child twice only when the layout
  genuinely needs it (flex), and say so in a comment.
- Text shaping is the expensive part: `Text` reshapes only when its text or style changed, and
  reuses `layout` for relayouts caused by anything else. Keep it that way for any new
  text-bearing element.

## 6. Lists and scrolling

- Lists go through `ListRows`, keyed by `ID`, so rows are reused across reorders. Prefer the
  incremental paths (`insertRow`/`removeRow`, i.e. the generated `@State` array mutation
  methods) over reassigning the whole array, which falls back to an O(n) `setItems`.
- Scrolling moves content; it must not rebuild rows or reshape text.

## 7. Measure, don't guess

- **Micro:** wrap a suspect call in `benchmark(title:mean:)` (`MetalGraphicsLib/Benchmark.swift`)
  — prints µs, averaged with `mean: true`. Remove it before finishing.
- **Whole app:** build Release and launch it the way the `drive-app` skill does
  (`-configuration Release`). Never measure a build instrumented for code coverage (`xcodebuild
  test -enableCodeCoverage YES`, or coverage turned back on in the scheme): every function call
  writes its counters, and with several windows animating their threads contend for them, so each
  frame slows down several times over. The scheme keeps coverage off, so a plain build is clean;
  `nm <app>/Contents/Frameworks/MetalGraphicsLib.framework/MetalGraphicsLib | grep -c ___profc_`
  prints 0. Idle CPU (`top -pid $(pgrep -x GPURayMarching) -l 3`) should be ~0%; then drive the
  feature and compare. `METALGRAPHICS_PROFILE=1` prints each window's frame phases every two
  seconds. For deeper work: Instruments (Time Profiler, Allocations, Metal System Trace) or an
  Xcode Metal frame capture.
- **Several windows:** check a per-frame change with 3–6 windows animating at once (⌘N, and the
  Redraw demo's stress rows), not just one: shared state shows up only then.
- **Scale:** try a new element or shape with many instances — hundreds of rows in
  `ScrollDemo`, many shapes on screen — before calling it done.

## 8. Before finishing

State these in the summary of any feature change:

- What now runs per frame that did not before, and does it allocate?
- Which invalidation kinds the change triggers, and how often (once, per interaction, per frame
  while animating)?
- Does the app still go idle when nothing changes?
- How cost scales with element count, shape count and window size.
- Any deliberate trade-off (clarity over speed, or the reverse) — named, not hidden.
