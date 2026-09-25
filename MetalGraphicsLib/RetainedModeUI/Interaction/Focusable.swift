import simd

/// Something that can take keyboard focus: a click on it, Tab, or `.focused(true)` gives it
/// focus, and key presses then go to the `.onKeyPress` handlers around it. Made by `.focusable()`.
///
/// Focus draws nothing by itself. Show it from `.onFocusChange`, through state.
public final class FocusableElement : SingleChildElement {
  public private(set) var isFocusable: Bool
  /// Settable, and cleared while unmounted, like a `HittableView`'s handlers.
  public var onFocusChange: ((Bool) -> Void)?

  /// Where layout last put it, window top left origin, y down: what a click has to land in.
  public private(set) var position: float2 = .zero
  public private(set) var size: float2 = .zero

  /// Asked for with `.focused(true)` before it was mounted; taken on mount.
  private var wantsFocus = false

  public init(_ isFocusable: Bool = true, @UIElementBuilder content: () -> [UIElement]) {
    self.isFocusable = isFocusable
    super.init()
    self.applyContent(content())
  }

  public override func mount(_ context: UIContext) {
    context.registerFocusable(self)
    if self.wantsFocus {
      self.wantsFocus = false
      // After this mount pass, so `@Component` has armed `onFocusChange` by the time it runs.
      context.afterLayout { [weak self, weak context] in
        guard let self, let context, self.mounted, self.isFocusable else { return }
        context.focus(self)
      }
    }
  }

  public override func unmount(_ context: UIContext) {
    context.unregisterFocusable(self)
  }

  public override func calcSize(_ proposal: ProposedSize) -> float2 {
    self.size = self.child?.calcSize(proposal) ?? .zero
    return self.size
  }

  public override func calcPosition(_ position: float2) {
    self.position = position
    self.child?.calcPosition(position)
  }

  /// A focusable element that stops being one loses focus.
  public func setFocusable(_ value: Bool, _ context: UIContext) -> Void {
    guard value != self.isFocusable else { return }
    self.isFocusable = value
    if !value, context.focused === self {
      context.focus(nil)
    }
  }

  /// True focuses it; false takes focus away, if it has it.
  public func setFocused(_ value: Bool, _ context: UIContext) -> Void {
    guard self.mounted else {
      self.wantsFocus = value
      return
    }
    if value {
      if self.isFocusable, context.focused !== self {
        context.focus(self)
      }
    } else if context.focused === self {
      context.focus(nil)
    }
  }

  // Built with the value `.focused` was given, before anything is mounted.
  public func focused(_ value: Bool) -> Self {
    self.wantsFocus = value
    return self
  }

  public func onFocusChange(_ action: @escaping (Bool) -> Void) -> Self {
    self.onFocusChange = action
    return self
  }
}

extension UIElementWrapping where Self: UIElement {
  /// Lets this element take keyboard focus. See `FocusableElement`.
  public func focusable(_ isFocusable: Bool = true) -> FocusableElement {
    FocusableElement(isFocusable) {
      self
    }
  }
}
