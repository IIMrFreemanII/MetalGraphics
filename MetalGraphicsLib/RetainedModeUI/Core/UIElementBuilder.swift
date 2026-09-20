import Combine

// Builds a list of elements. `if` / `if-else` / `if let` produce `ConditionalBranch` markers,
// which `DynamicContent` uses to swap only the branch whose outcome changed.
// Every statement yields exactly one top-level entry, so structures can be reconciled by index.
// `for` loops are intentionally unsupported; use `VList` / `HList` for collections.
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
    [ConditionalBranch(tag: 0, component)]
  }

  public static func buildEither(second component: [UIElement]) -> [UIElement] {
    [ConditionalBranch(tag: 1, component)]
  }

  public static func buildOptional(_ component: [UIElement]?) -> [UIElement] {
    [ConditionalBranch(tag: component == nil ? 1 : 0, component ?? [])]
  }

  public static func buildLimitedAvailability(_ component: [UIElement]) -> [UIElement] {
    component
  }

  // Expands branch markers into the elements they contain.
  public static func flatten(_ elements: [UIElement]) -> [UIElement] {
    elements.flatMap { element -> [UIElement] in
      if let branch = element as? ConditionalBranch {
        return flatten(branch.elements)
      }
      return [element]
    }
  }
}

// Marker produced by the builder for a conditional; never mounted or laid out.
public final class ConditionalBranch : UIElement {
  public let tag: Int
  public var elements: [UIElement]

  init(tag: Int, _ elements: [UIElement]) {
    self.tag = tag
    self.elements = elements
  }
}

// A builder closure as a `Reaction`: it re-runs the builder when a `State` read by one of its
// conditions changes, and keeps existing instances wherever the branch outcome is unchanged.
//
// Limitations:
// - Only conditions re-run the builder. Element arguments (`Rectangle(self.color)`) are reactive on
//   their own via `bind(_:to:)`; a value first read into a local (`let c = self.color`) is captured once.
// - `if let` swaps content only when the value flips between nil and non-nil.
// - A closure capturing `self` retains it; use `[unowned self]` for short-lived trees.
@MainActor
public enum DynamicContent {
  // Carries the last structure (branch markers included) from one run to the next.
  private final class Memory {
    var structure: [UIElement] = []
  }

  public static func reaction(_ build: @escaping () -> [UIElement],
                              apply: @escaping ([UIElement], UIContext) -> Void) -> Reaction<[UIElement]> {
    let memory = Memory()

    return Reaction({
      memory.structure = reconcile(memory.structure, build())
      return UIElementBuilder.flatten(memory.structure)
    }, apply: apply)
  }

  private static func reconcile(_ old: [UIElement], _ new: [UIElement]) -> [UIElement] {
    guard old.count == new.count else { return new }

    return zip(old, new).map { oldElement, newElement in
      if let newBranch = newElement as? ConditionalBranch {
        guard let oldBranch = oldElement as? ConditionalBranch, oldBranch.tag == newBranch.tag else {
          return newBranch
        }
        oldBranch.elements = reconcile(oldBranch.elements, newBranch.elements)
        return oldBranch
      }
      return type(of: oldElement) == type(of: newElement) ? oldElement : newElement
    }
  }
}
