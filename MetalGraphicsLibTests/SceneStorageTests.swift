@testable import MetalGraphicsLib
import XCTest

private enum Tab: String {
  case home, text, windows
}

@MainActor
final class SceneStorageTests: XCTestCase {
  private var saved: UserDefaults!

  override func setUp() {
    super.setUp()
    self.saved = UIStorage.defaults
    UIStorage.defaults = UserDefaults(suiteName: "SceneStorageTests.\(UUID().uuidString)")!
  }

  override func tearDown() {
    UIStorage.defaults = self.saved
    super.tearDown()
  }

  func testFallsBackToLastUsedThenDefault() {
    let storage = UISceneStorage()
    XCTAssertEqual(storage.value("tab", default: Tab.home), .home)

    UIStorage.set(Tab.text, for: "tab")
    XCTAssertEqual(storage.value("tab", default: Tab.home), .text)

    storage.set(Tab.windows, for: "tab")
    UIStorage.set(Tab.text, for: "tab")
    XCTAssertEqual(storage.value("tab", default: Tab.home), .windows)
  }

  func testSetWritesBothLevelsAndPersistsOnlyChanges() {
    let persisted = Persisted()
    let storage = UISceneStorage { persisted.values.append($0) }

    storage.set(Tab.text, for: "tab")
    storage.set(Tab.text, for: "tab")

    XCTAssertEqual(UIStorage.value("tab", default: Tab.home), .text)
    XCTAssertEqual(persisted.values, [#"{"tab":"text"}"#])
  }

  /// While the first tree is built, a set keeps its value without persisting it.
  func testHeldChangesAreKeptButNotPersisted() {
    let persisted = Persisted()
    let storage = UISceneStorage { persisted.values.append($0) }
    storage.holdsChanges = true
    storage.set(Tab.text, for: "tab")
    storage.holdsChanges = false

    XCTAssertEqual(storage.value("tab", default: Tab.home), .text)
    XCTAssertEqual(persisted.values, [])
  }

  func testRestoresWhatItPersisted() {
    let first = UISceneStorage()
    first.set(Tab.windows, for: "tab")
    UIStorage.set(Tab.home, for: "tab")

    let restored = UISceneStorage(restoring: first.encoded)
    XCTAssertEqual(restored.value("tab", default: Tab.text), .windows)
  }

  func testWindowsKeepTheirOwnValues() {
    let a = UISceneStorage()
    let b = UISceneStorage()
    a.set(Tab.text, for: "tab")
    b.set(Tab.windows, for: "tab")

    XCTAssertEqual(a.value("tab", default: Tab.home), .text)
    XCTAssertEqual(b.value("tab", default: Tab.home), .windows)
  }

  func testLateRestoreReplacesValuesWithoutPersisting() {
    let persisted = Persisted()
    let storage = UISceneStorage { persisted.values.append($0) }
    storage.restore(from: #"{"tab":"windows"}"#)

    XCTAssertEqual(storage.value("tab", default: Tab.home), .windows)
    XCTAssertEqual(persisted.values, [])
  }
}

/// What a storage handed to `persist`, which is called on the window's thread.
private final class Persisted: @unchecked Sendable {
  var values: [String] = []
}
