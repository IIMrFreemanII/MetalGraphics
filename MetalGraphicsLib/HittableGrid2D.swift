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
  private var hoveredViews: [UInt : HittableView] = [:]
  
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
  
  public func handleEvents(_ input: Input) {
    let mouseCoord = input.mousePositionFromCenter
    let xIndex = Int(floor(remap(mouseCoord.x, float2(self.bounds.left, self.bounds.right), float2(0, Float(self.cellCount.x)))))
    let yIndex = Int(floor(remap(mouseCoord.y, float2(self.bounds.top, self.bounds.bottom), float2(0, Float(self.cellCount.y)))))
    let index = from2DTo1DArray(int2(xIndex, yIndex), self.cellCount)
    let cell = self.cells[index]
    
    for hoveredView in self.hoveredViews.values {
      if !pointInAABBoxTopLeftOrigin(point: input.mousePosition, position: hoveredView.position, size: hoveredView.size) {
        hoveredView.isHovered = false
        hoveredView.onHover!(false, input)
        self.hoveredViews.removeValue(forKey: hoveredView.id)
      }
    }
    
    var tapHandled = false
    
    for view in cell.hittableViews {
      let result = pointInAABBoxTopLeftOrigin(point: input.mousePosition, position: view.position, size: view.size)
      if result {
        if let hoverHandler = view.onHover {
          if !view.isHovered {
            view.isHovered = true
            hoverHandler(true, input)
            self.hoveredViews[view.id] = view
          }
        } else if let tapHandler = view.onTap, !tapHandled, input.mouseDown {
          tapHandler(input)
          tapHandled = true
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
