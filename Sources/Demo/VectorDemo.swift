import MetalGraphicsLib
import ReactiveUI

// Vector shapes built in code, driven by state and animated on tap, hover and press.
//
// What each animation costs: circles, ellipses and rounded rectangles are evaluated analytically,
// and every shape's color, opacity, offset, rotation, scale, stroke width and trim are applied
// when drawing — none of those ever bake. Only a `Path` whose outline changes (the morph, the
// wave) bakes its distance field again, once per frame while it animates. Run with
// `VECTOR_STATS=1` to print bakes and GPU time per frame.
@Component
final class VectorDemo : SingleChildElement {
  private static let captionFont = TextFont.system(size: 12)
  private static let captionColor = float4(0.45, 0.45, 0.45, 1)
  private static let buttonFont = TextFont.system(size: 13)
  private static let buttonInset = Inset(vertical: 4, horizontal: 8)
  private static let buttonColor = float4(0.25, 0.25, 0.25, 1)
  private static let orange = float4(0.95, 0.5, 0.1, 1)
  private static let track = float4(0.85, 0.85, 0.85, 1)
  private static let venn = [float4(0.95, 0.3, 0.3, 1), float4(0.2, 0.7, 0.3, 1), float4(0.2, 0.45, 0.95, 1)]
  // Same commands in the same order, so one morphs into the other.
  private static let play = "M8 5 L12.5 7.9 L12.5 16.1 L8 19 Z M12.5 7.9 L19 12 L19 12 L12.5 16.1 Z"
  private static let pause = "M7 5 L10.5 5 L10.5 19 L7 19 Z M13.5 5 L17 5 L17 19 L13.5 19 Z"
  private static let check = "M7 12.5 L10.5 16 L17 9"
  private static let quick = UIAnimation.easeOut(0.3)
  private static let bouncy = UIAnimation.spring(response: 0.35, dampingFraction: 0.55)

  @State var checked: Bool = false
  @State var hovered: Bool = false
  @State var pressed: Bool = false
  @State var playing: Bool = false
  // Set on mount: a repeating animation starts when its state changes.
  @State var spinning: Bool = false
  @State var waving: Bool = false
  @State var ringHovered: Bool = false
  @State var hoveredA: Bool = false
  @State var hoveredB: Bool = false
  @State var hoveredC: Bool = false
  @State var picked: Int = -1
  @State var stress: Bool = false
  @State var stressRows: [StressIndex] = (0 ..< 10).map { StressIndex(id: $0) }

  @UIElementBuilder var body: [UIElement] {
    VStack(alignment: .leading, spacing: 8) {
      Text("Tap: the box fills and the check draws on (trim, no bakes); the icon morphs (one bake a frame)")
        .font(Self.captionFont)
        .foregroundColor(Self.captionColor)
      HStack(spacing: 16) {
        VectorCanvas(width: 24, height: 24) {
          RoundedRectangle(origin: float2(3, 3), size: float2(18, 18), cornerRadius: self.checked ? 5 : 3)
            .fill(Self.venn[1])
            .opacity(self.checked ? 1 : 0)
            .animation(Self.quick, value: self.checked)
          RoundedRectangle(origin: float2(3, 3), size: float2(18, 18), cornerRadius: self.checked ? 5 : 3)
            .stroke(self.checked ? Self.venn[1] : .black, lineWidth: 1.5)
            .animation(Self.quick, value: self.checked)
          Path(d: Self.check)
            .stroke(.white, lineWidth: 2.5)
            .trim(from: 0, to: self.checked ? 1 : 0)
            .animation(Self.quick, value: self.checked)
        }
        .resizable()
        .frame(width: 48, height: 48)
        .onTap { _ in self.checked.toggle() }

        VectorCanvas(width: 24, height: 24) {
          Circle(center: float2(12, 12), radius: 11.5)
            .fill(self.playing ? Self.orange : Self.buttonColor)
            .animation(Self.quick, value: self.playing)
          Path(d: self.playing ? Self.pause : Self.play)
            .fill(.white)
            .animation(Self.bouncy, value: self.playing)
        }
        .resizable()
        .frame(width: 48, height: 48)
        .onTap { _ in self.playing.toggle() }
      }

      Text("Hover and press: radius, color and scale of an analytic circle, springing")
        .font(Self.captionFont)
        .foregroundColor(Self.captionColor)
      HStack(spacing: 16) {
        VectorCanvas(width: 64, height: 64) {
          Circle(center: float2(32, 32), radius: self.hovered ? 30 : 24)
            .fill(self.hovered ? Self.orange : .blue)
            .scaleEffect(self.pressed ? 0.85 : 1)
            .animation(Self.bouncy, value: self.hovered)
            .animation(Self.bouncy, value: self.pressed)
            .onHover { hovering, _ in self.hovered = hovering }
            .onPress { down, _ in self.pressed = down }
          Circle(center: float2(32, 32), radius: self.hovered ? 12 : 8)
            .stroke(.white, lineWidth: self.pressed ? 6 : 3)
            .scaleEffect(self.pressed ? 0.85 : 1)
            .animation(Self.bouncy, value: self.hovered)
            .animation(Self.bouncy, value: self.pressed)
        }
        .resizable()
        .frame(width: 64, height: 64)
        // hit only inside the ring itself: the hole and the corners do not count
        VectorCanvas(width: 64, height: 64) {
          Circle(center: float2(32, 32), radius: 22)
            .stroke(self.ringHovered ? Self.orange : Self.track, lineWidth: self.ringHovered ? 14 : 10)
            .animation(Self.bouncy, value: self.ringHovered)
            .onHover { hovering, _ in self.ringHovered = hovering }
        }
        .resizable()
        .frame(width: 64, height: 64)
      }

      Text("Spinner and wave: rotation and trim never bake; the wave's outline is rebuilt every frame")
        .font(Self.captionFont)
        .foregroundColor(Self.captionColor)
      HStack(spacing: 16) {
        Text(self.spinning ? "Stop" : "Spin")
          .font(Self.buttonFont)
          .foregroundColor(.white)
          .padding(Self.buttonInset)
          .background(Self.buttonColor)
          .onTap { _ in self.spinning.toggle() }
        VectorCanvas(width: 24, height: 24) {
          Circle(center: float2(12, 12), radius: 9)
            .stroke(Self.track, lineWidth: 2.5)
          Circle(center: float2(12, 12), radius: 9)
            .stroke(.blue, lineWidth: 2.5)
            .trim(from: 0, to: self.spinning ? 0.7 : 0.25)
            .rotationEffect(self.spinning ? 360 : 0)
            .animation(self.spinning ? .linear(1).repeatForever(autoreverses: false) : .default, value: self.spinning)
        }
        .resizable()
        .frame(width: 48, height: 48)
        VectorCanvas(width: 48, height: 24) {
          Path(self.waving ? 2 * Float.pi : 0) { p, phase in
            for i in 0 ... 48 {
              let x = Float(i)
              p.addLine(to: float2(x, 12 + 7 * sin(x * 0.26 + phase)))
            }
          }
          .stroke(Self.orange, lineWidth: 2)
          .animation(self.waving ? .linear(1.5).repeatForever(autoreverses: false) : .default, value: self.waving)
        }
        .resizable()
        .frame(width: 96, height: 48)
        .onTap { _ in self.waving.toggle() }
      }

      Text("Per-shape hit testing: each circle hovers and taps only inside itself")
        .font(Self.captionFont)
        .foregroundColor(Self.captionColor)
      VectorCanvas(width: 100, height: 90) {
        Circle(center: float2(38, 34), radius: 26)
          .fill(Self.venn[0])
          .opacity(self.hoveredA ? 0.9 : 0.45)
          .scaleEffect(self.picked == 0 ? 1.1 : 1)
          .animation(Self.quick, value: self.hoveredA)
          .animation(Self.bouncy, value: self.picked)
          .onHover { hovering, _ in self.hoveredA = hovering }
          .onTap { _ in self.pick(0) }
        Circle(center: float2(62, 34), radius: 26)
          .fill(Self.venn[1])
          .opacity(self.hoveredB ? 0.9 : 0.45)
          .scaleEffect(self.picked == 1 ? 1.1 : 1)
          .animation(Self.quick, value: self.hoveredB)
          .animation(Self.bouncy, value: self.picked)
          .onHover { hovering, _ in self.hoveredB = hovering }
          .onTap { _ in self.pick(1) }
        Circle(center: float2(50, 56), radius: 26)
          .fill(Self.venn[2])
          .opacity(self.hoveredC ? 0.9 : 0.45)
          .scaleEffect(self.picked == 2 ? 1.1 : 1)
          .animation(Self.quick, value: self.hoveredC)
          .animation(Self.bouncy, value: self.picked)
          .onHover { hovering, _ in self.hoveredC = hovering }
          .onTap { _ in self.pick(2) }
      }
      .resizable()
      .frame(width: 150, height: 135)

      HStack(spacing: 8) {
        Text(self.stress ? "Hide stress test" : "Stress test: 200 cells")
          .font(Self.buttonFont)
          .foregroundColor(.white)
          .padding(Self.buttonInset)
          .background(Self.buttonColor)
          .onTap { _ in self.stress.toggle() }
        Text("each: a pulsing circle and a turning path (no bakes); each row: one wave (a bake a frame)")
          .font(Self.captionFont)
          .foregroundColor(Self.captionColor)
      }
      if self.stress {
        VList(alignment: .leading, spacing: 2, items: self.stressRows) { row in
          StressRow(index: row.id)
        }
      }
    }
  }

  override func onMount(_ context: UIContext) {
    self.spinning = true
    self.waving = true
  }

  // MARK: - Actions

  func pick(_ index: Int) {
    self.picked = self.picked == index ? -1 : index
  }
}

struct StressIndex : Identifiable {
  let id: Int
}

// A row of the stress test: twenty cells, and a wave re-baked every frame.
@Component
final class StressRow : SingleChildElement {
  let index: Int
  @State var cells: [StressIndex] = (0 ..< 20).map { StressIndex(id: $0) }
  @State var running: Bool = false

  init(index: Int) {
    self.index = index
    super.init()
  }

  override func onMount(_ context: UIContext) {
    self.running = true
  }

  @UIElementBuilder var body: [UIElement] {
    HStack(spacing: 2) {
      HList(spacing: 2, items: self.cells) { cell in
        StressCell(index: cell.id)
      }
      VectorCanvas(width: 48, height: 24) {
        Path(self.running ? 2 * Float.pi : 0) { p, phase in
          for i in 0 ... 24 {
            let x = Float(i) * 2
            p.addLine(to: float2(x, 12 + 8 * sin(x * 0.2 + phase)))
          }
        }
        .stroke(.blue, lineWidth: 1.5)
        .animation(.linear(1).repeatForever(autoreverses: false), value: self.running)
      }
      .resizable()
      .frame(width: 48, height: 24)
    }
  }
}

@Component
final class StressCell : SingleChildElement {
  private static let arrow = "M12 3 L20 19 L12 15 L4 19 Z"

  let index: Int
  @State var running: Bool = false

  init(index: Int) {
    self.index = index
    super.init()
  }

  override func onMount(_ context: UIContext) {
    self.running = true
  }

  @UIElementBuilder var body: [UIElement] {
    VectorCanvas(width: 24, height: 24) {
      Circle(center: float2(12, 12), radius: self.running ? 11 : 5)
        .fill(float4(Float(self.index) / 20, 0.5, 0.9, 1))
        .animation(.easeInOut(0.8).repeatForever(), value: self.running)
      Path(d: Self.arrow)
        .fill(.white)
        .scaleEffect(0.6)
        .rotationEffect(self.running ? 360 : 0)
        .animation(.linear(2).repeatForever(autoreverses: false), value: self.running)
    }
    .resizable()
    .frame(width: 24, height: 24)
  }
}
