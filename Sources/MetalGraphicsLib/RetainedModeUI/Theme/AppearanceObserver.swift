import AppKit

/// Follows the system appearance on the main thread and writes it to `ThemeStore.shared`, which
/// tells every window. Started with the first window.
@MainActor enum AppearanceObserver {
  private static var observation: NSKeyValueObservation?

  static func startIfNeeded() {
    guard self.observation == nil, let app = NSApp else { return }
    ThemeStore.shared.setSystemAppearance(Self.appearance(of: app.effectiveAppearance))
    self.observation = app.observe(\.effectiveAppearance, options: [.new]) { app, _ in
      MainActor.assumeIsolated {
        ThemeStore.shared.setSystemAppearance(Self.appearance(of: app.effectiveAppearance))
      }
    }
  }

  static func appearance(of appearance: NSAppearance) -> Appearance {
    appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua ? .dark : .light
  }
}

/// A window's ear for `ThemeStore.shared`: on its window's thread, swaps the context's theme for
/// the one showing. Subscribed before the window's tree is built, so it hears a change before
/// any component of the tree does.
final class ThemeSubscriber : UIElement {
  private unowned let context: UIContext

  init(context: UIContext) {
    self.context = context
    super.init()
    ThemeStore.shared.observers.add(self, token: 0)
  }

  func stop() {
    ThemeStore.shared.observers.remove(self)
  }

  override func __modelDidChange(_ token: Int, _ animated: Bool) {
    self.context.setTheme(ThemeStore.shared.theme)
  }
}
