import MetalGraphicsLib
import ReactiveUI

// The SwiftUI layout pieces beyond plain stacks and frames. Each button changes one state, so
// the layout changes in place and animates.
//
// - How an HStack shares its width: a text wraps against a rectangle, and `layoutPriority`
//   decides which of two texts gets the room.
// - `.frame(maxWidth: .infinity, alignment:)`.
// - `ZStack` alignment, and `.zIndex` bringing a card to the front.
// - `.overlay` with a badge that comes and goes, and `.background` with content.
// - `.fixedSize`, `.aspectRatio` on any element, `.position`, `.clipped`, `Divider`, and
//   padding on some edges only.
// - Alignment guides: text baselines, and `.alignmentGuide` moving one row of a stack.
//
// Grey backgrounds show a container's own bounds.
@Component
final class ContainersDemo : SingleChildElement {
  private static let captionFont = TextFont.system(size: 12)
  private static let captionColor = float4(0.45, 0.45, 0.45, 1)
  private static let buttonFont = TextFont.system(size: 13)
  private static let bodyFont = TextFont.system(size: 13)
  private static let buttonInset = Inset(vertical: 4, horizontal: 8)
  private static let buttonColor = float4(0.25, 0.25, 0.25, 1)
  private static let grey = float4(0.9, 0.9, 0.9, 1)
  private static let amber = float4(0.85, 0.6, 0.1, 1)
  private static let purple = float4(0.6, 0.3, 0.9, 1)
  private static let green = float4(0.2, 0.65, 0.35, 1)
  private static let animation = UIAnimation.easeInOut(0.35)

  private static let alignments: [(name: String, value: Alignment)] = [
    ("leading", .leading), ("center", .center), ("trailing", .trailing),
  ]
  private static let zAlignments: [(name: String, value: Alignment)] = [
    ("topLeading", .topLeading), ("center", .center), ("bottomTrailing", .bottomTrailing),
  ]

  @State var wideRect: Bool = false
  @State var priorityRight: Bool = false
  @State var fillAlignment: Int = 0
  @State var zAlignment: Int = 0
  @State var purpleInFront: Bool = false
  @State var unread: Int = 3
  @State var dotX: Float = 20
  @State var baselines: Bool = true
  @State var indented: Bool = false

  @UIElementBuilder var body: [UIElement] {
    HStack(alignment: .top, spacing: 40) {
      VStack(alignment: .leading, spacing: 8) {
        Text("HStack shares its width: the text wraps in what is left")
          .font(Self.captionFont)
          .foregroundColor(Self.captionColor)
        Text(self.wideRect ? "rectangle: 160" : "rectangle: 60")
          .font(Self.buttonFont)
          .foregroundColor(.white)
          .padding(Self.buttonInset)
          .background(Self.buttonColor)
          .onTap { _ in self.wideRect.toggle() }
        HStack(alignment: .top, spacing: 8) {
          Text("Every glyph is baked once into a shared distance field atlas and drawn at any size.")
            .font(Self.bodyFont)
          Rectangle(Self.amber)
            .frame(width: self.wideRect ? 160 : 60, height: 40)
            .animation(Self.animation, value: self.wideRect)
        }
        .frame(width: 300, alignment: .leading)
        .background(Self.grey)

        Text("layoutPriority: the higher one is sized first")
          .font(Self.captionFont)
          .foregroundColor(Self.captionColor)
        Text(self.priorityRight ? "priority: right" : "priority: left")
          .font(Self.buttonFont)
          .foregroundColor(.white)
          .padding(Self.buttonInset)
          .background(Self.buttonColor)
          .onTap { _ in self.priorityRight.toggle() }
        HStack(alignment: .top, spacing: 8) {
          Text("Sized first when it has priority")
            .font(Self.bodyFont)
            .layoutPriority(self.priorityRight ? 0 : 1)
            .background(Self.amber)
          Text("The other one")
            .font(Self.bodyFont)
            .layoutPriority(self.priorityRight ? 1 : 0)
            .background(Self.purple)
        }
        .animation(Self.animation, value: self.priorityRight)
        .frame(width: 300, alignment: .leading)
        .background(Self.grey)

        Text("frame(maxWidth: .infinity, alignment:)")
          .font(Self.captionFont)
          .foregroundColor(Self.captionColor)
        Text("alignment: \(Self.alignments[self.fillAlignment].name)")
          .font(Self.buttonFont)
          .foregroundColor(.white)
          .padding(Self.buttonInset)
          .background(Self.buttonColor)
          .onTap { _ in self.fillAlignment = (self.fillAlignment + 1) % Self.alignments.count }
        Text("fills the width")
          .font(Self.bodyFont)
          .foregroundColor(.white)
          .padding(Inset(all: 6))
          .background(Self.green)
          .frame(maxWidth: .infinity, alignment: Self.alignments[self.fillAlignment].value)
          .animation(Self.animation, value: self.fillAlignment)
          .background(Self.grey)
          .frame(width: 300)

        Text("HStack(alignment: .firstTextBaseline)")
          .font(Self.captionFont)
          .foregroundColor(Self.captionColor)
        Text(self.baselines ? "alignment: firstTextBaseline" : "alignment: center")
          .font(Self.buttonFont)
          .foregroundColor(.white)
          .padding(Self.buttonInset)
          .background(Self.buttonColor)
          .onTap { _ in self.baselines.toggle() }
        HStack(alignment: self.baselines ? .firstTextBaseline : .center, spacing: 8) {
          Text("Big")
            .font(TextFont.system(size: 32))
          Text("small")
            .font(TextFont.system(size: 12))
          Text("padded")
            .font(TextFont.system(size: 16))
            .padding(.top, 14)
            .background(Self.amber)
        }
        .animation(Self.animation, value: self.baselines)
        .background(Self.grey)

        Text("alignmentGuide: move one row by its own guide")
          .font(Self.captionFont)
          .foregroundColor(Self.captionColor)
        Text(self.indented ? "guide: leading - 40" : "guide: default")
          .font(Self.buttonFont)
          .foregroundColor(.white)
          .padding(Self.buttonInset)
          .background(Self.buttonColor)
          .onTap { _ in self.indented.toggle() }
        // A guide's closure runs at layout time and is not bound to state, so the row is
        // swapped rather than its guide changed.
        VStack(alignment: .leading, spacing: 4) {
          Rectangle(Self.purple)
            .frame(width: 120, height: 14)
          if self.indented {
            Rectangle(Self.amber)
              .frame(width: 120, height: 14)
              .alignmentGuide(.leading) { _ in -40 }
          } else {
            Rectangle(Self.amber)
              .frame(width: 120, height: 14)
          }
          Rectangle(Self.green)
            .frame(width: 120, height: 14)
        }
        .animation(Self.animation, value: self.indented)
        .background(Self.grey)
      }

      VStack(alignment: .leading, spacing: 8) {
        Text("ZStack: alignment, and zIndex")
          .font(Self.captionFont)
          .foregroundColor(Self.captionColor)
        HStack(spacing: 6) {
          Text("alignment: \(Self.zAlignments[self.zAlignment].name)")
            .font(Self.buttonFont)
            .foregroundColor(.white)
            .padding(Self.buttonInset)
            .background(Self.buttonColor)
            .onTap { _ in self.zAlignment = (self.zAlignment + 1) % Self.zAlignments.count }
          Text(self.purpleInFront ? "purple in front" : "purple behind")
            .font(Self.buttonFont)
            .foregroundColor(.white)
            .padding(Self.buttonInset)
            .background(Self.buttonColor)
            .onTap { _ in self.purpleInFront.toggle() }
        }
        ZStack(alignment: Self.zAlignments[self.zAlignment].value) {
          Rectangle(Self.purple)
            .frame(width: 120, height: 90)
            .zIndex(self.purpleInFront ? 1 : 0)
          Rectangle(Self.amber)
            .frame(width: 80, height: 60)
          Rectangle(Self.green)
            .frame(width: 40, height: 30)
        }
        .animation(Self.animation, value: self.zAlignment)
        .frame(width: 180, height: 120)
        .background(Self.grey)

        Text("overlay and background with content")
          .font(Self.captionFont)
          .foregroundColor(Self.captionColor)
        HStack(spacing: 6) {
          Text("+1")
            .font(Self.buttonFont)
            .foregroundColor(.white)
            .padding(Self.buttonInset)
            .background(Self.buttonColor)
            .onTap { _ in self.unread += 1 }
          Text("read all")
            .font(Self.buttonFont)
            .foregroundColor(.white)
            .padding(Self.buttonInset)
            .background(Self.buttonColor)
            .onTap { _ in self.unread = 0 }
        }
        Text("Inbox")
          .font(Self.bodyFont)
          .padding(Inset(vertical: 10, horizontal: 18))
          .background {
            Rectangle(Self.grey)
            Rectangle(Self.amber)
              .frame(height: 3)
              .frame(maxHeight: .infinity, alignment: .bottom)
          }
          .overlay(alignment: .topTrailing) {
            if self.unread > 0 {
              Text("\(self.unread)")
                .font(Self.captionFont)
                .foregroundColor(.white)
                .padding(Inset(vertical: 2, horizontal: 6))
                .background(.red)
                .offset(float2(8, -8))
                .transition(.scale().combined(with: .opacity))
            }
          }
          .animation(Self.animation, value: self.unread)
      }

      VStack(alignment: .leading, spacing: 8) {
        Text("fixedSize: ideal width, whatever is offered")
          .font(Self.captionFont)
          .foregroundColor(Self.captionColor)
        HStack(alignment: .top, spacing: 12) {
          Text("wraps in a 90pt frame")
            .font(Self.bodyFont)
            .frame(width: 90, alignment: .leading)
            .background(Self.grey)
          Text("fixed in 90pt")
            .font(Self.bodyFont)
            .fixedSize()
            .frame(width: 90, alignment: .leading)
            .background(Self.amber)
        }

        Text("aspectRatio on any element: fit, then fill")
          .font(Self.captionFont)
          .foregroundColor(Self.captionColor)
        HStack(spacing: 12) {
          Rectangle(Self.purple)
            .aspectRatio(2, contentMode: .fit)
            .frame(width: 100, height: 70)
            .background(Self.grey)
          Rectangle(Self.purple)
            .aspectRatio(2, contentMode: .fill)
            .frame(width: 100, height: 70)
            .clipped()
            .background(Self.grey)
        }

        Text("position: centred on a point")
          .font(Self.captionFont)
          .foregroundColor(Self.captionColor)
        Text("move")
          .font(Self.buttonFont)
          .foregroundColor(.white)
          .padding(Self.buttonInset)
          .background(Self.buttonColor)
          .onTap { _ in self.dotX = self.dotX > 100 ? 20 : self.dotX + 60 }
        Rectangle(Self.green)
          .frame(width: 16, height: 16)
          .position(x: self.dotX, y: 20)
          .animation(Self.animation, value: self.dotX)
          .frame(width: 220, height: 40)
          .background(Self.grey)

        Text("Divider, and padding on some edges")
          .font(Self.captionFont)
          .foregroundColor(Self.captionColor)
        VStack(alignment: .leading) {
          Text("horizontal 24")
            .font(Self.bodyFont)
            .padding(.horizontal, 24)
            .background(Self.amber)
          Divider()
          HStack {
            Text("top 12")
              .font(Self.bodyFont)
              .padding(.top, 12)
              .background(Self.amber)
            Divider()
            Text("default 16")
              .font(Self.bodyFont)
              .padding()
              .background(Self.amber)
          }
          // As in SwiftUI, a divider in an HStack takes all the height it is offered.
          .fixedSize(horizontal: false, vertical: true)
        }
        .frame(width: 220)
        .background(Self.grey)
      }
    }
  }
}
