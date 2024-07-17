import MetalGraphicsLib
import MetalKit
import SwiftUI

class TestViewRenderer: ViewRenderer {
  private let gameView = GameView()
  
  override func start() {
    self.graphics2D = Graphics2D(renderer: self)
  }

  override func draw(in view: MTKView) {
    super.draw(in: view)
    guard let graphics = self.graphics2D else {
      return
    }
    
    graphics.context(in: view) { _ in
      gameView.run(graphics.size)
      gameView.draw(in: graphics)
    }
  }
}
