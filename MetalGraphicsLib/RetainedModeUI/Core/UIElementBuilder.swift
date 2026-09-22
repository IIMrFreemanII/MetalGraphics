// A builder run produces the elements it was written from, in order, built exactly once.
//
// This is now only a type-checking surface. A `@Component`'s `body` is read by the macro and
// never executed — the macro emits straight-line construction instead — so there is no longer
// a positional cache, no re-running of builder closures, and no materialization step. Content
// used to be wrapped in per-expression thunks and branch tags so a re-run could rebuild it
// selectively; nothing re-runs, so the elements are built here and handed over as they are.
// Hand-written trees still use it, and get built exactly once.
//
// `for` loops remain unsupported; use `VList` / `HList` for collections.
@MainActor
@resultBuilder
public struct UIElementBuilder {
  public static func buildExpression(_ element: UIElement) -> [UIElement] {
    [element]
  }

  public static func buildBlock(_ components: [UIElement]...) -> [UIElement] {
    components.flatMap { $0 }
  }

  public static func buildEither(first component: [UIElement]) -> [UIElement] {
    component
  }

  public static func buildEither(second component: [UIElement]) -> [UIElement] {
    component
  }

  public static func buildOptional(_ component: [UIElement]?) -> [UIElement] {
    component ?? []
  }

  public static func buildLimitedAvailability(_ component: [UIElement]) -> [UIElement] {
    component
  }
}
