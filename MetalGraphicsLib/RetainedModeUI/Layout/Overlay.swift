import simd

/// Content drawn in front of, or behind, the element it wraps, sized to it. Made by
/// `.overlay(alignment:content:)` and `.background(alignment:content:)`.
///
/// The wrapped element is laid out as if the overlay were not there, and the overlay takes its
/// size. The content is then offered exactly that size and aligned in it; more than one element
/// of content is stacked as in a `ZStack`. Content larger than the element spills past it.
public final class OverlayElement : SingleChildElement {
  /// Behind the element rather than in front of it.
  public let isBackground: Bool

  /// Holds the content, stacked and aligned. Visited before the element for a background, after
  /// it for an overlay, which is what puts it behind or in front, drawn and hit alike.
  public let content: ZStack

  public var alignment: Alignment {
    get { self.content.alignment }
    set { self.content.alignment = newValue }
  }

  private var size: float2 = .zero

  public init(
    _ element: UIElement, alignment: Alignment = .center, isBackground: Bool = false,
    @UIElementBuilder content: () -> [UIElement] = { [] }
  ) {
    self.isBackground = isBackground
    self.content = ZStack(alignment: alignment, content: content)
    super.init()

    self.applyContent([element])
  }

  /// Replaces the content, mounting new elements and unmounting those that are gone.
  public func replaceContent(_ elements: [UIElement], _ context: UIContext, animation: UIAnimation? = nil) {
    self.content.replaceChildren(elements, context, animation: animation)
  }

  override func forEachChild(_ body: (UIElement) -> Void) {
    if self.isBackground {
      body(self.content)
      super.forEachChild(body)
    } else {
      super.forEachChild(body)
      body(self.content)
    }
  }

  public override func debugHierarchy(_ offset: String) {
    print(offset + (self.isBackground ? "Background" : "Overlay") + "(size: \(self.size))")
    self.child?.debugHierarchy(offset + "  ")
    self.content.debugHierarchy(offset + "  ")
  }

  public override func getSize() -> float2 {
    self.size
  }

  public override func calcSize(_ proposal: ProposedSize) -> float2 {
    self.size = self.child?.calcSize(proposal) ?? .zero
    _ = self.content.calcSize(ProposedSize(self.size))
    return self.size
  }

  public override func calcPosition(_ position: float2) {
    self.child?.calcPosition(position)
    // The content's stack is smaller than this when the content is, and larger when it spills
    // past it; either way its guides meet this element's.
    let offset = self.alignedOffset(self.content, self.alignment, in: self.size, ProposedSize(self.size), self.content.getSize())
    self.content.calcPosition(position + offset)
  }
}
