# Navigation

SwiftUI's navigation API for RetainedModeUI: `NavigationStack`, `NavigationLink`,
`.navigationDestination(for:)`, `.navigationTitle`, `NavigationPath` and a two-column
`NavigationSplitView`. The runtime is in `RetainedModeUI/Navigation/`, the demo in
`GPURayMarching/NavigationDemo.swift` and the tests in `MetalGraphicsLibTests/NavigationTests.swift`
and `ReactiveUIMacros/Tests/.../NavigationMacroTests.swift`.

```swift
@State var path: [Route] = []

NavigationStack(path: $path) {
  VList(items: self.routes) { route in NavigationLink(route.name, value: route) }
    .navigationTitle("Routes")
    .navigationDestination(for: Route.self) { route in RouteView(route: route) }
}
```

## What is supported

| API | Notes |
|---|---|
| `NavigationStack { root }` | Owns its path: value links push onto it. |
| `NavigationStack(path: $path) { root }` | `path` is a `[T]` of one `Hashable` type or a `NavigationPath`. The state is the only source of truth. |
| `NavigationLink("Title", value: v)`, `NavigationLink(value: v) { label }` | Pushes the page a destination builds for `v`. |
| `NavigationLink("Title") { Destination() }`, `NavigationLink { Destination() } label: { … }` | Pushes that view. The page is not in the path. |
| `.navigationDestination(for: T.self) { value in … }` | Anywhere inside the stack, or on the stack itself. The newest destination for a type wins, then the enclosing host's. |
| `.navigationTitle(_:)` | The page's title in the bar, and the back button's label on the page over it. Reactive. |
| Back | The bar's back button, Escape (no modifiers) and ⌘[. At the root they pass the key on. |
| `NavigationSplitView { sidebar } detail: { placeholder }` | A value or view link in the sidebar selects what the detail column shows, and is highlighted. The detail column is a stack. |
| `NavigationSplitView(selection: $selected) { … } detail: { … }` | The selection is the state's: a value link reports to it, and the value comes back through `setSelection`. It is also how the split view starts on a selection, restored from the window's `UISceneStorage` in `Demos`. A nil selection shows the placeholder. |

Links are `Button`s, so `.buttonStyle`, `.disabled` and `.pointerStyle` work on them.

Not supported yet: toolbar items, `navigationBarBackButtonHidden`, a `dismiss` environment,
three columns.

## How it works

**Finding the host.** `UIElement.parent` is set when an element mounts and cleared when it
unmounts. Links, destinations and titles walk up to the nearest `NavigationHost` (a stack or a
split view) or `NavigationEntry` (a page), when they mount or on a tap. It is never read per frame.

**Pages.** A stack holds one `NavigationEntry` per page: the root, then one per path value or
view link. Covered pages stay mounted, so their `@State` survives, but are `isHidden`, which makes
`UIContext.collect` skip them whole. Only the top page is laid out.

**Push and pop.** `NavigationPages.setEntries` mounts the pages that arrived and unmounts the
ones that went. Only the old top page is animated: pages popped from under it unmount at once. One
animator entry (`AnimatedProperty.navigation`) drives a 0 → 1 progress that sets both pages'
horizontal `slide`. The incoming page comes in from the trailing edge, and the covered one moves
⅓ of the width (`NavigationMetrics.parallax`). While it runs the page area clips and neither page
takes hits. An interrupting push or pop, and unmounting, first finish the running one where it
was going.

Push and pop animate with the change's own animation, else `NavigationMetrics.transition`, as
SwiftUI always animates them. A stack that is not mounted changes without animation.

**Path.** `setPath` keeps the pages up to the first value that differs, together with any view
pages above them, and pushes one page per new value. O(depth). An unchanged path returns at once
and allocates nothing. A bound stack never changes its own path. A link, the back button and the
keys report the new path through `onPathChange`, and it comes back through `setPath` in the same
event, as a form control's value does. Unarmed, as with `.constant`, they do nothing.
`NavigationStack.adapt` converts the reported `[AnyHashable]` to the state's type. A value of
another type than a typed path's is dropped.

**Pending pages.** A value whose destination is not registered yet gets an empty page, which is
resolved when a destination registers or is armed. Both cases come up. An initial path is set
before the root content mounts. `@Component` arms handlers after the subtree mounts on first mount,
but before it on a branch swap. Resolution that would happen during layout (a lazy row mounting a
destination) is deferred to `afterLayout`.

**Macro.** `path:` is a binding (`setPath` plus the `onPathChange` write-back), and the stack's
field is not generic, since a path is not a list's rows. `destination:` on a link and the
`.navigationDestination` closure are handlers, armed on mount. A destination is built with no
closure at all, `.navigationDestination(for: T.self)`, so a value waiting for it stays pending
until the real closure arrives rather than resolving to a stand-in. That
is what lets them build components, which a body cannot do directly (F4). `for: T.self` types the
destination's field `NavigationDestinationElement<T>`, which gives the armed closure its parameter
type (F19 when it is not written `T.self`). With a `value:` argument a link's trailing closure is
its label (`TypeSpec.trailingContentWith`), otherwise its destination.

## Costs

- **During a push or pop, per frame:** one animator sample and a capture-free write of two floats
  (`.render`), two more effects and one clip resolved, and both pages drawn. No layout, no
  tree-order rebuild, no allocation.
- **Once per push or pop:** building and mounting the new page, `.layout` + `.treeOrder` at the
  start and again at the end, and one completion closure.
- **Idle:** nothing. Depth costs nothing per frame, since covered pages are skipped whole.
- **On events:** the path diff is O(depth), a destination lookup O(destinations registered), a
  parent walk O(tree depth), and a sidebar selection O(sidebar links).
- **Trade-offs:** `parent` is `weak`, costing one side-table allocation per container on first
  mount (`unowned` could dangle through a popover's anchor). `Button` is no longer `final`, so
  `NavigationLink` can subclass it. Bar titles snap rather than crossfade.

## Limits

- A `NavigationStack` inside a split view's `detail:` nests, with two bars. The detail column is
  already a stack.
- A hand-built `NavigationLink(destination:)` in a list's `onCreate` that captures `self` leaks, as
  any hand-built handler does. Prefer `value:` links in rows.
