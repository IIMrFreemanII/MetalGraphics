public class HittableView: SingleChildElement, Hittable, PointerHandling {
  public var position: SIMD2<Float> = .init()
  public var size: SIMD2<Float> = .init()
  public var isHovered: Bool = false {
    didSet { if oldValue != self.isHovered, !self.followers.isEmpty { self.notifyFollowers() } }
  }
  public var isPressed: Bool = false {
    didSet { if oldValue != self.isPressed, !self.followers.isEmpty { self.notifyFollowers() } }
  }
  /// The left button went down over it and is still down, whether or not it takes presses
  /// itself (a row tapped on mouse down does not): what its followers see as pressed.
  var isPointerDown = false {
    didSet { if oldValue != self.isPointerDown, !self.followers.isEmpty { self.notifyFollowers() } }
  }

  /// Elements inside it that answer its hover and press: an `AnimatedIcon` playing as its row or
  /// button is hovered. Told on every change, including the reset on unmount.
  private var followers: [HostFollowerRef] = []

  /// Whether a follower wants the pointer's moves over it (the eye's pupil): the hover grid
  /// sends them only then.
  private(set) var followsPointer = false

  func addFollower(_ follower: HostFollower) {
    if !self.followers.contains(where: { $0.follower === follower }) {
      self.followers.append(HostFollowerRef(follower: follower))
      self.followsPointer = self.followsPointer || follower.wantsPointer
    }
  }

  func removeFollower(_ follower: HostFollower) {
    self.followers.removeAll { $0.follower === follower || $0.follower == nil }
    self.followsPointer = self.followers.contains { $0.follower?.wantsPointer == true }
  }

  var hasFollowers: Bool { !self.followers.isEmpty }

  private func notifyFollowers() {
    for ref in self.followers {
      ref.follower?.hostChanged(hovered: self.isHovered, pressed: self.isPressed || self.isPointerDown)
    }
  }

  /// The pointer over it, as a window point (top left origin).
  func notifyPointer(_ point: float2) {
    for ref in self.followers where ref.follower?.wantsPointer == true {
      ref.follower?.hostPointerMoved(point)
    }
  }
  
  /// Settable, and cleared while unmounted.
  ///
  /// A handler written in a `@Component` body captures `self` strongly, so the component reaches
  /// itself through the element that stores it. `@Component` breaks that loop by arming these on
  /// mount and clearing them on unmount, which is why they are `var` rather than the `let` the
  /// initializer would suggest. An element built by hand keeps whatever it was constructed with.
  public var onTap: ((Input) -> Void)?
  public var onHover: ((Bool, Input) -> Void)?
  /// Called with true when the left button goes down on it, and with false when it comes up,
  /// wherever the pointer is by then.
  public var onPress: ((Bool, Input) -> Void)?
  /// Called as the pointer moves while the left button is held, after it went down on this view.
  public var onDrag: ((Input) -> Void)?
  /// Called when the right button goes down on it: a context menu. A right click goes to the
  /// topmost view under the pointer that has one, instead of to `onTap`.
  public var onSecondaryTap: ((Input) -> Void)?
  /// Its pointer style, continuous hover, tap gesture and `.gesture`: made by the first that is
  /// set. See `PointerHandling`.
  public var pointer: PointerHandlers?
  /// `.contentShape(_:)`: where in its rect it is hit. Anywhere in it when nil.
  public var hitShape: UIShape?

  public var hitPosition: float2 { self.position }
  public var hitSize: float2 { self.size }

  public func hitTest(_ point: float2) -> Bool {
    guard pointInAABBoxTopLeftOrigin(point: point, position: self.position, size: self.size) else { return false }
    guard let shape = self.hitShape else { return true }
    return shape.contains(point, in: ClipRect(position: self.position, size: self.size))
  }

  /// Fits a tap handler with or without a location to `tapAction`: what `@Component` arms
  /// `.onTapGesture` through.
  public static func tapAction(_ action: @escaping () -> Void) -> (float2) -> Void {
    { _ in action() }
  }

  public static func tapAction(_ action: @escaping (float2) -> Void) -> (float2) -> Void {
    action
  }
  
  public override func mount(_ context: UIContext) {
    context.registerHittableView(self)
  }
  
  public override func unmount(_ context: UIContext) {
    // Cleared so a remount starts neutral. `ListRows` reuses a row's element across a reorder,
    // and an element unmounted mid-hover would otherwise come back believing it is still
    // hovered, and never fire `onHover(true)` again until the pointer left and re-entered.
    self.isHovered = false
    self.isPressed = false
    self.isPointerDown = false
    
    context.unregisterHittableView(self)
  }
  
  init(
    onTap: ((Input) -> Void)? = nil, onHover: ((Bool, Input) -> Void)? = nil,
    onPress: ((Bool, Input) -> Void)? = nil, onDrag: ((Input) -> Void)? = nil,
    @UIElementBuilder content: () -> [UIElement]
  ) {
    self.onTap = onTap
    self.onHover = onHover
    self.onPress = onPress
    self.onDrag = onDrag
    
    super.init()
    
    self.applyContent(content())
  }
  
  public override func getSize() -> float2 {
    self.size
  }
  
  /// The child, unless it is the `EmptyElement` that `applyContent` puts in for `{}`, which
  /// would size to zero and leave nothing to hit.
  private var content: UIElement? {
    self.child is EmptyElement ? nil : self.child
  }

  // Without content, the space it is offered.
  public override func sizeThatFits(_ proposal: ProposedSize) -> float2 {
    self.content?.measure(proposal) ?? proposal.replacingUnspecified(with: .zero)
  }

  public override func calcSize(_ proposal: ProposedSize) -> float2 {
    let contentSize = self.content?.calcSize(proposal) ?? proposal.replacingUnspecified(with: .zero)
    self.size = contentSize
    
    return contentSize
  }
  
  public override func calcPosition(_ position: float2) {
    self.position = position
    
    child?.calcPosition(position)
  }
}

/// Something inside a `HittableView` that follows its hover and press. See `HittableView.addFollower`.
protocol HostFollower: AnyObject {
  func hostChanged(hovered: Bool, pressed: Bool)
  /// Whether it wants `hostPointerMoved`.
  var wantsPointer: Bool { get }
  func hostPointerMoved(_ point: float2)
}

extension HostFollower {
  var wantsPointer: Bool { false }
  func hostPointerMoved(_ point: float2) {}
}

private struct HostFollowerRef {
  weak var follower: HostFollower?
}
