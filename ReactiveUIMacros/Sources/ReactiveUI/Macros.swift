// Macro declarations for the compile-time reactivity system.
//
// This target holds declarations only. It must stay free of runtime symbols and must not
// depend on MetalGraphicsLib, so generated code always emits unqualified names that resolve
// at the use site.

/// Marks a stored property as reactive.
///
/// Writing to it runs generated code that assigns directly into the element nodes the property
/// feeds and marks the context dirty. There is no tracking, no subscription and no diffing:
/// which nodes those are was decided at compile time by `@Component`.
///
/// Requires an explicit type annotation — a macro sees syntax only and cannot infer one.
///
/// Also declares `$name`, a `Binding` to the property. In a `@Component` body it is only a
/// spelling, lowered at compile time; see `Binding`.
@attached(accessor, names: named(init), named(get), named(set), named(_modify))
@attached(peer, names: prefixed(_), prefixed(__requiresComponent_), prefixed(`$`))
public macro State() =
  #externalMacro(module: "ReactiveUIMacrosPlugin", type: "StateMacro")

/// Generates a component's element tree and its per-state update code from its `body`.
@attached(member, names: arbitrary)
@attached(extension, conformances: ReactiveComponent)
public macro Component() =
  #externalMacro(module: "ReactiveUIMacrosPlugin", type: "ComponentMacro")

/// Makes a class a model several components — in any number of windows — can read and write.
///
///     @Model final class AppModel {
///       static let shared = AppModel()
///       var count: Int = 0
///     }
///
/// A `@Component` that declares it `@Bindable` and reads `self.model.count` in its body updates
/// when `count` is written from anywhere, as it does for its own `@State`: the component
/// subscribes on mount, and a write runs its generated setters for what `count` feeds.
///
/// Every stored `var` is tracked unless marked `@ModelIgnored`. Tracked properties need an
/// explicit type annotation. The class must not be `@MainActor`: each window reads and writes it
/// from a thread of its own, so its tracked storage is behind a lock, and it is `Sendable`. A
/// write updates the writer's window right away and every other window on its next frame.
@attached(member, names: named(__lock), named(__observers_any), named(__observers))
@attached(memberAttribute)
@attached(extension, conformances: ReactiveModel, Sendable)
public macro Model() =
  #externalMacro(module: "ReactiveUIMacrosPlugin", type: "ModelMacro")

/// Added by `@Model` to each tracked property; not written by hand.
@attached(accessor, names: named(init), named(get), named(set), named(_modify))
@attached(peer, names: prefixed(_), prefixed(__observers_))
public macro ModelTracked() =
  #externalMacro(module: "ReactiveUIMacrosPlugin", type: "ModelTrackedMacro")

/// Leaves a stored property of a `@Model` untracked: writing it updates nothing.
@attached(peer)
public macro ModelIgnored() =
  #externalMacro(module: "ReactiveUIMacrosPlugin", type: "ModelIgnoredMacro")

/// Declares a `@Model` a `@Component` reads: `@Bindable let model: AppModel = .shared`.
///
/// Reads of its properties in `body` (`self.model.count`) update when they are written, from any
/// window, and `$model.count` is a binding for a control, as `$state` is.
@attached(peer, names: prefixed(`$`), prefixed(__requiresComponent_))
public macro Bindable() =
  #externalMacro(module: "ReactiveUIMacrosPlugin", type: "BindableMacro")
