import MetalKit

enum ShapeType2D: Int32 {
  case Circle
  case Square
  case Line
  case Glyph
  case Image
  case Vector
  case Glass
}

struct Shape {
  public var index: Int32
  public var shapeType: Int32
  /// Index of the clip rect the shape is drawn inside; 0 clips nothing.
  public var clip: Int32
  /// The shape's depth, copied here so sorting a cell and cutting it off at a glass's depth
  /// (see `backdrop2D`) never reach into the per-type arrays.
  public var depth: Float

  public init(index: Int32, shapeType: Int32, clip: Int32 = 0, depth: Float) {
    self.index = index
    self.shapeType = shapeType
    self.clip = clip
    self.depth = depth
  }
}

/// A shape filed in a cell, with the hash of what it looks like there: its content and its clip's.
struct FiledShape {
  var shape: Shape
  var contentHash: UInt64
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

class GraphicsGrid2D {
  public var size: int2
  public var cellSize: Float
  public var position: float2
  public var bounds: BoundingBox2D
  public var cells: [GridCell] = []
  var shapesPerCell: [[FiledShape]] = []
  public var shapesPerCellCount: Int = 0
  public var cellBuffer: MTLBuffer!
  public var cellBufferCount: Int = 0
  public var gridArgBuffer: MTLBuffer!
  public var shapeBuffer: MTLBuffer!
  public var shapeBufferCount: Int = 0

  public unowned let graphics: Graphics2D

  /// Each cell's hash of its shapes, topmost first, as of the last `updateBuffers`; false until
  /// there has been one, when every cell counts as changed.
  private var cellHashes: [UInt64] = []
  private var hasCellHashes = false
  /// The cells whose shapes changed in the last `updateBuffers`: the only pixels that can look
  /// different from the frame before. Grown by `Graphics2D` for what shows through glass.
  var dirtyCells: [Int32] = []
  /// Each of `dirtyCells`' rect, as `cellRect` gives it: what the GPU shades again.
  var dirtyRects: [float4] = []

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
    self.cellHashes = Array(repeating: 0, count: self.cellBufferCount)

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

  private func sortShapesByDepth() {
    for i in self.shapesPerCell.indices {
      guard self.shapesPerCell[i].count > 1 else { continue }

      // decending order
      self.shapesPerCell[i].sort(by: Self.isAbove)
    }
  }

  private static func isAbove(_ a: FiledShape, _ b: FiledShape) -> Bool {
    a.shape.depth > b.shape.depth
  }

  /// The most shapes filed in one cell last frame.
  public private(set) var maxShapesPerCell = 0
  /// `kMaxShapesPerCell` in Shaders.metal.
  static let shaderCellLimit = 512
  nonisolated(unsafe) private static var warnedCellLimit = false

  public func updateBuffers() {
    self.sortShapesByDepth()
    
    if self.shapesPerCellCount > self.shapeBufferCount {
      self.shapeBufferCount = self.shapesPerCellCount + 10
      self.shapeBuffer = GPUDevice.main.makeBuffer(length: MemoryLayout<Shape>.stride * self.shapeBufferCount)
      self.shapeBuffer.label = "Shape buffer"
    }

    var startIndex = Int()
    let pointer = self.shapeBuffer.contents().assumingMemoryBound(to: Shape.self)
    self.maxShapesPerCell = 0
    self.dirtyCells.removeAll(keepingCapacity: true)
    self.dirtyRects.removeAll(keepingCapacity: true)
    for i in self.shapesPerCell.indices {
      let count = self.shapesPerCell[i].count
      self.maxShapesPerCell = max(self.maxShapesPerCell, count)

      self.cells[i] = GridCell(startIndex: Int32(startIndex), count: Int32(count))

      // In the order the shader composites them, so a change of stacking changes the hash too.
      var hash = ContentHash()
      for filed in self.shapesPerCell[i] {
        pointer.advanced(by: startIndex).pointee = filed.shape
        hash.add(filed.contentHash)
        startIndex += 1
      }
      hash.add(UInt64(count))
      if !self.hasCellHashes || self.cellHashes[i] != hash.value {
        self.dirtyCells.append(Int32(i))
        self.dirtyRects.append(self.cellRect(i))
      }
      self.cellHashes[i] = hash.value
    }
    self.hasCellHashes = true
#if DEBUG
    // `compute2D` shades at most this many per cell, topmost first: the bottom ones — backgrounds —
    // are dropped. Dense tiny text is what gets there.
    if self.maxShapesPerCell > Self.shaderCellLimit && !Self.warnedCellLimit {
      Self.warnedCellLimit = true
      print("MetalGraphics: \(self.maxShapesPerCell) shapes in one grid cell, past the shader's \(Self.shaderCellLimit)")
    }
#endif

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

  func mapShapeBoundingBoxToGrid(_ box: BoundingBox2D, _ shape: Shape, contentHash: UInt64) {
    // `StepSequence` never terminates on NaN or infinite bounds.
    guard
      box.center.x.isFinite, box.center.y.isFinite, box.size.x.isFinite, box.size.y.isFinite
    else {
      return
    }

    let gridTopLeft = self.bounds.topLeft
    let gridBottomRight = self.bounds.bottomRight
    // Only the part inside the grid can land in a cell. Clamping also keeps a huge box from
    // stepping in increments too small to change its float coordinate.
    let boxTopLeft = float2(max(box.topLeft.x, gridTopLeft.x), min(box.topLeft.y, gridTopLeft.y))
    let boxBottomRight = float2(min(box.bottomRight.x, gridBottomRight.x), max(box.bottomRight.y, gridBottomRight.y))
    guard boxTopLeft.x <= boxBottomRight.x, boxBottomRight.y <= boxTopLeft.y else {
      return
    }

    var prevY = Int(-1)
    for y in StepSequence(from: boxBottomRight.y, to: boxTopLeft.y, step: self.cellSize) {
      if y.isBetween(gridBottomRight.y...gridTopLeft.y) {
        let yIndex = Int(floor(remap(y, float2(self.bounds.bottom, self.bounds.top), float2(0, Float(self.size.y)))))

        if prevY == yIndex {
          continue
        }
        prevY = yIndex

        var prevX = Int(-1)
        for x in StepSequence(from: boxTopLeft.x, to: boxBottomRight.x, step: self.cellSize) {
          if x.isBetween(gridTopLeft.x...gridBottomRight.x) {
            let xIndex = Int(floor(remap(x, float2(self.bounds.left, self.bounds.right), float2(0, Float(self.size.x)))))

            if prevX == xIndex {
              continue
            }
            prevX = xIndex

            let coord = int2(xIndex, yIndex)
            let index = from2DTo1DArray(coord, size)

            if index < self.cells.count {
              self.shapesPerCell[index].append(FiledShape(shape: shape, contentHash: contentHash))
              self.shapesPerCellCount += 1
            }
          }
        }
      }
    }
  }

  /// Cell `index`'s rect: min x, min y, max x, max y, in points, as the shader places it.
  func cellRect(_ index: Int) -> float4 {
    let coord = float2(Float(index % Int(self.size.x)), Float(index / Int(self.size.x)))
    let min = self.position - float2(Float(self.size.x), Float(self.size.y)) * self.cellSize * 0.5 + coord * self.cellSize
    return float4(min.x, min.y, min.x + self.cellSize, min.y + self.cellSize)
  }

  /// The cell `point` falls in, clamped to the grid, as the shader's `gridCell` finds it.
  func cellCoord(_ point: float2) -> int2 {
    let half = float2(Float(self.size.x), Float(self.size.y)) * self.cellSize * 0.5
    // Clamped while still a float: converting an infinite or huge coordinate would trap.
    let top = float2(Float(self.size.x - 1), Float(self.size.y - 1))
    let coord = simd_clamp(((point - self.position + half) / self.cellSize).rounded(.down), .zero, top)
    return int2(Int(coord.x.isNaN ? 0 : coord.x), Int(coord.y.isNaN ? 0 : coord.y))
  }

  /// Calls `body` with the index of every cell `min`...`max` touches, in points.
  func forEachCell(min: float2, max: float2, _ body: (Int) -> Void) {
    guard min.x <= max.x, min.y <= max.y else { return }
    let lo = self.cellCoord(min)
    let hi = self.cellCoord(max)
    for y in Int(lo.y) ... Int(hi.y) {
      for x in Int(lo.x) ... Int(hi.x) {
        body(y * Int(self.size.x) + x)
      }
    }
  }
}
