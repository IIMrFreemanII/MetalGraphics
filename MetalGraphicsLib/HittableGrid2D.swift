//
//  HittableGrid2D.swift
//  MetalGraphics
//
//  Created by Nikolay Diahovets on 01.06.2026.
//

public struct HittableGridCell {
  var hittableViews: [any Hittable] = []
  /// The clip each of `hittableViews` is hit inside, nil for none. Parallel to it.
  var clips: [ClipRect?] = []
}

@MainActor public class HittableGrid2D {
  public var position: float2
  public var cellCount: int2
  public var cellSize: Float
  public var bounds: BoundingBox2D
  
  public var cells: [HittableGridCell] = []

  /// The views the pointer is currently inside, so a hover can be ended when it leaves.
  ///
  /// Hover has to outlive a grid rebuild — `reset()` clears only `cells` — which makes this the
  /// one place a view is referenced between frames, and the one place that can resurrect a view
  /// its own tree has already dropped. It is therefore weak, and entries are discarded as soon
  /// as the view is gone or unmounted: a row removed while hovered would otherwise keep its
  /// `HittableView` alive after the component that owns it was deallocated, and the next mouse
  /// move would call that view's handler against freed memory.
  private struct HoveredView {
    weak var view: (any Hittable)?
    var clip: ClipRect?
  }

  private var hoveredViews: [ObjectIdentifier : HoveredView] = [:]

  /// The view the left button went down on, told when it comes up. Weak for the same reason as
  /// `hoveredViews`.
  private weak var pressedView: (any Hittable)?

  public init(position: float2, size: int2, cellSize: Float) {
    let cellCount: Int = size.x * size.y
    self.cells = .init(repeating: .init(), count: cellCount)
    
    self.position = position
    self.cellCount = size
    self.cellSize = cellSize
    self.bounds = BoundingBox2D(center: position, size: float2(Float(size.x) * cellSize, Float(size.y) * cellSize))
  }
  
  public func reset() {
    for index in self.cells.indices {
      self.cells[index].hittableViews.removeAll(keepingCapacity: true)
      self.cells[index].clips.removeAll(keepingCapacity: true)
    }
  }
  
  /// The cell under a point in centered coordinates, or nil when the point is off the grid.
  ///
  /// Bounds-checked: the pointer can sit outside the grid — at the very edge of the window, or
  /// before the grid has been resized to match it — and the raw index is then negative or past
  /// the end. Reading `cells` with it traps.
  private func cell(at point: float2) -> HittableGridCell? {
    let xIndex = Int(floor(remap(point.x, float2(self.bounds.left, self.bounds.right), float2(0, Float(self.cellCount.x)))))
    let yIndex = Int(floor(remap(point.y, float2(self.bounds.top, self.bounds.bottom), float2(0, Float(self.cellCount.y)))))

    guard xIndex >= 0, xIndex < Int(self.cellCount.x),
          yIndex >= 0, yIndex < Int(self.cellCount.y)
    else { return nil }

    let index = from2DTo1DArray(int2(xIndex, yIndex), self.cellCount)

    return self.cells.indices.contains(index) ? self.cells[index] : nil
  }

  public func handleEvents(_ input: Input) {
    // Ending a hover runs first and unconditionally: it is exactly when the pointer leaves the
    // grid that hovers need to end, so this must not depend on finding a cell under it.
    //
    // Over a snapshot of the keys: the loop mutates the dictionary, and a handler it calls may
    // mutate it again by removing part of the tree.
    for id in Array(self.hoveredViews.keys) {
      guard let hovered = self.hoveredViews[id], let view = hovered.view, view.mounted else {
        // Gone, or on its way out. Dropped without an `onHover(false)`: there is nothing left
        // to tell, and calling into a component mid-teardown is the bug this guards against.
        self.hoveredViews.removeValue(forKey: id)
        continue
      }

      if !Self.hits(view, hovered.clip, input.mousePosition) {
        view.isHovered = false
        view.onHover?(false, input)
        self.hoveredViews.removeValue(forKey: id)
      }
    }

    // Before looking for a cell: a drag goes on wherever the pointer goes, off the view and off
    // the grid included.
    if input.mouseMoved, input.leftMousePressed, let view = self.pressedView, view.isPressed, view.mounted {
      view.onDrag?(input)
    }

    // After the press below, so a click whose down and up land in one frame still ends.
    defer { self.endPress(input) }

    guard let cell = self.cell(at: input.mousePositionFromCenter) else { return }

    // `cells` holds views strongly until the next rebuild, so one unmounted earlier in this very
    // frame — by a tap handler that removed it — is still reachable here.
    //
    // Each cell lists its views topmost first (see `UIContext.rebuildHitGrid`). Every view under
    // the pointer is hovered, but a tap goes only to the topmost view that handles one — the
    // one drawn over the others — so a view underneath cannot take a click aimed at what covers it.
    var tapHandled = false
    var pressHandled = false
    for (view, clip) in zip(cell.hittableViews, cell.clips) where view.mounted && view.handlesEvents {
      if Self.hits(view, clip, input.mousePosition) {
        if let hoverHandler = view.onHover, !view.isHovered {
          view.isHovered = true
          hoverHandler(true, input)
          self.hoveredViews[ObjectIdentifier(view)] = HoveredView(view: view, clip: clip)
        }

        // A view that only drags is pressed too: that is what later drags go to.
        if !pressHandled, view.onPress != nil || view.onDrag != nil, input.leftMouseDown {
          pressHandled = true
          self.pressedView = view
          view.isPressed = true
          view.onPress?(true, input)
        }

        if !tapHandled, let tapHandler = view.onTap, input.mouseDown {
          tapHandled = true
          tapHandler(input)
        }
      }
    }
  }
  
  private static func hits(_ view: any Hittable, _ clip: ClipRect?, _ point: float2) -> Bool {
    (clip?.contains(point) ?? true) && view.hitTest(point)
  }

  private func endPress(_ input: Input) {
    guard input.leftMouseUp, let view = self.pressedView else { return }
    self.pressedView = nil
    // Dropped silently when gone: calling into a component mid-teardown is what `hoveredViews`
    // guards against too.
    guard view.isPressed, view.mounted else { return }
    view.isPressed = false
    view.onPress?(false, input)
  }

  /// Files `view` under the cells its hit rect covers, cut to `clip`: none, when it is clipped
  /// away entirely.
  public func mapViewToGrid(_ view: any Hittable, _ clip: ClipRect?, _ renderer: Graphics2D) {
    let gridTopLeft = self.bounds.topLeft
    let gridBottomRight = self.bounds.bottomRight

    var rect = ClipRect(position: view.hitPosition, size: view.hitSize)
    if let clip {
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
            let index = from2DTo1DArray(coord, cellCount)
            
            if index < self.cells.count {
              self.cells[index].hittableViews.append(view)
              self.cells[index].clips.append(clip)
            }
          }
        }
      }
    }
  }
}
