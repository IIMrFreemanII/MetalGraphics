public class IMGameView : IMView {
  var color: float4 = .red
  
  public override init() {
  }
  
  internal override func update() {
    mouseOver({ self.color = $0 ? .green : .red }) {
      background(color) {
        frame(width: 100, height: 100)
      }
    }
  }
}
