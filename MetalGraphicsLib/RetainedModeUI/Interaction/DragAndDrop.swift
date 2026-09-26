import Foundation
import simd

// Drag and drop inside the app, in SwiftUI's shape: `.draggable(value)` on what is dragged,
// `.dropDestination(for: T.self) { items, location in … }` on where it can land, and
// `.onMove { from, to in … }` on a list whose rows the user reorders.
//
// A payload is any Swift value. A destination for `T` takes a payload that is a `T`; nothing
// goes through the pasteboard, so nothing leaves the app or comes in from another.
//
// The press and the moves come from the hit grid's pointer capture, the same `onPress`/`onDrag`
// a slider's knob follows. `UIContext` holds the one drag in progress (`DragSession`), finds the
// destination under the pointer and draws what follows it: by default the dragged element
// itself, drawn a second time above everything with its paint-order range, which needs no
// element of its own.

/// The drag in progress. Held by `UIContext.drag`.
@MainActor final class DragSession {
  /// How far the pointer moves with the button down before a press becomes a drag, in points.
  /// Less is a click.
  static let threshold: Float = 3
  /// How opaque the lifted copy of the dragged element is drawn.
  static let ghostOpacity: Float = 0.8

  /// The element that started it, and alone moves, ends or cancels it.
  weak var owner: UIElement?
  let payload: Any?
  /// Where the pointer was when the drag started, and where it is now, window top left origin.
  let start: float2
  var pointer: float2
  /// Where the element drawn under the pointer sits in `UIContext.paintOrder`, found by
  /// `collect` on each rebuild. Empty with a custom preview.
  var ghostStart = 0
  var ghostEnd = 0
  /// The custom preview, mounted for the drag.
  var preview: DragPreviewLayer?
  /// The destination the payload would drop on now.
  weak var target: DropDestinationBase?

  init(owner: UIElement, payload: Any?, start: float2) {
    self.owner = owner
    self.payload = payload
    self.start = start
    self.pointer = start
  }
}

/// A custom drag preview's root: laid out at its ideal size, centred on the pointer by its own
/// effect, so following the pointer only redraws. Collected after everything else as if leaving:
/// drawn on top, never hit.
final class DragPreviewLayer : SingleChildElement {
  var pointer: float2 = .zero
  private var size: float2 = .zero

  init(_ content: UIElement) {
    super.init()
    self.applyContent([content])
  }

  override func getSize() -> float2 {
    self.size
  }

  override func calcSize(_ proposal: ProposedSize) -> float2 {
    self.size = self.child?.calcSize(proposal) ?? .zero
    return self.size
  }

  override func calcPosition(_ position: float2) {
    self.child?.calcPosition(position)
  }

  override var localEffect: EffectState {
    EffectState(opacity: 1, scale: 1, translate: self.pointer - self.size * 0.5)
  }

  override var hasEffect: Bool { true }
}

// MARK: - Draggable

/// Makes its content draggable, carrying `payload`. Made by `.draggable(_:)`.
///
/// The drag starts once the pointer has moved `DragSession.threshold` points with the button
/// down; a shorter press stays a click. Escape cancels it.
public final class DraggableElement : HittableView {
  /// What a drop destination receives. Read when the drag starts.
  public var payload: Any
  /// Drawn under the pointer instead of the content itself. Not a child: mounted only while
  /// dragging.
  public internal(set) var preview: UIElement?

  private weak var context: UIContext?
  /// The text style it was last laid out under: what the preview, laid out apart from the
  /// tree, is styled with.
  private var textScope = TextEnvironment()
  /// Where the button went down, until the press becomes a drag or ends.
  private var pressPoint: float2? = nil

  public init(_ payload: Any, @UIElementBuilder content: () -> [UIElement]) {
    self.payload = payload
    super.init(content: content)
    // Its own, never armed or cleared by `@Component`: nothing captures a component here.
    self.onPress = { [unowned self] down, input in self.pressed(down, input) }
    self.onDrag = { [unowned self] input in self.dragged(input) }
    // An open hand over it, closed while it is pressed and dragged.
    self.pointerStyle = .grabIdle
    self.pressedPointerStyle = .grabActive
  }

  /// Sets the preview. What `.draggable(_:preview:)`'s content is applied with, like an
  /// overlay's content: the element's own content is its child.
  public func replaceContent(_ elements: [UIElement], _ context: UIContext, animation: UIAnimation? = nil) {
    self.preview = Self.preview(elements)
  }

  static func preview(_ elements: [UIElement]) -> UIElement? {
    switch elements.count {
    case 0: return nil
    case 1: return elements[0]
    default:
      let stack = ZStack()
      stack.applyContent(elements)
      return stack
    }
  }

  public override func mount(_ context: UIContext) {
    super.mount(context)
    self.context = context
  }

  public override func calcSize(_ proposal: ProposedSize) -> float2 {
    self.textScope = TextScope.current
    return super.calcSize(proposal)
  }

  public override func unmount(_ context: UIContext) {
    self.pressPoint = nil
    // Removed mid-drag: the drag goes with it.
    if context.drag?.owner === self {
      context.cancelDrag()
    }
    super.unmount(context)
  }

  private func pressed(_ down: Bool, _ input: Input) {
    guard let context = self.context else { return }
    if down {
      self.pressPoint = input.mousePosition
      return
    }
    self.pressPoint = nil
    context.endDrag(self, at: input.mousePosition)
  }

  private func dragged(_ input: Input) {
    guard let context = self.context else { return }
    let point = input.mousePosition
    if let start = self.pressPoint {
      guard simd_distance(start, point) >= DragSession.threshold else { return }
      self.pressPoint = nil
      context.beginDrag(
        owner: self, payload: self.payload, ghost: self.preview == nil ? self : nil, preview: self.preview, from: start,
        textStyle: self.textScope
      )
    }
    // After a cancel, the rest of the press moves nothing.
    context.dragMoved(self, to: point)
  }
}

// MARK: - Drop destination

/// What `UIContext` finds under a drag: a `DropDestinationElement` of any payload type.
public class DropDestinationBase : SingleChildElement {
  public internal(set) var position: float2 = .zero
  public internal(set) var size: float2 = .zero
  /// Whether a drag of something it takes is over it.
  public internal(set) var isTargetedNow: Bool = false

  func accepts(_ payload: Any) -> Bool { false }
  func perform(_ payload: Any, at location: float2) -> Bool { false }
  func targetedChanged(_ targeted: Bool) {}

  final func setTargeted(_ targeted: Bool) {
    guard targeted != self.isTargetedNow else { return }
    self.isTargetedNow = targeted
    self.targetedChanged(targeted)
  }

  public override func mount(_ context: UIContext) {
    context.registerDropTarget(self)
  }

  public override func unmount(_ context: UIContext) {
    // Quietly, as a hover ends in `HittableGrid2D`: no calling into a component mid-teardown.
    self.isTargetedNow = false
    context.unregisterDropTarget(self)
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

/// Takes drops of `T` on its content. Made by `.dropDestination(for:action:isTargeted:)`.
public final class DropDestinationElement<T> : DropDestinationBase {
  /// Called with the dropped items and where they landed, from this element's top left corner.
  /// Returns whether the drop was taken. Settable, and cleared while unmounted, like a
  /// `HittableView`'s handlers.
  public var action: (([T], float2) -> Bool)?
  /// Called with true when a drag of a `T` comes over it, and with false when it leaves or ends.
  public var isTargeted: ((Bool) -> Void)?

  public init(
    action: (([T], float2) -> Bool)?, isTargeted: ((Bool) -> Void)?,
    @UIElementBuilder content: () -> [UIElement]
  ) {
    self.action = action
    self.isTargeted = isTargeted
    super.init()
    self.applyContent(content())
  }

  override func accepts(_ payload: Any) -> Bool {
    payload is T
  }

  override func perform(_ payload: Any, at location: float2) -> Bool {
    guard let item = payload as? T, let action = self.action else { return false }
    return action([item], location)
  }

  override func targetedChanged(_ targeted: Bool) {
    self.isTargeted?(targeted)
  }
}

// MARK: - Reordering

/// Lets the user drag a list's rows to reorder them. Made by `VList.onMove` and `HList.onMove`.
///
/// A press on a row that no control inside it takes, moved past the threshold, lifts the row;
/// a line shows where it would go, and on release `action` is called with SwiftUI's
/// `move(fromOffsets:toOffset:)` arguments. The rows move only when the action moves the array,
/// e.g. with the generated `move…(fromOffsets:toOffset:)`.
public final class ReorderElement : HittableView {
  /// Settable, and cleared while unmounted, like a `HittableView`'s handlers.
  public var action: ((IndexSet, Int) -> Void)?

  private unowned let stack: StackElement
  private let indicator = ReorderIndicator()
  private weak var context: UIContext?
  /// The row pressed, by logical index, and where, until the press ends.
  private var source: Int? = nil
  private var pressPoint: float2? = nil
  private var dragging = false
  /// Where the row would go, as a `toOffset`.
  private var destination: Int = 0

  init(_ stack: StackElement, action: ((IndexSet, Int) -> Void)?) {
    self.stack = stack
    self.action = action
    super.init(content: { stack })
    self.onPress = { [unowned self] down, input in self.pressed(down, input) }
    self.onDrag = { [unowned self] input in self.dragged(input) }
  }

  override func forEachChild(_ body: (UIElement) -> Void) {
    super.forEachChild(body)
    body(self.indicator)
  }

  public override func mount(_ context: UIContext) {
    super.mount(context)
    self.context = context
  }

  public override func unmount(_ context: UIContext) {
    if context.drag?.owner === self {
      context.cancelDrag()
    }
    self.reset()
    super.unmount(context)
  }

  private func reset() {
    self.source = nil
    self.pressPoint = nil
    self.dragging = false
    self.indicator.isShown = false
  }

  /// The row at logical `index`, skipping rows playing their removal transition.
  private func row(_ index: Int) -> UIElement? {
    var live = 0
    for child in self.stack.children where !child.isLeaving {
      if live == index { return child }
      live += 1
    }
    return nil
  }

  /// A row's rect along the stack's axis, window top left origin.
  private func span(_ row: UIElement) -> (start: float2, size: float2) {
    (self.position + (row.placement ?? .zero), row.getSize())
  }

  private func pressed(_ down: Bool, _ input: Input) {
    guard let context = self.context else { return }
    if down {
      self.reset()
      let axis = self.stack.axis
      let point = input.mousePosition
      var index = 0
      for child in self.stack.children where !child.isLeaving {
        let (start, size) = self.span(child)
        if point[axis] >= start[axis], point[axis] < start[axis] + size[axis] {
          self.source = index
          self.pressPoint = point
          return
        }
        index += 1
      }
      return
    }

    let wasDragging = self.dragging
    let from = self.source
    let to = self.destination
    self.reset()
    context.invalidate(.render)
    guard wasDragging, let from else { return }
    context.endDrag(self, at: input.mousePosition)
    if to != from, to != from + 1 {
      self.action?(IndexSet(integer: from), to)
    }
  }

  private func dragged(_ input: Input) {
    guard let context = self.context, let source = self.source else { return }
    let point = input.mousePosition
    if let start = self.pressPoint {
      guard simd_distance(start, point) >= DragSession.threshold, let row = self.row(source) else { return }
      self.pressPoint = nil
      self.dragging = true
      self.destination = source
      context.beginDrag(owner: self, payload: nil, ghost: row, preview: nil, from: start)
    }
    // Cancelled: the rest of the press moves nothing.
    guard self.dragging, context.drag?.owner === self else {
      if self.indicator.isShown {
        self.reset()
        context.invalidate(.render)
      }
      return
    }
    context.dragMoved(self, to: point)
    self.updateDestination(point, context)
  }

  /// The gap nearest the pointer along the axis: before the first row whose middle is past it.
  private func updateDestination(_ point: float2, _ context: UIContext) {
    let axis = self.stack.axis
    var index = 0
    var destination: Int? = nil
    var lastEnd: Float = self.position[axis]
    var gapStart: Float = self.position[axis]
    for child in self.stack.children where !child.isLeaving {
      let (start, size) = self.span(child)
      if destination == nil, point[axis] < start[axis] + size[axis] * 0.5 {
        destination = index
        // Midway between this row and the one before it.
        gapStart = index == 0 ? start[axis] : (lastEnd + start[axis]) * 0.5
      }
      lastEnd = start[axis] + size[axis]
      index += 1
    }
    if destination == nil {
      gapStart = lastEnd
    }
    let to = destination ?? index
    guard to != self.destination || !self.indicator.isShown else { return }
    self.destination = to

    let thickness = ReorderIndicator.thickness
    var origin = self.position
    origin[axis] = gapStart - thickness * 0.5
    var size = self.size
    size[axis] = thickness
    self.indicator.origin = origin
    self.indicator.lineSize = size
    self.indicator.isShown = true
    context.invalidate(.render)
  }
}

/// The line a `ReorderElement` draws where the dragged row would go. Laid out by it, not by
/// layout: it moves only while dragging, and then only redraws.
final class ReorderIndicator : UIRenderableElement {
  static let thickness: Float = 2
  static let color = FormMetrics.accentColor

  var isShown = false
  var origin: float2 = .zero
  var lineSize: float2 = .zero

  override func mount(_ context: UIContext) {
    context.registerRenderableView(self)
  }

  override func unmount(_ context: UIContext) {
    context.unregisterRenderableView(self)
  }

  override func render(_ renderer: Graphics2D, _ effect: EffectState) {
    guard self.isShown, effect.opacity > 0 else { return }
    let size = self.lineSize * effect.scale
    var color = Self.color
    color.w *= effect.opacity
    // origin -> top left, window centered
    let origin = effect.apply(to: self.origin) - renderer.size * 0.5
    renderer.draw(roundedRect: origin, size: size, radii: float4(repeating: Self.thickness * 0.5 * effect.scale), color: color)
  }
}

// MARK: - Modifiers

extension UIElementWrapping where Self: UIElement {
  /// Makes this element draggable, carrying `payload` to any `.dropDestination(for:)` of its type.
  /// While dragging, a copy of it follows the pointer.
  public func draggable<T>(_ payload: T) -> DraggableElement {
    DraggableElement(payload) {
      self
    }
  }

  /// Makes this element draggable, carrying `payload`, with `preview` following the pointer.
  public func draggable<T>(_ payload: T, @UIElementBuilder preview: () -> [UIElement]) -> DraggableElement {
    let element = DraggableElement(payload) {
      self
    }
    element.preview = DraggableElement.preview(preview())
    return element
  }

  /// Takes drops of `T` on this element. `action` gets the dropped items and where they landed,
  /// from this element's top left corner, and returns whether it took them; `isTargeted` is told
  /// when a drag of a `T` comes over it and when it leaves.
  public func dropDestination<T>(
    for type: T.Type = T.self, action: @escaping ([T], float2) -> Bool,
    isTargeted: @escaping (Bool) -> Void = { _ in }
  ) -> DropDestinationElement<T> {
    DropDestinationElement(action: action, isTargeted: isTargeted) {
      self
    }
  }
}

extension VList {
  /// Lets the user drag the rows to reorder them. `action` gets SwiftUI's
  /// `move(fromOffsets:toOffset:)` arguments.
  public func onMove(perform action: @escaping (IndexSet, Int) -> Void) -> ReorderElement {
    ReorderElement(self, action: action)
  }
}

extension HList {
  /// Lets the user drag the items to reorder them. `action` gets SwiftUI's
  /// `move(fromOffsets:toOffset:)` arguments.
  public func onMove(perform action: @escaping (IndexSet, Int) -> Void) -> ReorderElement {
    ReorderElement(self, action: action)
  }
}
