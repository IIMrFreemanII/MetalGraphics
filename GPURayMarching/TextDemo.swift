import MetalGraphicsLib
import ReactiveUI

// Shows what the SDF text path can draw: one baked distance field per glyph, scaled to any size,
// laid out by CoreText (kerning, accents, fallback fonts, word wrapping).
//
// The last two sections are reactive. "Width" re-wraps the paragraph by resizing its frame, and
// "A-" / "A+" change the font size through `.font` (`Text.setFont`); neither rebuilds an element.
@Component
final class TextDemo : SingleChildElement {
  private static let captionFont = TextFont.system(size: 12)
  private static let captionColor = float4(0.45, 0.45, 0.45, 1)
  private static let buttonFont = TextFont.system(size: 13)
  private static let buttonInset = Inset(vertical: 4, horizontal: 8)
  private static let buttonColor = float4(0.25, 0.25, 0.25, 1)

  private static let helvetica = FontManager.shared.font(named: "Helvetica Neue")
  private static let georgia = FontManager.shared.font(named: "Georgia")
  private static let avenir = FontManager.shared.font(named: "Avenir Next")

  private static let paragraph =
    "Every glyph is baked once into a shared distance field atlas and drawn at any size from it. "
    + "Resize this box to watch CoreText re-wrap the words."
  private static let wrapWidths: [Float] = [160, 260, 360]

  @State var wrapWidth: Float = 260
  @State var fontSize: Float = 16
  @State var taps: Int = 0

  @UIElementBuilder var body: [UIElement] {
    VStack(alignment: .leading, spacing: 8) {
      Text("Sizes")
        .font(Self.captionFont)
        .foregroundColor(Self.captionColor)
      VStack(alignment: .leading, spacing: 2) {
        Text("Menlo 10pt")
          .font(.system(size: 10))
        Text("Menlo 14pt")
          .font(.system(size: 14))
        Text("Menlo 20pt")
          .font(.system(size: 20))
        Text("Menlo 32pt")
          .font(.system(size: 32))
      }

      Text("Fonts")
        .font(Self.captionFont)
        .foregroundColor(Self.captionColor)
      VStack(alignment: .leading, spacing: 2) {
        Text("Menlo: The quick brown fox")
          .font(.system(size: 18))
        Text("Helvetica Neue: The quick brown fox")
          .font(.custom(Self.helvetica, size: 18))
        Text("Georgia: The quick brown fox")
          .font(.custom(Self.georgia, size: 18))
        Text("Avenir Next: The quick brown fox")
          .font(.custom(Self.avenir, size: 18))
      }

      Text("Colours")
        .font(Self.captionFont)
        .foregroundColor(Self.captionColor)
      HStack(spacing: 10) {
        Text("red")
          .font(.system(size: 18))
          .foregroundColor(.red)
        Text("green")
          .font(.system(size: 18))
          .foregroundColor(.init(0.1, 0.6, 0.2, 1))
        Text("blue")
          .font(.system(size: 18))
          .foregroundColor(.blue)
        Text("purple")
          .font(.system(size: 18))
          .foregroundColor(.init(0.6, 0.3, 0.9, 1))
        Text("inverted")
          .font(.system(size: 18))
          .foregroundColor(.white)
          .padding(Inset(vertical: 2, horizontal: 6))
          .background(.black)
      }

      Text("Kerning, accents, fallback fonts")
        .font(Self.captionFont)
        .foregroundColor(Self.captionColor)
      Text("AVATAR To Wa · café naïve · 你好 · ∑ π ≈ ∞")
        .font(.custom(Self.helvetica, size: 20))

      Text("Word wrapping")
        .font(Self.captionFont)
        .foregroundColor(Self.captionColor)
      Text("Width: \(Int(self.wrapWidth))")
        .font(Self.buttonFont)
        .foregroundColor(.white)
        .padding(Self.buttonInset)
        .background(Self.buttonColor)
        .onTap { _ in self.cycleWidth() }
      Frame(float2(self.wrapWidth, 90), .topLeading) {
        Text(Self.paragraph)
          .font(.custom(Self.helvetica, size: 14))
          .padding(Inset(all: 6))
      }
      .background(.init(0.9, 0.9, 0.9, 1))

      Text("Reactive size and text")
        .font(Self.captionFont)
        .foregroundColor(Self.captionColor)
      HStack(spacing: 6) {
        Text("A-")
          .font(Self.buttonFont)
          .foregroundColor(.white)
          .padding(Self.buttonInset)
          .background(Self.buttonColor)
          .onTap { _ in self.stepFontSize(by: -4) }
        Text("A+")
          .font(Self.buttonFont)
          .foregroundColor(.white)
          .padding(Self.buttonInset)
          .background(Self.buttonColor)
          .onTap { _ in self.stepFontSize(by: 4) }
        Text("Tap count")
          .font(Self.buttonFont)
          .foregroundColor(.white)
          .padding(Self.buttonInset)
          .background(.blue)
          .onTap { _ in self.taps += 1 }
      }
      Text("Size \(Int(self.fontSize))pt, tapped \(self.taps) times")
        .font(.system(size: self.fontSize))
    }
  }

  // MARK: - Actions

  func cycleWidth() {
    let index = Self.wrapWidths.firstIndex(of: self.wrapWidth) ?? 0
    self.wrapWidth = Self.wrapWidths[(index + 1) % Self.wrapWidths.count]
  }

  func stepFontSize(by step: Float) {
    self.fontSize = min(max(self.fontSize + step, 8), 40)
  }
}
