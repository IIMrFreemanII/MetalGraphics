//
//  HittableGrid2D.swift
//  MetalGraphics
//
//  Created by Nikolay Diahovets on 01.06.2026.
//

struct HittableGridCell {
  var hittableViews: [HittableView] = []
}

@MainActor class HittableGrid2D {
  public var position: float2
  public var size: int2
  public var cellSize: Float
  public var bounds: BoundingBox2D
  
  public var cells: [HittableGridCell] = []
  
  public init(position: float2, size: int2, cellSize: Float) {
    let cellCount: Int = size.x * size.y
    self.cells = .init(repeating: .init(), count: cellCount)
    
    self.position = position
    self.size = size
    self.cellSize = cellSize
    self.bounds = BoundingBox2D(center: position, size: float2(Float(size.x) * cellSize, Float(size.y) * cellSize))
  }
  
  public func reset() {
    self.cells.forEach { $0.hittableViews.removeAll(keepingCapacity: true)}
  }
  
  public func sortByDepth() {
    self.cells.forEach { $0.hittableViews.sort(by: { $0.depth > $1.depth }) }
  }
  
  public func mapViewToGrid(_ view: HittableView) {
    let gridTopLeft = self.bounds.topLeft
    let gridBottomRight = self.bounds.bottomRight
    let box = BoundingBox2D(center: .init(), size: .init())
    let boxTopLeft = box.topLeft
    let boxBottomRight = box.bottomRight

    
  }
}
