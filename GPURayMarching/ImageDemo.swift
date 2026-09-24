import AppKit
import MetalGraphicsLib
import ReactiveUI

// Shows what `Image` draws. SVG icons (data sets in Assets.xcassets) are baked into the SDF atlas
// and stay sharp at any size; bitmaps are drawn from mipmapped textures.
//
// The reactive parts: "Tint" animates the foreground color that `currentColor` and template
// images take, "Like" swaps an icon by name, and "Resize" animates the frames that the fit and
// fill images are laid out in.
@Component
final class ImageDemo : SingleChildElement {
  private static let captionFont = TextFont.system(size: 12)
  private static let captionColor = float4(0.45, 0.45, 0.45, 1)
  private static let buttonFont = TextFont.system(size: 13)
  private static let buttonInset = Inset(vertical: 4, horizontal: 8)
  private static let buttonColor = float4(0.25, 0.25, 0.25, 1)
  private static let panelColor = float4(0.9, 0.9, 0.9, 1)
  private static let orange = float4(0.95, 0.5, 0.1, 1)
  private static let tintAnimation = UIAnimation.easeInOut(0.4)
  private static let resizeAnimation = UIAnimation.easeInOut(0.5)
  private static let appIcon = NSImage(named: NSImage.applicationIconName)!

  @State var tinted: Bool = false
  @State var liked: Bool = false
  @State var wide: Bool = true

  @UIElementBuilder var body: [UIElement] {
    VStack(alignment: .leading, spacing: 8) {
      Text("SVG at 16, 24, 48 and 128 pt: one bake, any size")
        .font(Self.captionFont)
        .foregroundColor(Self.captionColor)
      HStack(spacing: 12) {
        Image("star")
          .resizable()
          .frame(width: 16, height: 16)
        Image("star")
          .resizable()
          .frame(width: 24, height: 24)
        Image("star")
          .resizable()
          .frame(width: 48, height: 48)
        Image("star")
          .resizable()
          .frame(width: 128, height: 128)
        Image("badge")
          .resizable()
          .frame(width: 128, height: 128)
      }

      Text("Strokes, arcs, even-odd, transforms, curves, colours")
        .font(Self.captionFont)
        .foregroundColor(Self.captionColor)
      HStack(spacing: 12) {
        Image("check-circle")
          .resizable()
          .frame(width: 48, height: 48)
        Image("ring")
          .resizable()
          .frame(width: 48, height: 48)
        Image("sun")
          .resizable()
          .frame(width: 48, height: 48)
        Image("arrow")
          .resizable()
          .frame(width: 48, height: 48)
        Image("wave")
          .resizable()
          .frame(width: 48, height: 48)
        Image("badge")
          .resizable()
          .frame(width: 48, height: 48)
        // natural size: the SVG's own 24x24
        Image("badge")
      }

      Text("Foreground color: currentColor and templates")
        .font(Self.captionFont)
        .foregroundColor(Self.captionColor)
      HStack(spacing: 12) {
        Text("Tint")
          .font(Self.buttonFont)
          .foregroundColor(.white)
          .padding(Self.buttonInset)
          .background(Self.buttonColor)
          .onTap { _ in self.tinted.toggle() }
        Image("check-circle")
          .resizable()
          .foregroundColor(self.tinted ? Self.orange : .black)
          .animation(Self.tintAnimation, value: self.tinted)
          .frame(width: 32, height: 32)
        Image("wave")
          .resizable()
          .foregroundColor(self.tinted ? .blue : .black)
          .animation(Self.tintAnimation, value: self.tinted)
          .frame(width: 32, height: 32)
        // A template draws every paint, even fixed ones, in the foreground color.
        Image("badge")
          .resizable()
          .renderingMode(.template)
          .foregroundColor(self.tinted ? .red : .black)
          .animation(Self.tintAnimation, value: self.tinted)
          .frame(width: 32, height: 32)
        Image("pixel-heart")
          .resizable()
          .interpolation(.none)
          .renderingMode(.template)
          .foregroundColor(self.tinted ? .green : .black)
          .animation(Self.tintAnimation, value: self.tinted)
          .frame(width: 32, height: 32)
        Text("Like")
          .font(Self.buttonFont)
          .foregroundColor(.white)
          .padding(Self.buttonInset)
          .background(Self.buttonColor)
          .onTap { _ in self.liked.toggle() }
        Image(self.liked ? "star-fill" : "star")
          .resizable()
          .foregroundColor(self.liked ? Self.orange : .black)
          .frame(width: 32, height: 32)
      }

      Text("Bitmaps: fit and fill")
        .font(Self.captionFont)
        .foregroundColor(Self.captionColor)
      HStack(spacing: 12) {
        Text("Resize")
          .font(Self.buttonFont)
          .foregroundColor(.white)
          .padding(Self.buttonInset)
          .background(Self.buttonColor)
          .onTap { _ in self.wide.toggle() }
        Image("photo")
          .resizable()
          .scaledToFit()
          .frame(width: self.wide ? 240 : 110, height: 120)
          .animation(Self.resizeAnimation, value: self.wide)
          .background(Self.panelColor)
        Image("photo")
          .resizable()
          .scaledToFill()
          .frame(width: self.wide ? 240 : 110, height: 120)
          .animation(Self.resizeAnimation, value: self.wide)
          .background(Self.panelColor)
      }

      Text("Pixel art, nearest and smooth; mipmapped downscaling; an NSImage")
        .font(Self.captionFont)
        .foregroundColor(Self.captionColor)
      HStack(spacing: 12) {
        Image("pixel-heart")
          .resizable()
          .interpolation(.none)
          .frame(width: 64, height: 64)
        Image("pixel-heart")
          .resizable()
          .frame(width: 64, height: 64)
        Image("pixel-heart")
        Image("photo")
          .resizable()
          .scaledToFit()
          .frame(width: 60, height: 40)
        Image(nsImage: Self.appIcon)
          .resizable()
          .frame(width: 64, height: 64)
      }
    }
  }
}
