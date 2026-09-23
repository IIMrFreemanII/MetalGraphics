import MetalGraphicsLib
import ReactiveUI

struct AnimatedItem : Identifiable {
  let id = UUID()
  let name: String
  let color: float4
}

// Shows the three ways a change animates.
//
// - A scope, `.animation(_:value:)`: the hover card. Everything written before the scope in its
//   chain animates when `hovered` changes; the label text cannot be interpolated and snaps.
// - A scope over a branch: the `if isOn` arm fades and slides in and out with its `.transition`,
//   while its buttons stop responding as soon as it starts to leave.
// - `withAnimation`: the size and dim buttons, and the list's append/remove. "Snap size" writes
//   the same state without it, and jumps. "Remove first" counts removals in its completion.
// - Layout slides: rows below a removed or inserted one, and "below the arm", slide to their
//   new place instead of jumping.
// - Keyframes, both kinds: "Pop" is a keyframed curve that overshoots; the shake card plays
//   value keyframes each time it is tapped.
// - Repeat: the dot pulses forever, started from `onMount`.
// - Text styling: "Restyle" animates a text's font size and color, set with `.font` and
//   `.foregroundColor`.
@Component
final class AnimationDemo : SingleChildElement {
  private static let palette: [(name: String, color: float4)] = [
    ("red", .red),
    ("green", .init(0.1, 0.6, 0.2, 1)),
    ("blue", .blue),
    ("amber", .init(0.85, 0.6, 0.1, 1)),
    ("purple", .init(0.6, 0.3, 0.9, 1)),
    ("teal", .init(0.1, 0.6, 0.6, 1)),
  ]
  private static let buttonFont = TextFont.system(size: 13)
  private static let buttonInset = Inset(vertical: 4, horizontal: 8)
  private static let buttonColor = float4(0.25, 0.25, 0.25, 1)
  private static let captionFont = TextFont.system(size: 12)
  private static let captionColor = float4(0.45, 0.45, 0.45, 1)
  private static let cardFont = TextFont.system(size: 13)
  private static let rowInset = Inset(vertical: 3, horizontal: 8)
  private static let shake = UIKeyframes(offset: [
    .linear(float2(-10, 0), duration: 0.05),
    .linear(float2(10, 0), duration: 0.1),
    .linear(float2(-7, 0), duration: 0.1),
    .linear(float2(4, 0), duration: 0.08),
    .spring(.zero, duration: 0.35, response: 0.25, dampingFraction: 0.7),
  ])
  private static let pop = UIAnimation.keyframes([
    .easeOut(1.3, duration: 0.18),
    .easeInOut(0.9, duration: 0.14),
    .easeInOut(1, duration: 0.12),
  ])

  @State var hovered: Bool = false
  @State var isOn: Bool = true
  @State var dimmed: Bool = false
  @State var size: Float = 40
  @State var removed: Int = 0
  @State var shakes: Int = 0
  @State var pulsing: Bool = false
  @State var big: Bool = false
  @State var items: [AnimatedItem] = [
    AnimationDemo.makeItem(0),
    AnimationDemo.makeItem(1),
  ]

  private var nextItem = 2

  @UIElementBuilder var body: [UIElement] {
    VStack(alignment: .leading, spacing: 12) {
      HStack(spacing: 6) {
        Text("Toggle arm")
          .font(Self.buttonFont)
          .foregroundColor(.white)
          .padding(Self.buttonInset)
          .background(Self.buttonColor)
          .onTap { _ in self.isOn.toggle() }
        Text("Grow")
          .font(Self.buttonFont)
          .foregroundColor(.white)
          .padding(Self.buttonInset)
          .background(Self.buttonColor)
          .onTap { _ in
            withAnimation(.spring(response: 0.45, dampingFraction: 0.6)) { self.toggleSize() }
          }
        Text("Snap size")
          .font(Self.buttonFont)
          .foregroundColor(.white)
          .padding(Self.buttonInset)
          .background(Self.buttonColor)
          .onTap { _ in self.toggleSize() }
        Text("Dim")
          .font(Self.buttonFont)
          .foregroundColor(.white)
          .padding(Self.buttonInset)
          .background(Self.buttonColor)
          .onTap { _ in
            withAnimation(.easeInOut(0.4)) { self.dimmed.toggle() }
          }
        Text("Append row")
          .font(Self.buttonFont)
          .foregroundColor(.white)
          .padding(Self.buttonInset)
          .background(Self.buttonColor)
          .onTap { _ in
            withAnimation(.spring()) { self.append() }
          }
        Text("Remove first")
          .font(Self.buttonFont)
          .foregroundColor(.white)
          .padding(Self.buttonInset)
          .background(Self.buttonColor)
          .onTap { _ in
            withAnimation(.easeOut(0.3)) {
              self.removeItems(at: 0)
            } completion: {
              self.removed += 1
            }
          }
      }

      HStack(spacing: 6) {
        Text("Pop")
          .font(Self.buttonFont)
          .foregroundColor(.white)
          .padding(Self.buttonInset)
          .background(Self.buttonColor)
          .onTap { _ in
            withAnimation(Self.pop) { self.toggleSize() }
          }
        Text("Restyle")
          .font(Self.buttonFont)
          .foregroundColor(.white)
          .padding(Self.buttonInset)
          .background(Self.buttonColor)
          .onTap { _ in
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { self.big.toggle() }
          }
        Text("shake me")
          .font(Self.cardFont)
          .foregroundColor(.white)
          .padding(Self.buttonInset)
          .background(.init(0.6, 0.3, 0.9, 1))
          .keyframes(Self.shake, trigger: self.shakes)
          .onTap { _ in self.shakes += 1 }
        Rectangle(.init(0.9, 0.2, 0.3, 1))
          .frame(width: 14, height: 14)
          .opacity(self.pulsing ? 0.2 : 1)
          .animation(.easeInOut(0.7).repeatForever(), value: self.pulsing)
      }

      Text("restyle me")
        .font(.system(size: self.big ? 24 : 13))
        .foregroundColor(self.big ? .init(0.85, 0.25, 0.1, 1) : .init(0.2, 0.2, 0.2, 1))

      // A scope: the padding and the background animate, the text snaps.
      Text("scope: hover the card")
        .font(Self.captionFont)
        .foregroundColor(Self.captionColor)
      Text(self.hovered ? "hovered" : "hover me")
        .font(Self.cardFont)
        .foregroundColor(.white)
        .padding(self.hovered ? Inset(all: 16) : Inset(all: 8))
        .background(self.hovered ? .init(0.1, 0.5, 0.9, 1) : .init(0.3, 0.3, 0.3, 1))
        .animation(.easeOut(0.2), value: self.hovered)
        .onHover { hovered, _ in
          self.hovered = hovered
        }

      // A scope over a branch: the arm transitions in and out.
      Text("scope over a branch: if isOn")
        .font(Self.captionFont)
        .foregroundColor(Self.captionColor)
      VStack(alignment: .leading, spacing: 6) {
        if self.isOn {
          Text("I fade and slide")
            .font(Self.cardFont)
            .foregroundColor(.white)
            .padding(Self.buttonInset)
            .background(.init(0.1, 0.6, 0.2, 1))
            .transition(.opacity.combined(with: .move(float2(-30, 0))))
        }
        Text("below the arm")
          .font(Self.captionFont)
          .foregroundColor(Self.captionColor)
      }
      .animation(.spring(), value: self.isOn)

      // No scope: animated only by `withAnimation`.
      Text("withAnimation: Grow and Dim animate, Snap size does not")
        .font(Self.captionFont)
        .foregroundColor(Self.captionColor)
      Rectangle(.init(0.85, 0.6, 0.1, 1))
        .frame(width: self.size, height: self.size)
        .opacity(self.dimmed ? 0.3 : 1)

      Text("rows: withAnimation + .transition, removed \(self.removed)")
        .font(Self.captionFont)
        .foregroundColor(Self.captionColor)
      VList(alignment: .leading, spacing: 4, items: self.items) { item in
        Text(item.name)
          .font(Self.cardFont)
          .foregroundColor(.white)
          .padding(Self.rowInset)
          .background(item.color)
          .transition(.scale(0.6).combined(with: .opacity))
      }
    }
  }

  // Toggled rather than set: on a remount `pulsing` is already true and the dot sits at its
  // target, where setting it again would start nothing.
  override func onMount(_ context: UIContext) {
    self.pulsing.toggle()
  }

  // MARK: - Actions

  func toggleSize() {
    self.size = self.size == 40 ? 80 : 40
  }

  func append() {
    self.appendItems(Self.makeItem(self.nextItem))
    self.nextItem += 1
  }

  private static func makeItem(_ index: Int) -> AnimatedItem {
    let entry = Self.palette[index % Self.palette.count]
    return AnimatedItem(name: "\(entry.name) \(index)", color: entry.color)
  }
}
