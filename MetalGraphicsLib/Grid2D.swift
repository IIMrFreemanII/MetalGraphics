import MetalKit

enum ShapeType2D: Int32 {
  case Circle
  case Square
  case Line
}

struct Shape {
  public var index: Int32
  public var shapeType: Int32

  public init(index: Int32, shapeType: Int32) {
    self.index = index
    self.shapeType = shapeType
  }
}

struct GridCell {
  // maps into shapes buffer
  var startIndex: Int32 = 0
  var count: Int32 = 0
}

struct GridArgBuffer {
  var gridCells: UInt64 = 0
  var shapes: UInt64 = 0
  var gridSize = SIMD2<Int32>()
  var cellSize = Float()
  var gridPosition = float2()
}

@MainActor class Grid2D {
  public var size: int2
  public var cellSize: Float
  public var position: float2
  public var bounds: BoundingBox2D
  public var cells: [GridCell] = []
  public var shapesPerCell: [[Shape]] = []
  public var shapesPerCellCount: Int = 0
  public var cellBuffer: MTLBuffer!
  public var cellBufferCount: Int = 0
  public var gridArgBuffer: MTLBuffer!
  public var shapeBuffer: MTLBuffer!
  public var shapeBufferCount: Int = 0

  public var graphics: Graphics2D

  public init(position: float2, size: int2, cellSize: Float, graphics: Graphics2D) {
    self.graphics = graphics
    self.size = size
    self.cellSize = cellSize
    self.position = position
    self.bounds = BoundingBox2D(center: position, size: float2(Float(size.x) * cellSize, Float(size.y) * cellSize))
    self.cellBufferCount = size.x * size.y

    self.shapesPerCell.reserveCapacity(self.cellBufferCount)
    self.cells = Array(repeating: GridCell(), count: self.cellBufferCount)
    self.shapesPerCell = Array(repeating: [], count: self.cellBufferCount)

    self.cellBuffer = GPUDevice.main.makeBuffer(length: MemoryLayout<GridCell>.stride * self.cellBufferCount)
    self.cellBuffer.label = "Cell buffer"
    self.shapeBuffer = GPUDevice.main.makeBuffer(length: MemoryLayout<Shape>.stride * 1)
    self.shapeBuffer.label = "Shape buffer"
    self.gridArgBuffer = GPUDevice.main.makeBuffer(length: MemoryLayout<GridArgBuffer>.stride * 1)
    self.gridArgBuffer.label = "Grid arg buffer"
  }

  public func reset() {
    self.shapesPerCellCount = 0
    for i in self.shapesPerCell.indices {
      self.shapesPerCell[i].removeAll(keepingCapacity: true)
    }
  }

  private func getDepth(of shape: Shape) -> Float {
    self.graphics.getDepth(of: shape)
  }

  private func sortShapesByDepth() {
    for i in self.shapesPerCell.indices {
      guard self.shapesPerCell[i].count > 1 else { continue }

      // decending order
      self.shapesPerCell[i].sort(by: { self.getDepth(of: $0) > self.getDepth(of: $1) })
    }
  }

  public func updateBuffers() {
    self.sortShapesByDepth()
    
    if self.shapesPerCellCount > self.shapeBufferCount {
      self.shapeBufferCount = self.shapesPerCellCount + 10
      self.shapeBuffer = GPUDevice.main.makeBuffer(length: MemoryLayout<Shape>.stride * self.shapeBufferCount)
      self.shapeBuffer.label = "Shape buffer"
    }

    var startIndex = Int()
    let pointer = self.shapeBuffer.contents().assumingMemoryBound(to: Shape.self)
    for i in self.shapesPerCell.indices {
      let count = self.shapesPerCell[i].count

      self.cells[i] = GridCell(startIndex: Int32(startIndex), count: Int32(count))

      for shape in self.shapesPerCell[i] {
        pointer.advanced(by: startIndex).pointee = shape
        startIndex += 1
      }
      // another approach with memory coping
//        pointer.advanced(by: startIndex * MemoryLayout<Shape>.stride).copyMemory(from: self.shapesPerCell[i], byteCount: self.shapesPerCell[i].byteCount)
//        startIndex += count
    }

    // to debug
//    var tempShapes = Array(repeating: Shape(index: Int32(), shapeType: Int32()), count: self.shapesPerCellCount)
//    let tempPointer = pointer.assumingMemoryBound(to: Shape.self)
//    for i in tempShapes.indices {
//      tempShapes[i] = tempPointer.advanced(by: i).pointee
//    }
//    print(tempShapes)

    self.cellBuffer.contents().copyMemory(from: &self.cells, byteCount: self.cells.byteCount)

    let gridBuffer = self.gridArgBuffer.contents().bindMemory(to: GridArgBuffer.self, capacity: 1)
    gridBuffer.pointee.gridCells = self.cellBuffer.gpuAddress
    gridBuffer.pointee.shapes = self.shapeBuffer.gpuAddress
    gridBuffer.pointee.gridSize = SIMD2<Int32>(Int32(self.size.x), Int32(self.size.y))
    gridBuffer.pointee.cellSize = self.cellSize
    gridBuffer.pointee.gridPosition = self.position
  }

  public func mapShapeBoundingBoxToGrid(_ box: BoundingBox2D, _ shape: Shape) {
    let gridTopLeft = self.bounds.topLeft
    let gridBottomRight = self.bounds.bottomRight
    let boxTopLeft = box.topLeft
    let boxBottomRight = box.bottomRight

    var prevY = Int(-1)
    for y in StepSequence(from: boxBottomRight.y, to: boxTopLeft.y, step: self.cellSize) {
      if y.isBetween(gridBottomRight.y...gridTopLeft.y) {
        let yIndex = Int(floor(remap(y, float2(bounds.bottom, self.bounds.top), float2(0, Float(self.size.y)))))

        if prevY == yIndex {
          continue
        }
        prevY = yIndex

        var prevX = Int(-1)
        for x in StepSequence(from: boxTopLeft.x, to: boxBottomRight.x, step: self.cellSize) {
          if x.isBetween(gridTopLeft.x...gridBottomRight.x) {
            let xIndex = Int(floor(remap(x, float2(bounds.left, self.bounds.right), float2(0, Float(self.size.x)))))

            if prevX == xIndex {
              continue
            }
            prevX = xIndex

            let coord = int2(xIndex, yIndex)
            let index = from2DTo1DArray(coord, size)

            if index < self.cells.count {
              self.shapesPerCell[index].append(shape)
              self.shapesPerCellCount += 1
            }
          }
        }
      }
    }
  }
}
