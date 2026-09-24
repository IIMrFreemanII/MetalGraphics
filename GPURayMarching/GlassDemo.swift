import MetalGraphicsLib
import ReactiveUI

// Shows `.glass(_:in:)` and `.blur(radius:)`:
//
// - The four material presets over photos, text and vector shapes.
// - Stacking: a glass sheet, which casts a shadow, over a glass card. The sheet's backdrop shows
//   the card already frosted. Tap to slide the sheet; a capsule sweeps back and forth over it
//   all, so the backdrops are rendered anew every frame.
// - `.blur(radius:)` on text, a photo, vector shapes and a shaped background, animated on tap.
//
// Each glass adds a backdrop pass and two blur passes over its own area before the frame; blur
// adds no pass at all.
@Component
final class GlassDemo : SingleChildElement {
  private static let captionFont = TextFont.system(size: 12)
  private static let captionColor = float4(0.45, 0.45, 0.45, 1)
  private static let labelFont = TextFont.system(size: 15)
  private static let titleFont = TextFont.system(size: 44)
  private static let red = float4(0.95, 0.3, 0.3, 1)
  private static let green = float4(0.2, 0.7, 0.3, 1)
  private static let blue = float4(0.2, 0.45, 0.95, 1)
  private static let orange = float4(0.95, 0.5, 0.1, 1)
  private static let purple = float4(0.6, 0.3, 0.85, 1)
  private static let clear = float4(0, 0, 0, 0)
  private static let card = UIShape.rect(cornerRadius: 16)
  private static let slide = UIAnimation.spring(response: 0.5, dampingFraction: 0.75)

  @State var slid: Bool = false
  @State var blurred: Bool = true
  // Set on mount: a repeating animation starts when its state changes.
  @State var sweeping: Bool = false

  @UIElementBuilder var body: [UIElement] {
    VStack(alignment: .leading, spacing: 10) {
      Text("glass(_:in:): .ultraThin, .thin, .regular, .thick")
        .font(Self.captionFont)
        .foregroundColor(Self.captionColor)
      ZStack(alignment: .topLeading) {
        HStack(spacing: 0) {
          Image("photo")
            .resizable()
            .scaledToFill()
            .frame(width: 260, height: 160)
          VStack(alignment: .leading, spacing: 0) {
            Text("Frosted")
              .font(Self.titleFont)
              .foregroundColor(Self.orange)
            Text("glass")
              .font(Self.titleFont)
              .foregroundColor(Self.blue)
          }
          .padding(Inset(vertical: 20, horizontal: 20))
          VectorCanvas(width: 240, height: 160) {
            Circle(center: float2(60, 60), radius: 50)
              .fill(Self.red)
            Circle(center: float2(140, 90), radius: 60)
              .fill(Self.green)
            Circle(center: float2(200, 40), radius: 35)
              .fill(Self.purple)
          }
        }
        HStack(spacing: 16) {
          Text("ultraThin")
            .font(Self.labelFont)
            .frame(width: 150, height: 110)
            .glass(.ultraThin, in: Self.card)
          Text("thin")
            .font(Self.labelFont)
            .frame(width: 150, height: 110)
            .glass(.thin, in: Self.card)
          Text("regular")
            .font(Self.labelFont)
            .frame(width: 150, height: 110)
            .glass(.regular, in: Self.card)
          Text("thick")
            .font(Self.labelFont)
            .frame(width: 150, height: 110)
            .glass(.thick, in: Self.card)
        }
        .padding(Inset(vertical: 25, horizontal: 40))
      }

      Text("Stacked: the sheet's backdrop is the card, already frosted. Tap to slide it")
        .font(Self.captionFont)
        .foregroundColor(Self.captionColor)
      ZStack(alignment: .topLeading) {
        HStack(spacing: 0) {
          VectorCanvas(width: 240, height: 200) {
            Circle(center: float2(80, 70), radius: 60)
              .fill(Self.blue)
            Circle(center: float2(170, 140), radius: 55)
              .fill(Self.orange)
          }
          Image("photo")
            .resizable()
            .scaledToFill()
            .frame(width: 300, height: 200)
          VStack(alignment: .leading, spacing: 4) {
            Text("Layers")
              .font(Self.titleFont)
              .foregroundColor(Self.red)
            Text("of glass")
              .font(Self.titleFont)
              .foregroundColor(Self.green)
          }
          .padding(Inset(vertical: 20, horizontal: 20))
        }
        Text("Card")
          .font(Self.labelFont)
          .frame(width: 240, height: 130)
          .glass(.thin, in: .rect(cornerRadius: 20))
          .padding(Inset(left: 120, top: 20))
        // Every shape under a shadow casts one, so the label goes over it rather than under.
        // Placed by padding, not offset, so it is tapped where it is drawn.
        Rectangle(Self.clear)
          .frame(width: 240, height: 130)
          .glass(.regular, in: .rect(cornerRadius: 20))
          .shadow(radius: 12, y: 6)
          .overlay {
            Text("Sheet")
              .font(Self.labelFont)
          }
          .onTap { _ in self.slid.toggle() }
          .padding(Inset(left: self.slid ? 420 : 250, top: 55))
          .animation(Self.slide, value: self.slid)
        Text("Sweep")
          .font(Self.labelFont)
          .frame(width: 110, height: 44)
          .glass(.ultraThin, in: .capsule)
          .offset(x: self.sweeping ? 640 : 10, y: 150)
          .animation(self.sweeping ? .easeInOut(3).repeatForever(autoreverses: true) : .default, value: self.sweeping)
      }

      Text("blur(radius:): each shape blurs on its own, no extra pass. Tap to toggle")
        .font(Self.captionFont)
        .foregroundColor(Self.captionColor)
      HStack(spacing: 20) {
        Text("Blurred text")
          .font(Self.titleFont)
          .foregroundColor(Self.purple)
        Image("photo")
          .resizable()
          .scaledToFill()
          .frame(width: 160, height: 100)
        VectorCanvas(width: 100, height: 100) {
          Circle(center: float2(50, 50), radius: 40)
            .stroke(Self.orange, lineWidth: 8)
          RoundedRectangle(origin: float2(30, 30), size: float2(40, 40), cornerRadius: 8)
            .fill(Self.blue)
        }
        Text("Chip")
          .font(Self.labelFont)
          .foregroundColor(.white)
          .padding(Inset(vertical: 8, horizontal: 16))
          .background(Self.green, in: .capsule)
      }
      .padding(Inset(vertical: 10, horizontal: 10))
      .blur(radius: self.blurred ? 6 : 0)
      .animation(.easeInOut(0.5), value: self.blurred)
      .onTap { _ in self.blurred.toggle() }
    }
  }

  override func onMount(_ context: UIContext) {
    self.sweeping = true
  }
}
