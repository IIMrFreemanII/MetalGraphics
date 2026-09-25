import MetalGraphicsLib
import ReactiveUI

// Shows clip shapes, corner radii, borders and shaped backgrounds:
//
// - A photo clipped to a rounded rect, a capsule, a circle, and per-corner radii.
// - A card whose corner radius, border color and border width animate on hover, over an image
//   that its rounded clip cuts too.
// - Shaped backgrounds and borders on text.
// - Shadows: a card lifting on hover, text, a vector shape, a clipped photo (the clip shapes its
//   shadow without cutting it), an SVG icon and a transparent bitmap.
// - Rounded rows inside a rounded scroll view: clips nested in clips, cut while scrolling.
@Component
final class ShapesDemo : SingleChildElement {
  private static let captionFont = TextFont.system(size: 12)
  private static let captionColor = float4(0.45, 0.45, 0.45, 1)
  private static let chipFont = TextFont.system(size: 13)
  private static let cardColor = float4(0.93, 0.93, 0.95, 1)
  private static let borderColor = float4(0.75, 0.75, 0.78, 1)
  private static let orange = float4(0.95, 0.5, 0.1, 1)
  private static let hoverAnimation = UIAnimation.spring()

  @State var hovered: Bool = false
  @State var lifted: Bool = false
  @State var rows: [ScrollRow] = (0..<60).map { ScrollRow.make($0) }

  @UIElementBuilder var body: [UIElement] {
    VStack(alignment: .leading, spacing: 10) {
      Text("clipShape: .rect(cornerRadius: 16), .capsule, .circle, per-corner radii")
        .font(Self.captionFont)
        .foregroundColor(Self.captionColor)
      HStack(spacing: 12) {
        Image("photo")
          .resizable()
          .scaledToFill()
          .frame(width: 120, height: 90)
          .clipShape(.rect(cornerRadius: 16))
        Image("photo")
          .resizable()
          .scaledToFill()
          .frame(width: 160, height: 60)
          .clipShape(.capsule)
        Image("photo")
          .resizable()
          .scaledToFill()
          .frame(width: 120, height: 90)
          .clipShape(.circle)
        Image("photo")
          .resizable()
          .scaledToFill()
          .frame(width: 120, height: 90)
          .clipShape(.rect(topLeadingRadius: 40, bottomTrailingRadius: 40))
      }

      Text("Hover: cornerRadius, border color and width animate together")
        .font(Self.captionFont)
        .foregroundColor(Self.captionColor)
      VStack(alignment: .leading, spacing: 8) {
        Image("photo")
          .resizable()
          .scaledToFill()
          .frame(width: 240, height: 100)
        Text(self.hovered ? "Rounder" : "Hover me")
          .font(Self.chipFont)
          .padding(Inset(left: 12, right: 12, bottom: 10))
      }
      .background(Self.cardColor)
      .cornerRadius(self.hovered ? 28 : 8)
      .border(self.hovered ? Self.orange : Self.borderColor, width: self.hovered ? 3 : 1, in: .rect(cornerRadius: self.hovered ? 28 : 8))
      .animation(Self.hoverAnimation, value: self.hovered)
      .onHover { isHovered, _ in self.hovered = isHovered }

      Text("background(_:in:) and border(_:width:in:) on text")
        .font(Self.captionFont)
        .foregroundColor(Self.captionColor)
      HStack(spacing: 8) {
        Text("Capsule")
          .font(Self.chipFont)
          .foregroundColor(.white)
          .padding(Inset(vertical: 4, horizontal: 12))
          .background(.blue, in: .capsule)
        Text("Rounded")
          .font(Self.chipFont)
          .foregroundColor(.white)
          .padding(Inset(vertical: 4, horizontal: 12))
          .background(Self.orange, in: .rect(cornerRadius: 6))
        Text("Border")
          .font(Self.chipFont)
          .padding(Inset(vertical: 4, horizontal: 12))
          .border(.black, width: 1)
        Text("Rounded border")
          .font(Self.chipFont)
          .padding(Inset(vertical: 4, horizontal: 12))
          .border(.blue, width: 2, in: .capsule)
        Text("Both")
          .font(Self.chipFont)
          .padding(Inset(vertical: 4, horizontal: 12))
          .background(Self.cardColor, in: .rect(cornerRadius: 10))
          .border(Self.borderColor, width: 1, in: .rect(cornerRadius: 10))
      }

      Text("shadow(color:radius:x:y:): hover the card to lift it")
        .font(Self.captionFont)
        .foregroundColor(Self.captionColor)
      HStack(spacing: 24) {
        Text(self.lifted ? "Lifted" : "Hover me")
          .font(Self.chipFont)
          .frame(width: 120, height: 70)
          .background(.white, in: .rect(cornerRadius: 12))
          .shadow(radius: self.lifted ? 12 : 3, y: self.lifted ? 8 : 1)
          .animation(Self.hoverAnimation, value: self.lifted)
          .onHover { isHovered, _ in self.lifted = isHovered }
        Text("Shadowed")
          .font(TextFont.system(size: 28))
          .foregroundColor(Self.orange)
          .shadow(color: float4(0, 0, 0, 0.5), radius: 2, x: 2, y: 2)
        VectorCanvas(width: 64, height: 64) {
          Circle(center: float2(32, 32), radius: 24)
            .fill(.blue)
        }
        .shadow(color: float4(0, 0, 0.6, 0.5), radius: 6, y: 4)
        Image("photo")
          .resizable()
          .scaledToFill()
          .frame(width: 100, height: 70)
          .cornerRadius(12)
          .shadow(radius: 6, y: 4)
        Image("star")
          .resizable()
          .frame(width: 56, height: 56)
          .shadow(radius: 4, x: 3, y: 3)
        Image("pixel-heart")
          .resizable()
          .interpolation(.none)
          .frame(width: 56, height: 56)
          .shadow(radius: 4, y: 4)
      }
      .padding(Inset(vertical: 8, horizontal: 8))

      Text("Rounded rows in a rounded scroll view: nested clips")
        .font(Self.captionFont)
        .foregroundColor(Self.captionColor)
      ScrollView {
        VList(alignment: .leading, spacing: 4, items: self.rows) { row in
          Text(row.name)
            .font(ShapesDemo.chipFont)
            .foregroundColor(.white)
            .padding(Inset(vertical: 6, horizontal: 10))
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(row.color)
            .cornerRadius(10)
        }
        .padding(6)
      }
      .frame(width: 260, height: 220)
      .background(Self.cardColor)
      .cornerRadius(18)
      .border(Self.borderColor, width: 1, in: .rect(cornerRadius: 18))
    }
  }
}
