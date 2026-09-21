//
//  HittableGrid2D.swift
//  MetalGraphics
//
//  Created by Nikolay Diahovets on 01.06.2026.
//

public struct HittableGridCell {
  var hittableViews: [HittableView] = []
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
    weak var view: HittableView?
  }

  private var hoveredViews: [UInt : HoveredView] = [:]

  public init(position: float2, size: int2, cellSize: Float) {
    let cellCount: Int = size.x * size.y
    self.cells = .init(repeating: .init(), count: cellCount)
    
    self.position = position
    self.cellCount = size
    self.cellSize = cellSize
    self.bounds = BoundingBox2D(center: position, size: float2(Float(size.x) * cellSize, Float(size.y) * cellSize))
  }
  
  public func reset() {
    self.cells.forEach { $0.hittableViews.removeAll(keepingCapacity: true)}
  }
  
  public func sortByDepth() {
    self.cells.forEach { $0.hittableViews.sort(by: { $0.depth > $1.depth }) }
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
      guard let view = self.hoveredViews[id]?.view, view.mounted else {
        // Gone, or on its way out. Dropped without an `onHover(false)`: there is nothing left
        // to tell, and calling into a component mid-teardown is the bug this guards against.
        self.hoveredViews.removeValue(forKey: id)
        continue
      }

      if !pointInAABBoxTopLeftOrigin(point: input.mousePosition, position: view.position, size: view.size) {
        view.isHovered = false
        view.onHover?(false, input)
        self.hoveredViews.removeValue(forKey: id)
      }
    }

    guard let cell = self.cell(at: input.mousePositionFromCenter) else { return }

    // `cells` holds views strongly until the next rebuild, so one unmounted earlier in this very
    // frame — by a tap handler that removed it — is still reachable here.
    for view in cell.hittableViews where view.mounted {
      let result = pointInAABBoxTopLeftOrigin(point: input.mousePosition, position: view.position, size: view.size)
      if result {
        if let hoverHandler = view.onHover, !view.isHovered {
          view.isHovered = true
          hoverHandler(true, input)
          self.hoveredViews[view.id] = HoveredView(view: view)
        }

        if let tapHandler = view.onTap, input.mouseDown {
          tapHandler(input)
        }
      }
    }
  }
  
  public func mapViewToGrid(_ view: HittableView, _ renderer: Graphics2D) {
    let gridTopLeft = self.bounds.topLeft
    let gridBottomRight = self.bounds.bottomRight
    
    // origin -> top left
    let newPosition = view.position - renderer.size * 0.5 + view.size * 0.5
    let box = BoundingBox2D(center: newPosition, size: view.size)
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
            }
          }
        }
      }
    }
  }
}
