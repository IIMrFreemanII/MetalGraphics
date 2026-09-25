import simd

/// Marks its content with `id`, so a `ScrollViewProxy` can scroll to it. Made by `.id(_:)`.
///
/// Draws nothing and changes no layout; it only remembers where its content was laid out.
public final class IDElement : SingleChildElement {
  public let id: AnyHashable

  private(set) var position: float2 = .zero
  private(set) var size: float2 = .zero

  public init(_ id: AnyHashable, @UIElementBuilder content: () -> [UIElement] = { [] }) {
    self.id = id
    super.init()
    self.applyContent(content())
  }

  public override func debugHierarchy(_ offset: String) {
    print(offset + "IDElement(id: \(self.id))")
    self.child?.debugHierarchy(offset + "  ")
  }

  public override func getSize() -> float2 {
    self.size
  }

  public override func calcSize(_ proposal: ProposedSize) -> float2 {
    self.size = self.child?.calcSize(proposal) ?? .zero
    return self.size
  }

  public override func calcPosition(_ position: float2) {
    self.position = position
    self.child?.calcPosition(position)
  }
}

extension UIElementWrapping where Self: UIElement {
  /// Tags this element with `id`, which `ScrollViewProxy.scrollTo(_:anchor:animation:)` finds
  /// it by.
  public func id<ID: Hashable>(_ id: ID) -> IDElement {
    IDElement(AnyHashable(id)) {
      self
    }
  }
}

/// Scrolls the scroll views inside a `ScrollViewReader` to the element tagged with an id.
@MainActor
public final class ScrollViewProxy {
  fileprivate weak var reader: ScrollViewReader?

  public init() {}

  /// Scrolls the innermost scroll view around the element tagged `id` until the element's
  /// `anchor` point lines up with the scroll view's — or, with no anchor, by as little as it
  /// takes to show it whole. Does nothing when no such element is in the reader.
  ///
  /// Positions come from the last layout pass, so an element added in the same frame is not
  /// reachable until the next one.
  public func scrollTo<ID: Hashable>(_ id: ID, anchor: Alignment? = nil, animation: UIAnimation? = nil) -> Void {
    guard let reader = self.reader, let context = reader.context else { return }
    let key = AnyHashable(id)
    guard let (scrollView, target) = Self.find(key, in: reader, scrollView: nil) else { return }
    let origin = target.position - scrollView.contentOrigin
    scrollView.scrollTo(contentRect: origin, size: target.size, anchor: anchor, context, animation: animation)
  }

  // Depth first, remembering the innermost scroll view on the way down.
  private static func find(
    _ id: AnyHashable, in element: UIElement, scrollView: ScrollView?
  ) -> (ScrollView, IDElement)? {
    let scrollView = (element as? ScrollView) ?? scrollView
    if let tagged = element as? IDElement, tagged.id == id, let scrollView {
      return (scrollView, tagged)
    }
    var found: (ScrollView, IDElement)? = nil
    element.forEachChild { child in
      guard found == nil, !child.isLeaving else { return }
      found = Self.find(id, in: child, scrollView: scrollView)
    }
    return found
  }
}

/// Hands its content a `ScrollViewProxy` that scrolls the scroll views inside it.
///
/// ```swift
/// ScrollViewReader { proxy in
///   ScrollView {
///     VStack { ... Text(row.name).id(row.id) ... }
///   }
///   Text("Top").onTap { _ in proxy.scrollTo(firstID, anchor: .top, animation: .default) }
/// }
/// ```
public final class ScrollViewReader : SingleChildElement {
  public let proxy: ScrollViewProxy
  fileprivate weak var context: UIContext?

  /// More than one element is stacked in a `VStack`.
  public init(proxy: ScrollViewProxy = ScrollViewProxy(), @UIElementBuilder content: (ScrollViewProxy) -> [UIElement]) {
    self.proxy = proxy
    super.init()
    proxy.reader = self

    let elements = content(proxy)
    if elements.count > 1 {
      let stack = VStack()
      stack.applyContent(elements)
      self.applyContent([stack])
    } else {
      self.applyContent(elements)
    }
  }

  public override func mount(_ context: UIContext) {
    self.context = context
  }
}
