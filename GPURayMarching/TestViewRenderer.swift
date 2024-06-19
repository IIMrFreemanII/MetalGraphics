import MetalGraphicsLib
import MetalKit

class TestViewRenderer : ViewRenderer {
  let grid = Grid2D(position: float2(), size: int2(10, 10), cellSize: Float(50))
  
  override func start() {
    
  }
  
  override func draw(in view: MTKView) {
    super.draw(in: view)
    
    self.grid.reset()
    
//    print(Input.mousePositionFromCenter)
    
    let boundsSize = float2(30, 30)
    let bounds = BoundingBox2D(center: Input.mousePositionFromCenter, size: boundsSize)
    self.grid.mapShapeBoundingBoxToGrid(bounds, Shape(index: Int32(), shapeType: Int32()))
    
    for cell in grid.cells {
      if cell.shapes.count > 1 {
        print("has duplicates")
      }
    }
    
//    Graphics.context(in: view) { r in
//      Graphics.draw(circle: Circle(position: float2(0, 0), radius: Float(50), color: float4(1, 0, 0, 1)))
//      Graphics.draw(circle: Circle(position: float2(50, 0), radius: Float(50), color: float4(0, 1, 0, 1)))
//      Graphics.draw(circle: Circle(position: float2(100, 0), radius: Float(50), color: float4(0, 0, 1, 1)))
//      Graphics.draw(line: Line(start: float2(0, 0), end: float2(cos(Time.time) * 100, sin(Time.time) * 100), color: float4(0, 0, 0, 1), thickness: 1))
//    }
    
    let spacing = Float(0)
    
    Graphics.context(in: view) { r in
      Graphics.draw(square: Square(position: bounds.center, size: boundsSize, color: float4(0, 0, 1, 1)))
      for y in 0..<grid.size.y {
        for x in 0..<grid.size.x {
          let index = from2DTo1DArray(int2(x, y), self.grid.size)
          let isEmply = self.grid.cells[index].shapes.isEmpty
          let size = float2(self.grid.cellSize, self.grid.cellSize)
          
          Graphics.draw(square: Square(position: float2((Float(x) - Float(self.grid.size.x) * 0.5) * (self.grid.cellSize + spacing), (Float(y) - Float(self.grid.size.y) * 0.5) * (self.grid.cellSize + spacing)) + size * 0.5, size: size, color: isEmply ? float4(1, 0, 0, 1) : float4(0, 1, 0, 1)))
        }
      }
    }

  }
}
