import Foundation
import simd
import Synchronization

/// How a tab group's tabs look: by the kind of the panel it shows.
public enum DockTabStyle: Sendable {
  /// Small pills on a 30 pt bar: a navigator, an outline, a console.
  case panel
  /// Larger pills on a 40 pt bar with a separator under it, each with its panel's icon and
  /// unsaved mark: an editor's documents.
  case document
}

/// A kind of panel the app offers: what makes one, on the thread of the window it is shown in.
public struct DockPanelKind: Sendable {
  public let id: String
  public let title: String
  /// What the panel's content is drawn on: the opaque `.contentBackground`, or `.sidebarTint`
  /// for a navigator or an outline, which lets a translucent window's desktop through.
  public let background: float4
  /// How the tabs of a group showing one look.
  public let tabStyle: DockTabStyle
  /// The icon on a document tab, and its colour, from the panel's title: shown before the
  /// panel is ever made, as for a tab behind another. `DockPanel.setIcon` overrides it.
  public let tabIcon: (@Sendable (String) -> (ThemeIcon, float4)?)?
  let make: @Sendable (DockPanel) -> UIElement

  public init(
    _ id: String, title: String, background: float4 = .contentBackground, tabStyle: DockTabStyle = .panel,
    tabIcon: (@Sendable (String) -> (ThemeIcon, float4)?)? = nil,
    make: @escaping @Sendable (DockPanel) -> UIElement
  ) {
    self.id = id
    self.title = title
    self.background = background
    self.tabStyle = tabStyle
    self.tabIcon = tabIcon
    self.make = make
  }
}

/// One panel as a window shows it, handed to its kind's `make`. Made again in each window the
/// panel moves to; what must survive the move goes in `storage` (or in a shared `@Model`).
public final class DockPanel {
  public let id: String
  public let kind: String
  public let space: DockSpace
  /// The panel's own values, like a window's scene storage: kept in the dock layout, so they
  /// follow the panel to every window and across relaunches. Values are not shared with other
  /// panels of the kind.
  public let storage: UISceneStorage

  init(id: String, kind: String, space: DockSpace, storage encoded: String) {
    self.id = id
    self.kind = kind
    self.space = space
    self.storage = UISceneStorage(
      restoring: encoded,
      persist: { [space] encoded in space.setStorage(encoded, ofPanel: id) },
      sharesLastUsed: false
    )
  }

  public var title: String {
    self.space.layout.panels[self.id]?.title ?? ""
  }

  public func setTitle(_ title: String) {
    self.space.setTitle(title, ofPanel: self.id)
  }

  /// Marks its tab as holding unsaved changes: a dot after the title, in a document tab.
  public func setEdited(_ edited: Bool) {
    self.space.decorate(panel: self.id) { $0.isEdited = edited }
  }

  /// A count on its tab, in a capsule after the title: a problems list's. 0 shows none.
  public func setBadge(_ count: Int) {
    self.space.decorate(panel: self.id) { $0.badge = max(count, 0) }
  }

  /// The icon before its title, in a document tab.
  public func setIcon(_ icon: ThemeIcon?, color: float4 = .secondaryLabel) {
    self.space.decorate(panel: self.id) {
      $0.icon = icon
      $0.iconColor = color
    }
  }

  public func close() {
    self.space.close(panel: self.id)
  }

  /// Asked, on the panel's window thread, when the user closes the panel by its tab: false keeps
  /// it open, and the panel asks the user itself (an unsaved document's alert). Closing its
  /// detached window, or `close()`, does not ask.
  public var shouldClose: (() -> Bool)?
}

/// What a dock area asks of the main thread, which owns the windows. See `DockWindows`.
public enum DockWindowRequest: Sendable {
  /// Detached host `host` was just made from a float being dragged out of its window: open its
  /// window under the pointer, `grab` from its content's top left, `size` large, and let the
  /// drag carry it.
  case tearOut(host: String, grab: float2, size: float2)
  /// Drag detached host `host`'s window, held `grab` from its view's top left.
  case drag(host: String, grab: float2)
  case close(host: String)
  case minimize(host: String)
  case zoom(host: String)
}

/// Panels docked across windows: the layout every window's `DockArea` shows its part of, the
/// kinds of panel there are, and who shows which host.
///
/// Shared by every window's thread, and the main thread, under one lock. A change is committed
/// here — a drop, a close, a sash let go — and reaches each window's areas on its next turn
/// (the writer's own at once), as a `@Model` write does. Nothing here is touched per frame: a
/// drag moves elements in its own window, and commits once, when it ends.
///
/// The layout is saved to `UserDefaults` (`UIStorage.defaults`) after each commit, and loaded
/// when the space is made.
public final class DockSpace: @unchecked Sendable {
  public let name: String
  private let kinds: [String: DockPanelKind]
  private let makeDefault: @Sendable () -> DockLayout
  private let persists: Bool

  private let lock = NSLock()
  private var current: DockLayout
  private var currentGeneration: UInt64 = 1

  /// Every window's areas, told of each change.
  let observers = ModelObservers()

  public init(
    name: String, kinds: [DockPanelKind], persists: Bool = true,
    defaultLayout: @escaping @Sendable () -> DockLayout
  ) {
    self.name = name
    self.kinds = Dictionary(kinds.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
    self.makeDefault = defaultLayout
    self.persists = persists
    var layout = (persists ? Self.load(name) : nil) ?? defaultLayout()
    layout.normalize()
    self.current = layout
    if persists {
      Self.registryLock.withLock { Self.saved.append(WeakSpace(self)) }
    }
  }

  public var layout: DockLayout {
    self.lock.withLock { self.current }
  }

  /// Moves on with every change. An area reconciles when it differs from the one it last built.
  public var generation: UInt64 {
    self.lock.withLock { self.currentGeneration }
  }

  func snapshot() -> (DockLayout, UInt64) {
    self.lock.withLock { (self.current, self.currentGeneration) }
  }

  public var panelKinds: [DockPanelKind] {
    self.kinds.values.sorted { $0.id < $1.id }
  }

  public func kind(_ id: String) -> DockPanelKind? {
    self.kinds[id]
  }

  // MARK: - Changes

  /// Applies `edit`; if it changed the layout, moves the generation on, tells every area and
  /// saves. `notifies: false` for what no area shows, such as a window's screen frame.
  @discardableResult
  private func commit<R>(notifies: Bool = true, _ edit: (inout DockLayout) -> R) -> R {
    let (result, changed): (R, Bool) = self.lock.withLock {
      var layout = self.current
      let result = edit(&layout)
      guard layout != self.current else { return (result, false) }
      self.current = layout
      self.currentGeneration &+= 1
      return (result, true)
    }
    guard changed else { return result }
    if notifies {
      self.observers.notify()
    }
    self.save()
    return result
  }

  /// Applies `edit` to the layout, then normalizes it: for what the other changes do not cover,
  /// such as placing new panels with `DockLayout.place`. Returns what `edit` did.
  @discardableResult
  public func update<R>(_ edit: (inout DockLayout) -> R) -> R {
    self.commit { layout in
      let result = edit(&layout)
      layout.normalize()
      return result
    }
  }

  /// See `DockLayout.move`.
  @discardableResult
  public func move(_ source: DockSource, to target: DockTarget) -> String? {
    self.commit { $0.move(source, to: target) }
  }

  public func close(panel: String) {
    self.commit { $0.close(panel: panel) }
  }

  public func close(host: String) {
    self.commit { $0.close(host: host) }
  }

  public func select(panel: String) {
    self.commit { $0.select(panel: panel) }
  }

  public func setFractions(_ fractions: [Float], of split: String) {
    self.commit { $0.setFractions(fractions, of: split) }
  }

  public func setFrame(_ frame: DockRect, ofFloat id: String) {
    self.commit { $0.setFrame(frame, ofFloat: id) }
  }

  public func setTitle(_ title: String, ofPanel id: String) {
    self.commit { $0.panels[id]?.title = title }
  }

  /// Changes what a panel's tab shows besides its title: see `DockPanel.setEdited`.
  func decorate(panel id: String, _ edit: (inout DockPanelInfo) -> Void) {
    self.commit { layout in
      guard var info = layout.panels[id] else { return }
      edit(&info)
      layout.panels[id] = info
    }
  }

  /// Switches how every detached window looks, at once.
  public func setWindowStyle(_ style: DockWindowStyle) {
    self.commit { $0.windowStyle = style }
  }

  /// Opens a new panel of `kind`, floating over host `host` at `frame`. Returns its id, or nil
  /// for a kind or host there is none of.
  @discardableResult
  public func open(kind: String, in host: String, at frame: DockRect) -> String? {
    guard let kind = self.kinds[kind] else { return nil }
    return self.commit { layout -> String? in
      guard layout.host(host) != nil else { return nil }
      let id = layout.addPanel(kind: kind.id, title: kind.title)
      layout.hosts[layout.hostIndex(host)!].floating.append(DockFloat(node: .group([id]), frame: frame))
      return id
    }
  }

  /// Back to the app's default layout: every panel as it was first placed, and their storage
  /// empty.
  public func reset() {
    let layout = self.makeDefault()
    self.commit { current in
      let style = current.windowStyle
      current = layout
      current.windowStyle = style
      current.normalize()
    }
  }

  /// A panel's storage changed. What it holds is the panel's alone to read, so no area is told.
  func setStorage(_ encoded: String, ofPanel id: String) {
    self.commit(notifies: false) { $0.panels[id]?.storage = encoded }
  }

  /// A detached host's window moved or was resized. Only `DockWindows` reads it.
  func setScreenFrame(_ frame: DockRect, ofHost id: String) {
    self.commit(notifies: false) { layout in
      guard let index = layout.hostIndex(id) else { return }
      layout.hosts[index].screenFrame = frame
    }
  }

  // MARK: - Saving

  private static let saveQueue = DispatchQueue(label: "DockSpace.save", qos: .utility)
  private let isSavePending = Atomic<Bool>(false)

  private var defaultsKey: String { "Dock.\(self.name)" }

  private static func load(_ name: String) -> DockLayout? {
    guard let data = UIStorage.defaults.data(forKey: "Dock.\(name)") else { return nil }
    return try? JSONDecoder().decode(DockLayout.self, from: data)
  }

  private static let registryLock = NSLock()
  nonisolated(unsafe) private static var saved: [WeakSpace] = []

  /// Writes every space's layout now, waiting for it: at quit, after the windows have unmounted
  /// their trees, whose panels save their last values as they go.
  static func saveAllNow() {
    let spaces = registryLock.withLock { saved.compactMap(\.space) }
    saveQueue.sync {}
    let defaults = UIStorage.defaults
    for space in spaces {
      guard let data = try? JSONEncoder().encode(space.layout) else { continue }
      defaults.set(data, forKey: space.defaultsKey)
    }
  }

  /// Writes the layout soon, once for a burst of changes.
  private func save() {
    guard self.persists, !self.isSavePending.exchange(true, ordering: .acquiringAndReleasing) else { return }
    // Read now: a test swaps the store, and a write landing after it put the old one back must
    // not reach the real one.
    nonisolated(unsafe) let defaults = UIStorage.defaults
    Self.saveQueue.async { [self] in
      // Cleared before reading, so a change racing the write saves again.
      self.isSavePending.store(false, ordering: .releasing)
      guard let data = try? JSONEncoder().encode(self.layout) else { return }
      defaults.set(data, forKey: self.defaultsKey)
    }
  }

  // MARK: - Areas and windows

  struct AreaEntry {
    let executor: ThreadExecutor
    weak var area: DockArea?
    /// The window the area is in, when it is in one.
    let window: WindowHandle?
  }

  private var areas: [String: AreaEntry] = [:]

  /// Set by `DockWindows` when it manages this space's windows: where areas send what they ask
  /// of the main thread, and what it is told when areas come and go.
  private var requestHandler: (@Sendable (DockWindowRequest) -> Void)?
  private var areasHandler: (@Sendable () -> Void)?

  func setWindowHandlers(
    requests: (@Sendable (DockWindowRequest) -> Void)?, areasChanged: (@Sendable () -> Void)?
  ) {
    self.lock.withLock {
      self.requestHandler = requests
      self.areasHandler = areasChanged
    }
  }

  /// Whether anything opens windows for detached hosts: without it, a float dragged out of its
  /// window stays in it.
  var managesWindows: Bool {
    self.lock.withLock { self.requestHandler != nil }
  }

  /// Asks the main thread for `request`. Returns false when nothing manages the windows.
  @discardableResult
  func request(_ request: DockWindowRequest) -> Bool {
    guard let handler = self.lock.withLock({ self.requestHandler }) else { return false }
    handler(request)
    return true
  }

  func register(_ area: DockArea, host: String, window: WindowHandle?) {
    let handler = self.lock.withLock {
      self.areas[host] = AreaEntry(executor: ThreadState.current.executor, area: area, window: window)
      return self.areasHandler
    }
    handler?()
  }

  func unregister(_ area: DockArea, host: String) {
    let handler = self.lock.withLock { () -> (@Sendable () -> Void)? in
      guard self.areas[host]?.area === area || self.areas[host]?.area == nil else { return nil }
      self.areas[host] = nil
      return self.areasHandler
    }
    handler?()
  }

  /// Which hosts are shown now, and in which window.
  func shownAreas() -> [(host: String, window: WindowHandle?)] {
    self.lock.withLock {
      self.areas.compactMap { host, entry in entry.area == nil ? nil : (host, entry.window) }
    }
  }

  /// Runs `body` with the area showing host `host`, on its window's thread; nothing when none
  /// does.
  func withArea(_ host: String, _ body: @escaping @Sendable (DockArea) -> Void) {
    guard let entry = self.lock.withLock({ self.areas[host] }) else { return }
    let area = WeakArea(entry.area)
    entry.executor.post {
      guard let area = area.area else { return }
      body(area)
    }
  }
}

private final class WeakSpace: @unchecked Sendable {
  weak var space: DockSpace?
  init(_ space: DockSpace) { self.space = space }
}

/// A weak reference to an area, to hand to its thread. Read only there.
private final class WeakArea: @unchecked Sendable {
  weak var area: DockArea?
  init(_ area: DockArea?) { self.area = area }
}
