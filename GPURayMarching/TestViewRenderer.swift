import MetalGraphicsLib
import MetalKit

class TestViewRenderer: ViewRenderer {
  override func start() {}

  override func draw(in view: MTKView) {
    super.draw(in: view)

    //    benchmark(title: "Test") {
    Graphics.context(in: view) { _ in
      forEachGridCell(SIMD2<Int>(100, 100), 100, 0) { coord in
        Graphics.draw(circle: Circle(position: coord, radius: Float(50), color: float4(1, 0, 0, 1)))
      }
      //      for y in stride(from: Float(-1000), through: Float(1000), by: Float(100)) {
      //        for x in stride(from: Float(-1000), through: Float(1000), by: Float(100)) {
      //          Graphics.draw(circle: Circle(position: float2(x, y), radius: Float(50), color: float4(1, 0, 0, 1)))
      //        }
      //      }
      //      do {
      //        let temp = Square(position: float2(), size: float2(150, 100), rotation: Time.time, color: .red)
      //        Graphics.draw(square: Square(position: float2(), size: temp.bounds.size, color: .blue))
      //        Graphics.draw(square: temp)
      //      }
      //      do {
      //        let temp = float2(cos(Time.time), sin(Time.time)) * 100
      //        let line = Line(start: Input.mousePositionFromCenter + temp, end: Input.mousePositionFromCenter - temp, color: .red, thickness: 4)
      //        Graphics.draw(square: Square(position: line.bounds.center, size: line.bounds.size, color: .blue))
      //        Graphics.draw(line: line)
      //      }
      //      Graphics.draw(circle: Circle(position: Input.mousePositionFromCenter, radius: Float(50), color: float4(0, 1, 0, 1)))
      //      Graphics.draw(line: Line(start: float2(0, 0), end: float2(cos(Time.time) * 100, sin(Time.time) * 100), color: float4(0, 0, 0, 1), thickness: 1))
      //      }
    }
  }
}
