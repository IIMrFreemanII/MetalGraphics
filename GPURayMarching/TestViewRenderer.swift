import MetalGraphicsLib
import MetalKit
import Combine

class Counter : SingleChildElement {
  var count: Int = 0
  var timer: Timer!
  var vStack: VStack?
  var alignments: [HorizontalAlignment] = [.leading, .center, .trailing]
  var test: CurrentValueSubject<Bool, Never> = .init(true)
  
  override func mount() {
    super.mount()
    
    self.timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
      self.test.value.toggle()
      self.test.send(self.test.value)
    }
    
    self.setChild(
      VStack {
        Rectangle(.red)
          .frame(width: 100, height: 100)
          .padding(Inset(all: 25))
          .background(.green)
        Rectangle(.red)
          .frame(width: 200, height: 200)
          .padding(Inset(all: 50))
          .background(.green)
        Rectangle(.red)
          .frame(width: 100, height: 100)
          .padding(Inset(all: 25))
          .background(.green)
      }.ref { (elem: VStack) in
        
        Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { _ in
          elem.alignment = self.alignments[self.count]
          self.count = (self.count + 1) % 3
        }
        
        _ = self.test.sink { value in
          if value {
            self.removeChild()
          } else {
            self.setChild(elem)
          }
        }
        
//        self.timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
//          if self.child != nil {
//            self.removeChild()
//          } else {
//            self.setChild(elem)
//          }
//        }
      }
    )
  }
  
  override func unmount() {
    timer.invalidate()
  }
}

class TestViewRenderer: ViewRenderer {
  //  private let gameView = IMGameView()
  let root = Frame(float2())
  
  //  func createRect(_ size: float2) -> UIElement {
  //    let background = Background(color: .red)
  //    let frame = Frame(size, .center)
  //    background.setChild(frame)
  //
  //    let background1 = Background(color: .green)
  //    let frame1 = Frame(size * 0.5, .center)
  //    background1.setChild(frame1)
  //    frame.setChild(background1)
  //
  ////    let padding = Padding(.init(all: 10))
  ////    padding.setChild(background)
  //
  //    return background
  //  }
  
  override func start() {
    self.graphics2D = Graphics2D(renderer: self)
    //    self.gameView.renderer = self
    
//    let size = SIMD2<Int>(100, 100)
//    let cellSize = Float(5)
//    let spacing = Float(2)
//    
//    let vStack = VStack(spacing: spacing)
//    
//    for _ in 0..<size.y {
//      let hStack = HStack(spacing: spacing)
//      for _ in 0..<size.x {
//        hStack.appendChild(
//          Rectangle(.red)
//            .frame(width: cellSize, height: cellSize)
//        )
//      }
//      vStack.appendChild(hStack)
//    }
    
    self.root.mounted = true
    //    benchmark(title: "Mount") {
    self.root.setChild(Counter())
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
    
    self.root.size = self.windowSize
    //    benchmark(title: "Calc size") {
    _ = self.root.calcSize(self.windowSize)
    //    }
    //    benchmark(title: "Calc Position") {
    self.root.calcPosition(.init())
    //    }
    
    //    if frame < 1 {
    //      self.root.debugHierarchy("")
    //      self.frame += 1
    //    }
    
//    self.input.keyDown(.escape) {
//      self.root.removeChild()
//    }
    
    graphics.context(in: view) { _ in
      //      benchmark(title: "Submit to render") {
      self.root.render(graphics)
      //      }
      //      gameView.run(graphics.size)
      //      gameView.draw(in: graphics)
    }
//    print("------------------------------------------")
  }
}
