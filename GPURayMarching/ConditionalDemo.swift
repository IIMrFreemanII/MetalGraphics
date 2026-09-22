import MetalGraphicsLib
import ReactiveUI

// Shows how a branch reaches the screen: every `if` in `body` becomes a tag, and a state change
// that flips the tag builds the new arm, drops the old one's node fields, and re-applies the
// parent's children. Nothing is diffed; an arm that is not taken simply has no elements.
//
// Buttons, left to right: green toggles `isOn`, blue cycles `mode` through 0, 1, 2, amber
// selects a colour or clears it, grey steps `size`. The black square inside the last branch is
// tappable too and steps `size` from inside a freshly swapped-in arm.
@Component
final class ConditionalDemo : SingleChildElement {
  private static let palette: [float4] = [
    .red, .green, .blue,
    .init(1, 0.8, 0.2, 1),    // amber
    .init(0.6, 0.3, 0.9, 1),  // purple
    .init(0.2, 0.8, 0.8, 1),  // teal
  ]

  @State var isOn: Bool = true
  @State var mode: Int = 0
  @State var selected: float4? = nil
  @State var size: Float = 24

  @UIElementBuilder var body: [UIElement] {
    VStack(alignment: .leading, spacing: 12) {
      HStack(spacing: 6) {
        Rectangle(.green).frame(width: 24, height: 24)
          .onTap { _ in self.toggle() }
        Rectangle(.blue).frame(width: 24, height: 24)
          .onTap { _ in self.cycleMode() }
        Rectangle(.init(1, 0.8, 0.2, 1)).frame(width: 24, height: 24)
          .onTap { _ in self.toggleSelection() }
        Rectangle(.init(0.5, 0.5, 0.5, 1)).frame(width: 24, height: 24)
          .onTap { _ in self.stepSize() }
      }

      // `if` with no else: the empty arm contributes no children, so everything below moves up.
      if self.isOn {
        Rectangle(.green).frame(width: 60, height: 24)
      }

      // No `switch` in a body (F2): a multi-way choice is an `else if` chain, which is one
      // branch nested in the else arm of another.
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
      if let color = self.selected {
        Rectangle(color).frame(width: 60, height: 24)
      } else {
        Rectangle(.init(0.3, 0.3, 0.3, 1)).frame(width: 60, height: 24)
      }

      // A condition reading two states swaps on a change to either. Inside the arm, `self.size`
      // is an ordinary reactive argument: while the arm is hidden its node fields are nil, so a
      // size change is a no-op, and re-entering builds it with whatever `size` is by then.
      // The tap handler is armed right after the swap, so it works on the arm's first frame.
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
