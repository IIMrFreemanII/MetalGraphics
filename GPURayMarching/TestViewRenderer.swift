import MetalGraphicsLib
import MetalKit
import SwiftUI

class TestViewRenderer: ViewRenderer {
  var rotation = Float()
  override func start() {
    self.graphics2D = Graphics2D(renderer: self)
  }

  override func draw(in view: MTKView) {
    super.draw(in: view)
    guard let graphics = self.graphics2D else {
      return
    }

    self.rotation += input.mouseScroll.y * deltaTime

    graphics.context(in: view) { _ in
//      forEachGridCell(SIMD2<Int>(100, 100), 100, 0) { coord in
//        graphics.draw(circle: Circle(position: coord, radius: Float(50), color: float4(1, 0, 0, 1)))
//      }
      graphics.draw(square: Square(position: float2(), size: float2(100, 100), rotation: self.rotation, color: .red))
    }
  }
}
