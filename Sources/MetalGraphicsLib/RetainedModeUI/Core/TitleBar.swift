import simd

/// Where a translucent window's title bar is, over the tree: the content runs under it, so the
/// views along the window's top edge make room for it. A sidebar starts its content below it
/// with the traffic lights on its top; a navigation bar or a dock tab bar takes its row,
/// clear of the traffic lights. Zero in a window with a title bar of its own, and in full screen.
///
/// Measured on the main thread (`RetainedLayerView`), posted to the window's thread like its
/// size, and read during layout through `TitleBarInsets.current`.
public struct TitleBarInsets: Hashable, Sendable {
  /// The title bar's height, from the window's top.
  public var top: Float
  /// Past the traffic lights, from the window's left edge.
  public var leading: Float

  public init(top: Float, leading: Float) {
    self.top = top
    self.leading = leading
  }

  public static let zero = TitleBarInsets(top: 0, leading: 0)

  /// What a headless translucent window has: a standard macOS title bar.
  public static let standard = TitleBarInsets(top: 32, leading: 78)

  /// The window's being laid out on this thread, set by `UIContext` for each layout pass.
  public static var current: TitleBarInsets {
    ThreadState.current.titleBar
  }

  /// The height of a bar that shares the title bar's row: a navigation bar in a split view.
  public static let unifiedBarHeight: Float = 52
  /// The height of the row a dock area gives the title bar: tab bars sit in it or below it.
  public static let dockRowHeight: Float = 40

  /// Marks `rect` (x, y, width, height, window points from its top left) as empty title bar:
  /// a press there drags the window, and a double click zooms it. Called during layout by the
  /// views along the window's top, for the parts of them nothing else takes.
  public static func addDragRegion(_ rect: float4) {
    guard rect.z > 0, rect.w > 0 else { return }
    ThreadState.current.titleBarDragRegions.append(rect)
  }
}

/// Where an element placed at the window's top by the last layout pass: whether it touches the
/// title bar. Sizes are decided before positions, so an element sizes from where it was last
/// placed and lays out once more if that turns out to have changed (once, when it first
/// appears or moves to or from the top).
struct TitleBarPlacement {
  private(set) var atTop = true

  /// Whether the element at `y` touches the window's top, and lays the tree out again when its
  /// size assumed otherwise and the window has a title bar over its content.
  mutating func settle(_ y: Float, _ context: UIContext?) {
    let atTop = y < 0.5
    guard atTop != self.atTop else { return }
    self.atTop = atTop
    guard TitleBarInsets.current.top > 0, let context else { return }
    context.afterLayout { [weak context] in context?.invalidate(.layout) }
  }
}
