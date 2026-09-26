import simd

/// What a hittable element does with the pointer beyond tap, hover, press and drag: its pointer
/// style, continuous hover, tap gesture and `.gesture`. Made only for an element that uses one,
/// so the many that don't carry nothing extra.
@MainActor public final class PointerHandlers {
  public var pointerStyle: PointerStyle?
  /// Shown instead of `pointerStyle` while the element is pressed: a draggable's closed hand.
  var pressedPointerStyle: PointerStyle?

  public var onContinuousHover: ((HoverPhase) -> Void)?
  public var hoverSpace: CoordinateSpace = .local

  /// `.onTapGesture(count:coordinateSpace:)`: called with where it was tapped.
  public var tapAction: ((float2) -> Void)?
  public var tapCount = 1
  public var tapSpace: CoordinateSpace = .local

  public var gesture: (any Gesture)? {
    // Cast once, here, rather than on every event.
    didSet {
      self.drag = self.gesture as? DragGesture
      self.tap = self.gesture as? TapGesture
    }
  }
  private(set) var drag: DragGesture?
  private(set) var tap: TapGesture?

  /// Whether it has anything for the hit grid to deliver.
  var handlesEvents: Bool {
    self.pointerStyle != nil || self.pressedPointerStyle != nil || self.onContinuousHover != nil
      || self.handlesPress
  }

  /// Whether a press on it goes to it: it taps, or it drags.
  var handlesPress: Bool { self.tapAction != nil || self.drag != nil || self.tap != nil }

  /// The tap it fires for `count` clicks, if any.
  func tap(forCount count: Int) -> ((float2) -> Void)? {
    if let action = self.tapAction, self.tapCount == count { return action }
    if let tap = self.tap, tap.count == count, let ended = tap.ended { return { _ in ended() } }
    return nil
  }

  init() {}
}

/// An element that keeps `PointerHandlers`: a `HittableView` or a vector shape. The properties
/// here are what `@Component` arms on mount and clears on unmount; clearing one never makes the
/// storage.
@MainActor public protocol PointerHandling: AnyObject {
  var pointer: PointerHandlers? { get set }
}

extension PointerHandling {
  private var handlers: PointerHandlers {
    if let pointer = self.pointer { return pointer }
    let pointer = PointerHandlers()
    self.pointer = pointer
    return pointer
  }

  public var pointerStyle: PointerStyle? {
    get { self.pointer?.pointerStyle }
    set {
      guard newValue != nil || self.pointer != nil else { return }
      self.handlers.pointerStyle = newValue
    }
  }

  var pressedPointerStyle: PointerStyle? {
    get { self.pointer?.pressedPointerStyle }
    set {
      guard newValue != nil || self.pointer != nil else { return }
      self.handlers.pressedPointerStyle = newValue
    }
  }

  public var onContinuousHover: ((HoverPhase) -> Void)? {
    get { self.pointer?.onContinuousHover }
    set {
      guard newValue != nil || self.pointer != nil else { return }
      self.handlers.onContinuousHover = newValue
    }
  }

  public var tapAction: ((float2) -> Void)? {
    get { self.pointer?.tapAction }
    set {
      guard newValue != nil || self.pointer != nil else { return }
      self.handlers.tapAction = newValue
    }
  }

  public var gesture: (any Gesture)? {
    get { self.pointer?.gesture }
    set {
      guard newValue != nil || self.pointer != nil else { return }
      // The placeholder `@Component` builds the chain with is no gesture at all.
      self.handlers.gesture = newValue is EmptyGesture ? nil : newValue
    }
  }

  /// Sets up `.onContinuousHover`: the space its locations are in, and the handler.
  func setContinuousHover(_ space: CoordinateSpace, _ action: ((HoverPhase) -> Void)?) {
    self.handlers.hoverSpace = space
    self.onContinuousHover = action
  }

  /// Sets up `.onTapGesture`: how many clicks, the space its location is in, and the handler.
  func setTapGesture(_ count: Int, _ space: CoordinateSpace, _ action: ((float2) -> Void)?) {
    self.handlers.tapCount = count
    self.handlers.tapSpace = space
    self.tapAction = action
  }
}
