public enum ShapeType2D: Int32 {
  case Circle
  case Square
  case Line
}

public struct Shape {
  public var index: Int32;
  public var shapeType: Int32;
  
  public init(index: Int32, shapeType: Int32) {
    self.index = index
    self.shapeType = shapeType
  }
}

public class Grid2D {
  public struct Cell {
    public var shapes: [Shape] = []
  }
  
  public var size: int2
  public var cellSize: Float
  public var position: float2
  public var bounds: BoundingBox2D
  public var cells: [Cell] = []
  
  public init(position: float2, size: int2, cellSize: Float) {
    self.size = size
    self.cellSize = cellSize
    self.position = position
    self.bounds = BoundingBox2D(center: position, size: float2(Float(size.x) * cellSize, Float(size.y) * cellSize))
    self.cells = Array(repeating: Cell(), count: size.x * size.y)
  }
  
  public func reset() {
    for i in 0..<self.cells.count {
      cells[i].shapes.removeAll(keepingCapacity: true)
    }
  }
  
  public func mapShapeBoundingBoxToGrid(_ box: BoundingBox2D, _ shape: Shape) {
    let gridTopLeft = self.bounds.topLeft
    let gridBottomRight = self.bounds.bottomRight
    let boxTopLeft = box.topLeft
    let boxBottomRight = box.bottomRight
    var usedIndecies: [Int] = []
    
    iterateWithStep(from: boxBottomRight.y, to: boxTopLeft.y, step: self.cellSize) { y in
      if y.isBetween(gridBottomRight.y...gridTopLeft.y) {
        let yIndex = floor(remap(y, float2(self.bounds.bottom, self.bounds.top), float2(0, Float(self.size.y))))
        iterateWithStep(from: boxTopLeft.x, to: boxBottomRight.x, step: self.cellSize) { x in
          if x.isBetween(gridTopLeft.x...gridBottomRight.x) {
            let xIndex = floor(remap(x, float2(self.bounds.left, self.bounds.right), float2(0, Float(self.size.x))))
            
            let coord = int2(Int(xIndex), Int(yIndex))
            let index = from2DTo1DArray(coord, self.size)
            
            if !usedIndecies.contains(where: { $0 == index })  {
              self.cells[index].shapes.append(shape)
              usedIndecies.append(index)
            }
          }
        }
      }
    }
  }
}
