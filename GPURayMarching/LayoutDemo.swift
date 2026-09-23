import MetalGraphicsLib
import ReactiveUI

// Walks through the layout elements a body can use. Each button cycles one argument through its
// reactive setter (`setAlignment`, `setSpacing`, `setSize`, `setInset`, `setAxis`), so the layout
// changes in place and the button reads the new value back.
//
// Grey backgrounds show a container's own bounds: the space it was given, or the size it took.
@Component
final class LayoutDemo : SingleChildElement {
  private static let captionFont = TextFont.system(size: 12)
  private static let captionColor = float4(0.45, 0.45, 0.45, 1)
  private static let buttonFont = TextFont.system(size: 13)
  private static let labelFont = TextFont.system(size: 13)
  private static let buttonInset = Inset(vertical: 4, horizontal: 8)
  private static let buttonColor = float4(0.25, 0.25, 0.25, 1)
  private static let grey = float4(0.9, 0.9, 0.9, 1)
  private static let amber = float4(0.85, 0.6, 0.1, 1)
  private static let purple = float4(0.6, 0.3, 0.9, 1)
  private static let lightBlue = float4(0.7, 0.82, 1, 1)

  // Settings are indices into these tables, which keeps each value and its name together.
  private static let horizontalAlignments: [(name: String, value: HorizontalAlignment)] = [
    ("leading", .leading), ("center", .center), ("trailing", .trailing),
  ]
  private static let verticalAlignments: [(name: String, value: VerticalAlignment)] = [
    ("top", .top), ("center", .center), ("bottom", .bottom),
  ]
  private static let spacings: [Float] = [0, 8, 24]
  private static let alignments: [(name: String, value: Alignment)] = [
    ("topLeading", .topLeading), ("top", .top), ("topTrailing", .topTrailing),
    ("leading", .leading), ("center", .center), ("trailing", .trailing),
    ("bottomLeading", .bottomLeading), ("bottom", .bottom), ("bottomTrailing", .bottomTrailing),
  ]
  private static let frameSizes: [float2] = [float2(120, 60), float2(200, 60), float2(200, 100)]
  private static let insets: [Float] = [0, 8, 20]
  private static let axes: [(name: String, value: Axis)] = [
    ("none", .none), ("horizontal", .horizontal), ("vertical", .vertical), ("both", .both),
  ]

  @State var vStackAlignment: Int = 0
  @State var hStackAlignment: Int = 1
  @State var spacing: Int = 1
  @State var frameAlignment: Int = 0
  @State var frameSize: Int = 0
  @State var inset: Int = 1
  @State var axis: Int = 0

  @UIElementBuilder var body: [UIElement] {
    HStack(alignment: .top, spacing: 40) {
      VStack(alignment: .leading, spacing: 8) {
        // Children are placed within the widest child; the stack is only as wide as that.
        Text("VStack: alignment and spacing")
          .font(Self.captionFont)
          .foregroundColor(Self.captionColor)
        HStack(spacing: 6) {
          Text("alignment: \(Self.horizontalAlignments[self.vStackAlignment].name)")
            .font(Self.buttonFont)
            .foregroundColor(.white)
            .padding(Self.buttonInset)
            .background(Self.buttonColor)
            .onTap { _ in self.cycleVStackAlignment() }
          Text("spacing: \(Int(Self.spacings[self.spacing]))")
            .font(Self.buttonFont)
            .foregroundColor(.white)
            .padding(Self.buttonInset)
            .background(Self.buttonColor)
            .onTap { _ in self.cycleSpacing() }
        }
        VStack(alignment: Self.horizontalAlignments[self.vStackAlignment].value, spacing: Self.spacings[self.spacing]) {
          Rectangle(.red).frame(width: 40, height: 16)
          Rectangle(.green).frame(width: 110, height: 16)
          Rectangle(.blue).frame(width: 70, height: 16)
        }
        .padding(Inset(all: 6))
        .background(Self.grey)

        // The same spacing state drives both stacks.
        Text("HStack: alignment and spacing")
          .font(Self.captionFont)
          .foregroundColor(Self.captionColor)
        Text("alignment: \(Self.verticalAlignments[self.hStackAlignment].name)")
          .font(Self.buttonFont)
          .foregroundColor(.white)
          .padding(Self.buttonInset)
          .background(Self.buttonColor)
          .onTap { _ in self.cycleHStackAlignment() }
        HStack(alignment: Self.verticalAlignments[self.hStackAlignment].value, spacing: Self.spacings[self.spacing]) {
          Rectangle(.red).frame(width: 24, height: 20)
          Rectangle(.green).frame(width: 24, height: 56)
          Rectangle(.blue).frame(width: 24, height: 36)
        }
        .padding(Inset(all: 6))
        .background(Self.grey)

        // A spacer takes an equal share of what the stack was offered, so each row sits in a
        // fixed-width frame to give it something to divide.
        Text("Spacer: pushes apart, centres, shares equally")
          .font(Self.captionFont)
          .foregroundColor(Self.captionColor)
        Frame(float2(300, 24), .topLeading) {
          HStack {
            Text("A").font(Self.labelFont).foregroundColor(.white)
              .frame(width: 24, height: 24).background(.blue)
            Spacer()
            Text("B").font(Self.labelFont).foregroundColor(.white)
              .frame(width: 24, height: 24).background(.blue)
          }
        }
        .background(Self.grey)
        Frame(float2(300, 24), .topLeading) {
          HStack {
            Spacer()
            Text("A").font(Self.labelFont).foregroundColor(.white)
              .frame(width: 24, height: 24).background(Self.purple)
            Spacer()
          }
        }
        .background(Self.grey)
        Frame(float2(300, 24), .topLeading) {
          HStack {
            Text("A").font(Self.labelFont).foregroundColor(.white)
              .frame(width: 24, height: 24).background(Self.amber)
            Spacer()
            Text("B").font(Self.labelFont).foregroundColor(.white)
              .frame(width: 24, height: 24).background(Self.amber)
            Spacer()
            Text("C").font(Self.labelFont).foregroundColor(.white)
              .frame(width: 24, height: 24).background(Self.amber)
          }
        }
        .background(Self.grey)
      }

      VStack(alignment: .leading, spacing: 8) {
        // A frame has a fixed size and places its child inside it.
        Text("Frame: alignment")
          .font(Self.captionFont)
          .foregroundColor(Self.captionColor)
        Text("alignment: \(Self.alignments[self.frameAlignment].name)")
          .font(Self.buttonFont)
          .foregroundColor(.white)
          .padding(Self.buttonInset)
          .background(Self.buttonColor)
          .onTap { _ in self.cycleFrameAlignment() }
        Frame(float2(180, 110), Self.alignments[self.frameAlignment].value) {
          Rectangle(.blue).frame(width: 36, height: 36)
        }
        .background(Self.grey)

        Text("Frame: size")
          .font(Self.captionFont)
          .foregroundColor(Self.captionColor)
        Text("size: \(Int(Self.frameSizes[self.frameSize].x))×\(Int(Self.frameSizes[self.frameSize].y))")
          .font(Self.buttonFont)
          .foregroundColor(.white)
          .padding(Self.buttonInset)
          .background(Self.buttonColor)
          .onTap { _ in self.cycleFrameSize() }
        Frame(Self.frameSizes[self.frameSize], .center) {
          Text("centred")
        }
        .background(Self.grey)

        // Padding shrinks the space offered to its child and grows the child's size by the inset.
        Text("Padding: uniform and per edge")
          .font(Self.captionFont)
          .foregroundColor(Self.captionColor)
        Text("inset: \(Int(Self.insets[self.inset]))")
          .font(Self.buttonFont)
          .foregroundColor(.white)
          .padding(Self.buttonInset)
          .background(Self.buttonColor)
          .onTap { _ in self.cycleInset() }
        HStack(alignment: .top, spacing: 12) {
          Text("padded")
            .font(Self.labelFont)
            .foregroundColor(.white)
            .padding(Inset(all: Self.insets[self.inset]))
            .background(Self.amber)
          Text("left 24, bottom 16")
            .font(Self.labelFont)
            .foregroundColor(.white)
            .padding(Inset(left: 24, top: 4, right: 4, bottom: 16))
            .background(Self.purple)
        }

        // An expanded frame takes all the offered space along its axis and only its content's
        // size across it. Light blue is the expanded frame; grey is the space it was offered.
        Text("ExpandedFrame: axis")
          .font(Self.captionFont)
          .foregroundColor(Self.captionColor)
        Text("axis: \(Self.axes[self.axis].name)")
          .font(Self.buttonFont)
          .foregroundColor(.white)
          .padding(Self.buttonInset)
          .background(Self.buttonColor)
          .onTap { _ in self.cycleAxis() }
        Frame(float2(220, 90), .topLeading) {
          ExpandedFrame(Self.axes[self.axis].value, .center) {
            Text("content")
              .font(Self.labelFont)
              .foregroundColor(.white)
              .padding(Inset(all: 6))
              .background(.blue)
          }
          .background(Self.lightBlue)
        }
        .background(Self.grey)
      }
    }
  }

  // MARK: - Actions

  func cycleVStackAlignment() {
    self.vStackAlignment = (self.vStackAlignment + 1) % Self.horizontalAlignments.count
  }

  func cycleHStackAlignment() {
    self.hStackAlignment = (self.hStackAlignment + 1) % Self.verticalAlignments.count
  }

  func cycleSpacing() {
    self.spacing = (self.spacing + 1) % Self.spacings.count
  }

  func cycleFrameAlignment() {
    self.frameAlignment = (self.frameAlignment + 1) % Self.alignments.count
  }

  func cycleFrameSize() {
    self.frameSize = (self.frameSize + 1) % Self.frameSizes.count
  }

  func cycleInset() {
    self.inset = (self.inset + 1) % Self.insets.count
  }

  func cycleAxis() {
    self.axis = (self.axis + 1) % Self.axes.count
  }
}
