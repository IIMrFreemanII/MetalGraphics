/// Dismisses the presentation the element it was read from is in, as SwiftUI's
/// `@Environment(\.dismiss)`: asks its presenter's binding to go false. Outside one it does
/// nothing.
///
///     @Component final class EditSheet : SingleChildElement {
///       @Environment(\.dismiss) private var dismiss
///       var body: some UIElement {
///         Button("Done") { self.dismiss() }
///       }
///     }
public struct DismissAction {
  weak var element: UIElement?

  public func callAsFunction() -> Void {
    self.element?.dismissPresentation()
  }
}

/// What `@Environment` reads, from where the element it is read from sits in the tree.
public struct EnvironmentValues {
  weak var element: UIElement?

  /// Dismisses the presentation the element is in.
  public var dismiss: DismissAction { DismissAction(element: self.element) }

  /// Whether the element is in a presentation: a sheet, a cover, a popover, an alert.
  public var isPresented: Bool { self.element?.nearestAncestor(PresentationRoot.self) != nil }
}

/// Reads a value from where the element that declares it sits, as SwiftUI's `@Environment`:
/// `@Environment(\.dismiss) private var dismiss`. Only on elements, and read on input rather than
/// per frame: each read walks up the tree.
@propertyWrapper
public struct Environment<Value> {
  let keyPath: KeyPath<EnvironmentValues, Value>

  public init(_ keyPath: KeyPath<EnvironmentValues, Value>) {
    self.keyPath = keyPath
  }

  @available(*, unavailable, message: "@Environment is only available on elements")
  public var wrappedValue: Value {
    get { fatalError() }
    set { fatalError() }
  }

  public static subscript<Element: UIElement>(
    _enclosingInstance element: Element,
    wrapped wrappedKeyPath: ReferenceWritableKeyPath<Element, Value>,
    storage storageKeyPath: ReferenceWritableKeyPath<Element, Environment<Value>>
  ) -> Value {
    get { EnvironmentValues(element: element)[keyPath: element[keyPath: storageKeyPath].keyPath] }
    // Environment values are read-only; the setter exists only to satisfy the wrapper protocol.
    set {}
  }
}

extension UIElement {
  /// Dismisses the presentation this element is in: its sheet, cover, popover or alert. What
  /// `@Environment(\.dismiss)` does, for trees built by hand.
  public func dismissPresentation() -> Void {
    let root = self as? PresentationRoot ?? self.nearestAncestor(PresentationRoot.self)
    root?.requestDismiss()
  }
}
