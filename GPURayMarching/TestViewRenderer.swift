import MetalGraphicsLib
import MetalKit

class TestViewRenderer : ViewRenderer {
  
  override func start() {
    
  }
  
  override func draw(in view: MTKView) {
    super.draw(in: view)
    
    Graphics.context(in: view) { r in
//      for y in stride(from: Float(-500), through: Float(500), by: Float(50)) {
//        for x in stride(from: Float(-500), through: Float(500), by: Float(50)) {
//          Graphics.draw(circle: Circle(position: float2(x, y), radius: Float(50), color: float4(1, 0, 0, 1)))
//        }
//      }
      Graphics.draw(square: Square(position: Input.mousePositionFromCenter, size: float2(100, 100), rotation: Time.time, color: float4(1, 0, 0, 1)))
//      Graphics.draw(circle: Circle(position: Input.mousePositionFromCenter, radius: Float(50), color: float4(0, 1, 0, 1)))
//      Graphics.draw(line: Line(start: float2(0, 0), end: float2(cos(Time.time) * 100, sin(Time.time) * 100), color: float4(0, 0, 0, 1), thickness: 1))
    }
    
//    Graphics.testGrid(in: view)

  }
}
