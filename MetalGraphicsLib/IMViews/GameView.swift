public class GameView : IMView {
  
  public override init() {
    
  }
  
  internal override func update() {
    //    vStack(4) {
    //      vStack(2) {
    //        padding(Inset(all: 2)) {
    //          rect(.init(100, 100))
    //        }
    //        padding(Inset(all: 2)) {
    //          rect(.init(100, 100))
    //        }
    //      }
    //      vStack(1) {
    //        padding(Inset(all: 1)) {
    //          rect(.init(100, 100))
    //        }
    //        padding(Inset(all: 1)) {
    //          rect(.init(100, 100))
    //        }
    //      }
    //    }
    //    rect(.init(200, 200)) {
    //      padding(Inset(all: 5)) {
    //        rect(.init(100, 100))
    //      }
    //    }
    background(.blue) {
      expandedFrame(.both) {
        background(.red) {
          frame(.init(100, 100))
        }
      }
    }
//    vStack {
//      spacer()
//      background(.red) {
//        frame(.init(100, 100))
//      }
//      spacer()
//      background(.green) {
//        frame(.init(200, 100))
//      }
//      spacer()
//      background(.blue) {
//        frame(.init(100, 100))
//      }
//      spacer()
//    }
  }
}
