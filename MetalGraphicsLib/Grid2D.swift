import MetalKit

enum ShapeType2D: Int32 {
  case Circle
  case Square
  case Line
}

struct Shape {
  public var index: Int32;
  public var shapeType: Int32;
  
  public init(index: Int32, shapeType: Int32) {
    self.index = index
    self.shapeType = shapeType
  }
}

struct GridCellArgBuffer {
  var shapes: UInt64 = 0
  var count: Int32 = 0
}

struct GridArgBuffer {
  var gridCells: UInt64 = 0
  var gridSize = SIMD2<Int32>()
  var cellSize = Float()
  var gridPosition = float2()
}

class Grid2D {
  class Cell {
    var shapes: [Shape] = []
    var shapeBuffer: MTLBuffer!
    var shapeBufferCount: Int = 0
    
    init() {
      self.shapeBuffer = Graphics.shared.device.makeBuffer(length: MemoryLayout<Shape>.stride * 1)
    }
    
    public func updateBuffer() {
      if shapeBufferCount < shapes.count {
        shapeBufferCount += 10
        shapeBuffer = Graphics.shared.device.makeBuffer(length: MemoryLayout<Shape>.stride * shapeBufferCount)
        shapeBuffer.label = "Shape buffer"
      }
      
      shapeBuffer.contents().copyMemory(from: &shapes, byteCount: shapes.byteCount)
    }
  }
  
  public var size: int2
  public var cellSize: Float
  public var position: float2
  public var bounds: BoundingBox2D
  public var cells: [Cell] = []
  public var cellBuffer: MTLBuffer!
  public var cellBufferCount: Int = 0
  public var gridArgBuffer: MTLBuffer!
  
  public init(position: float2, size: int2, cellSize: Float) {
    self.size = size
    self.cellSize = cellSize
    self.position = position
    self.bounds = BoundingBox2D(center: position, size: float2(Float(size.x) * cellSize, Float(size.y) * cellSize))
    self.cellBufferCount = size.x * size.y
    
    self.cells.reserveCapacity(self.cellBufferCount)
    for _ in 0..<self.cellBufferCount {
      self.cells.append(Cell())
    }
    
    self.cellBuffer = Graphics.shared.device.makeBuffer(length: MemoryLayout<GridCellArgBuffer>.stride * self.cellBufferCount)
    self.gridArgBuffer = Graphics.shared.device.makeBuffer(length: MemoryLayout<GridArgBuffer>.stride * 1)
  }
  
  public func reset() {
    for i in 0..<self.cells.count {
      cells[i].shapes.removeAll(keepingCapacity: true)
    }
  }
  
  private func getDepth(of shape: Shape) -> Float {
    return Graphics.getDepth(of: shape)
  }
  
  private func sortShapesByDepth() {
    for i in 0..<self.cells.count {
      // decending order
      self.cells[i].shapes.sort(by: { getDepth(of: $0) > getDepth(of: $1) })
    }
  }
  
  public func updateBuffers() {
    self.sortShapesByDepth()
    
    for i in 0..<self.cells.count {
      self.cells[i].updateBuffer()
    }
    
    let gridCellBuffer = self.cellBuffer.contents().bindMemory(to: GridCellArgBuffer.self, capacity: self.cellBufferCount)
    
    for i in 0..<self.cellBufferCount {
      let pointer = gridCellBuffer.advanced(by: i)
      pointer.pointee.shapes = self.cells[i].shapeBuffer.gpuAddress
      pointer.pointee.count = Int32(self.cells[i].shapes.count)
    }
    
    let gridBuffer = self.gridArgBuffer.contents().bindMemory(to: GridArgBuffer.self, capacity: 1)
    gridBuffer.pointee.gridCells = self.cellBuffer.gpuAddress
    gridBuffer.pointee.gridSize = SIMD2<Int32>(Int32(self.size.x), Int32(self.size.y))
    gridBuffer.pointee.cellSize = self.cellSize
    gridBuffer.pointee.gridPosition = self.position
  }
  
  public func mapShapeBoundingBoxToGrid(_ box: BoundingBox2D, _ shape: Shape) {
    let gridTopLeft = self.bounds.topLeft
    let gridBottomRight = self.bounds.bottomRight
    let boxTopLeft = box.topLeft
    let boxBottomRight = box.bottomRight
    var usedIndecies: [Int] = []
    
    for y in StepSequence(from: boxBottomRight.y, to: boxTopLeft.y, step: self.cellSize) {
      if y.isBetween(gridBottomRight.y...gridTopLeft.y) {
        let yIndex = floor(remap(y, float2(self.bounds.bottom, self.bounds.top), float2(0, Float(self.size.y))))
        for x in StepSequence(from: boxTopLeft.x, to: boxBottomRight.x, step: self.cellSize) {
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
