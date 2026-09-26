//
//  HittableGrid2D.swift
//  MetalGraphics
//
//  Created by Nikolay Diahovets on 01.06.2026.
//

import simd

public struct HittableGridCell {
  /// The views over this cell, as indices into the grid's `views`, topmost first.
  var entries: [Int32] = []
}

/// Where the pointer goes: the views it can hit, filed by the cells of the window they cover,
/// and what it is doing to them — hovering, pressing, dragging — between frames.
///
/// The pointer is SwiftUI's. It hovers the topmost view under it that has anything to do with
/// the pointer, and the views that one sits in; a view covered by another is not hovered. A
/// press goes to the topmost view under it that takes presses, and stays with it until the
/// button comes up, wherever the pointer goes: its drag, its pointer style and its tap belong
/// to it until then.
@MainActor public class HittableGrid2D {
  public var position: float2
  public var cellCount: int2
  public var cellSize: Float
  public var bounds: BoundingBox2D

  public var cells: [HittableGridCell] = []

  /// Every view the pointer can hit, in tree order, and for each the nearest one it sits in
  /// (an index into `views`, or -1) and the clip it is hit inside.
  private(set) var views: [any Hittable] = []
  private var parents: [Int32] = []
  private var clips: [ClipRect?] = []

  /// A view the pointer is doing something to, held weakly.
  ///
  /// This is the one place a view is referenced between frames, and the one place that could
  /// resurrect a view its own tree has already dropped. It is therefore weak, and an entry is
  /// discarded as soon as its view is gone or unmounted: a row removed while hovered would
  /// otherwise keep its `HittableView` alive after the component that owns it was deallocated,
  /// and the next mouse move would call that view's handler against freed memory.
  private struct Entry {
    weak var view: (any Hittable)?
    var clip: ClipRect?
    /// For hover: where the pointer was over it last, in its hover space.
    var location = float2()
  }

  /// The views hovered: the topmost under the pointer, then the ones it sits in.
  private var hoverChain: [Entry] = []
  /// The next hover chain, built into kept storage so a move allocates nothing.
  private var nextChain: [Entry] = []
  /// Handlers to call once the hover state is settled, so one that changes the tree meets a
  /// consistent grid.
  private var hoverCalls: [(entry: Entry, phase: HoverChange)] = []
  private enum HoverChange { case entered, moved, left }

  /// The view the left button went down on, until it comes up.
  private weak var pressedView: (any Hittable)?
  /// That view and the ones it sits in, which a tap may land on instead: an inner view that
  /// only handles double clicks leaves a single click to the one around it.
  private var pressChain: [Entry] = []
  private var pressClickCount = 0
  /// The pointer style when the press began, kept while it lasts.
  private var pressStyle: PointerStyle = .default
  private var drag = DragState()

  private struct DragState {
    var start = float2()
    var startOrigin = float2()
    var last = float2()
    var lastTime: Double = 0
    var velocity = float2()
    var isActive = false
  }

  /// The pointer's shape, as of the last event or re-hover. See `PointerStyle`.
  public private(set) var pointerStyle: PointerStyle = .default

  public init(position: float2, size: int2, cellSize: Float) {
    let cellCount: Int = size.x * size.y
    self.cells = .init(repeating: .init(), count: cellCount)

    self.position = position
    self.cellCount = size
    self.cellSize = cellSize
    self.bounds = BoundingBox2D(center: position, size: float2(Float(size.x) * cellSize, Float(size.y) * cellSize))
  }

  /// Changes the cell count, for a window of a new size, keeping what the pointer is doing.
  func resize(_ size: int2) {
    self.cellCount = size
    self.cells = .init(repeating: .init(), count: size.x * size.y)
    self.bounds = BoundingBox2D(center: self.position, size: float2(Float(size.x) * self.cellSize, Float(size.y) * self.cellSize))
  }

  /// Starts a rebuild. Then `add` each view the pointer can hit, in tree order, and
  /// `mapViewToGrid` each, topmost first.
  func reset() {
    for index in self.cells.indices {
      self.cells[index].entries.removeAll(keepingCapacity: true)
    }
    self.views.removeAll(keepingCapacity: true)
    self.parents.removeAll(keepingCapacity: true)
    self.clips.removeAll(keepingCapacity: true)
  }

  /// A view the pointer can hit, with the nearest one it sits in (an index of an earlier `add`,
  /// or -1) and the clip it is hit inside.
  func add(_ view: any Hittable, parent: Int32, clip: ClipRect?) {
    self.views.append(view)
    self.parents.append(parent)
    self.clips.append(clip)
  }

  /// The cell under a point in centered coordinates, or nil when the point is off the grid.
  ///
  /// Bounds-checked: the pointer can sit outside the grid — at the very edge of the window, or
  /// before the grid has been resized to match it — and the raw index is then negative or past
  /// the end. Reading `cells` with it traps.
  private func cellIndex(at point: float2) -> Int? {
    let xIndex = Int(floor(remap(point.x, float2(self.bounds.left, self.bounds.right), float2(0, Float(self.cellCount.x)))))
    let yIndex = Int(floor(remap(point.y, float2(self.bounds.top, self.bounds.bottom), float2(0, Float(self.cellCount.y)))))

    guard xIndex >= 0, xIndex < Int(self.cellCount.x),
          yIndex >= 0, yIndex < Int(self.cellCount.y)
    else { return nil }

    let index = from2DTo1DArray(int2(xIndex, yIndex), self.cellCount)
    return self.cells.indices.contains(index) ? index : nil
  }

  private func hits(_ index: Int, _ point: float2) -> Bool {
    let view = self.views[index]
    return view.mounted && (self.clips[index]?.contains(point) ?? true) && view.hitTest(point)
  }

  /// The topmost view under `point` that `accepts`, as an index into `views`.
  ///
  /// `views` holds views strongly until the next rebuild, so one unmounted earlier in this very
  /// frame — by a tap handler that removed it — is still reachable, and skipped.
  private func topmost(at input: Input, where accepts: (any Hittable) -> Bool) -> Int? {
    guard let cell = self.cellIndex(at: input.mousePositionFromCenter) else { return nil }
    for entry in self.cells[cell].entries {
      let index = Int(entry)
      if accepts(self.views[index]), self.hits(index, input.mousePosition) {
        return index
      }
    }
    return nil
  }

  /// Fills `chain` with the view at `index` and the ones it sits in that the point also hits
  /// and that handle events, innermost first.
  private func chain(from index: Int, _ point: float2, into chain: inout [Entry]) {
    var current = index
    while current >= 0 {
      let view = self.views[current]
      if view.handlesEvents, self.hits(current, point) {
        chain.append(Entry(view: view, clip: self.clips[current]))
      }
      current = Int(self.parents[current])
    }
  }

  private static func location(_ point: float2, in space: CoordinateSpace, of view: any Hittable) -> float2 {
    space == .local ? point - view.hitPosition : point
  }

  // MARK: - Hover

  /// Hovers what is under the pointer now: ends the hover of views it left, starts it on views
  /// it entered, and tells continuous hovers where it is. Also what a re-hover runs, when the
  /// content moved under a pointer that did not.
  func updateHover(_ input: Input) {
    let point = input.mousePosition
    self.nextChain.removeAll(keepingCapacity: true)
    if let top = self.topmost(at: input, where: { $0.handlesEvents }) {
      self.chain(from: top, point, into: &self.nextChain)
    }

    self.hoverCalls.removeAll(keepingCapacity: true)
    // Leaves first, then enters, as the pointer passes from one to the next.
    for old in self.hoverChain {
      guard let view = old.view, view.mounted else {
        // Gone, or on its way out. Dropped without an `onHover(false)`: there is nothing left
        // to tell, and calling into a component mid-teardown is the bug this guards against.
        continue
      }
      if !self.nextChain.contains(where: { $0.view === view }) {
        view.isHovered = false
        self.hoverCalls.append((old, .left))
      }
    }
    for index in self.nextChain.indices {
      let view = self.nextChain[index].view!
      let space = view.pointer?.hoverSpace ?? .local
      let location = Self.location(point, in: space, of: view)
      self.nextChain[index].location = location
      if let old = self.hoverChain.first(where: { $0.view === view }) {
        if old.location != location, view.pointer?.onContinuousHover != nil {
          self.hoverCalls.append((self.nextChain[index], .moved))
        }
      } else {
        view.isHovered = true
        self.hoverCalls.append((self.nextChain[index], .entered))
      }
    }
    swap(&self.hoverChain, &self.nextChain)

    for (entry, change) in self.hoverCalls {
      guard let view = entry.view, view.mounted || change == .left else { continue }
      switch change {
      case .left:
        view.onHover?(false, input)
        view.pointer?.onContinuousHover?(.ended)
      case .entered:
        view.onHover?(true, input)
        view.pointer?.onContinuousHover?(.active(entry.location))
      case .moved:
        view.pointer?.onContinuousHover?(.active(entry.location))
      }
    }
    self.hoverCalls.removeAll(keepingCapacity: true)
    self.resolvePointerStyle()
  }

  // MARK: - Pointer style

  /// The pressed view's while a press lasts; otherwise the first set along the hover chain,
  /// from the topmost view out; otherwise the arrow.
  func resolvePointerStyle() {
    if let view = self.pressedView, view.mounted, view.isPressed {
      self.pointerStyle = view.pointer?.pressedPointerStyle ?? self.pressStyle
      return
    }
    for entry in self.hoverChain {
      if let style = entry.view?.pointer?.pointerStyle {
        self.pointerStyle = style
        return
      }
    }
    self.pointerStyle = .default
  }

  // MARK: - Buttons

  /// Presses, drags, taps and gestures, after `updateHover`.
  func handlePointer(_ input: Input, time: Double) {
    let point = input.mousePosition

    // Before looking for a view: a drag goes on wherever the pointer goes, off the view and off
    // the grid included.
    if input.mouseMoved, input.leftMousePressed, let view = self.pressedView, view.isPressed, view.mounted {
      view.onDrag?(input)
      if let gesture = view.pointer?.drag {
        self.moveDrag(gesture, view, point, time)
      }
    }

    // After the press below, so a click whose down and up land in one frame still ends.
    defer { self.endPress(input, time: time) }

    // A press goes to the topmost view that takes one: the one drawn over the others.
    if input.leftMouseDown, let index = self.topmost(at: input, where: { $0.handlesEvents && $0.handlesPress }) {
      let view = self.views[index]
      self.pressedView = view
      self.pressClickCount = max(input.clickCount, 1)
      self.pressChain.removeAll(keepingCapacity: true)
      self.chain(from: index, point, into: &self.pressChain)
      self.pressStyle = self.pointerStyle
      view.isPressed = true
      self.startDrag(view, point, time)
      view.onPress?(true, input)
      self.resolvePointerStyle()
    }

    // `onTap` fires on the button going down, left or right, on the topmost view that has one.
    if input.mouseDown, let index = self.topmost(at: input, where: { $0.handlesEvents && $0.onTap != nil }) {
      self.views[index].onTap?(input)
    }
  }

  private func endPress(_ input: Input, time: Double) {
    guard input.leftMouseUp, let view = self.pressedView else { return }
    self.pressedView = nil
    let wasDragging = self.drag.isActive
    self.drag.isActive = false
    defer {
      self.pressChain.removeAll(keepingCapacity: true)
      self.resolvePointerStyle()
    }
    // Dropped silently when gone: calling into a component mid-teardown is what the weak
    // entries guard against.
    guard view.isPressed, view.mounted else { return }
    view.isPressed = false
    view.onPress?(false, input)

    let point = input.mousePosition
    if wasDragging {
      if let gesture = view.pointer?.drag {
        gesture.ended?(self.dragValue(gesture, view, point, time))
      }
      return
    }
    // A tap: released over the view it went down on, or one around it, that takes this many
    // clicks.
    for entry in self.pressChain {
      guard let target = entry.view, target.mounted, (entry.clip?.contains(point) ?? true), target.hitTest(point),
            let pointer = target.pointer, let tap = pointer.tap(forCount: self.pressClickCount)
      else { continue }
      tap(Self.location(point, in: pointer.tapSpace, of: target))
      return
    }
  }

  // MARK: - Drag gesture

  private func startDrag(_ view: any Hittable, _ point: float2, _ time: Double) {
    self.drag = DragState(start: point, startOrigin: view.hitPosition, last: point, lastTime: time)
    guard let gesture = view.pointer?.drag, gesture.minimumDistance <= 0 else { return }
    self.drag.isActive = true
    gesture.changed?(self.dragValue(gesture, view, point, time))
  }

  private func moveDrag(_ gesture: DragGesture, _ view: any Hittable, _ point: float2, _ time: Double) {
    let dt = time - self.drag.lastTime
    if dt > 0 {
      let velocity = (point - self.drag.last) / Float(dt)
      // Smoothed, so one uneven frame does not throw it.
      self.drag.velocity = self.drag.velocity == .zero ? velocity : simd_mix(self.drag.velocity, velocity, float2(repeating: 0.5))
    }
    self.drag.last = point
    self.drag.lastTime = time
    if !self.drag.isActive {
      guard simd_distance(point, self.drag.start) >= gesture.minimumDistance else { return }
      self.drag.isActive = true
    }
    gesture.changed?(self.dragValue(gesture, view, point, time))
  }

  private func dragValue(_ gesture: DragGesture, _ view: any Hittable, _ point: float2, _ time: Double) -> DragGesture.Value {
    let local = gesture.coordinateSpace == .local
    let location = local ? point - view.hitPosition : point
    let start = local ? self.drag.start - self.drag.startOrigin : self.drag.start
    let translation = point - self.drag.start
    let throwDistance = self.drag.velocity * 0.5
    return DragGesture.Value(
      time: time, location: location, startLocation: start, translation: translation, velocity: self.drag.velocity,
      predictedEndLocation: location + throwDistance, predictedEndTranslation: translation + throwDistance
    )
  }

  // MARK: - Filing

  /// Files view `index` under the cells its hit rect covers, cut to its clip: none, when it is
  /// clipped away entirely.
  func mapViewToGrid(_ index: Int, _ renderer: Graphics2D) {
    let view = self.views[index]
    let gridTopLeft = self.bounds.topLeft
    let gridBottomRight = self.bounds.bottomRight

    var rect = ClipRect(position: view.hitPosition, size: view.hitSize)
    if let clip = self.clips[index] {
      rect = rect.intersection(clip)
      if rect.isEmpty { return }
    }
    let size = rect.max - rect.min
    // origin -> top left
    let newPosition = rect.min - renderer.size * 0.5 + size * 0.5
    let box = BoundingBox2D(center: newPosition, size: size)
    let boxTopLeft = box.topLeft
    let boxBottomRight = box.bottomRight

    var prevY = Int(-1)
    for y in StepSequence(from: boxBottomRight.y, to: boxTopLeft.y, step: self.cellSize) {
      if y.isBetween(gridBottomRight.y...gridTopLeft.y) {
        let yIndex = Int(floor(remap(y, float2(self.bounds.bottom, self.bounds.top), float2(0, Float(self.cellCount.y)))))

        if prevY == yIndex {
          continue
        }
        prevY = yIndex

        var prevX = Int(-1)
        for x in StepSequence(from: boxTopLeft.x, to: boxBottomRight.x, step: self.cellSize) {
          if x.isBetween(gridTopLeft.x...gridBottomRight.x) {
            let xIndex = Int(floor(remap(x, float2(self.bounds.left, self.bounds.right), float2(0, Float(self.cellCount.x)))))

            if prevX == xIndex {
              continue
            }
            prevX = xIndex

            let coord = int2(xIndex, yIndex)
            let cell = from2DTo1DArray(coord, cellCount)

            if cell < self.cells.count {
              self.cells[cell].entries.append(Int32(index))
            }
          }
        }
      }
    }
  }
}
