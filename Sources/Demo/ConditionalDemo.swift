import MetalGraphicsLib
import ReactiveUI

// Shows how a branch reaches the screen: every `if` in `body` becomes a tag, and a state change
// that flips the tag builds the new arm, drops the old one's node fields, and re-applies the
// parent's children. Nothing is diffed; an arm that is not taken simply has no elements.
//
// Each section owns its state and its buttons, and each button reads its state back, so a tap
// shows both the new value and the arm it picked. Grey backgrounds show a container's bounds.
//
// - `if`: an empty arm has no children, so what follows moves up.
// - `if / else`: the arms need not be the same kind of element.
// - `else if`: the multi-way choice a body has instead of `switch`.
// - `if let`: the bound value is read once, when the arm is built.
// - A compound condition: a change to either state it reads can flip it.
// - Nested branches: the inner choice lives in state, so it survives the outer arm going away.
// - A hidden arm catches up: while hidden it has no elements to update, and re-entering builds
//   it from the state as it is by then.
// - Ternary vs branch: the same label, updated in place or rebuilt.
// - A branch in an HStack: siblings on the right slide over when the arm comes and goes.
@Component
final class ConditionalDemo : SingleChildElement {
  private static let palette: [(name: String, color: float4)] = [
    ("red", .init(0.9, 0.25, 0.2, 1)),
    ("amber", .init(0.85, 0.6, 0.1, 1)),
    ("green", .init(0.1, 0.6, 0.2, 1)),
    ("teal", .init(0.1, 0.6, 0.6, 1)),
    ("blue", .init(0.2, 0.45, 0.95, 1)),
    ("purple", .init(0.6, 0.3, 0.9, 1)),
  ]
  private static let phases = ["idle", "loading", "error", "done"]
  private static let captionFont = TextFont.system(size: 12)
  private static let captionColor = float4(0.45, 0.45, 0.45, 1)
  private static let buttonFont = TextFont.system(size: 13)
  private static let labelFont = TextFont.system(size: 13)
  private static let buttonInset = Inset(vertical: 4, horizontal: 8)
  private static let buttonColor = float4(0.25, 0.25, 0.25, 1)
  private static let grey = float4(0.9, 0.9, 0.9, 1)
  private static let dim = float4(0.6, 0.6, 0.6, 1)

  @State var showBanner: Bool = true
  @State var showText: Bool = true
  @State var phase: Int = 0
  @State var selected: Int? = nil
  @State var armed: Bool = false
  @State var fuel: Int = 0
  @State var outer: Bool = true
  @State var inner: Bool = true
  @State var visible: Bool = true
  @State var hits: Int = 0
  @State var isOn: Bool = false
  @State var showMiddle: Bool = true
  @State var size: Float = 24

  @UIElementBuilder var body: [UIElement] {
    HStack(alignment: .top, spacing: 40) {
      VStack(alignment: .leading, spacing: 8) {
        // `if` with no else: the empty arm contributes no children, so the caption moves up.
        Text("if showBanner")
          .font(Self.captionFont)
          .foregroundColor(Self.captionColor)
        Text("showBanner: \(self.showBanner)")
          .font(Self.buttonFont)
          .foregroundColor(.white)
          .padding(Self.buttonInset)
          .background(Self.buttonColor)
          .onTap { _ in self.showBanner.toggle() }
        VStack(alignment: .leading, spacing: 4) {
          if self.showBanner {
            Text("I am the arm")
              .font(Self.labelFont)
              .foregroundColor(.white)
              .padding(Self.buttonInset)
              .background(Self.palette[2].color)
          }
          Text("I move up when it goes")
            .font(Self.captionFont)
            .foregroundColor(Self.captionColor)
        }
        .padding(Inset(all: 6))
        .background(Self.grey)

        // The arms are unrelated elements: a text in one, a plain rectangle in the other.
        Text("if showText / else: different element types")
          .font(Self.captionFont)
          .foregroundColor(Self.captionColor)
        Text("showText: \(self.showText)")
          .font(Self.buttonFont)
          .foregroundColor(.white)
          .padding(Self.buttonInset)
          .background(Self.buttonColor)
          .onTap { _ in self.showText.toggle() }
        Frame(float2(160, 40), .leading) {
          if self.showText {
            Text("Text arm")
              .font(.system(size: 18))
              .foregroundColor(Self.palette[4].color)
          } else {
            Rectangle(Self.palette[0].color).frame(width: 120, height: 24)
          }
        }
        .background(Self.grey)

        // No `switch` in a body (F2): a multi-way choice is an `else if` chain, which is one
        // branch nested in the else arm of another.
        Text("if phase == 0 / else if … / else")
          .font(Self.captionFont)
          .foregroundColor(Self.captionColor)
        Text("phase: \(Self.phases[self.phase])")
          .font(Self.buttonFont)
          .foregroundColor(.white)
          .padding(Self.buttonInset)
          .background(Self.buttonColor)
          .onTap { _ in self.cyclePhase() }
        Frame(float2(220, 40), .leading) {
          if self.phase == 0 {
            Text("Press to start")
              .font(Self.labelFont)
              .foregroundColor(Self.captionColor)
          } else if self.phase == 1 {
            HStack(spacing: 4) {
              Rectangle(Self.palette[4].color).frame(width: 12, height: 12)
              Rectangle(Self.palette[4].color).frame(width: 12, height: 12).opacity(0.6)
              Rectangle(Self.palette[4].color).frame(width: 12, height: 12).opacity(0.3)
            }
          } else if self.phase == 2 {
            Text("Something went wrong")
              .font(Self.labelFont)
              .foregroundColor(.white)
              .padding(Self.buttonInset)
              .background(Self.palette[0].color)
          } else {
            Text("✓ Done")
              .font(.system(size: 18))
              .foregroundColor(Self.palette[2].color)
          }
        }
        .background(Self.grey)

        // `if let` swaps only when the value flips between nil and non-nil, and `index` is read
        // once, when the arm is built. That is why `select` always goes through nil: each
        // selection is a fresh entry into the arm, built with the new colour.
        Text("if let selected / else")
          .font(Self.captionFont)
          .foregroundColor(Self.captionColor)
        HStack(spacing: 4) {
          Rectangle(Self.palette[0].color).frame(width: 22, height: 22).onTap { _ in self.select(0) }
          Rectangle(Self.palette[1].color).frame(width: 22, height: 22).onTap { _ in self.select(1) }
          Rectangle(Self.palette[2].color).frame(width: 22, height: 22).onTap { _ in self.select(2) }
          Rectangle(Self.palette[3].color).frame(width: 22, height: 22).onTap { _ in self.select(3) }
          Rectangle(Self.palette[4].color).frame(width: 22, height: 22).onTap { _ in self.select(4) }
          Rectangle(Self.palette[5].color).frame(width: 22, height: 22).onTap { _ in self.select(5) }
          Text("Clear")
            .font(Self.buttonFont)
            .foregroundColor(.white)
            .padding(Self.buttonInset)
            .background(Self.buttonColor)
            .onTap { _ in self.selected = nil }
        }
        Frame(float2(220, 40), .leading) {
          if let index = self.selected {
            HStack(spacing: 8) {
              Rectangle(Self.palette[index].color).frame(width: 60, height: 24)
              Text("selected: \(Self.palette[index].name)")
                .font(Self.labelFont)
            }
          } else {
            Text("nothing selected")
              .font(Self.labelFont)
              .foregroundColor(Self.captionColor)
          }
        }
        .background(Self.grey)

        // A condition reading two states is re-evaluated on a change to either.
        Text("if armed && fuel >= 3")
          .font(Self.captionFont)
          .foregroundColor(Self.captionColor)
        HStack(spacing: 6) {
          Text("armed: \(self.armed)")
            .font(Self.buttonFont)
            .foregroundColor(.white)
            .padding(Self.buttonInset)
            .background(Self.buttonColor)
            .onTap { _ in self.armed.toggle() }
          Text("fuel: \(self.fuel)")
            .font(Self.buttonFont)
            .foregroundColor(.white)
            .padding(Self.buttonInset)
            .background(Self.buttonColor)
            .onTap { _ in self.fuel = (self.fuel + 1) % 5 }
        }
        Frame(float2(220, 40), .leading) {
          if self.armed && self.fuel >= 3 {
            Text("Launch!")
              .font(Self.labelFont)
              .foregroundColor(.white)
              .padding(Self.buttonInset)
              .background(Self.palette[0].color)
          } else {
            Text("not ready")
              .font(Self.labelFont)
              .foregroundColor(Self.captionColor)
          }
        }
        .background(Self.grey)
      }

      VStack(alignment: .leading, spacing: 8) {
        // Only the taken outer arm has an inner branch at all. `inner` keeps its value while
        // the outer arm is gone, and the inner branch is built from it when the arm returns.
        Text("nested: if outer { if inner … else … } else …")
          .font(Self.captionFont)
          .foregroundColor(Self.captionColor)
        HStack(spacing: 6) {
          Text("outer: \(self.outer)")
            .font(Self.buttonFont)
            .foregroundColor(.white)
            .padding(Self.buttonInset)
            .background(Self.buttonColor)
            .onTap { _ in self.outer.toggle() }
          Text("inner: \(self.inner)")
            .font(Self.buttonFont)
            .foregroundColor(.white)
            .padding(Self.buttonInset)
            .background(Self.buttonColor)
            .onTap { _ in self.inner.toggle() }
        }
        Frame(float2(240, 60), .leading) {
          if self.outer {
            HStack(spacing: 6) {
              Text("outer")
                .font(Self.labelFont)
                .foregroundColor(.white)
                .padding(Self.buttonInset)
                .background(Self.palette[4].color)
              if self.inner {
                Text("inner A")
                  .font(Self.labelFont)
                  .foregroundColor(.white)
                  .padding(Self.buttonInset)
                  .background(Self.palette[2].color)
              } else {
                Text("inner B")
                  .font(Self.labelFont)
                  .foregroundColor(.white)
                  .padding(Self.buttonInset)
                  .background(Self.palette[1].color)
              }
            }
          } else {
            Text("outer is off")
              .font(Self.labelFont)
              .foregroundColor(Self.captionColor)
          }
        }
        .background(Self.grey)

        // Inside the arm, `self.hits` is an ordinary reactive argument. While the arm is hidden
        // its node fields are nil, so "+1" is a no-op on screen; showing it again builds it with
        // whatever `hits` is by then.
        Text("hidden arm catches up: if visible")
          .font(Self.captionFont)
          .foregroundColor(Self.captionColor)
        HStack(spacing: 6) {
          Text("visible: \(self.visible)")
            .font(Self.buttonFont)
            .foregroundColor(.white)
            .padding(Self.buttonInset)
            .background(Self.buttonColor)
            .onTap { _ in self.visible.toggle() }
          Text("+1")
            .font(Self.buttonFont)
            .foregroundColor(.white)
            .padding(Self.buttonInset)
            .background(Self.buttonColor)
            .onTap { _ in self.hits += 1 }
        }
        Frame(float2(240, 40), .leading) {
          if self.visible {
            HStack(spacing: 8) {
              Rectangle(Self.palette[5].color)
                .frame(width: Float(min(self.hits, 12)) * 10 + 4, height: 16)
              Text("hits: \(self.hits)")
                .font(Self.labelFont)
            }
          }
        }
        .background(Self.grey)

        // Same label two ways. The ternary is an argument: `setText` changes the one element.
        // The branch swaps one element for another. On screen they look the same.
        Text("ternary argument vs if / else")
          .font(Self.captionFont)
          .foregroundColor(Self.captionColor)
        Text("isOn: \(self.isOn)")
          .font(Self.buttonFont)
          .foregroundColor(.white)
          .padding(Self.buttonInset)
          .background(Self.buttonColor)
          .onTap { _ in self.isOn.toggle() }
        HStack(spacing: 12) {
          Text(self.isOn ? "ON (setText)" : "OFF (setText)")
            .font(Self.labelFont)
            .foregroundColor(.white)
            .padding(Self.buttonInset)
            .background(self.isOn ? Self.palette[2].color : Self.dim)
          if self.isOn {
            Text("ON (arm)")
              .font(Self.labelFont)
              .foregroundColor(.white)
              .padding(Self.buttonInset)
              .background(Self.palette[2].color)
          } else {
            Text("OFF (arm)")
              .font(Self.labelFont)
              .foregroundColor(.white)
              .padding(Self.buttonInset)
              .background(Self.dim)
          }
        }
        .padding(Inset(all: 6))
        .background(Self.grey)

        // The black square is tappable and steps `size` from inside a freshly swapped-in arm;
        // the handler is armed right after the swap, so it works on the arm's first frame.
        Text("branch in an HStack: A, if showMiddle { ■ }, C")
          .font(Self.captionFont)
          .foregroundColor(Self.captionColor)
        HStack(spacing: 6) {
          Text("showMiddle: \(self.showMiddle)")
            .font(Self.buttonFont)
            .foregroundColor(.white)
            .padding(Self.buttonInset)
            .background(Self.buttonColor)
            .onTap { _ in self.showMiddle.toggle() }
          Text("size: \(Int(self.size))")
            .font(Self.buttonFont)
            .foregroundColor(.white)
            .padding(Self.buttonInset)
            .background(Self.buttonColor)
            .onTap { _ in self.stepSize() }
        }
        HStack(spacing: 6) {
          Rectangle(Self.palette[0].color).frame(width: 24, height: 24)
          if self.showMiddle {
            Rectangle(.black)
              .frame(width: self.size, height: self.size)
              .onTap { _ in self.stepSize() }
          }
          Rectangle(Self.palette[3].color).frame(width: 24, height: 24)
        }
        .padding(Inset(all: 6))
        .background(Self.grey)
      }
    }
  }

  // MARK: - Actions

  func cyclePhase() {
    self.phase = (self.phase + 1) % Self.phases.count
  }

  func select(_ index: Int) {
    self.selected = nil
    self.selected = index
  }

  func stepSize() {
    self.size = self.size == 24 ? 48 : 24
  }
}
