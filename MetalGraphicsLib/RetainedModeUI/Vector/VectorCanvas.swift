import simd

/// Vector shapes drawn in a coordinate space of their own, `width` by `height` units, y down.
///
/// Laid out like an `Image`: at `width` by `height` points, until `resizable()` lets it take the
/// size it is offered, which it fits keeping its proportions. What its shapes draw outside it is
/// cut off.
///
/// ```swift
/// VectorCanvas(width: 24, height: 24) {
///   Circle(center: float2(12, 12), radius: self.hovered ? 10 : 8)
///     .fill(self.hovered ? .orange : .black)
///     .animation(.spring(), value: self.hovered)
/// }
/// ```
public final class VectorCanvas: UIRenderableElement {
  public let canvasSize: float2
  /// Set by `.resizable()`.
  public private(set) var isResizable = false

  public var position: float2 = .init()
  public var size: float2 = .init()
  /// Where the fitted canvas sits within `size`, and points per canvas unit.
  private var contentOrigin: float2 = .init()
  private var unitScale: Float = 1
  private var reportedStrayChild = false

  /// Holds the shapes, so the canvas can be a drawing element with many children.
  private let shapes = VectorShapeList()

  public init(width: Float, height: Float, @UIElementBuilder content: () -> [UIElement] = { [] }) {
    self.canvasSize = float2(width, height)
    super.init()
    self.child = self.shapes
    self.shapes.applyContent(content())
  }

  /// Replaces the shapes, mounting new ones and unmounting those that are gone.
  public func replaceChildren(_ elements: [UIElement], _ context: UIContext, animation: UIAnimation? = nil) {
    self.shapes.replaceChildren(elements, context, animation: animation)
  }

  public var children: [UIElement] { self.shapes.children }

  public override func mount(_ context: UIContext) {
    context.registerRenderableView(self)
  }

  public override func unmount(_ context: UIContext) {
    context.unregisterRenderableView(self)
  }

  public override func debugHierarchy(_ offset: String) {
    print(offset + "VectorCanvas(position: \(self.position), size: \(self.size))")
    self.shapes.children.forEach { $0.debugHierarchy(offset + "  ") }
  }

  public override func getSize() -> float2 {
    self.size
  }

  public override func calcSize(_ availableSize: float2) -> float2 {
    let natural = self.canvasSize
    guard natural.x > 0, natural.y > 0 else {
      self.size = .zero
      return self.size
    }
    guard self.isResizable else {
      self.size = natural
      self.unitScale = 1
      self.contentOrigin = .zero
      return self.size
    }
    // an axis offered no bound takes the canvas's own length
    let offered = float2(
      availableSize.x.isFinite && availableSize.x < 1e7 ? max(availableSize.x, 0) : natural.x,
      availableSize.y.isFinite && availableSize.y < 1e7 ? max(availableSize.y, 0) : natural.y
    )
    self.unitScale = min(offered.x / natural.x, offered.y / natural.y)
    self.size = natural * self.unitScale
    self.contentOrigin = .zero
    return self.size
  }

  public override func calcPosition(_ position: float2) {
    self.position = position
    for case let shape as VectorShape in self.shapes.children {
      shape.hitPosition = position
      shape.hitSize = self.size
    }
  }

  public override func render(_ renderer: Graphics2D, _ effect: EffectState) {
    guard effect.opacity > 0, self.size.x > 0, self.size.y > 0 else { return }
    // origin -> top left
    let clipMin = effect.apply(to: self.position) - renderer.size * 0.5
    let clipMax = clipMin + self.size * effect.scale
    let origin = clipMin + self.contentOrigin * effect.scale
    let unitScale = self.unitScale * effect.scale

    for child in self.shapes.children {
      guard let shape = child as? VectorShape else {
        if !self.reportedStrayChild {
          self.reportedStrayChild = true
          print("VectorCanvas draws only shapes; \(type(of: child)) is ignored")
        }
        continue
      }
      shape.draw(
        renderer, origin: origin, unitScale: unitScale,
        clipMin: clipMin, clipMax: clipMax, opacity: effect.opacity
      )
    }
  }

  // MARK: - Modifiers

  /// Lets the canvas take the size it is offered, fitting its own proportions into it. Sets this
  /// canvas and returns it.
  public func resizable() -> Self {
    self.isResizable = true
    return self
  }
}

/// The shapes of a `VectorCanvas`. Lays nothing out: its shapes are placed by their own
/// coordinates.
final class VectorShapeList: MultiChildElement {}
