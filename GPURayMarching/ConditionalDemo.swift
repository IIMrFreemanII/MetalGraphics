import MetalGraphicsLib
import ReactiveUI

// Shows how a branch reaches the screen: every `if` in `body` becomes a tag, and a state change
// that flips the tag builds the new arm, drops the old one's node fields, and re-applies the
// parent's children. Nothing is diffed; an arm that is not taken simply has no elements.
//
// Each branch below is captioned with its condition, and the line under the buttons reads the
// state back, so a tap shows both the new value and the arm it picked. The black square inside
// the last branch is tappable too and steps `size` from inside a freshly swapped-in arm.
@Component
final class ConditionalDemo : SingleChildElement {
  private static let palette: [float4] = [
    .red, .green, .blue,
    .init(1, 0.8, 0.2, 1),    // amber
    .init(0.6, 0.3, 0.9, 1),  // purple
    .init(0.2, 0.8, 0.8, 1),  // teal
  ]
  private static let buttonStyle = TextStyle(color: .white, fontSize: 13)
  private static let buttonInset = Inset(vertical: 4, horizontal: 8)
  private static let captionStyle = TextStyle(color: .init(0.45, 0.45, 0.45, 1), fontSize: 12)

  @State var isOn: Bool = true
  @State var mode: Int = 0
  @State var selected: float4? = nil
  @State var size: Float = 24

  @UIElementBuilder var body: [UIElement] {
    VStack(alignment: .leading, spacing: 10) {
      HStack(spacing: 6) {
        Text("Toggle isOn", style: Self.buttonStyle)
          .padding(Self.buttonInset)
          .background(.green)
          .onTap { _ in self.toggle() }
        Text("Cycle mode", style: Self.buttonStyle)
          .padding(Self.buttonInset)
          .background(.blue)
          .onTap { _ in self.cycleMode() }
        Text("Pick colour", style: Self.buttonStyle)
          .padding(Self.buttonInset)
          .background(.init(0.85, 0.6, 0.1, 1))
          .onTap { _ in self.toggleSelection() }
        Text("Step size", style: Self.buttonStyle)
          .padding(Self.buttonInset)
          .background(.init(0.5, 0.5, 0.5, 1))
          .onTap { _ in self.stepSize() }
      }

      // Reactive arguments: each state change goes through `Text.setText`, no arm is rebuilt.
      Text("isOn: \(self.isOn)   mode: \(self.mode)   size: \(Int(self.size))")
      Text(self.selected == nil ? "selected: nil" : "selected: a colour", style: Self.captionStyle)

      // `if` with no else: the empty arm contributes no children, so everything below moves up.
      Text("if isOn", style: Self.captionStyle)
      if self.isOn {
        Rectangle(.green).frame(width: 60, height: 24)
      }

      // No `switch` in a body (F2): a multi-way choice is an `else if` chain, which is one
      // branch nested in the else arm of another.
      Text("if mode == 0 / else if mode == 1 / else", style: Self.captionStyle)
      if self.mode == 0 {
        Rectangle(.red).frame(width: 40, height: 40)
      } else if self.mode == 1 {
        Rectangle(.blue).frame(width: 120, height: 20)
      } else {
        Rectangle(.init(0.6, 0.3, 0.9, 1)).frame(width: 20, height: 60)
      }

      // `if let` swaps only when the value flips between nil and non-nil, and `color` is read
      // once, when the arm is built. That is why `toggleSelection` always goes through nil:
      // each selection is a fresh entry into the arm, built with the new colour.
      Text("if let selected / else", style: Self.captionStyle)
      if let color = self.selected {
        Rectangle(color).frame(width: 60, height: 24)
      } else {
        Rectangle(.init(0.3, 0.3, 0.3, 1)).frame(width: 60, height: 24)
      }

      // A condition reading two states swaps on a change to either. Inside the arm, `self.size`
      // is an ordinary reactive argument: while the arm is hidden its node fields are nil, so a
      // size change is a no-op, and re-entering builds it with whatever `size` is by then.
      // The tap handler is armed right after the swap, so it works on the arm's first frame.
      Text("if isOn && mode != 2", style: Self.captionStyle)
      if self.isOn && self.mode != 2 {
        HStack(spacing: 6) {
          Rectangle(.black)
            .frame(width: self.size, height: self.size)
            .onTap { _ in self.stepSize() }
          Rectangle(.init(0.2, 0.8, 0.8, 1)).frame(width: 24, height: self.size)
        }
      }
    }
  }

  // MARK: - Actions

  func toggle() {
    self.isOn.toggle()
  }

  func cycleMode() {
    self.mode = (self.mode + 1) % 3
  }

  func toggleSelection() {
    self.selected = self.selected == nil ? Self.palette.randomElement() : nil
  }

  func stepSize() {
    self.size = self.size == 24 ? 48 : 24
  }
}
