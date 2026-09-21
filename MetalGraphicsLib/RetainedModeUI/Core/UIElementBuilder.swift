// A builder run produces nodes, not elements: each expression becomes a thunk, and each
// `if` / `if-else` / `if let` becomes a branch carrying the tag that was taken.
//
// This is now only a type-checking surface. A `@Component`'s `body` is read by the macro and
// never executed — the macro emits straight-line construction instead — so there is no longer
// a positional cache, no re-running of builder closures, and no materialization step.
// Hand-written trees still use it, and get built exactly once.
//
// `for` loops remain unsupported; use `VList` / `HList` for collections.
public enum UIElementNode {
  case element(() -> UIElement)
  case branch(tag: Int, [UIElementNode])
}

@MainActor
@resultBuilder
public struct UIElementBuilder {
  public static func buildExpression(_ element: @autoclosure @escaping () -> UIElement) -> [UIElementNode] {
    [.element(element)]
  }

  public static func buildBlock(_ components: [UIElementNode]...) -> [UIElementNode] {
    components.flatMap { $0 }
  }

  public static func buildEither(first component: [UIElementNode]) -> [UIElementNode] {
    [.branch(tag: 0, component)]
  }

  public static func buildEither(second component: [UIElementNode]) -> [UIElementNode] {
    [.branch(tag: 1, component)]
  }

  public static func buildOptional(_ component: [UIElementNode]?) -> [UIElementNode] {
    [.branch(tag: component == nil ? 1 : 0, component ?? [])]
  }

  public static func buildLimitedAvailability(_ component: [UIElementNode]) -> [UIElementNode] {
    component
  }
}

@MainActor
public enum DynamicContent {
  /// Builds every node once, in order. Branches contribute whichever arm the builder took.
  public static func elements(_ nodes: [UIElementNode]) -> [UIElement] {
    var elements: [UIElement] = []

    for node in nodes {
      switch node {
      case .element(let make):
        elements.append(make())
      case .branch(_, let nodes):
        elements.append(contentsOf: self.elements(nodes))
      }
    }

    return elements
  }
}
