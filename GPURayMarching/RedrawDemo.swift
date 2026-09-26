import MetalGraphicsLib
import ReactiveUI

// Shows partial re-rendering: only what changed is shaded again, and every other pixel is left
// as the last frame drew it.
//
// - "Show redrawn areas" tints what was shaded lately: steady while an area keeps redrawing,
//   fading once it stops.
// - The dot, the spinner and the sliding bar animate forever: each stays tinted in its own
//   50 pt cells only, while the text and the cards around them stay clear.
// - "Nudge" shakes a card once: its area lights up while it moves, then fades.
// - "Partial rendering" off shades the whole window every frame, for comparison: with the tint
//   on, all of it stays tinted.
// - "Stress" adds rows of static labels, most of them below the window: the animations then
//   run over a big tree. Launch with `METALGRAPHICS_PROFILE=1` to log where each frame's time
//   goes (`FrameProfiler`).
@Component
final class RedrawDemo : SingleChildElement {
  private static let buttonFont = TextFont.system(size: 13)
  private static let buttonInset = Inset(vertical: 4, horizontal: 8)
  private static let buttonColor = float4(0.25, 0.25, 0.25, 1)
  private static let captionFont = TextFont.system(size: 12)
  private static let captionColor = float4(0.45, 0.45, 0.45, 1)
  private static let bodyFont = TextFont.system(size: 13)
  private static let track = float4(0.88, 0.88, 0.88, 1)
  private static let shake = UIKeyframes(offset: [
    .linear(float2(-12, 0), duration: 0.06),
    .linear(float2(12, 0), duration: 0.12),
    .linear(float2(-8, 0), duration: 0.1),
    .linear(float2(5, 0), duration: 0.08),
    .spring(.zero, duration: 0.35, response: 0.25, dampingFraction: 0.7),
  ])

  @State var running: Bool = false
  @State var nudges: Int = 0
  // A body cannot hold a component (F4), but a list's `onCreate` can: one row, the toggles.
  @State var panels: [RenderDebugPanel] = [RenderDebugPanel()]
  @State var stressRows: [StressIndex] = []

  @UIElementBuilder var body: [UIElement] {
    VStack(alignment: .leading, spacing: 14) {
      Text("Only the areas whose content changed are drawn again; the rest stays as it was.")
        .font(Self.bodyFont)
        .foregroundColor(.black)
      Text("Redrawn areas are tinted green; the tint fades once an area stops redrawing.")
        .font(Self.captionFont)
        .foregroundColor(Self.captionColor)
      VList(alignment: .leading, items: self.panels) { _ in
        RenderDebugToggles()
      }
      .frame(width: 280)

      Text("static: drawn once")
        .font(Self.captionFont)
        .foregroundColor(Self.captionColor)
      HStack(spacing: 10) {
        Rectangle(.init(0.9, 0.35, 0.3, 1))
          .frame(width: 70, height: 44)
        Rectangle(.init(0.2, 0.6, 0.35, 1))
          .frame(width: 70, height: 44)
        Rectangle(.init(0.2, 0.45, 0.85, 1))
          .frame(width: 70, height: 44)
        Text("shake me")
          .font(Self.bodyFont)
          .foregroundColor(.white)
          .padding(Inset(vertical: 13, horizontal: 10))
          .background(.init(0.6, 0.3, 0.9, 1))
          .keyframes(Self.shake, trigger: self.nudges)
      }
      Text("Nudge")
        .font(Self.buttonFont)
        .foregroundColor(.white)
        .padding(Self.buttonInset)
        .background(Self.buttonColor)
        .onTap { _ in self.nudges += 1 }

      Text("animated: each redraws its own cells only")
        .font(Self.captionFont)
        .foregroundColor(Self.captionColor)
      HStack(spacing: 80) {
        Rectangle(.init(0.9, 0.2, 0.3, 1))
          .frame(width: 16, height: 16)
          .opacity(self.running ? 0.15 : 1)
          .animation(.easeInOut(0.7).repeatForever(), value: self.running)
        VectorCanvas(width: 24, height: 24) {
          Circle(center: float2(12, 12), radius: 9)
            .stroke(Self.track, lineWidth: 2.5)
          Circle(center: float2(12, 12), radius: 9)
            .stroke(.blue, lineWidth: 2.5)
            .trim(from: 0, to: 0.3)
            .rotationEffect(self.running ? 360 : 0)
            .animation(.linear(1).repeatForever(autoreverses: false), value: self.running)
        }
        .resizable()
        .frame(width: 32, height: 32)
      }
      HStack {
        Rectangle(.init(0.1, 0.6, 0.6, 1))
          .frame(width: 40, height: 8)
          .offset(x: self.running ? 260 : 0, y: 0)
          .animation(.easeInOut(1.5).repeatForever(), value: self.running)
        Spacer()
      }
      .frame(width: 300, height: 8)
      .background(Self.track)

      HStack(spacing: 6) {
        Text("Stress: off")
          .font(Self.buttonFont)
          .foregroundColor(.white)
          .padding(Self.buttonInset)
          .background(Self.buttonColor)
          .onTap { _ in self.setStress(rows: 0) }
        Text("100 rows")
          .font(Self.buttonFont)
          .foregroundColor(.white)
          .padding(Self.buttonInset)
          .background(Self.buttonColor)
          .onTap { _ in self.setStress(rows: 100) }
        Text("500 rows")
          .font(Self.buttonFont)
          .foregroundColor(.white)
          .padding(Self.buttonInset)
          .background(Self.buttonColor)
          .onTap { _ in self.setStress(rows: 500) }
        Text("\(self.stressRows.count) rows of 8 labels")
          .font(Self.captionFont)
          .foregroundColor(Self.captionColor)
      }
      // Scrolled, so the controls above stay on screen: every row is still laid out, walked and
      // emitted each frame; only the visible ones are filed in the grid.
      if !self.stressRows.isEmpty {
        ScrollView {
          VList(alignment: .leading, spacing: 2, items: self.stressRows) { row in
            StressLabelRow(index: row.id)
          }
        }
        .frame(width: 760, height: 300)
      }
    }
  }

  func setStress(rows: Int) {
    guard rows != self.stressRows.count else { return }
    self.stressRows = (0 ..< rows).map { StressIndex(id: $0) }
  }

  // Toggled rather than set: on a remount `running` is already true and everything sits at its
  // target, where setting it again would start nothing.
  override func onMount(_ context: UIContext) {
    self.running.toggle()
  }
}

// A row of the stress content: eight static labels, each a square and a short text.
@Component
final class StressLabelRow : SingleChildElement {
  let index: Int
  @State var cells: [StressIndex] = (0 ..< 8).map { StressIndex(id: $0) }

  init(index: Int) {
    self.index = index
    super.init()
  }

  @UIElementBuilder var body: [UIElement] {
    HList(spacing: 10, items: self.cells) { cell in
      StressLabel(number: self.index * 8 + cell.id)
    }
  }
}

@Component
final class StressLabel : SingleChildElement {
  private static let font = TextFont.system(size: 11)
  let number: Int

  init(number: Int) {
    self.number = number
    super.init()
  }

  @UIElementBuilder var body: [UIElement] {
    HStack(spacing: 3) {
      Rectangle(.init(Float(self.number % 7) / 7, 0.5, 0.8, 1))
        .frame(width: 8, height: 8)
      Text("Item \(self.number)")
        .font(Self.font)
        .foregroundColor(.init(0.3, 0.3, 0.3, 1))
    }
  }
}

struct RenderDebugPanel : Identifiable {
  let id = 0
}

/// Switches for how frames are drawn: the redrawn-area tint and partial rendering.
///
/// Built by hand, not with `@Component`: flipping one writes to `Graphics2D`, a side effect a
/// component's binding cannot have. Mirrors the renderer's values while mounted and puts them
/// back to their defaults when unmounted, so other tabs draw as usual.
final class RenderDebugToggles : SingleChildElement {
  private let showDamage = Toggle("Show redrawn areas", isOn: false)
  private let partial = Toggle("Partial rendering", isOn: true)
  private weak var context: UIContext?

  override init() {
    super.init()
    self.child = VStack(alignment: .leading, spacing: 8) {
      self.showDamage
      self.partial
    }
    self.showDamage.onIsOnChange = { [unowned self] on in
      self.context?.graphics?.sceneData.debug.showDamage = on
      self.sync()
    }
    self.partial.onIsOnChange = { [unowned self] on in
      self.context?.graphics?.partialRendering = on
      self.sync()
    }
  }

  override func onMount(_ context: UIContext) {
    self.context = context
    self.sync()
  }

  override func onUnmount(_ context: UIContext) {
    if let graphics = context.graphics {
      graphics.sceneData.debug.showDamage = false
      graphics.partialRendering = true
    }
    self.context = nil
  }

  /// Shows what the renderer holds. The first mount can come before the first frame, when there
  /// is no renderer yet: the toggles then keep the defaults they were built with.
  private func sync() {
    guard let context = self.context, let graphics = context.graphics else { return }
    self.showDamage.setIsOn(graphics.sceneData.debug.showDamage, context)
    self.partial.setIsOn(graphics.partialRendering, context)
  }
}
