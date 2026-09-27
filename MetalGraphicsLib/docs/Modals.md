# Modals

This document covers SwiftUI's modal presentations in RetainedModeUI: `.sheet`, `.fullScreenCover`, `.popover`, `.alert`, `.confirmationDialog` and `@Environment(\.dismiss)`. Each one shows over the app's window, or in a window of its own, attached to the app's or floating over it.

- The runtime is in `RetainedModeUI/Presentation/`, with the AppKit side in `PresentedWindows.swift`.
- The demo is `GPURayMarching/ModalDemo.swift`.
- The tests are in `MetalGraphicsLibTests/ModalTests.swift` (over the window), `PresentationWindowTests.swift` (windows of their own), `PresentationThreadTests.swift`, `GPURayMarchingTests/ModalsE2ETests.swift` and `ReactiveUIMacros/Tests/.../PresentationMacroTests.swift`.

```swift
@State var renaming = false
@State var confirmingDelete = false
@State var name = "Notes"

VStack {
  Button("Rename…") { self.renaming = true }
    .sheet(isPresented: $renaming) { RenameSheet(name: self.$name) }
  Button("Delete…", role: .destructive) { self.confirmingDelete = true }
    .alert("Delete “\(self.name)”?", isPresented: $confirmingDelete) {
      Button("Delete", role: .destructive) { self.delete() }
      Button("Cancel", role: .cancel) {}
    } message: {
      Text("This cannot be undone.")
    }
}
.presentationWindow(.attached)   // or .inline (the default), .floating

@Component final class RenameSheet : SingleChildElement {
  @Environment(\.dismiss) private var dismiss
  …
  Button("Save") { self.name.wrappedValue = self.draft; self.dismiss() }
}
```

## What is supported

| API | Notes |
|---|---|
| `.sheet(isPresented:onDismiss:content:)` | A card at the top of the window, over a dimmed backdrop. It is as large as its content, at least 200 wide, and scrolls when it does not fit. |
| `.sheet(item:onDismiss:content:)` | Shown while `item` is not nil, with content built for it. A new `id` dismisses the old sheet and presents afresh. The same `id` again changes nothing. |
| `.fullScreenCover(isPresented:)`, `(item:)` | Covers the window. It slides up from below, and has no backdrop to click. |
| `.popover(isPresented:attachmentAnchor:arrowEdge:content:)` | A card pointing at the element it modifies. It sits below that element, or above it with `arrowEdge: .bottom`, wherever there is room. It has no arrow. |
| `.alert(_:isPresented:actions:message:)` | A title, a message and buttons. |
| `.confirmationDialog(_:isPresented:titleVisibility:actions:message:)` | Buttons stacked, with Cancel last. |
| `@Environment(\.dismiss)`, `element.dismissPresentation()` | Dismisses the presentation the element is in. Outside one, it does nothing. `@Environment(\.isPresented)` reads whether the element is in one. |
| `.presentationWindow(_:)` | Where presentations show: `.inline`, `.attached` or `.floating`, optionally `.resizable()`. It applies to what is presented from under it or from the element it modifies, and to presentations made from inside those. |

All of these work in hand-built trees too, with a `Binding` and a content closure.

A presentation's content is built each time it is presented and let go once it has gone. Its components' `@State` therefore starts afresh every time, as in SwiftUI. The closure is armed like a handler, which is how it can build a component (a body cannot, F4).

Elements written inline in the closure do not follow the presenter's state after they are built, though `$state` inside it is a real binding and writes back. Put stateful content in a component. An alert's title is an argument rather than content, so it stays reactive.

## Dismissing

What asks a presentation to go reports `false` to its binding, or `nil` to an item's. The state's update then dismisses it. With a constant binding, only the value dismisses it.

| | Sheet, popover | Alert, dialog | Cover |
|---|---|---|---|
| Escape | dismisses | runs the cancel button, or dismisses | dismisses |
| Return | — | runs the default button: the first without a role | — |
| Click outside (the backdrop, or the window it came from) | dismisses | runs the cancel button, or dismisses | — |
| Any of its buttons | — | runs it, then dismisses | — |
| A floating window's close button | dismisses | — | — |

- A popover in a window of its own also goes when the keyboard moves to a window that is not shown over it.
- A dialog without a `.cancel` button gets a Cancel button, and an alert without buttons gets an OK button.
- Alert buttons are styled bordered, with the default one prominent. A two-button alert puts Cancel first; otherwise the buttons stack with Cancel last.

A presentation takes the input from everything under it:
- the pointer (hover, press, tap);
- clicks that would focus something;
- scrolling, drops and keys.

A NavigationStack under a sheet does not pop on Escape. Tab cycles only inside the topmost modal. Focus is taken when the modal is presented and given back when it goes. A popover a control opened inside a sheet (a picker's menu) still works, and a scroll outside it closes only the menu.

Presentations stack. An alert shown from a sheet goes first on Escape. A presentation going away dismisses, and writes back, everything presented from inside it.

## In a window of its own

| Kind | `.attached` | `.floating` |
|---|---|---|
| sheet, alert, dialog | An AppKit sheet (`beginSheet`) on the window. | A window centred over it, as a child window. A sheet has a close button; an alert or dialog shows no title bar. |
| popover | A borderless child window by its source. It may extend past the window, and follows the source when it moves. | the same |
| cover | A borderless child window over the window's content, which follows the window's size. | A window of its own that goes full screen. |

While a modal window is up, the window it came from takes no input (`UIContext.blockInput()`). AppKit blocks a sheet's parent by itself. A local `NSEvent` monitor turns a click on the parent into a click outside, and takes the click. The popover's window blocks nothing.

**What runs where.** A presentation's window runs its tree on the thread of the window it was presented from. It gets a child `WindowHandle` (`WindowHandle(childOf:name:)`) with the parent's thread and mailbox, and a renderer of its own: its own root, `UIContext`, `Input`, `Graphics2D` and display link. The content closure captures the presenter, and a component's setters run against its own context, so the two trees have to share a thread. They then touch each other directly, as over the app's window.

The flow for one presentation:
- Main makes the `NSWindow` and its view.
- The view's layer is attached to the renderer that is already running.
- What the user does to the window comes back as a `PresentedWindowEvent` posted to the presentation.

A window whose frame changes another's tree on the same thread wakes it if it is paused (`WindowHandle.wakeSurfaces`).

**Sizing.**
- **Sheets, alerts, dialogs and popovers** are fitted to their content, and follow its size when it changes. The fit is at least 200×80, at most 90% of the screen.
- **A `.resizable()` sheet** starts at its content's size, and the user resizes it.
- **Alerts** are 260 wide, and **dialogs** 280 wide.

**Headless.** A `HeadlessApp` opens these windows on its screen where AppKit would (`HeadlessPresentedWindows`).
- `app.presentation(over: window)` finds the one shown from a window.
- A click on that window goes to the presentation as a click outside.
- Keys go to the topmost one.
- In a `UIHarness` there is no window to open one beside, so a window style shows over the tree instead.

## How it works

**Layers.** An inline presentation is an `OverlayLayer` in `UIContext.overlays`, as a popover a control opens is:
- a root of its own, laid out after the tree at the window's size, and collected after it, so it draws and hits above everything, outside every clip.
- `ModalLayer` draws a sheet, cover, alert or dialog.
- `PopoverLayer` draws the popover, and a control's menus too.
- Both, and a presentation's window root (`WindowPresentation`), are `PresentationRoot`s. That is what `DismissAction` finds by walking up `parent`, and what nested presentations take their style from.
- A modal layer mounts with no parent, so a navigation link inside a sheet does not find the stack under it.

**The barrier.** `rebuildTreeOrder` records where the topmost modal overlay starts in the focus, key, scroll and drop orders. Focus clicks, Tab, key dispatch, scroll and drop routing only look at entries from there on. The modal's backdrop takes both taps and presses, so neither hover nor clicks reach under it.

**Alert buttons.** Tapping a `Button` runs `performTap()`, which runs its action and then `presentationAction`. The alert sets `presentationAction` to dismiss itself.

**Macro.**
- `isPresented: $state` and `item: $state` are lowered like a constructor's binding:
  - the value binds to `setIsPresented`/`setItem`;
  - the write-back `onIsPresentedChange`/`onItemChange` is armed on mount.
- `content:`/`actions:`, `message:` and `onDismiss:` are handlers, armed on mount; a closure or a reference like `onDismiss: self.cleanup` both work.
- `item:`'s optional `@State` types the element as `ItemPresentationElement<T>` (F22).
- `.presentationWindow(self.style)` is reactive: it applies from the next presentation.
- `@Environment` is a plain property to the macro, read in handlers.

In a file that imports both SwiftUI and MetalGraphicsLib, write `@SwiftUI.Environment` for SwiftUI's wrapper.

## Costs

- **Nothing presented, per frame:** two integer checks (`inputBlocks`, and the surface count after a frame). No allocation.
- **While an inline one animates:** two transitions' effects, `.render` only, and no relayout (`ModalTests.testPresentingOnlyRedrawsWhileItAnimatesAndThenIdles`).
- **Once per present:** building and mounting the content, plus the layer's dozen elements.
  - Invalidations: `.layout` + `.treeOrder` when it is presented, `.treeOrder` when it starts going, and `.layout` + `.treeOrder` when it has gone.
  - A window presentation also makes a `Graphics2D` (a few pipelines and a command queue) and the `NSWindow`.
- **Messages:** resize and popover-move messages go to the main thread only when the value changed.
- **Idle:** both windows pause their display links when idle.
- **On events:** the barrier makes each event O(1) extra. Focus and dismissal walk up the tree, O(depth), on input only.
- **Scaling:** what is under an inline modal is still drawn.
- **Trade-offs:**
  - Content is built lazily and is not reactive, in exchange for letting it hold components.
  - Unmounting a presenter removes what it shows at once, with no animation and no write-back.
  - `onDismiss` for a window runs once its tree has unmounted, before AppKit's close animation ends.

## Limits

- A popover has no arrow, and `attachmentAnchor` is only `.rect(.bounds)`. There are no sheet detents, and no `alert(_:isPresented:presenting:)`.
- A hot reload rebuilds the presenter's tree, which closes what it showed; the state that presented it presents it again if it survives. A relaunch opens none.
- Attached sheets on the same window queue, as AppKit's do.
- A click anywhere on a window with a presentation over it dismisses the presentation, the title bar included.
- A dock area inside a presentation's window is not supported.
