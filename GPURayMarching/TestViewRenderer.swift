import MetalGraphicsLib
import MetalKit
import Combine

class Counter : SingleChildElement {
  var count: Int = 0
  var timer: Timer!
  var vStack: VStack?
  var alignments: [HorizontalAlignment] = [.leading, .center, .trailing]
  var test: CurrentValueSubject<Bool, Never> = .init(false)
  var temp: AnyCancellable?
  
  let colors: [float4] = [.red, .green, .blue]
  var items: ObservableCollection<float4> = .init([.red, .green, .blue])
  
  override func mount() {
    super.mount()
    
    self.timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
//      self.test.value.toggle()
//      self.test.send(self.test.value)
      self.items.append(self.colors[.random(in: 0..<self.colors.count)])
    }
    
    self.setChild(
      VList(items: self.items) { color, i in
        Rectangle(color)
          .frame(width: .random(in: 100...300), height: 100)
      }
//      VStack {
//        ConditionalElseContent(test, {
//          Rectangle(.red)
//            .frame(width: 100, height: 100)
//            .padding(Inset(all: 25))
//            .background(.green)
//        }, {
//          Rectangle(.blue)
//            .frame(width: 100, height: 100)
//            .padding(Inset(all: 25))
//            .background(.green)
//        })
//        Rectangle(.red)
//          .frame(width: 200, height: 200)
//          .padding(Inset(all: 50))
//          .background(.green)
//        Rectangle(.red)
//          .frame(width: 100, height: 100)
//          .padding(Inset(all: 25))
//          .background(.green)
//      }.ref { (elem: VStack) in
//        Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { _ in
//          elem.alignment = self.alignments[self.count]
//          self.count = (self.count + 1) % 3
//        }
//      }
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
    
    self.root.mounted = true
    //    benchmark(title: "Mount") {
//    self.root.setChild(HStack {
//      Counter()
//      Counter()
//    })
    self.root.setChild(
      HStack {
        Counter()
        Spacer()
      }
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
