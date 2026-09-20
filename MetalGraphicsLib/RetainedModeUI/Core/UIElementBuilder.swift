// A builder run produces nodes, not elements: each expression becomes a thunk, and each
// `if` / `if-else` / `if let` becomes a branch carrying the tag that was taken. Elements are
// materialized afterwards from a positional cache, so a re-run only constructs what changed.
// `for` loops are intentionally unsupported; use `VList` / `HList` for collections.
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

// A builder closure as a `Reaction`: it re-runs the builder when a `State` read by one of its
// conditions changes. Elements are kept in a cache shaped like the node tree, so everything but
// a flipped branch keeps its instance, and nothing is built just to be thrown away.
//
// Limitations:
// - Only conditions re-run the builder. Element arguments (`Rectangle(self.color)`) are reactive on
//   their own via `bind(_:to:)`; a value first read into a local (`let c = self.color`) is captured once.
// - `if let` swaps content only when the value flips between nil and non-nil.
// - A closure capturing `self` retains it; use `[unowned self]` for short-lived trees.
@MainActor
public enum DynamicContent {
  // Mirrors the node tree. The statement count at each level is fixed, so slot `i` always
  // describes the same statement and can be found by index alone.
  private final class Slot {
    var element: UIElement?
    var tag: Int?
    var children: [Slot] = []

    func child(_ index: Int) -> Slot {
      while self.children.count <= index {
        self.children.append(Slot())
      }
      return self.children[index]
    }
  }

  public static func reaction(_ build: @escaping () -> [UIElementNode],
                              apply: @escaping ([UIElement], UIContext) -> Void) -> Reaction<[UIElement]> {
    let root = Slot()

    return Reaction({
      let nodes = build()

      // Building elements is isolated from the builder's tracker: an element's own arguments
      // are tracked by its `bind`, and nothing here should make the builder re-run.
      return DependencyTracker.untracked { materialize(nodes, root) }
    }, apply: apply)
  }

  // One-shot materialization for callers that don't re-run their builder.
  public static func elements(_ nodes: [UIElementNode]) -> [UIElement] {
    self.materialize(nodes, Slot())
  }

  private static func materialize(_ nodes: [UIElementNode], _ slot: Slot) -> [UIElement] {
    var elements: [UIElement] = []

    for (index, node) in nodes.enumerated() {
      let slot = slot.child(index)

      switch node {
      case .element(let make):
        let element = slot.element ?? make()
        slot.element = element
        elements.append(element)

      case .branch(let tag, let nodes):
        // A different branch than last time: drop what the old one built.
        if slot.tag != tag {
          slot.tag = tag
          slot.children.removeAll()
        }
        elements.append(contentsOf: self.materialize(nodes, slot))
      }
    }

    return elements
  }
}
