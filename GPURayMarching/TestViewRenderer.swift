import MetalGraphicsLib
import MetalKit

class TestViewRenderer: ViewRenderer {
//  private let gameView = IMGameView()
  let root = Frame(.init(), .center)
  
  func createRect(_ size: float2) -> UIElement {
    let background = Background(color: .red)
    let frame = Frame(size, .center)
    background.setChild(frame)
    
    let background1 = Background(color: .green)
    let frame1 = Frame(size * 0.5, .center)
    background1.setChild(frame1)
    frame.setChild(background1)
    
//    let padding = Padding(.init(all: 10))
//    padding.setChild(background)
    
    return background
  }
  
  override func start() {
    self.graphics2D = Graphics2D(renderer: self)
//    self.gameView.renderer = self
    
    let elem0 = createRect(.init(100, 100))
    let expandedFrame = FlexFrame(minWidth: 150, maxWidth: 300)
    expandedFrame.setChild(elem0)
    let background = Background(color: .blue)
    background.setChild(expandedFrame)
//    let elem1 = createRect(.init(200, 200))
//    let elem2 = createRect(.init(100, 100))
    
//    let spacer = Spacer()
//    let stack = HStack(alignment: .bottom, spacing: 10)
//    stack.appendChild(spacer)
//    stack.appendChild(elem0)
//    stack.appendChild(spacer)
//    stack.appendChild(elem1)
//    stack.appendChild(spacer)
//    stack.appendChild(elem2)
//    stack.appendChild(spacer)
    
    self.root.setChild(background)
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
    
    self.root.size = self.windowSize
    _ = self.root.calcSize(self.windowSize)
    self.root.calcPosition(.init())
    
    if frame < 1 {
      self.root.debugHierarchy("")
      self.frame += 1
    }
    
    graphics.context(in: view) { _ in
      self.root.render(graphics)
//      gameView.run(graphics.size)
//      gameView.draw(in: graphics)
    }
  }
}
