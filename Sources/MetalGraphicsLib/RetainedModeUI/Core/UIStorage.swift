import Foundation

/// Values that outlive the element tree: a component reads its initial `@State` from here and
/// writes back when it changes, so it reopens where it was after the tree is rebuilt — by a hot
/// reload, or by a relaunch (it is backed by `UserDefaults`).
///
///     @State var selected: Tab = UIStorage.value("Tabs.selected", default: .home)
///     func select(_ tab: Tab) { self.selected = tab; UIStorage.set(tab, for: "Tabs.selected") }
///
/// One value per key for the whole app. For a value each window keeps for itself, like SwiftUI's
/// `@SceneStorage`, use the window's `UISceneStorage` (`WindowScene.storage`); it writes here
/// too, so this holds the value last used in any window.
///
/// Read once per component creation and written on user actions — never per frame.
public enum UIStorage {
  private static let prefix = "UIStorage."
  /// Swapped for a private suite by tests.
  nonisolated(unsafe) static var defaults: UserDefaults = .standard

  public static func value<T: RawRepresentable>(_ key: String, default value: T) -> T where T.RawValue == String {
    self.defaults.string(forKey: prefix + key).flatMap(T.init(rawValue:)) ?? value
  }

  public static func set<T: RawRepresentable>(_ value: T, for key: String) where T.RawValue == String {
    self.defaults.set(value.rawValue, forKey: prefix + key)
  }
}

/// One window's storage, like SwiftUI's `@SceneStorage`: each window reopens on its own values
/// after a hot reload or a relaunch, and a new window starts from the values last used in any.
///
///     @State var selected: Tab
///     init(scene: WindowScene) {
///       self.selected = scene.storage.value("Tabs.selected", default: .home)
///     }
///     func select(_ tab: Tab) { self.selected = tab; self.scene.storage.set(tab, for: "Tabs.selected") }
///
/// The values are kept as one JSON string that `persist` hands to the window's `@SceneStorage`,
/// which SwiftUI saves and restores with the window. Read once per component creation and
/// written on user actions — never per frame.
///
/// Like the rest of a window's tree, it belongs to the window's thread; `persist` is called on
/// it, and hops to the main thread for SwiftUI.
public final class UISceneStorage {
  private var values: [String: String]
  private let persist: (@Sendable (String) -> Void)?
  /// While set, changes are kept but not persisted: set while the window's first tree is built.
  /// What it saves then are the fallback values, and SwiftUI may not have restored the window's
  /// own yet: persisting them would race the restore and could replace the restored values.
  var holdsChanges = false

  /// Whether a value this store lacks falls back to the one last set in any window, and a value
  /// set here becomes that. True for a window's scene storage; false for a dock panel's, whose
  /// values are its own: a new notes panel must not open with another one's text.
  private let sharesLastUsed: Bool

  /// `encoded`: what `encoded` returned in an earlier session, or "" for a new window.
  public init(restoring encoded: String = "", persist: (@Sendable (String) -> Void)? = nil, sharesLastUsed: Bool = true) {
    self.values = Self.decode(encoded)
    self.persist = persist
    self.sharesLastUsed = sharesLastUsed
  }

  /// Replaces every value with those `encoded` holds, without persisting them: they came from
  /// the persisted store. For values restored after the tree was built from the fallbacks.
  func restore(from encoded: String) {
    self.values = Self.decode(encoded)
  }

  private static func decode(_ encoded: String) -> [String: String] {
    guard !encoded.isEmpty else { return [:] }
    return (try? JSONDecoder().decode([String: String].self, from: Data(encoded.utf8))) ?? [:]
  }

  /// This store's value; else, when it shares them, the value last set in any window; else `value`.
  public func value<T: RawRepresentable>(_ key: String, default value: T) -> T where T.RawValue == String {
    if let raw = self.values[key], let stored = T(rawValue: raw) {
      return stored
    }
    return self.sharesLastUsed ? UIStorage.value(key, default: value) : value
  }

  public func set<T: RawRepresentable>(_ value: T, for key: String) where T.RawValue == String {
    if self.sharesLastUsed {
      UIStorage.set(value, for: key)
    }
    guard self.values[key] != value.rawValue else { return }
    self.values[key] = value.rawValue
    if !self.holdsChanges {
      self.persist?(self.encoded)
    }
  }

  /// Every value, as the JSON string `init(restoring:)` reads.
  public var encoded: String {
    let encoder = JSONEncoder()
    encoder.outputFormatting = .sortedKeys
    guard let data = try? encoder.encode(self.values) else { return "" }
    return String(decoding: data, as: UTF8.self)
  }
}
