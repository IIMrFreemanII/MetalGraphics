import simd

/// Where a presentation shows: over the app's own window, or in a window of its own.
///
///     Button("Edit") { self.editing = true }
///       .sheet(isPresented: $editing) { EditSheet() }
///       .presentationWindow(.attached)
///
/// Set around the presenting modifier, on the element it modifies, or anywhere above: it applies
/// to every presentation under it, and to those presented from inside them.
public struct PresentationWindowStyle: Equatable, Sendable {
  public enum Placement: Hashable, Sendable {
    /// In a layer over the app's window, with a dimmed backdrop.
    case inline
    /// In a window attached to the app's: an AppKit sheet sliding from its title bar, a popover's
    /// window pointing at the source, a cover over its content.
    case attached
    /// In a window of its own over the app's, which it blocks until it goes.
    case floating
  }

  public var placement: Placement
  /// Whether the user can resize its window: a sheet's. Fitted to the content otherwise.
  public var isResizable: Bool

  public init(_ placement: Placement, isResizable: Bool = false) {
    self.placement = placement
    self.isResizable = isResizable
  }

  public static let inline = PresentationWindowStyle(.inline)
  public static let attached = PresentationWindowStyle(.attached)
  public static let floating = PresentationWindowStyle(.floating)

  /// The same, in a window the user can resize.
  public func resizable(_ isResizable: Bool = true) -> PresentationWindowStyle {
    var style = self
    style.isResizable = isResizable
    return style
  }

  /// The style `presentation` shows with: the nearest set on it, around it, or on the presentation
  /// it is in, else `.inline`. O(depth); once per presentation.
  static func effective(for presentation: PresentationElement) -> PresentationWindowStyle {
    // On the element it modifies: `Button(…).presentationWindow(.floating).sheet(…)`.
    var current = presentation.child
    while let element = current {
      if let style = element as? PresentationWindowStyleElement { return style.style }
      guard let single = element as? SingleChildElement else { break }
      current = single.child
    }
    var ancestor = presentation.parent
    while let element = ancestor {
      if let style = element as? PresentationWindowStyleElement { return style.style }
      if let root = element as? PresentationRoot { return root.inheritedWindowStyle }
      ancestor = element.parent
    }
    return .inline
  }
}

/// Sets the window style of the presentations under it. Made by `.presentationWindow(_:)`. Draws
/// nothing and takes its content's layout.
public final class PresentationWindowStyleElement : SingleChildElement {
  public private(set) var style: PresentationWindowStyle

  public init(_ style: PresentationWindowStyle, @UIElementBuilder content: () -> [UIElement]) {
    self.style = style
    super.init()
    self.applyContent(content())
  }

  /// Applies to what is presented from now on; what shows stays where it is.
  public func setStyle(_ value: PresentationWindowStyle, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.style = value
  }
}

extension UIElementWrapping where Self: UIElement {
  /// Shows the sheets, covers, popovers, alerts and dialogs under it in a window of their own, or
  /// over the app's (see `PresentationWindowStyle`).
  public func presentationWindow(_ style: PresentationWindowStyle) -> PresentationWindowStyleElement {
    PresentationWindowStyleElement(style) { self }
  }
}
