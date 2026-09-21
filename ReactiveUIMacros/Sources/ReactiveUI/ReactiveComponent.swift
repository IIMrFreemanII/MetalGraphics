/// Marker conformance added by `@Component`.
///
/// It lives here, not in MetalGraphicsLib, for two reasons: `@attached(extension, conformances:)`
/// needs the name resolvable where the macro is declared, and ReactiveUI must not depend on
/// MetalGraphicsLib (that would be a cycle, since MetalGraphicsLib links ReactiveUI).
///
/// So this stays a bare marker. The `onMount`/`onUnmount` hooks are `open` members of `UIElement`
/// in MetalGraphicsLib, where `UIContext` exists — components override them like any other.
public protocol ReactiveComponent: AnyObject {}
