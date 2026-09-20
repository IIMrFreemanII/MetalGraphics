# State tracking in RetainedModeUI

Every reactive update rests on one rule: **reading `wrappedValue` while a tracker is active records that `State` as a dependency.**

## 1. The pieces

| Piece | File | Role |
|---|---|---|
| `State<T>` | [State.swift](../MetalGraphicsLib/RetainedModeUI/State/State.swift) | Holds a value. The `wrappedValue` getter calls `DependencyTracker.record(self)`. Setting it calls every `onChange` handler. `.value` is the untracked way to read it. |
| `DependencyTracker` | same file | A static **stack** of trackers. `track { … }` pushes a fresh tracker, runs the closure, pops it, and returns `(result, statesRead)`. `record` adds only to the top tracker. |
| `Reaction<T>` | [StateBindable.swift](../MetalGraphicsLib/RetainedModeUI/State/StateBindable.swift) | **The one reactive primitive.** It evaluates an expression under a tracker, subscribes to the states it read, and re-evaluates on change, re-tracking each time. Both property bindings and builder content are built on it. |
| `bind(_:to:)` | same file | Creates a `Reaction` for one property expression, e.g. `self.color`, and assigns each new value through a key path. |
| `DynamicContent` | [UIElementBuilder.swift](../MetalGraphicsLib/RetainedModeUI/Core/UIElementBuilder.swift) | Makes a `Reaction` out of a builder closure. Its `compute` is "run the builder, reconcile against the previous structure, flatten". |
| `reactions` / `setContent` / `applyContent` | [UIElement.swift](../MetalGraphicsLib/RetainedModeUI/Core/UIElement.swift) | Every element holds one `reactions` list, activated on mount and cancelled on unmount. Content is just another reaction in that list; containers override `applyContent` to say how to apply the result. |

## 2. Construction: building the tree (nothing is subscribed yet)

```swift
VStack(spacing: self.gap) {
  if self.isLoggedIn { Rectangle(.green) } else { Rectangle(.blue) }
  Rectangle(self.color).frame(width: self.w, height: 100)
}
```

1. **`VStack.init`** runs first:
   - `bind(\.spacing, to: spacing)` evaluates the autoclosure `self.gap` inside `DependencyTracker.untracked`. That pushes a throwaway tracker, so the read of `gap` is not recorded by any outer builder. The result sets `spacing = 10`.
   - It appends the `Reaction` to `reactions`. The value is set, but nothing is subscribed yet.
2. **`setContent(content)`** creates the content `Reaction`, whose `compute` calls the builder inside `DependencyTracker.track`:
   - **Tracker A is pushed** (the VStack builder's tracker).
   - The closure runs. `if self.isLoggedIn` reads `wrappedValue`, so **`isLoggedIn` is recorded in A**.
   - `buildEither(second:)` wraps the result as `ConditionalBranch(tag: 1, [Rectangle(.blue)])`.
   - `Rectangle(self.color)` calls `bind(\.color, …)`, which evaluates `self.color` under **its own tracker B**, pushed on top of A. The read is recorded in B, which is then discarded, so **`color` does not go into A**. The same happens for `self.w` inside `.frame(…)`.
   - Tracker A is popped. The reaction keeps `dependencies` (just `isLoggedIn`) and its `value`, the flattened list that becomes `children`. `DynamicContent` remembers the unflattened `structure`, branch markers included, for the next reconciliation.

**Why the stack matters:** each closure's reads go only to the innermost active tracker. Conditions in the builder body belong to the container, and element arguments belong to that element. Changing `color` never re-runs the `VStack` builder.

## 3. Mount: subscriptions start

`handleMount` runs top-down. Each element runs this sequence:

1. `mount(context)`, the element's own hook, e.g. registering as renderable.
2. **`activateReactions(context)`**: every reaction in the list, property bindings and content alike, subscribes via `state.observe { run() }` to the states recorded at init.
   - On a **first** mount this only subscribes, since the value from `init` is still current.
   - On a **remount** it re-evaluates first, to pick up changes made while unmounted.
3. Mounts its children, setting each child's `depth` from the parent first.

The result is a set of per-state handlers:
- `color` → the Rectangle's observer
- `w` → the Frame's observer
- `gap` → the VStack spacing observer
- `isLoggedIn` → the VStack's `DynamicContent`

## 4. A property change: `self.color = .black`

1. The `State.value` `didSet` calls each handler, which is the Rectangle's `Reaction.run()`.
2. `run()` re-evaluates `self.color` under a fresh tracker. It **re-tracks**: it cancels the old subscriptions and subscribes to whatever was read this time. So `cond ? a : b` follows whichever branch of the expression is currently used.
3. `apply` sets `rectangle.color = .black` and calls `context.invalidate(layout: false)`.
   - For `.frame` size, padding inset, spacing, alignment and axis, the binding was registered with `layout: true`, so it sets `dirtyLayout` too.
4. The next frame draws the new colour. There is no rebuild and no remount.

## 5. A condition change: `isLoggedIn.toggle()`

1. The VStack's content reaction runs:
   - Its `compute` re-runs the whole builder closure under a new tracker A′. This constructs **new** element instances for every statement.
   - **`reconcile(old, new)`** walks the two structures index by index. This is safe because every statement produces exactly one entry:
     - **Branch with a different tag** (1 → 0): take the new branch, i.e. the new green `Rectangle`.
     - **Branch with the same tag**: keep the old branch and recurse into its elements.
     - **Plain element**: keep the **old** instance and discard the freshly built one. The discarded one was never mounted, so it holds no subscriptions and nothing leaks.
   - It flattens the new structure and re-subscribes to A′'s dependencies. The new branch might read different states.
2. The reaction's `apply` calls `applyContent`, which for `MultiChildElement` is `replaceChildren(elements, context)`:
   - children that disappeared (`===`, i.e. compared by instance) → `handleUnmount`. That unregisters them as renderable/hittable and cancels their bindings.
   - new children → `calcDepth` then `handleMount`, which runs the sequence from section 3 for the new subtree.
   - `dirtyLayout = true`.
3. The sibling `Rectangle(self.color)` is the same instance, so its hover state and bindings are untouched.

## 6. How it lands on screen (same frame)

`TestViewRenderer.draw(in:)` runs these steps in order:

1. **Hit-test**: `onTap` runs and flips the state, so sections 4 and 5 happen synchronously right here.
2. **Layout if `dirtyLayout`**: the new children get their sizes and positions. `dirtyGrid` is set so the next hit-test rebuilds the grid.
3. **Render**: draws the laid-out tree.

This order matters. If layout ran before hit-testing, an element mounted by `onTap` would be drawn once before it had been laid out, and the UI would blink for one frame.

## 7. Unmount

`handleUnmount` runs this sequence:
1. `deactivateReactions()`, which cancels every subscription, for properties and content alike.
2. `unmount(context)`, the element's own hook.
3. It unmounts the children.

The reactions themselves are kept, along with their expressions and the builder closure. A later remount re-evaluates them, so it picks up any changes made while the element was detached.

## Rules that follow from this flow

- **Tracked:** `self.isLoggedIn`, which reads `wrappedValue`.
- **Not tracked:** `_isLoggedIn.value`.
- Reads **in the builder body** (conditions) re-run the builder. Reads **inside element arguments** only update that element.
- A value copied into a local first (`let c = self.color; Rectangle(c)`) is read by the builder's tracker, not the element's. It triggers a pointless builder re-run, and the reconciler keeps the old element with the old value.
- Event handlers like `onTap` and timers run with no tracker active, so their reads are never recorded.
- `for` loops in builders are unsupported. Use `VList` / `HList` for collections.
- `if let` swaps content only when the value flips between nil and non-nil.
- Builder closures and element arguments are stored (`@escaping`), so inside a class they need an explicit `self.`. A closure that captures `self` keeps it alive. Use `[unowned self]` for trees that don't live for the whole app.
