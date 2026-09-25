# Compile-time state in RetainedModeUI

Every reactive update rests on one rule: **which element property a `@State` feeds is decided
when the code is written, so the generated setter assigns into that property directly.**

There is no dependency tracking, no subscription, and no diffing at runtime. A state change is a
store plus a dirty flag.

## 1. The pieces

| Piece | Where | Role |
|---|---|---|
| `@State` | `ReactiveUIMacros/Sources/ReactiveUI/Macros.swift` | Accessor + peer macro. Adds `private var _x` and an init accessor; `set` and `_modify` both call `__update_x()`. Needs an explicit type annotation. |
| `@Component` | same | Member + extension macro. Reads `body`, emits one field per node, `__build`, the branch machinery, `mount`/`unmount`, one `__update_<state>` per state, and mutation methods for each `@State` array. |
| `ElementCatalog` | `Sources/ReactiveUIMacrosPlugin/ElementCatalog.swift` | Which constructor/modifier argument feeds which property. The macro resolves *spellings*, not types. |
| `UIElement+ReactiveSetters.swift` | `RetainedModeUI/Core/` | `setColor`, `setSize`, `setSpacing`… Each one knows whether it invalidates layout or only render. |
| `UIElementBuilder` | `RetainedModeUI/Core/` | Now only a type-checking surface for `body`, plus the builder for hand-written trees. Yields elements directly. |
| `Binding` | `RetainedModeUI/Core/` | What `$state` spells. Lowered at compile time in a body (§5, *Bindings*); a real get/set pair elsewhere. |
| `ListRows` | `RetainedModeUI/Layout/` | A row cache keyed by `T.ID`, plus the three doors a list is driven through. Memoization, not reactivity — it is told what changed, never asked. |
| `Animator`, `UIAnimation`, `withAnimation` | `RetainedModeUI/Animation/` | Per-frame driving of animated setters, the curves, and the transaction `withAnimation` sets. See §9. |
| `EffectElement`, `TransitionElement` | `RetainedModeUI/Animation/` | Visual-only opacity/offset/scale, and the insert/remove transitions built on them. |

## 2. What a component looks like

```swift
@Component
final class ToggleDemo: SingleChildElement {
  @State var color: float4 = .blue
  @State var isLoggedIn: Bool = false

  @UIElementBuilder var body: [UIElement] {
    VStack(spacing: 10) {
      if self.isLoggedIn {
        Rectangle(.green).frame(width: 100, height: 100)
      } else {
        Rectangle(.red).frame(width: 100, height: 100)
      }
      Rectangle(self.color)
        .frame(width: 100, height: 100)
        .onHover { hovered, _ in self.color = hovered ? .black : .red }
        .onTap   { _ in self.isLoggedIn.toggle() }
    }
  }
}
```

`body` is **read but never executed**. It stays in the source so the declarative form still
type-checks; the macro emits straight-line construction instead. Element initializers therefore
take plain values, and no builder signature needs `@autoclosure`: nothing is deferred, so a
builder run hands back the elements its expressions produced, in order and built exactly once.

## 3. What gets generated

Node fields are named from the statement path, so they are stable and readable in a debugger:
`__n0` is the VStack, `__n0_1a` the `Rectangle(self.color)`, `__n0_1b` its `Frame`.

```swift
private var __context: UIContext?
private var __n0_1a: Rectangle?
private var __tag0_0: Int = -1

private func __update_color(_ animated: Bool = true) {
  guard let context = self.__context else { self.__needsRefresh = true; return }
  let transaction = animated ? UITransaction.animation : nil
  if let n = self.__n0_1a { n.setColor(self._color, context, animation: transaction) }
}

private func __update_isLoggedIn(_ animated: Bool = true) {
  guard let context = self.__context else { self.__needsRefresh = true; return }
  let transaction = animated ? UITransaction.animation : nil
  self.__swap0_0(context, animation: transaction)  // compare tag; on a flip build the new arm and re-apply children
}
```

A hover is one store and one `invalidate()`. A tap is one tag compare, one subtree
construction, and one `replaceChildren`.

## 4. Rules that follow

- An argument's expression is **copied verbatim** into the setter, with only `self.x` rewritten
  to `self._x`. That is why `Rectangle(self.isOn ? .red : .blue)` works without the macro
  understanding ternaries.
- An expression reading *n* states is emitted into all *n* update methods. When a
  non-deciding state changes, the same value is written back — a redundant store, still far
  cheaper than the subscribe/re-track cycle it replaced.
- An untaken branch has **nil node fields**, so `if let n = …` *is* the liveness check.
- `.frame(width:height:)` collapses into the single property `Frame.size`. Modifier chains
  desugar into one node field per link, and the generated code calls the modifier itself.
- **Closure bodies are never dependency sites and are never rewritten.** `self.color = …`
  inside `onHover` is a write through the public setter, which is exactly what triggers the
  update.
- State changed while unmounted sets `__needsRefresh`; the next mount replays every setter.
- `@State` also gets a `_modify` accessor, so an in-place mutation (`self.items.append(x)`,
  `self.flag.toggle()`) yields the storage instead of copying it out and back, and fires the
  update once the yield returns.

## 5. Collections are just `@State` arrays

There is no separate collection type. A list's rows live in an ordinary `@State` array, so
`Float(self.items.count)` and `if self.items.isEmpty` are ordinary state reads needing no special
case in the scanner, and `VList`/`HList` take `items: [T]` like any other argument.

```swift
@State var items: [DemoItem] = [...]

VList(spacing: self.spacing, items: self.items) { item in RowView(item: item) }
```

The list's node field is `VList<DemoItem>?`. The macro gets that `DemoItem` from the **written
annotation** of the `@State` being passed, which is the only place a macro can find it — hence
F10: a list's `items:` must be a direct `self.<name>` reference to a `@State` array, not a
computed expression.

### Mutation carries the operation

A plain assignment can only say *the array is different now*, so it rebuilds every row. To avoid
that, `@Component` generates one method per operation for each `@State` array, so the call site
names what happened and the generated code applies it directly:

| Generated for `items` | Effect |
|---|---|
| `appendItems(_:)` | append, then one `insertRow` per list |
| `insertItems(_:at:)` | insert (index clamped), then one `insertRow` per list |
| `removeItems(at:)` | remove, then one `removeRow` per list |
| `removeItems(where:)` | one match → incremental; zero or several → full rebuild |
| `replaceItems(_:)` | full rebuild; identical to `self.items = new` |

The incremental applier is `__update_items` with only the list lines swapped:

```swift
private func __items_didInsert(_ element: DemoItem, at index: Int) {
  guard let context = self.__context else { self.__needsRefresh = true; return }
  if let n = self.__n0_1a { n.setSize(float2(Float(self._items.count) * 24, 6), context) }  // unchanged
  if let n = self.__n0_2a { n.insertRow(element, at: index, context) }                      // was setItems
  self.__swap0_4(context)                                                                   // unchanged
}
```

Everything that is *not* a list re-runs its ordinary expression, because a count read or an
`isEmpty` branch has no incremental form however the array changed. An array that feeds no list
gets the mutation methods anyway; they simply fall through to the full update.

### The plain setter still works

`self.items = …`, or a write from outside the component, goes through `@State`'s ordinary setter
and triggers a full `setItems`. It is O(n) rather than O(1), but it is correct — and it is what
repairs the one invariant the fast path depends on, that each list's children stay index-for-index
with the array. Any full path restores that alignment.

`ListRows` caches elements by `T.ID`, so a row keeps its element — and therefore its own
`@State` — across a reorder or a remount.

Because a `@State` array is owned by exactly one component, a collection can no longer be shared
by reference between components. A child receives rows by value and is not reactive to the
parent's array; it calls back instead, as `RowView(onRemove:)` does.

### Bindings are lowered, not passed

`Toggle("Wi-Fi", isOn: $wifi)` passes no binding at runtime. A binding argument (an `ArgSpec` with
`binding:` in the catalog) is split at compile time into its two directions:

```swift
let n0a = Toggle("Wi-Fi", isOn: self._wifi)                        // built with the value
if let n = self.__n0a { n.setIsOn(self._wifi, context, animation: transaction) }  // in __update_wifi
self.__n0a?.onIsOnChange = { self.wifi = $0 }                      // in __armHandlers
```

A member path lowers the same way (`$audio.volume` reads `self._audio.volume` and writes
`self.audio.volume = $0`), and `.constant(v)` lowers to the value with no write-back. A numeric or
selection binding is wrapped in the control's `adapt`, which converts between the control's
`Double` or `AnyHashable` and the state's own type.

A control never changes its own value on input: it calls its change handler, and the value comes
back through the setter within the same event. The state stays the only source of truth, and a
control given a constant keeps it. `@State` still declares `$name` — a real `Binding` over the
property — for hand-built trees, but a body never evaluates it.

Constructor callbacks (`Button("OK") { … }`) are handlers too (`ArgSpec.handler`): dropped from
the constructor and armed on mount, so they never capture `self` for good.

### Named content closures

`Section { rows } header: { Text("Account") } footer: { … }` has three content closures. The
constructor's own is attached by arity as always; the others are listed in the catalog's
`namedContents` (`"header": "replaceHeader"`), taken out of the constructor, parsed like any
content under a path of their own (`0k0`, `0k1`), and applied through the method named. A branch
inside a header swaps and re-applies through that same method, like a content modifier's
`replaceContent`, which is now just one more such door.

## 6. Composition, not helper methods

The macro cannot see inside a method, so a helper that returns an element is a compile error
(F1). Extract it into its own `@Component` instead. That is also the only way to give a list row
its own state:

```swift
@Component
final class RowView: SingleChildElement {
  let item: DemoItem
  @State var hovered: Bool = false
  @UIElementBuilder var body: [UIElement] { … }
}
```

From the outside `RowView(item:onRemove:)` is an ordinary constructor call, opaque to the parent.

## 7. Diagnostics

| # | Rejected |
|---|---|
| F1 | a helper method in element position |
| F2 | `for` / `while` / `switch` in a body — use `VList`/`HList` |
| F3 | a local binding (`let c = self.color`) — it captures once and never updates |
| F4 | a constructor or modifier not in `ElementCatalog` |
| F5 | `@State` on a `let`, a `static`, a computed property, or without a type annotation |
| F6 | `@Component` on a non-class, or a missing/ill-formed `body` |
| F7 | a component declaring `mount`/`unmount` — use `onMount`/`onUnmount` |
| F8 | writing `self._color` in a body |
| F10 | a list's `items:` that is not a direct `@State` array reference |
| F11 | a generated mutation method colliding with one the component declares |
| F12 | `.animation(_:value:)` whose `value:` reads no `@State`, or written without `value:` |
| F13 | an in-place modifier (`.font`, `.foregroundColor`, `.resizable`, `.fill`, `.trim`, …) called on something other than the element it styles |
| F14 | a binding argument (`isOn:`, `text:`, `selection:`, …) that is neither `$state[.member…]` nor `.constant(v)` |

F9 is retired, not missing: it warned that a handler capturing `self` strongly leaks, which stopped
being true once the macro started clearing handlers on unmount. The numbers are not reused.

F3 is worth calling out: under the old tracking system it failed **silently**, binding the
value to the wrong tracker and leaving a stale element. It is now a compile error.

Handlers are written with a plain strong `self` — no capture list. The closure is not emitted
into `__build` with the rest of the chain: the element stores it, so an inline closure would make
the component reachable from its own tree and neither would ever be released. Instead the chain is
built with an empty placeholder of the right arity and the real closure is assigned in
`__armHandlers`, called at the end of `mount` and again after a branch swap enters a new arm;
`__disarmHandlers` nils them at the start of `unmount`. The cycle therefore exists only while the
element is mounted, which is exactly when something above it is holding the subtree anyway. Both
methods are omitted entirely from a component with no handlers.

Two consequences worth knowing. A handler that arrives after its element unmounts is a no-op,
because the property is nil — the same outcome `[weak self]` gave, reached differently. And an
element built *outside* a `@Component` keeps whatever handler it was constructed with, since
`HittableView.unmount` is not involved: a hand-built tree that captures `self` strongly in a
handler still leaks, and nothing warns about it any more.

F7's replacements are not macro output. `onMount(_:)` and `onUnmount(_:)` are `open` members of
`UIElement`, called by its mount traversal, so they are reachable from the type: Xcode offers them
in the `override` completion list, and they work the same on a plain element as on a component.
Write `override func onMount(_ context: UIContext)`. `mount`/`unmount` stay the element's own
mount behaviour, which is what `@Component` generates and why writing one is F7.

## 8. How it lands on screen

`TestViewRenderer.draw(in:)` calls `UIContext.update` and then `UIContext.render`, which run, in order:

1. **Hit-test** — handlers fire, so generated setters run synchronously here.
2. **Advance animations** — `Animator.tick` writes each running animation's value through the
   element's own setter, which invalidates exactly what a plain write would.
3. **Layout if `.layout` is pending** — setters and child changes call `invalidate(.layout)`.
   When a change made with an animation caused it, elements the pass moves within their
   container start sliding from where they were drawn (§9, *Sliding layout*).
4. **Render** the registered renderables in paint order: tree pre-order, rebuilt only when
   the tree changed. Layout alone does not rebuild it: moving things never reorders them. When
   nothing is pending, `TestViewRenderer` skips the GPU pass entirely and the last frame stays
   on screen.

That order matters: laying out before hit-testing would draw an element mounted by `onTap` once
before it had a position, and the UI would blink for one frame.

## 9. Animation

Animation follows the same rule as everything else: **which binding animates, and with what, is
decided when the code is written.** At runtime an animated write is the ordinary setter plus an
`animation:` argument.

### Scopes

```swift
Text(self.hovered ? "remove" : self.item.name)
  .padding(self.hovered ? Inset(all: 16) : Inset(all: 8))
  .background(self.hovered ? .black : self.item.color)
  .animation(.easeOut(0.2), value: self.hovered)
  .onHover { hovered, _ in self.hovered = hovered }
```

`.animation(A, value: V)` is a marker, not an element: it adds no node and no field, and at
runtime returns the element it was called on.

- **Triggers** are the states `V` reads. Only their update methods animate through this scope.
- **Scope** is the links *before* the marker in its chain, plus everything under the element:
  children, nested elements, branch swaps, list rows. Links after it are outside.
- **Nesting**: for a given state, the innermost scope that state triggers wins.
- **What animates** is every *animatable* setter (`ElementCatalog`'s `animatable:` flag): colours,
  `Frame` size, `Padding` inset, stack spacing, `opacity`, `offset`, and a `Text`'s color and
  font size. Text, alignment and axis cannot be interpolated: they snap, but take the animation
  anyway and hand it to the layout change, so whatever they move slides.
- `A` is copied like any argument. When it reads no state and names neither `self` nor `Self`
  it is hoisted into a `private static let __anim<path>_<n>`, so a spring's coefficients are
  computed once. `Self.x` is left in place — a stored property's initializer cannot reference
  `Self` — and is already a static built once.

### `withAnimation`

```swift
.onTap { _ in withAnimation(.spring()) { self.size = self.size == 24 ? 48 : 24 } }
```

Sets `UITransaction.animation` for the duration of the closure. A `@State` write runs its update
synchronously, so every animatable binding that **no scope claims** reads it. Outside
`withAnimation` it is nil, and those bindings snap as they always did. A scope always wins over
the transaction. SwiftUI declares the same name: a file importing both must write
`MetalGraphicsLib.withAnimation` (and `Editor.swift`, inside the library, writes
`SwiftUI.withAnimation`).

**Completion.** `withAnimation(_:_:completion:)` runs `completion` once everything the body
started is over:

```swift
withAnimation(.easeOut(0.3)) { self.removeItems(at: 0) } completion: { self.removed += 1 }
```

The body's animations join an `AnimationGroup`; each leaves it however it ends — arriving,
replaced by a later animation, cancelled, or snapped by an unmount — so a retargeted animation
counts as over. A layout pass the body caused holds the group until its slides have joined, so a
row removal completes after the rows below have finished sliding. With nothing animating the
completion runs as soon as the body returns; otherwise from the frame loop, after that frame's
removals. A nested `withAnimation` without a completion feeds the outer group. A `repeatForever`
never completes.

Every update method takes `_ animated: Bool = true`. The remount replay (`__refreshAll`) passes
`false`: changes made while nothing was on screen are never animated.

### The runtime

- **Presentation and model.** The element's property is the presented value and `@State` is the
  model. Retargeting mid-flight therefore starts from wherever the element is, and a spring keeps
  its velocity.
- **`Animator`** keeps running animations in one flat array of a concrete struct. Values are packed
  into `SIMD4<Float>` (`UIAnimatable`), keys are `(ObjectIdentifier, AnimatedProperty)`, and removal
  is swap-remove. One tick is a linear pass: sample, write through the setter's closure.
- **Redundant writes are free.** Re-animating towards the target already in flight is a no-op, and
  so is a plain write of that same target. That is what keeps a multi-state expression (§4) from
  restarting or snapping an animation when an unrelated state it reads is written.
- **Unmounting snaps.** An element's animations finish at their targets when it unmounts, which is
  what lets the animator hold elements without retaining them.
- **Springs settle.** A spring ends once no lane can be more than a small fraction of the distance
  travelled from its target, instead of running out its asymptotic tail.
- **Mounting elements wait.** An animation started on an element that is not mounted yet — a
  component's `onMount` runs before its children mount — is held until the next tick, and starts
  then if the element has mounted (it snaps if not). So `onMount` can start an animation, e.g. a
  `repeatForever` pulse.

### Effects and transitions

`.opacity(_)` and `.offset(_)` wrap content in an `EffectElement`. `.transition(_)` wraps it in a
`TransitionElement`, which plays a `UITransition` (`.opacity`, `.move(_:)`, `.scale(_:)`,
`.combined(with:)`, `.asymmetric(...)`) when an animated change inserts or removes it.

- Effects are **visual only**: layout and hit-testing see the content where it was laid out.
- `UIContext` resolves effects once per frame in tree order, each composed onto its parent's, and
  hands every renderable its resolved state; there is no per-renderable walk up the tree.
- A parent finds a child's transition by walking down through wrappers that draw nothing (frames,
  paddings, hittables, components), so `.transition(.opacity).onTap { … }` still transitions.

**Shadows.** `.shadow(color:radius:x:y:)` wraps content in a `ShadowElement` (color defaults to
black at 0.33; every argument is bound and animates on its own). Like SwiftUI without a
`compositingGroup`, every shape under it casts its own shadow just beneath itself, so text on a
shadowed card shadows the card; put the shadow on the background to avoid that. It is drawn from
each shape's distance field in the same pass — a Gaussian of standard deviation `radius`
reaching 3σ past the shape — so there is no offscreen pass.

- Clips *above* the shadow cut it; a clip *below* it (`.cornerRadius(12).shadow(...)`) shapes it
  without cutting it: the shadow is drawn under a soft clip, the innermost clip's rounded rect
  blurred with it. Clips between that one and the shadow do not shape it.
- Nested shadows each cast one, outermost beneath; a shadow of a shadow is not drawn.
- `UIContext` resolves shadows once per frame, parents first, scaled by the effects above them;
  `Graphics2D` emits the copies, so renderables know nothing about shadows.
- Approximations: text and baked paths extend their distance field past its baked padding, so a
  large blur is slightly off far from the outline; a bitmap's blur is its alpha sampled at a
  coarser mip level; a cropped (`scaledToFill`) bitmap casts its visible rect's shadow.

**Blur.** `.blur(radius:)` wraps content in a `BlurElement` (the radius is bound and animates).
It works the way a shadow does: every shape under it is drawn with a Gaussian edge of standard
deviation `radius`, straight from its distance field, so no pass is added. Overlapping shapes
each blur on their own instead of blurring as one composite, which is close to a true blur but
not exact. Nested blurs combine as Gaussians do, `√(σ₁² + σ₂²)`, and scale with the effects
above them. A blurred shape's shadow is blurred by both. A whole bitmap blurs by sampling a
coarser mip level over a quad grown by 3σ; a cropped one blurs only inside its rect, so its edge
stays hard. Circles and lines, which are debug primitives, stay sharp.

**Glass.** `.glass(_ material:, in: shape)` puts a frosted `GlassBackground` behind content,
fitted to it like `.background`: what is drawn below it, blurred, made more vivid, under a
tint, with grain. The presets are `.ultraThin`, `.thin`, `.regular` and `.thick`, or build a
`GlassMaterial(blurRadius:tint:saturation:noise:)`. The material is bound, but it snaps instead
of animating; the shape animates.

- Each glass costs three compute passes over its own area before the frame, plus how far its
  blur reaches: `backdrop2D` renders everything below it, then `glassBlur` blurs that along x
  and then along y into the glass's region of the glass atlas. The main pass then samples that
  region. The backdrop is rendered at a lower resolution (up to 1/8) chosen so the blur stays at
  about 3 to 6 texels, so a large radius is no more expensive than a small one.
- Glass stacks. Passes run lowest glass first, so a glass above another sees the lower one
  already frosted.
- A frame without glass runs a main-pass pipeline compiled without the glass branch: glass costs
  nothing until one is drawn.
- Limits: the panel's own edge is never blurred, even under `.blur`. A rounded clip cuts the
  panel, not its backdrop. If the atlas cannot grow any taller (16384 texels), the extra glass
  is drawn as its tint alone.

**Leaving children.** Removed with an animation, a child with a transition stays in its parent
until the transition ends, marked `isLeaving`: still drawn, no longer hit, and not counted by the
logical indices `insertChild`/`remove(at:)` take. That keeps a list's children index-for-index
with its array while rows animate out. A leaving child that comes back turns round from where it
got to. A leaving child is out of layout from the start: in a `VStack`/`HStack` it is drawn where
it was last placed within the stack (it still moves with the stack) while the gap closes and the
children after it slide up; under a single-child parent it is drawn under the new child, which
reads as a crossfade. A list row gets a transition simply by adding `.transition(...)` inside
`onCreate`.

### Sliding layout

Layout changes made with an animation move things smoothly without any modifier: a removed row's
siblings slide up while it fades, an inserted row pushes the rows after it down, a reordered list
slides its rows, and a new text or alignment slides whatever it pushes.

- **Which changes.** Structural changes made with an animation — `replaceChildren`, `insertChild`,
  `remove(at:)`, `setChild`, and so branch swaps and list edits — and `setText`, `setAlignment`
  and `setAxis` with one. They pass it to `invalidate(.layout, animation:)`; the next layout pass
  is then *animated*. Writes from a running animation never are: an animating frame size already
  moves its siblings a little every frame.
- **Who slides.** Stacks and frames position children through `place(_:at:in:)`, which records
  each child's position *relative to its container*. In an animated pass, a child whose relative
  position changed starts drawing at its old spot and slides to the new one. Relative, so that a
  moved container slides as one instead of everything under it sliding on its own.
- **How.** The slide is an offset animated to zero, drawn through the effect pass like `offset`:
  render only, no per-frame layout, and hit-testing already sees the new position. A slide
  interrupted by another layout change retargets from where it is drawn, keeping a spring's
  velocity.
- **Artifact.** In an animated pass, a sibling also being moved by a running size animation gets
  that one frame's step as a slide, and trails it briefly.

### Repeat and keyframes

`.repeatCount(n, autoreverses:)` and `.repeatForever(autoreverses:)` replay any animation. A cycle
is the curve's duration; a repeating spring's is its settling time, worked out once when it is
made. The value ends where it was set, so an even count that autoreverses jumps back at the end.
A `repeatForever` runs until the value is set again or the element unmounts, and keeps the UI
rendering every frame while it does.

```swift
Rectangle(.red)
  .opacity(self.pulsing ? 0.2 : 1)
  .animation(.easeInOut(0.7).repeatForever(), value: self.pulsing)
```

Keyframes come in two forms sharing one sampler (`UIKeyframe`: `.linear`, `.easeIn`, `.easeOut`,
`.easeInOut`, `.spring(_:duration:…)`, each moving from where the previous keyframe ended):

- **A keyframed curve**, `UIAnimation.keyframes([...])`, in *progress*: 0 is where the value
  starts, 1 where it was set, and values past either overshoot. It goes anywhere an animation
  does — scopes, `withAnimation`, transitions — but cannot move a value that is already where it
  was set.
- **Value keyframes**, `.keyframes(UIKeyframes(opacity:offset:scale:), trigger: self.x)`, play
  absolute values on their own effect layer each time `trigger` changes, so they move things in
  place: a shake, a bounce. Only `trigger:` is reactive; the tracks are built once. A play is one
  animator entry, a clock sampled against every track, and ends on the last keyframes.

```swift
Text("Wrong")
  .keyframes(UIKeyframes(offset: [
    .linear(float2(-8, 0), duration: 0.05),
    .linear(float2(8, 0), duration: 0.1),
    .spring(.zero, duration: 0.3),
  ]), trigger: self.shakes)
```

### Text styling

```swift
Text(self.title)
  .font(.system(size: self.big ? 24 : 14))
  .foregroundColor(self.hovered ? .red : .white)
  .animation(.spring(), value: self.big)
```

`.font(_:)` (a `TextFont`: `.system(size:)`, `.custom(_:size:)`) and `.foregroundColor(_:)` are
how a `Text` is styled; unset, it draws at 16pt in the default face, in black. They set the
`Text` they are called on and return it — no wrapper element. For
the macro they are *in-place* modifiers: links of their own whose field holds the same `Text`, so
scopes cover them by position like any link, and calling one on anything but a `Text` is F13.
`TextFont` is not named `Font`, which would clash with SwiftUI's.

`Image` works the same way. `Image(name)` takes its name reactively (`setName`), and
`.foregroundColor(_:)` is in place on it as on `Text`: an in-place modifier lists every type it
may be called on, and its link is typed as its receiver. `.resizable()`, `.aspectRatio(_:contentMode:)`,
`.scaledToFit()`, `.scaledToFill()`, `.renderingMode(_:)` and `.interpolation(_:)` are in place on
`Image` only, and constant: they have no setter, so they are built once with the image and a
`@State` they read is read then and never again.

A `VectorCanvas(width:height:)` holds shapes — `Circle`, `Ellipse`, `RoundedRectangle`, `Capsule`
and `Path` — whose constructor arguments are reactive like any element's. Their modifiers are in
place on the shapes. Two catalog features exist for them:

- **Per-argument setters** (`ModifierSpec.argSetters`). `.stroke(color, lineWidth:)` binds each
  argument to a setter of its own, `setColor` and `setLineWidth`, the way a constructor's
  arguments are bound, instead of combining them into one value. `.trim(from:to:)`,
  `.rotationEffect(_:anchor:)` and `.scaleEffect(_:anchor:)` do the same, so an argument that
  reads no state needs no binding.
- **In place or wrap** (`ModifierSpec.wrapsOtherwise`). `.offset`, `.opacity`, `.onTap`, `.onHover`
  and `.onPress` set a shape's own property when called on a shape, which is then hit only
  inside its outline, and wrap anything else as before. Only the wrapping modifiers do this; a
  modifier that is only in place is still F13 elsewhere.

At runtime the shape's versions win overload resolution because the general ones live in a
protocol extension (`UIElementWrapping`), which ranks below a concrete class's members.
A `Path`'s trailing builder closure is opaque, like a list's `onCreate`. `Path(value) { p, v in }`
rebuilds from `value` whenever it changes, and `Path(d:)` morphs when the new data has the same
commands.

Color and font size animate — `setFont` and `setForegroundColor` — and a new face snaps, since
glyphs cannot morph. The text is shaped once, at the size it animates to, and drawn scaled in
between: an animated size costs no shaping per frame, and wraps as it will at the end. A color
change alone no longer reshapes at all.

### Costs to know

- Animating a layout property (`frame`, `padding`, spacing) re-lays out every frame. Tree order is
  not rebuilt and a `Text` whose offered size did not change is not reshaped, but a `Text` inside
  the animating container is offered a new size each frame and is. Prefer `opacity`, `offset`
  and colours, which only redraw, for large animated sets.
- Starting a slide on an element not already sliding rebuilds the tree order once, so the effect
  pass picks it up. Slides themselves only redraw.
- `repeatForever` keeps rendering every frame for as long as it runs.
- A shadow doubles the shapes it covers, and each copy spans 3σ more on every side, so it lands
  in more grid cells. Many large-radius shadows over one area fill cells toward
  `kMaxShapesPerCell`. Animating a shadow only redraws.

