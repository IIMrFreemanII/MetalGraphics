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
| `UIElementBuilder` | `RetainedModeUI/Core/` | Now only a type-checking surface for `body`, plus the builder for hand-written trees. |
| `ListRows` | `RetainedModeUI/Layout/` | A row cache keyed by `T.ID`, plus the three doors a list is driven through. Memoization, not reactivity — it is told what changed, never asked. |

## 2. What a component looks like

```swift
@Component
final class ToggleDemo: SingleChildElement {
  @State var color: float4 = .blue
  @State var isLoggedIn: Bool = false

  @UIElementBuilder var body: [UIElementNode] {
    VStack(spacing: 10) {
      if self.isLoggedIn {
        Rectangle(.green).frame(width: 100, height: 100)
      } else {
        Rectangle(.red).frame(width: 100, height: 100)
      }
      Rectangle(self.color)
        .frame(width: 100, height: 100)
        .onHover { [weak self] hovered, _ in self?.color = hovered ? .black : .red }
        .onTap   { [weak self] _ in self?.isLoggedIn.toggle() }
    }
  }
}
```

`body` is **read but never executed**. It stays in the source so the declarative form still
type-checks, which is why every element initializer keeps its `@autoclosure @escaping`
signature. The macro emits straight-line construction instead.

## 3. What gets generated

Node fields are named from the statement path, so they are stable and readable in a debugger:
`__n0` is the VStack, `__n0_1a` the `Rectangle(self.color)`, `__n0_1b` its `Frame`.

```swift
private var __context: UIContext?
private var __n0_1a: Rectangle?
private var __tag0_0: Int = -1

private func __update_color() {
  guard let context = self.__context else { self.__needsRefresh = true; return }
  if let n = self.__n0_1a { n.setColor(self._color, context) }
}

private func __update_isLoggedIn() {
  guard let context = self.__context else { self.__needsRefresh = true; return }
  self.__swap0_0(context)     // compare tag; on a flip build the new arm and re-apply children
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

## 6. Composition, not helper methods

The macro cannot see inside a method, so a helper that returns an element is a compile error
(F1). Extract it into its own `@Component` instead. That is also the only way to give a list row
its own state:

```swift
@Component
final class RowView: SingleChildElement {
  let item: DemoItem
  @State var hovered: Bool = false
  @UIElementBuilder var body: [UIElementNode] { … }
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
| F9 | *(warning)* a stored handler capturing `self` strongly — the fix is `[weak self]` |
| F10 | a list's `items:` that is not a direct `@State` array reference |
| F11 | a generated mutation method colliding with one the component declares |

F3 is worth calling out: under the old tracking system it failed **silently**, binding the
value to the wrong tracker and leaving a stale element. It is now a compile error.

F7's replacements are not macro output. `onMount(_:)` and `onUnmount(_:)` are `open` members of
`UIElement`, called by its mount traversal, so they are reachable from the type: Xcode offers them
in the `override` completion list, and they work the same on a plain element as on a component.
Write `override func onMount(_ context: UIContext)`. `mount`/`unmount` stay the element's own
mount behaviour, which is what `@Component` generates and why writing one is F7.

## 8. How it lands on screen

`TestViewRenderer.draw(in:)` runs, in order:

1. **Hit-test** — handlers fire, so generated setters run synchronously here.
2. **Layout if `dirtyLayout`**.
3. **Render** the flat, depth-sorted renderable list.

That order matters: laying out before hit-testing would draw an element mounted by `onTap` once
before it had a position, and the UI would blink for one frame.
