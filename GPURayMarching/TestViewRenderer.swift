import MetalGraphicsLib
import MetalKit
import Combine
import ReactiveUI

class TestViewRenderer: ViewRenderer {
  let root = Frame(float2())

  override func start() {
    self.graphics2D = Graphics2D(renderer: self)
    
    self.root.mounted = true
    
    self.root.setChild(Demos(), self.uiContext)
  }

  // New code only runs in a fresh tree; `Demos` reopens the stored tab.
  override func hotReload() {
    self.root.setChild(Demos(), self.uiContext)
  }
  
  //  override func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
  //    super.mtkView(view, drawableSizeWillChange: size)
  //
  //    self.root.size = self.windowSize
  //    print(self.root.size)
  //  }
  
  var frame = Int(0)
  
  override func draw(in view: MTKView) {
    super.draw(in: view)
    guard let graphics = self.graphics2D else {
      return
    }

    self.uiContext.update(root: self.root, size: self.windowSize, input: self.input, graphics: graphics)
    // A cursor is set only when it changes, so this costs a compare on an idle frame.
    (view as? MyMTKView)?.pointerStyle = self.uiContext.pointerStyle

    // Nothing changed since the last frame, so there is nothing new to present: the layer keeps
    // showing the last drawable. A running animation keeps `needsRender` set every frame.
    //
    // The input's per-frame state (clicks, deltas, keys) is normally reset at the end of the
    // drawn frame; a skipped frame has to reset it too, or a click would still read as pressed
    // on every frame after it.
    guard self.uiContext.needsRender else {
      self.input.endFrame()
      return
    }

    graphics.context(in: view) { _ in
      self.uiContext.render(root: self.root, graphics)
//      self.root.render(graphics)
//      let boxSize = float2(100, 100)
//      let box = BoundingBox2D(center: float2() - self.graphics2D!.size * 0.5 + boxSize * 0.5, size: boxSize)
//      print(box.center)
//      graphics.draw(square: Square(position: box.center, size: box.size, rotation: 0, color: .black))
      //      gameView.run(graphics.size)
      //      gameView.draw(in: graphics)
    }
  }
}
