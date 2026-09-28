import MetalGraphicsLib
import simd

/// A component's docs: what it is, where it lives, its props, and each story in light and dark
/// with the Swift that makes it.
final class DocsPage : SingleChildElement {
  static let titleFont = TextFont.system(size: 22, weight: .bold)
  static let headingFont = TextFont.system(size: 13, weight: .semibold)
  static let bodyFont = TextFont.system(size: 13)
  static let smallFont = TextFont.system(size: 11)
  static let codeFont = TextFont.system(size: 11.5, design: .monospaced)
  static let codeShape = UIShape.rect(cornerRadius: 6)
  static let cardShape = UIShape.rect(cornerRadius: 10)

  init(component: ComponentStories) {
    super.init()
    let context = StoryContext(model: .shared)
    var sections: [UIElement] = [
      Text(component.name).font(Self.titleFont),
      Text(component.summary).font(Self.bodyFont).foregroundColor(.secondaryLabel),
      HStack(spacing: 6) {
        Text(component.group.rawValue).font(Self.smallFont).foregroundColor(.secondaryLabel)
        Text("·").font(Self.smallFont).foregroundColor(.tertiaryLabel)
        Text(component.source).font(Self.codeFont).foregroundColor(.secondaryLabel)
      },
    ]
    if !component.argTypes.isEmpty {
      sections.append(Text("Props").font(Self.headingFont).padding(Inset(top: 8)))
      sections.append(Self.propsTable(component.argTypes))
    }
    sections.append(Text("Stories").font(Self.headingFont).padding(Inset(top: 8)))
    for story in component.stories {
      let args = component.args(for: story)
      sections.append(Text(story.name).font(Self.bodyFont.weight(.medium)))
      sections.append(
        HStack(spacing: 0) {
          Self.sample(component.render(args, context), story).background(.contentBackground).colorScheme(.light)
          Rectangle(.separator).frame(width: 0.5)
          Self.sample(component.render(args, context), story).background(.contentBackground).colorScheme(.dark)
        }
        .clipShape(Self.cardShape)
        .border(.separator, width: 0.5, in: Self.cardShape)
      )
      sections.append(
        Text(component.snippet(args))
          .font(Self.codeFont)
          .padding(10)
          .frame(maxWidth: .infinity, alignment: .leading)
          .background(.fill, in: Self.codeShape)
      )
    }
    let column = VStack(alignment: .leading, spacing: 10) { () -> [UIElement] in return sections }
    self.child = ScrollView(.vertical) {
        column
          .padding(Inset(vertical: 28, horizontal: 32))
          .frame(maxWidth: 900, alignment: .topLeading)
          .frame(maxWidth: .infinity, alignment: .top)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .background(.contentBackground)
  }

  /// A story on half a card: centred, with room round it, not interactive.
  private static func sample(_ element: UIElement, _ story: Story) -> UIElement {
    element
      .allowsHitTesting(false)
      .padding(20)
      .frame(maxWidth: .infinity, minHeight: 80, alignment: story.layout == .centered ? .center : .topLeading)
  }

  private static func propsTable(_ args: [ArgType]) -> UIElement {
    var content: [UIElement] = [
      Self.row("Name", "Type", "Default", "Description", header: true),
    ]
    for arg in args {
      content.append(Rectangle(.separator).frame(height: 0.5))
      content.append(Self.row(arg.name, arg.typeName, arg.defaultValue.display, arg.summary, header: false))
    }
    return VStack(alignment: .leading, spacing: 0) { () -> [UIElement] in return content }
      .background(.card, in: Self.cardShape)
      .border(.separator, width: 0.5, in: Self.cardShape)
  }

  private static func row(_ name: String, _ type: String, _ value: String, _ summary: String, header: Bool) -> UIElement {
    let color: float4 = header ? .secondaryLabel : .label
    let font = header ? Self.smallFont.weight(.semibold) : Self.smallFont
    return HStack(alignment: .top, spacing: 12) {
      Text(name).font(header ? font : Self.codeFont).foregroundColor(color).frame(width: 130, alignment: .leading)
      Text(type).font(header ? font : Self.codeFont).foregroundColor(header ? color : .secondaryLabel).frame(width: 170, alignment: .leading)
      Text(value).font(header ? font : Self.codeFont).foregroundColor(header ? color : .secondaryLabel).lineLimit(1)
        .frame(width: 120, alignment: .leading)
      Text(summary).font(font).foregroundColor(color).frame(maxWidth: .infinity, alignment: .leading)
    }
    .padding(Inset(vertical: 7, horizontal: 12))
  }
}
