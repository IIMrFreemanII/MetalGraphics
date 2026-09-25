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
