import simd

/// Draws everything under it with another theme than its window's: a dark card in a light window,
/// light and dark side by side. Made by `.colorScheme(_:)` or `.theme(_:)`.
///
/// Colours are resolved as they are drawn (`Graphics2D.resolve`), so the render loop only hands
/// the renderer this theme for what is under it (`UIContext.collect`); nothing is rebuilt when it
/// changes. Popovers shown from inside it take it too. What it cannot change:
///
/// - What is read from `Theme.current` while a tree is built — type, metrics — is the window's,
///   so a scope's theme should share its window theme's typography. Light and dark do.
/// - A presentation in a window of its own (`WindowPresentation`) draws with that window's theme.
///
/// Cost: none per frame for a window without scopes; with them, one comparison per drawn element
/// and a swap where a scope starts or ends.
public final class ThemeScopeElement : SingleChildElement, ThemeObserving {
  /// A theme given outright, or nil to take `appearance`'s from `ThemeStore.shared`.
  public private(set) var explicitTheme: Theme?
  /// Which of the store's themes, when `explicitTheme` is nil.
  public private(set) var appearance: Appearance
  /// The theme drawn with: kept up to date on mount and on every window theme change.
  public private(set) var theme: Theme
  /// This scope's index in its context's `themeOrder` since the last tree order, or -1.
  var collectIndex = -1

  public init(theme: Theme, @UIElementBuilder content: () -> [UIElement] = { [] }) {
    self.explicitTheme = theme
    self.appearance = theme === Theme.dark ? .dark : .light
    self.theme = theme
    super.init()
    self.applyContent(content())
  }

  public init(appearance: Appearance, @UIElementBuilder content: () -> [UIElement] = { [] }) {
    self.explicitTheme = nil
    self.appearance = appearance
    self.theme = ThemeStore.shared.theme(for: appearance)
    super.init()
    self.applyContent(content())
  }

  public override func debugHierarchy(_ offset: String) {
    print(offset + "ThemeScope(\(self.explicitTheme == nil ? "\(self.appearance)" : "theme"))")
    child?.debugHierarchy(offset + "  ")
  }

  /// The theme it stands for now: its own, or the store's for its appearance.
  func resolve() -> Theme {
    self.explicitTheme ?? ThemeStore.shared.theme(for: self.appearance)
  }

  public override func mount(_ context: UIContext) {
    self.theme = self.resolve()
    context.addThemeScope(self)
  }

  public override func unmount(_ context: UIContext) {
    context.removeThemeScope(self)
  }

  // The window's theme changed: the store's themes may have too.
  public func themeDidChange(_ theme: Theme, _ context: UIContext) {
    let resolved = self.resolve()
    guard resolved !== self.theme else { return }
    self.theme = resolved
    context.invalidate(.render)
  }

  /// Draws what is under it with `appearance`'s theme from the store.
  public func setAppearance(_ value: Appearance, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    guard self.explicitTheme != nil || value != self.appearance else { return }
    self.explicitTheme = nil
    self.appearance = value
    self.apply(self.resolve(), context)
  }

  /// Draws what is under it with `value`.
  public func setTheme(_ value: Theme, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    guard value !== self.explicitTheme else { return }
    self.explicitTheme = value
    self.apply(value, context)
  }

  private func apply(_ theme: Theme, _ context: UIContext) {
    guard theme !== self.theme else { return }
    let relayout = theme.typography != self.theme.typography
    self.theme = theme
    guard self.mounted else { return }
    context.invalidate(relayout ? .layout : .render)
    context.themeChanged(inside: self)
  }
}

public extension UIElement {
  /// Draws this element and everything in it light or dark, whatever its window shows: the
  /// store's theme for `appearance`, following `ThemeStore.setThemes`. See `ThemeScopeElement`.
  func colorScheme(_ appearance: Appearance) -> ThemeScopeElement {
    ThemeScopeElement(appearance: appearance) { self }
  }

  /// Draws this element and everything in it with `theme`. See `ThemeScopeElement`.
  func theme(_ theme: Theme) -> ThemeScopeElement {
    ThemeScopeElement(theme: theme) { self }
  }
}
