import MetalGraphicsLib
import MetalKit
import Combine

struct Item: Identifiable {
  var id: Int
  var color: float4
  
  init(_ color: float4) {
    self.id = Int.random(in: Int.min...Int.max)
    self.color = color
  }
}

class CounterDemo : SingleChildElement {
  var timer: Timer?
  
  let colors: [float4] = [.red, .green, .blue]
  var items: ObservableCollection<Item> = .init([.init(.red), .init(.green), .init(.blue)])
  
  @State var color: float4 = .blue
  @State var isLoggedIn = false
  @State var size: Float = 100
  
  override func mount(_ context: UIContext) {
    super.mount(context)
    
    self.setChild(
      VStack(spacing: 10) {
        if self.isLoggedIn {
          Rectangle(.green)
            .frame(width: 100, height: 100)
        } else {
          Rectangle(.red)
            .frame(width: 100, height: 100)
        }
        Rectangle(self.color)
          .frame(width: 100, height: 100)
          .onHover { hovered, _ in
            self.color = hovered ? .black : .red
          }
          .onTap { _ in
            self.isLoggedIn.toggle()
          }
      },
      context
    )
  }
  
  override func unmount(_ context: UIContext) {
    timer?.invalidate()
  }
}

class TestViewRenderer: ViewRenderer {
  let root = Frame(float2())
  
  override func start() {
    self.graphics2D = Graphics2D(renderer: self)
    
    self.root.mounted = true
    
    self.root.setChild(
      VStack {
        HStack {
          CounterDemo()
//          ListDemo()   // swap for Counter() to see the conditional-rendering demo
          Spacer()
        }
        Spacer()
      },
      self.uiContext
    )
    //    }
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
    
//    self.root.handleHitTest(self.input)

    if self.input.mouseMoved || self.input.mousePressed {
      self.uiContext.handleHitTest(self.hittableGrid2D, self.input, graphics)
    }

    // Lay out after event handlers so state changes they make are laid out before this frame renders.
    if self.uiContext.dirtyLayout {
      self.root.size = self.windowSize
      _ = self.root.calcSize(self.windowSize)
      self.root.calcPosition(.init())

      self.uiContext.dirtyGrid = true
      self.uiContext.dirtyLayout = false
    }
    
    graphics.context(in: view) { _ in
      self.uiContext.handleRenderableViews(graphics)
      self.uiContext.dirtyRender = false
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
