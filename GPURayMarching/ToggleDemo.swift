import MetalGraphicsLib
import ReactiveUI

// The minimal if/else from docs/CompileTimeState.md.
@Component
final class ToggleDemo : SingleChildElement {
  private static let labelStyle = TextStyle(color: .white, fontSize: 13)

  @State var color: float4 = .blue
  @State var isLoggedIn: Bool = false

  @UIElementBuilder var body: [UIElement] {
    VStack(spacing: 10) {
      if self.isLoggedIn {
        Text("Logged in", style: Self.labelStyle)
          .frame(width: 100, height: 100)
          .background(.init(0.1, 0.6, 0.2, 1))
      } else {
        Text("Logged out", style: Self.labelStyle)
          .frame(width: 100, height: 100)
          .background(.red)
      }
      Text("Hover me,\ntap to toggle", style: Self.labelStyle)
        .frame(width: 100, height: 100)
        .background(self.color)
        .onHover { hovered, _ in
          self.color = hovered ? .black : .blue
        }
        .onTap { _ in
          self.isLoggedIn.toggle()
        }
    }
  }
}
