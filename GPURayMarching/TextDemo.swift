import MetalGraphicsLib
import ReactiveUI

// Shows what the SDF text path can draw: one baked distance field per glyph, scaled to any size,
// laid out by CoreText (kerning, accents, fallback fonts, word wrapping), and the SwiftUI Text API
// on top: text styles, weights and designs, decorations, `Text + Text`, truncation, alignment,
// and styles inherited from the containers around a text.
//
// Reactive parts: "Width" re-wraps the paragraph by resizing its frame; "A-" / "A+" change the
// font size through `.font` (`Text.setFont`); the greeting's name is one run of a `Text + Text`
// (`setRunText`); "More" lifts a line limit; "Tint" animates a colour every text under a stack
// inherits. None of them rebuilds an element.
@Component
final class TextDemo : SingleChildElement {
  private static let captionFont = TextFont.system(size: 12)
  private static let captionColor = float4(0.45, 0.45, 0.45, 1)
  private static let buttonFont = TextFont.system(size: 13)
  private static let buttonInset = Inset(vertical: 4, horizontal: 8)
  private static let buttonColor = float4(0.25, 0.25, 0.25, 1)
  private static let accent = float4(0.2, 0.4, 0.9, 1)

  private static let helvetica = FontManager.shared.font(named: "Helvetica Neue")
  private static let georgia = FontManager.shared.font(named: "Georgia")
  private static let avenir = FontManager.shared.font(named: "Avenir Next")

  private static let paragraph =
    "Every glyph is baked once into a shared distance field atlas and drawn at any size from it. "
    + "Resize this box to watch CoreText re-wrap the words."
  private static let wrapWidths: [Float] = [160, 260, 360]
  private static let names = ["world", "SwiftUI", "Metal", "everyone"]

  @State var wrapWidth: Float = 260
  @State var fontSize: Float = 16
  @State var taps: Int = 0
  @State var name: String = "world"
  @State var expanded: Bool = false
  @State var tinted: Bool = false

  @UIElementBuilder var body: [UIElement] {
    ScrollView(.vertical) {
      HStack(alignment: .top, spacing: 40) {
        VStack(alignment: .leading, spacing: 8) {
          Text("Sizes")
            .font(Self.captionFont)
            .foregroundColor(Self.captionColor)
          VStack(alignment: .leading, spacing: 2) {
            Text("System 10pt")
              .font(.system(size: 10))
            Text("System 14pt")
              .font(.system(size: 14))
            Text("System 20pt")
              .font(.system(size: 20))
            Text("System 32pt")
              .font(.system(size: 32))
          }

          Text("Fonts")
            .font(Self.captionFont)
            .foregroundColor(Self.captionColor)
          VStack(alignment: .leading, spacing: 2) {
            Text("System: The quick brown fox")
            Text("Monospaced: The quick brown fox")
              .monospaced()
            Text("Helvetica Neue: The quick brown fox")
              .font(.custom(Self.helvetica, size: 18))
            Text("Georgia: The quick brown fox")
              .font(.custom(Self.georgia, size: 18))
            Text("Avenir Next: The quick brown fox")
              .font(.custom(Self.avenir, size: 18))
          }
          .font(.system(size: 18))

          Text("Colours")
            .font(Self.captionFont)
            .foregroundColor(Self.captionColor)
          HStack(spacing: 10) {
            Text("red")
              .foregroundColor(.red)
            Text("green")
              .foregroundColor(.init(0.1, 0.6, 0.2, 1))
            Text("blue")
              .foregroundColor(.blue)
            Text("purple")
              .foregroundColor(.init(0.6, 0.3, 0.9, 1))
            Text("inverted")
              .foregroundColor(.white)
              .padding(Inset(vertical: 2, horizontal: 6))
              .background(.black)
          }
          .font(.system(size: 18))

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
              .padding(Self.buttonInset)
              .background(Self.buttonColor)
              .onTap { _ in self.stepFontSize(by: -4) }
            Text("A+")
              .padding(Self.buttonInset)
              .background(Self.buttonColor)
              .onTap { _ in self.stepFontSize(by: 4) }
            Text("Tap count")
              .padding(Self.buttonInset)
              .background(.blue)
              .onTap { _ in self.taps += 1 }
          }
          .font(Self.buttonFont)
          .foregroundColor(.white)
          Text("Size \(Int(self.fontSize))pt, tapped \(self.taps) times")
            .font(.system(size: self.fontSize))
        }

        VStack(alignment: .leading, spacing: 8) {
          Text("Text styles")
            .font(Self.captionFont)
            .foregroundColor(Self.captionColor)
          VStack(alignment: .leading, spacing: 2) {
            Text("Large Title")
              .font(.largeTitle)
            Text("Title")
              .font(.title)
            Text("Headline")
              .font(.headline)
            Text("Body")
              .font(.body)
            Text("Caption")
              .font(.caption)
          }

          Text("Weights and designs")
            .font(Self.captionFont)
            .foregroundColor(Self.captionColor)
          HStack(spacing: 10) {
            Text("Light")
              .fontWeight(.light)
            Text("Regular")
            Text("Semibold")
              .fontWeight(.semibold)
            Text("Black")
              .fontWeight(.black)
          }
          .font(.title3)
          HStack(spacing: 10) {
            Text("Serif")
              .fontDesign(.serif)
            Text("Rounded")
              .fontDesign(.rounded)
            Text("Mono")
              .fontDesign(.monospaced)
            Text("Italic")
              .italic()
          }
          .font(.title3)

          Text("Decorations and spacing")
            .font(Self.captionFont)
            .foregroundColor(Self.captionColor)
          HStack(spacing: 12) {
            Text("Underline")
              .underline()
            Text("Struck")
              .strikethrough(color: .red)
            Text("Tracking")
              .tracking(3)
            Text("E = mc") + Text("2").font(.caption).baselineOffset(7)
          }
          .font(.body)

          Text("Text + Text")
            .font(Self.captionFont)
            .foregroundColor(Self.captionColor)
          HStack(spacing: 10) {
            Text("Hello, ") + Text(self.name).bold().foregroundColor(Self.accent) + Text("!")
            Text("Next name")
              .font(Self.buttonFont)
              .foregroundColor(.white)
              .padding(Self.buttonInset)
              .background(Self.buttonColor)
              .onTap { _ in self.nextName() }
          }
          .font(.title3)

          Text("Line limit, truncation, alignment")
            .font(Self.captionFont)
            .foregroundColor(Self.captionColor)
          Frame(float2(300, 110), .topLeading) {
            VStack(alignment: .leading, spacing: 6) {
              Text(Self.paragraph)
                .lineLimit(self.expanded ? nil : 2)
              Text(Self.paragraph)
                .lineLimit(1)
                .truncationMode(.middle)
            }
          }
          Text(self.expanded ? "Less" : "More")
            .font(Self.buttonFont)
            .foregroundColor(.white)
            .padding(Self.buttonInset)
            .background(Self.buttonColor)
            .onTap { _ in self.expanded.toggle() }
          Text("Centred lines,\nas many as it takes")
            .multilineTextAlignment(.center)
            .frame(width: 300)

          Text("Inherited from a stack")
            .font(Self.captionFont)
            .foregroundColor(Self.captionColor)
          VStack(alignment: .leading, spacing: 2) {
            Text("Every text here takes the stack's font")
            Text("and its colour, animated")
            Text("unless it sets its own")
              .foregroundColor(.red)
          }
          .font(.headline)
          .foregroundStyle(self.tinted ? Self.accent : .black)
          .animation(.easeInOut(0.4), value: self.tinted)
          Text("Tint")
            .font(Self.buttonFont)
            .foregroundColor(.white)
            .padding(Self.buttonInset)
            .background(Self.buttonColor)
            .onTap { _ in self.tinted.toggle() }

          Text("Formatted")
            .font(Self.captionFont)
            .foregroundColor(Self.captionColor)
          Text(Double(self.taps) * 1234.5, format: .number)
            .monospacedDigit()
        }
      }
      .padding(Inset(all: 16))
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

  func nextName() {
    let index = Self.names.firstIndex(of: self.name) ?? 0
    self.name = Self.names[(index + 1) % Self.names.count]
  }
}
