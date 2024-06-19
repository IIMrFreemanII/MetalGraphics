import MetalGraphicsLib
import MetalKit

class TestViewRenderer : ViewRenderer {
  override func start() {
  }
  
  override func draw(in view: MTKView) {
    super.draw(in: view)
    
    Graphics.context(in: view) { r in
      Graphics.draw(circle: Circle(position: float2(0, 0), radius: Float(50), color: float4(1, 0, 0, 1)))
      Graphics.draw(circle: Circle(position: float2(50, 0), radius: Float(50), color: float4(0, 1, 0, 1)))
      Graphics.draw(circle: Circle(position: float2(100, 0), radius: Float(50), color: float4(0, 0, 1, 1)))
      Graphics.draw(line: Line(start: float2(0, 0), end: float2(cos(Time.time) * 100, sin(Time.time) * 100), color: float4(0, 0, 0, 1), thickness: 1))
    }

  }
}
