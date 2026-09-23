/// A face and a size, for `Text.font(_:)`. Not `Font`, which would clash with SwiftUI's in a file
/// that imports both.
public struct TextFont {
  /// nil is `FontManager.shared.defaultFont`.
  public var font: SDFFont?
  public var size: Float

  public init(font: SDFFont?, size: Float) {
    self.font = font
    self.size = size
  }

  public static func system(size: Float) -> TextFont {
    TextFont(font: nil, size: size)
  }

  public static func custom(_ font: SDFFont, size: Float) -> TextFont {
    TextFont(font: font, size: size)
  }
}

public class Text : UIRenderableElement {
  public var text: String {
    didSet {
      if self.text != oldValue { self.layoutMaxSize = nil }
    }
  }
  /// Set by `.font(_:)`.
  public internal(set) var font: TextFont = .system(size: 16)
  /// Set by `.foregroundColor(_:)`.
  public internal(set) var color: float4 = .black

  /// What is drawn while color or size animate, nil when it is the model value itself.
  ///
  /// `font` and `color` are the model; these are the presentation. Text is shaped only at the
  /// model size — the one it animates to — and drawn scaled in between, so an animated size
  /// costs no shaping per frame. Its line breaks are the ones of the final size throughout.
  private var presentedColor: float4? = nil
  private var presentedFontSize: Float? = nil

  public var position: SIMD2<Float> = .init()
  public var size: SIMD2<Float> = .init()
  // Made by `calcSize` for the space layout offered, and drawn as is every frame.
  private var layout = TextLayout()
  // What `layout` was shaped for; `layoutMaxSize` is nil once the text changed. Shaping is the
  // expensive part of layout, and a relayout caused by anything else — a sibling's animated
  // size, say, or this text's own animated size — shapes the same thing again, so it reuses the
  // layout instead of reshaping.
  private var layoutMaxSize: float2? = nil
  private var layoutFontSize: Float = 0
  private var layoutFace: SDFFont? = nil

  public init(_ text: String) {
    self.text = text

    super.init()
  }

  // MARK: - Style

  private var displayedColor: float4 { self.presentedColor ?? self.color }
  private var displayedFontSize: Float { self.presentedFontSize ?? self.font.size }

  /// How much the drawn text is scaled from the layout it was shaped as.
  private var fontScale: Float {
    let size = self.font.size
    return size > 0 ? self.displayedFontSize / size : 1
  }

  /// Applies a change to `font` or `color`, animating color and size from what is drawn now.
  /// The one path `setFont` and `setForegroundColor` go through.
  func restyle(_ context: UIContext, _ animation: UIAnimation?, _ change: (Text) -> Void) {
    let color = self.displayedColor
    let fontSize = self.displayedFontSize
    let face = self.font.font
    change(self)

    guard face === self.font.font else {
      // One face's glyphs cannot morph into another's: snap, and let the layout change slide.
      context.animator.cancel(self, .color)
      context.animator.cancel(self, .fontSize)
      self.presentedColor = nil
      self.presentedFontSize = nil
      context.invalidate(.layout, animation: animation)
      return
    }

    // Hold what is drawn until the animator moves it; a plain write replaces it at once.
    self.presentedColor = color
    self.presentedFontSize = fontSize
    context.animator.set(self, .color, from: color, to: self.color, animation, context) { element, value, context in
      let text = unsafeDowncast(element, to: Text.self)
      let color = float4(packed: value)
      text.presentedColor = color == text.color ? nil : color
      context.invalidate()
    }
    context.animator.set(self, .fontSize, from: fontSize, to: self.font.size, animation, context) { element, value, context in
      let text = unsafeDowncast(element, to: Text.self)
      text.presentedFontSize = value.x == text.font.size ? nil : value.x
      context.invalidate(.layout)
    }
  }

  // MARK: - Element

  public override func mount(_ context: UIContext) {
    context.registerRenderableView(self)
  }

  public override func unmount(_ context: UIContext) {
    context.unregisterRenderableView(self)
  }

  public override func debugHierarchy(_ offset: String) {
    print(offset + "\(self)".split(separator: ".").last! + "(text: \"\(text)\", position: \(position), size: \(size))")
  }

  public override func getSize() -> float2 {
    self.size
  }

  public override func calcSize(_ availableSize: float2) -> float2 {
    let fontSize = self.font.size
    let face = self.font.font
    if self.layoutMaxSize != availableSize || self.layoutFontSize != fontSize || self.layoutFace !== face {
      let style = TextStyle(color: self.color, fontSize: fontSize, font: face)
      self.layout = layoutText(self.text, style: style, maxSize: availableSize)
      self.layoutMaxSize = availableSize
      self.layoutFontSize = fontSize
      self.layoutFace = face
    }
    self.size = self.layout.size * self.fontScale

    return self.size
  }

  public override func calcPosition(_ position: float2) {
    self.position = position
  }

  public override func render(_ renderer: Graphics2D, _ effect: EffectState) {
    guard effect.opacity > 0 else { return }
    var color = self.displayedColor
    color.w *= effect.opacity
    // origin -> top left
    renderer.draw(
      textLayout: self.layout, at: effect.apply(to: self.position) - renderer.size * 0.5,
      color: color, scale: effect.scale * self.fontScale
    )
  }

  // MARK: - Modifiers

  /// The face and size to draw in; 16pt in the default face when never set. Unlike most
  /// modifiers it wraps nothing: it sets this text's own font and returns it.
  public func font(_ font: TextFont) -> Self {
    self.font = font
    return self
  }

  /// The color to draw in; black when never set. Sets this text's own color and returns it.
  public func foregroundColor(_ color: float4) -> Self {
    self.color = color
    return self
  }
}
