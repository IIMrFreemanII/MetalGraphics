import simd

/// A gesture an element recognizes, attached with `.gesture(_:)`: a `DragGesture` or a
/// `TapGesture`, as in SwiftUI.
///
/// Recognized by the hit grid on the element the left button went down on. A drag that has
/// started is not also a tap.
public protocol Gesture {}

/// No gesture: what `@Component` builds `.gesture(…)` with until it arms the real one on mount.
public struct EmptyGesture: Gesture {
  public init() {}
}

/// Recognizes `count` clicks in a row, ending on the button's release inside the element.
public struct TapGesture: Gesture {
  public var count: Int
  var ended: (() -> Void)?

  public init(count: Int = 1) {
    self.count = count
  }

  public func onEnded(_ action: @escaping () -> Void) -> TapGesture {
    var gesture = self
    gesture.ended = action
    return gesture
  }
}

/// Recognizes the pointer moving with the left button held, once it has moved
/// `minimumDistance` points from where the button went down.
public struct DragGesture: Gesture {
  public struct Value: Equatable, Sendable {
    /// When this value was made, in the context's clock.
    public var time: Double
    /// Where the pointer is, in the gesture's coordinate space.
    public var location: float2
    /// Where the button went down, in the gesture's coordinate space.
    public var startLocation: float2
    /// How far the pointer has moved since the button went down, in window points: the same
    /// whichever space the locations are in, and unaffected by the element moving with it.
    public var translation: float2
    /// Points per second, smoothed over the last few moves.
    public var velocity: float2
    /// Where the pointer would come to rest if it were thrown now. An estimate: `location`
    /// plus half a second of `velocity`.
    public var predictedEndLocation: float2
    public var predictedEndTranslation: float2
  }

  public var minimumDistance: Float
  public var coordinateSpace: CoordinateSpace
  var changed: ((Value) -> Void)?
  var ended: ((Value) -> Void)?

  public init(minimumDistance: Float = 10, coordinateSpace: CoordinateSpace = .local) {
    self.minimumDistance = minimumDistance
    self.coordinateSpace = coordinateSpace
  }

  /// Called on every move once the drag has started, and when it starts.
  public func onChanged(_ action: @escaping (Value) -> Void) -> DragGesture {
    var gesture = self
    gesture.changed = action
    return gesture
  }

  /// Called when the button comes up after the drag started.
  public func onEnded(_ action: @escaping (Value) -> Void) -> DragGesture {
    var gesture = self
    gesture.ended = action
    return gesture
  }
}
