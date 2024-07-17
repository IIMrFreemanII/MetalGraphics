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
    vStack {
      spacer()
      rect(.init(100, 100), .red)
//      rect(.init(100, 100), .green)
//      rect(.init(100, 100), .blue)
      //      rect(.init(100, 100))
      //      spacer()
    }
  }
}
