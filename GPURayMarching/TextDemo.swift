import MetalGraphicsLib
import ReactiveUI

// Shows what the SDF text path can draw: one baked distance field per glyph, scaled to any size,
// laid out by CoreText (kerning, accents, fallback fonts, word wrapping).
//
// The last two sections are reactive. "Width" re-wraps the paragraph by resizing its frame, and
// "A-" / "A+" change the font size through `Text.setStyle`; neither rebuilds an element.
@Component
final class TextDemo : SingleChildElement {
  private static let captionStyle = TextStyle(color: .init(0.45, 0.45, 0.45, 1), fontSize: 12)
  private static let buttonStyle = TextStyle(color: .white, fontSize: 13)
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
      Text("Sizes", style: Self.captionStyle)
      VStack(alignment: .leading, spacing: 2) {
        Text("Menlo 10pt", style: TextStyle(fontSize: 10))
        Text("Menlo 14pt", style: TextStyle(fontSize: 14))
        Text("Menlo 20pt", style: TextStyle(fontSize: 20))
        Text("Menlo 32pt", style: TextStyle(fontSize: 32))
      }

      Text("Fonts", style: Self.captionStyle)
      VStack(alignment: .leading, spacing: 2) {
        Text("Menlo: The quick brown fox", style: TextStyle(fontSize: 18))
        Text("Helvetica Neue: The quick brown fox", style: TextStyle(fontSize: 18, font: Self.helvetica))
        Text("Georgia: The quick brown fox", style: TextStyle(fontSize: 18, font: Self.georgia))
        Text("Avenir Next: The quick brown fox", style: TextStyle(fontSize: 18, font: Self.avenir))
      }

      Text("Colours", style: Self.captionStyle)
      HStack(spacing: 10) {
        Text("red", style: TextStyle(color: .red, fontSize: 18))
        Text("green", style: TextStyle(color: .init(0.1, 0.6, 0.2, 1), fontSize: 18))
        Text("blue", style: TextStyle(color: .blue, fontSize: 18))
        Text("purple", style: TextStyle(color: .init(0.6, 0.3, 0.9, 1), fontSize: 18))
        Text("inverted", style: TextStyle(color: .white, fontSize: 18))
          .padding(Inset(vertical: 2, horizontal: 6))
          .background(.black)
      }

      Text("Kerning, accents, fallback fonts", style: Self.captionStyle)
      Text("AVATAR To Wa · café naïve · 你好 · ∑ π ≈ ∞", style: TextStyle(fontSize: 20, font: Self.helvetica))

      Text("Word wrapping", style: Self.captionStyle)
      Text("Width: \(Int(self.wrapWidth))", style: Self.buttonStyle)
        .padding(Self.buttonInset)
        .background(Self.buttonColor)
        .onTap { _ in self.cycleWidth() }
      Frame(float2(self.wrapWidth, 90), .topLeading) {
        Text(Self.paragraph, style: TextStyle(fontSize: 14, font: Self.helvetica))
          .padding(Inset(all: 6))
      }
      .background(.init(0.9, 0.9, 0.9, 1))

      Text("Reactive size and text", style: Self.captionStyle)
      HStack(spacing: 6) {
        Text("A-", style: Self.buttonStyle)
          .padding(Self.buttonInset)
          .background(Self.buttonColor)
          .onTap { _ in self.stepFontSize(by: -4) }
        Text("A+", style: Self.buttonStyle)
          .padding(Self.buttonInset)
          .background(Self.buttonColor)
          .onTap { _ in self.stepFontSize(by: 4) }
        Text("Tap count", style: Self.buttonStyle)
          .padding(Self.buttonInset)
          .background(.blue)
          .onTap { _ in self.taps += 1 }
      }
      Text("Size \(Int(self.fontSize))pt, tapped \(self.taps) times", style: TextStyle(fontSize: self.fontSize))
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
