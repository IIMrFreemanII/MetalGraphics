import simd

/// Styles every `Text` under it, as SwiftUI's environment does: what `.font`, `.bold`,
/// `.lineLimit` and the other text modifiers make when called on anything but a `Text`.
///
/// A text's own modifiers win over it, and a nearer `TextStyleElement` over a farther one.
/// `defaults` are weaker still: they apply only where nothing around this element set the same
/// field. A control styles its label with them, so a font set around the control reaches the
/// label too.
///
/// Font and paragraph style reach the texts during layout (`TextScope`); the colour at render
/// time, so changing or animating it only redraws.
public class TextStyleElement : SingleChildElement {
  public internal(set) var overrides: TextEnvironment {
    didSet { self.scopeOverrides = self.overrides.withoutForeground }
  }
  public internal(set) var defaults: TextEnvironment

  /// `overrides` without the colour, which does not go through layout.
  private var scopeOverrides: TextEnvironment
  /// The colour drawn while it animates, nil when it is `overrides.foreground` itself.
  private var presentedForeground: float4? = nil

  /// The colour its texts draw in, if it sets one.
  var displayedForeground: float4? { self.presentedForeground ?? self.overrides.foreground }

  public init(
    overrides: TextEnvironment = TextEnvironment(), defaults: TextEnvironment = TextEnvironment(),
    @UIElementBuilder content: () -> [UIElement] = { [] }
  ) {
    self.overrides = overrides
    self.defaults = defaults
    self.scopeOverrides = overrides.withoutForeground
    super.init()

    self.applyContent(content())
  }

  public override func debugHierarchy(_ offset: String) {
    print(offset + "TextStyleElement(overrides: \(self.overrides), defaults: \(self.defaults))")
    child?.debugHierarchy(offset + "  ")
  }

  // MARK: - Layout

  private var scope: TextEnvironment {
    let outer = TextScope.current
    return self.defaults.overriding(outer).overriding(self.scopeOverrides)
  }

  public override func sizeThatFits(_ proposal: ProposedSize) -> float2 {
    TextScope.with(self.scope) { super.sizeThatFits(proposal) }
  }

  public override func calcSize(_ proposal: ProposedSize) -> float2 {
    TextScope.with(self.scope) { super.calcSize(proposal) }
  }

  public override func guideValue(_ key: AlignmentKey, _ proposal: ProposedSize, _ size: float2) -> Float? {
    TextScope.with(self.scope) { super.guideValue(key, proposal, size) }
  }

  public override func calcPosition(_ position: float2) {
    TextScope.with(self.scope) { super.calcPosition(position) }
  }

  // MARK: - Setters

  /// Changes a field of `overrides` that layout shows. Skipped when nothing changes.
  func restyleLayout<V: Equatable>(
    _ key: WritableKeyPath<TextEnvironment, V>, _ value: V, _ context: UIContext, _ animation: UIAnimation?
  ) {
    guard self.overrides[keyPath: key] != value else { return }
    self.overrides[keyPath: key] = value
    context.invalidate(.layout, animation: animation)
  }

  /// Changes the colour its texts draw in, animating from what is drawn now. Only redraws,
  /// unless it sets a colour where there was none, or stops setting one: then which texts it
  /// colours changes, and the tree order is rebuilt once.
  public func setForegroundColor(_ value: float4?, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    let old = self.displayedForeground
    guard let value, let old else {
      context.animator.cancel(self, .color)
      self.presentedForeground = nil
      if self.overrides.foreground != value {
        self.overrides.foreground = value
        context.invalidate([.render, .treeOrder])
      }
      return
    }
    self.overrides.foreground = value
    self.presentedForeground = old
    context.animator.set(self, .color, from: old, to: value, animation, context) { element, value, context in
      let style = unsafeDowncast(element, to: TextStyleElement.self)
      let color = float4(packed: value)
      style.presentedForeground = color == style.overrides.foreground ? nil : color
      context.invalidate()
    }
  }

  // MARK: - Modifiers
  //
  // Another text modifier on it adds to its style rather than wrapping it again. It sits
  // farther out than the ones before it in the chain, so it only fills what they left unset:
  // `.font(.title).font(.body)` stays `.title`, as in SwiftUI.

  public func font(_ font: TextFont?) -> Self { self.applyStyle(TextEnvironment().font(font)) }
  public func fontWeight(_ weight: TextFont.Weight?) -> Self { self.applyStyle(TextEnvironment().fontWeight(weight)) }
  public func fontDesign(_ design: TextFont.Design?) -> Self { self.applyStyle(TextEnvironment().fontDesign(design)) }
  public func bold(_ isActive: Bool = true) -> Self { self.applyStyle(TextEnvironment().bold(isActive)) }
  public func italic(_ isActive: Bool = true) -> Self { self.applyStyle(TextEnvironment().italic(isActive)) }
  public func monospaced(_ isActive: Bool = true) -> Self { self.applyStyle(TextEnvironment().monospaced(isActive)) }
  public func monospacedDigit() -> Self { self.applyStyle(TextEnvironment().monospacedDigit()) }
  public func foregroundColor(_ color: float4) -> Self { self.applyStyle(TextEnvironment().foregroundColor(color)) }
  public func foregroundStyle(_ color: float4) -> Self { self.foregroundColor(color) }

  public func underline(_ isActive: Bool = true, color: float4? = nil) -> Self {
    self.applyStyle(TextEnvironment().underline(isActive, color: color))
  }

  public func strikethrough(_ isActive: Bool = true, color: float4? = nil) -> Self {
    self.applyStyle(TextEnvironment().strikethrough(isActive, color: color))
  }

  public func kerning(_ kerning: Float) -> Self { self.applyStyle(TextEnvironment().kerning(kerning)) }
  public func tracking(_ tracking: Float) -> Self { self.applyStyle(TextEnvironment().tracking(tracking)) }
  public func baselineOffset(_ offset: Float) -> Self { self.applyStyle(TextEnvironment().baselineOffset(offset)) }
  public func lineLimit(_ limit: Int?) -> Self { self.applyStyle(TextEnvironment().lineLimit(limit)) }
  public func multilineTextAlignment(_ alignment: TextAlignment) -> Self {
    self.applyStyle(TextEnvironment().multilineTextAlignment(alignment))
  }
  public func truncationMode(_ mode: TextTruncationMode) -> Self { self.applyStyle(TextEnvironment().truncationMode(mode)) }
  public func lineSpacing(_ spacing: Float) -> Self { self.applyStyle(TextEnvironment().lineSpacing(spacing)) }
  public func minimumScaleFactor(_ factor: Float) -> Self { self.applyStyle(TextEnvironment().minimumScaleFactor(factor)) }
  public func textCase(_ textCase: TextCase?) -> Self { self.applyStyle(TextEnvironment().textCase(textCase)) }

  /// Adds `style` from farther out: it fills only the fields not set yet. What each modifier
  /// above does, and what the macro makes of a chain of them with constant arguments.
  public func applyStyle(_ style: TextEnvironment) -> Self {
    self.overrides = self.overrides.filling(style)
    return self
  }
}

// On anything but a `Text` or a `TextStyleElement`, the text modifiers wrap it in a
// `TextStyleElement` that its texts inherit from. The two classes' own versions win overload
// resolution, since these live in a protocol extension.
extension UIElementWrapping where Self: UIElement {
  private func styled(_ style: TextEnvironment) -> TextStyleElement {
    TextStyleElement(overrides: style) { self }
  }

  public func font(_ font: TextFont?) -> TextStyleElement { self.styled(TextEnvironment().font(font)) }
  public func fontWeight(_ weight: TextFont.Weight?) -> TextStyleElement { self.styled(TextEnvironment().fontWeight(weight)) }
  public func fontDesign(_ design: TextFont.Design?) -> TextStyleElement { self.styled(TextEnvironment().fontDesign(design)) }
  public func bold(_ isActive: Bool = true) -> TextStyleElement { self.styled(TextEnvironment().bold(isActive)) }
  public func italic(_ isActive: Bool = true) -> TextStyleElement { self.styled(TextEnvironment().italic(isActive)) }
  public func monospaced(_ isActive: Bool = true) -> TextStyleElement { self.styled(TextEnvironment().monospaced(isActive)) }
  public func monospacedDigit() -> TextStyleElement { self.styled(TextEnvironment().monospacedDigit()) }
  public func foregroundColor(_ color: float4) -> TextStyleElement { self.styled(TextEnvironment().foregroundColor(color)) }
  public func foregroundStyle(_ color: float4) -> TextStyleElement { self.styled(TextEnvironment().foregroundColor(color)) }

  public func underline(_ isActive: Bool = true, color: float4? = nil) -> TextStyleElement {
    self.styled(TextEnvironment().underline(isActive, color: color))
  }

  public func strikethrough(_ isActive: Bool = true, color: float4? = nil) -> TextStyleElement {
    self.styled(TextEnvironment().strikethrough(isActive, color: color))
  }

  public func kerning(_ kerning: Float) -> TextStyleElement { self.styled(TextEnvironment().kerning(kerning)) }
  public func tracking(_ tracking: Float) -> TextStyleElement { self.styled(TextEnvironment().tracking(tracking)) }
  public func baselineOffset(_ offset: Float) -> TextStyleElement { self.styled(TextEnvironment().baselineOffset(offset)) }
  public func lineLimit(_ limit: Int?) -> TextStyleElement { self.styled(TextEnvironment().lineLimit(limit)) }
  public func multilineTextAlignment(_ alignment: TextAlignment) -> TextStyleElement {
    self.styled(TextEnvironment().multilineTextAlignment(alignment))
  }
  public func truncationMode(_ mode: TextTruncationMode) -> TextStyleElement { self.styled(TextEnvironment().truncationMode(mode)) }
  public func lineSpacing(_ spacing: Float) -> TextStyleElement { self.styled(TextEnvironment().lineSpacing(spacing)) }
  public func minimumScaleFactor(_ factor: Float) -> TextStyleElement { self.styled(TextEnvironment().minimumScaleFactor(factor)) }
  public func textCase(_ textCase: TextCase?) -> TextStyleElement { self.styled(TextEnvironment().textCase(textCase)) }
}
