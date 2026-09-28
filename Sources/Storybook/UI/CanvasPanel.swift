import MetalGraphicsLib
import simd

/// The canvas: the selected story drawn with its args, in the appearance, on the background, at
/// the width and the zoom the toolbar picks; or, in Docs mode, the component's docs page.
///
/// Built again when a story is picked or an arg is edited in Controls: one story's subtree, once
/// per edit. An arg the story writes back itself leaves it, as it shows it already.
final class CanvasPanel : ModelWatcher {
  override var watched: [String] { ["revision", "appearance", "background", "viewport", "zoom", "outline", "mode"] }

  override init() {
    super.init()
    self.child = self.make()
  }

  override func update(_ token: Int, _ context: UIContext) {
    if token > 0 { self.model.persistSettings() }
    self.show(self.make(), context)
  }

  private func make() -> UIElement {
    let catalog = StoryRegistry.catalog()
    guard let (component, story) = catalog.find(self.model.selection) else {
      return Text("Pick a story").foregroundColor(.secondaryLabel).frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    if self.model.mode == .docs {
      return DocsPage(component: component)
    }
    let args = StoryArgs(values: self.model.args)
    let context = StoryContext(model: self.model)
    switch self.model.appearance {
    case .window:
      return self.pane(component, story, args, context, appearance: nil)
    case .light:
      return self.pane(component, story, args, context, appearance: .light)
    case .dark:
      return self.pane(component, story, args, context, appearance: .dark)
    case .sideBySide:
      return HStack(spacing: 0) {
        self.pane(component, story, args, context, appearance: .light)
        Rectangle(.separator).frame(width: 0.5)
        self.pane(component, story, args, context, appearance: .dark)
      }
    }
  }

  /// The story on its background, laid out as it asks, in `appearance` or the window's.
  private func pane(_ component: ComponentStories, _ story: Story, _ args: StoryArgs, _ context: StoryContext, appearance: Appearance?) -> UIElement {
    let settings = CanvasSettings(model: self.model)
    let content = StoryFrame.make(component.render(args, context), layout: story.layout, settings: settings)
    let backed: UIElement = settings.background == .wallpaper
      ? ZStack {
          Image("wallpaper", bundle: .module).resizable().scaledToFill()
          content
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
      : content.background(settings.background.color)
    guard let appearance else { return backed }
    return backed.colorScheme(appearance)
  }
}

/// The toolbar's settings a story is framed with.
struct CanvasSettings {
  var background: CanvasBackground = .content
  var viewport: Viewport = .fit
  var zoom: Double = 1
  var outline: Bool = false

  init(background: CanvasBackground = .content, viewport: Viewport = .fit, zoom: Double = 1, outline: Bool = false) {
    self.background = background
    self.viewport = viewport
    self.zoom = zoom
    self.outline = outline
  }

  init(model: StorybookModel) {
    self.init(background: model.background, viewport: model.viewport, zoom: model.zoom, outline: model.outline)
  }
}

/// How a story is placed on a canvas or a docs page.
enum StoryFrame {
  static let margin: Float = 24
  /// The id the story itself is tagged with: where tests and the Inspector find it.
  static let storyID = "storybook.story"

  /// The story the canvas shows now, for the Inspector: on the window's thread.
  nonisolated(unsafe) static weak var shown: UIElement?

  static func make(_ story: UIElement, layout: StoryLayout, settings: CanvasSettings) -> UIElement {
    let tagged = IDElement(Self.storyID) { story }
    Self.shown = tagged
    var element: UIElement = tagged
    if let width = settings.viewport.width, layout != .fullscreen {
      element = element.frame(width: width, alignment: .topLeading)
    }
    if settings.outline {
      element = element.layoutOutline()
    }
    if settings.zoom != 1 {
      let zoomed = EffectElement { element }
      zoomed.scale = Float(settings.zoom)
      // Zoomed, it is drawn where it is not laid out, and would be hit where it is not seen.
      element = zoomed.allowsHitTesting(false)
    }
    switch layout {
    case .centered:
      return element
        .padding(Self.margin)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    case .padded:
      return ScrollView(.vertical) {
        element
          .padding(Self.margin)
          .frame(maxWidth: .infinity, alignment: .topLeading)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
    case .fullscreen:
      return element.frame(maxWidth: .infinity, maxHeight: .infinity)
    }
  }
}
