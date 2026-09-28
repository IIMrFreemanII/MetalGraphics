import Foundation

/// The app's themes and which appearance is showing: shared by every window's thread and the
/// main thread, under one lock, like a `DockSpace`.
///
/// The main thread follows the system appearance (`AppearanceObserver`) and writes it here; each
/// window hears of it once, on its own thread, and swaps its `UIContext.theme` (see
/// `ThemeSubscriber`). Components can read it too, as a model:
///
///     @Bindable let themes: ThemeStore = .shared
///     ... .editorTheme(self.themes.theme.editor)
///
/// Nothing here is touched per frame.
public final class ThemeStore: @unchecked Sendable {
  public static let shared = ThemeStore()

  private let lock = NSLock()
  private var systemAppearance: Appearance = .light
  private var forcedAppearance: Appearance? = nil
  private var lightTheme: Theme = .light
  private var darkTheme: Theme = .dark

  /// Every reader, in every window. One list: all of it changes together.
  let observers = ModelObservers()

  public init() {}

  /// The appearance showing: the system's, unless `override` says otherwise.
  public var appearance: Appearance {
    self.lock.withLock { self.forcedAppearance ?? self.systemAppearance }
  }

  /// The theme showing.
  public var theme: Theme {
    self.lock.withLock {
      (self.forcedAppearance ?? self.systemAppearance) == .dark ? self.darkTheme : self.lightTheme
    }
  }

  /// The theme for `appearance`, whichever is showing: what a `.colorScheme(_:)` scope draws with.
  public func theme(for appearance: Appearance) -> Theme {
    self.lock.withLock { appearance == .dark ? self.darkTheme : self.lightTheme }
  }

  /// What the system appearance is now. Called by `AppearanceObserver` on the main thread.
  public func setSystemAppearance(_ appearance: Appearance) {
    self.update { $0.systemAppearance = appearance }
  }

  /// Shows `appearance` whatever the system's is, or follows the system again for nil: for a
  /// demo's or a setting's light/dark switch.
  public var appearanceOverride: Appearance? {
    get { self.lock.withLock { self.forcedAppearance } }
    set { self.update { $0.forcedAppearance = newValue } }
  }

  /// Replaces the built-in themes: an app's brand colours, say. See `Theme.with(_:)`.
  public func setThemes(light: Theme, dark: Theme) {
    self.update {
      $0.lightTheme = light
      $0.darkTheme = dark
    }
  }

  /// Changes the store under the lock, then tells every window if the theme showing changed.
  private func update(_ change: (ThemeStore) -> Void) {
    let changed: Bool = self.lock.withLock {
      let before = (self.forcedAppearance ?? self.systemAppearance) == .dark ? self.darkTheme : self.lightTheme
      change(self)
      let after = (self.forcedAppearance ?? self.systemAppearance) == .dark ? self.darkTheme : self.lightTheme
      return before !== after
    }
    if changed {
      self.observers.notify()
    }
  }

  /// For `@Bindable`: every property feeds the same readers.
  public func __observers(named name: String) -> ModelObservers {
    self.observers
  }
}
