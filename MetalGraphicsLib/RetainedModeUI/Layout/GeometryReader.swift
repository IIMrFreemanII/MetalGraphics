import simd

/// Which coordinates a `GeometryProxy` frame is in.
public enum CoordinateSpace: Sendable {
  /// The window's: top left origin, y down, in points.
  case global
  /// The element's own: its top left is the origin.
  case local
}

/// Where an element was laid out and how large it is, as of the last layout pass.
@MainActor
public final class GeometryProxy {
  public fileprivate(set) var size: float2 = .zero
  /// The top left, in the window.
  public fileprivate(set) var origin: float2 = .zero

  public init() {}

  public func frame(in space: CoordinateSpace) -> ClipRect {
    switch space {
    case .global: ClipRect(position: self.origin, size: self.size)
    case .local: ClipRect(position: .zero, size: self.size)
    }
  }
}

/// Takes all the space it is offered and hands its content a `GeometryProxy` with its size and
/// place, as SwiftUI's. The content is offered that same size and put at the top left.
///
/// Content is built once, so it reads the proxy where it runs later: in a handler, or in an
/// alignment guide. To react to a size in a `@Component`, use `.onGeometryChange` instead, which
/// writes it into state.
public final class GeometryReader : SingleChildElement {
  public let proxy: GeometryProxy

  /// More than one element is stacked in a `ZStack` aligned top left.
  public init(proxy: GeometryProxy = GeometryProxy(), @UIElementBuilder content: (GeometryProxy) -> [UIElement]) {
    self.proxy = proxy
    super.init()
    let elements = content(proxy)
    if elements.count > 1 {
      let stack = ZStack(alignment: .topLeading)
      stack.applyContent(elements)
      self.applyContent([stack])
    } else {
      self.applyContent(elements)
    }
  }

  public override func getSize() -> float2 {
    self.proxy.size
  }

  public override func sizeThatFits(_ proposal: ProposedSize) -> float2 {
    proposal.replacingUnspecified(with: Rectangle.idealSize)
  }

  public override func calcSize(_ proposal: ProposedSize) -> float2 {
    self.proxy.size = proposal.replacingUnspecified(with: Rectangle.idealSize)
    _ = self.child?.calcSize(ProposedSize(self.proxy.size))
    return self.proxy.size
  }

  // Its content is put at its top left, not aligned, so what the content defines is not passed on.
  public override func guideValue(_ key: AlignmentKey, _ proposal: ProposedSize, _ size: float2) -> Float? {
    self.explicitGuide(key, size)
  }

  public override func calcPosition(_ position: float2) {
    self.proxy.origin = position
    if let child = self.child {
      self.place(child, at: position, in: position)
    }
  }
}

/// Calls `action` with a value read from its content's geometry whenever that value changes.
/// Made by `.onGeometryChange(for:of:action:)`.
///
/// The value is read after each layout pass that places the element, and `action` runs once that
/// pass is over, so the state it writes is laid out on the next frame.
public final class GeometryChangeElement<Value: Equatable> : SingleChildElement {
  private let transform: (GeometryProxy) -> Value
  /// Settable, and cleared while unmounted, like a `HittableView`'s handlers.
  public var action: ((Value) -> Void)?

  private let proxy = GeometryProxy()
  private var last: Value? = nil
  private weak var context: UIContext? = nil

  public init(
    of transform: @escaping (GeometryProxy) -> Value, action: ((Value) -> Void)?,
    @UIElementBuilder content: () -> [UIElement]
  ) {
    self.transform = transform
    self.action = action
    super.init()
    self.applyContent(content())
  }

  public override func mount(_ context: UIContext) {
    self.context = context
  }

  public override func unmount(_ context: UIContext) {
    // A remount reports the value again.
    self.last = nil
  }

  public override func calcSize(_ proposal: ProposedSize) -> float2 {
    self.proxy.size = self.child?.calcSize(proposal) ?? .zero
    return self.proxy.size
  }

  public override func calcPosition(_ position: float2) {
    self.proxy.origin = position
    self.child?.calcPosition(position)

    let value = self.transform(self.proxy)
    guard value != self.last, let context = self.context else { return }
    self.last = value
    context.afterLayout { [weak self] in
      self?.action?(value)
    }
  }
}

extension UIElementWrapping where Self: UIElement {
  /// Calls `action` with what `transform` reads from this element's geometry, first once it is
  /// laid out and then whenever it changes.
  public func onGeometryChange<Value: Equatable>(
    for type: Value.Type, of transform: @escaping (GeometryProxy) -> Value,
    action: @escaping (Value) -> Void
  ) -> GeometryChangeElement<Value> {
    GeometryChangeElement(of: transform, action: action) {
      self
    }
  }
}
