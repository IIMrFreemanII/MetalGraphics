import Foundation

/// Values that outlive the element tree, like SwiftUI's `@SceneStorage`: a component reads its
/// initial `@State` from here and writes back when it changes, so it reopens where it was after
/// the tree is rebuilt — by a hot reload, or by a relaunch (it is backed by `UserDefaults`).
///
///     @State var selected: Tab = UIStorage.value("Tabs.selected", default: .home)
///     func select(_ tab: Tab) { self.selected = tab; UIStorage.set(tab, for: "Tabs.selected") }
///
/// Read once per component creation and written on user actions — never per frame.
public enum UIStorage {
  private static let prefix = "UIStorage."

  public static func value<T: RawRepresentable>(_ key: String, default value: T) -> T where T.RawValue == String {
    UserDefaults.standard.string(forKey: prefix + key).flatMap(T.init(rawValue:)) ?? value
  }

  public static func set<T: RawRepresentable>(_ value: T, for key: String) where T.RawValue == String {
    UserDefaults.standard.set(value.rawValue, forKey: prefix + key)
  }
}
