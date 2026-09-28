import Foundation
import MetalGraphicsLib
import ReactiveUI

/// Which theme the canvas draws the story in.
enum CanvasAppearance : String, CaseIterable, Sendable {
  /// The window's: follows the system, or the app's appearance menu.
  case window = "Auto"
  case light = "Light"
  case dark = "Dark"
  /// Light and dark, next to each other.
  case sideBySide = "Both"
}

/// What the canvas puts behind the story.
enum CanvasBackground : String, CaseIterable, Sendable {
  case content = "Content"
  case grouped = "Grouped"
  case window = "Window"
  case card = "Card"
  /// A picture under the story, for glass to blur.
  case wallpaper = "Wallpaper"

  var color: float4 {
    switch self {
    case .content: .contentBackground
    case .grouped: .groupedBackground
    case .window, .wallpaper: .windowBackground
    case .card: .card
    }
  }
}

/// How wide the story is laid out.
enum Viewport : String, CaseIterable, Sendable {
  case fit = "Fit"
  case w320 = "320"
  case w480 = "480"
  case w600 = "600"
  case w800 = "800"
  case w1024 = "1024"

  var width: Float? { Float(self.rawValue) }
}

/// The canvas or the component's docs page.
enum CanvasMode : String, CaseIterable, Sendable {
  case canvas = "Canvas"
  case docs = "Docs"
}

/// One callback a story made, as the Actions panel lists it.
struct ActionEntry : Identifiable, Hashable, Sendable {
  let id: Int
  let time: String
  let name: String
  let value: String
}

/// What the Storybook window shows: the story, its args, and the canvas's settings. One for the
/// app, read by the sidebar, the toolbar, the canvas and every addon panel. Written on user
/// actions, never per frame.
@Model
final class StorybookModel {
  static let shared = StorybookModel()

  /// The story shown.
  var selection: StoryID = StoryID(component: "Button", story: "Styles")
  /// Its args, as the Controls panel edits them.
  var args: [String: StoryValue] = [:]
  /// Moves on when the canvas must build the story again: another story, or an arg edited in
  /// Controls. An arg the story wrote back itself leaves it, as the canvas shows it already.
  var revision: Int = 0
  /// Moves on when the Controls panel must show new values: another story, or an arg the story
  /// wrote back. An arg edited in Controls leaves it, so the field typed in keeps its focus.
  var formRevision: Int = 0
  var appearance: CanvasAppearance = .window
  var background: CanvasBackground = .content
  var viewport: Viewport = .fit
  var zoom: Double = 1
  var outline: Bool = false
  var mode: CanvasMode = .canvas
  /// Newest first, at most `maxActions`.
  var actions: [ActionEntry] = []
  var search: String = ""
  /// The components whose stories the sidebar shows.
  var expanded: Set<String> = []

  static let maxActions = 200
  static let zooms: [Double] = [0.5, 0.75, 1, 1.25, 1.5, 2]

  @ModelIgnored private var nextAction = 0
  /// The window's storage, where the canvas settings and each story's edited args are kept.
  @ModelIgnored var storage: UISceneStorage?

  /// Shows `id`, with the args kept for it, or its defaults.
  func select(_ id: StoryID, in catalog: StoryCatalog) {
    guard let (component, story) = catalog.find(id) else { return }
    var args = component.args(for: story).values
    if let stored = self.storedArgs(for: id) {
      args.merge(stored) { _, kept in kept }
    }
    if self.selection != id { self.selection = id }
    self.args = args
    self.expanded.insert(id.component)
    self.revision += 1
    self.formRevision += 1
    self.storage?.set(id, for: Keys.selection)
  }

  /// Changes one arg. `rebuild: false` when the story wrote it back itself.
  func setArg(_ name: String, _ value: StoryValue, rebuild: Bool = true) {
    guard self.args[name] != value else { return }
    self.args[name] = value
    if rebuild { self.revision += 1 } else { self.formRevision += 1 }
    self.storeArgs()
  }

  /// Back to the story's own args.
  func resetArgs(in catalog: StoryCatalog) {
    self.storage?.set(StoredText(rawValue: ""), for: Keys.args(self.selection))
    guard let (component, story) = catalog.find(self.selection) else { return }
    self.args = component.args(for: story).values
    self.revision += 1
    self.formRevision += 1
  }

  func log(_ name: String, _ value: String) {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm:ss"
    let entry = ActionEntry(id: self.nextAction, time: formatter.string(from: Date()), name: name, value: value)
    self.nextAction += 1
    var actions = self.actions
    actions.insert(entry, at: 0)
    if actions.count > Self.maxActions { actions.removeLast(actions.count - Self.maxActions) }
    self.actions = actions
  }

  func clearActions() {
    self.actions = []
  }

  /// The story `offset` places after the one shown, in sidebar order, wrapping round.
  func selectNeighbour(_ offset: Int, in catalog: StoryCatalog) {
    let all = catalog.allStories
    guard !all.isEmpty else { return }
    let index = all.firstIndex(of: self.selection) ?? 0
    self.select(all[(index + offset + all.count) % all.count], in: catalog)
  }

  /// Auto, Light, Dark, Both, and round again.
  func cycleAppearance() {
    let all = CanvasAppearance.allCases
    let index = all.firstIndex(of: self.appearance) ?? 0
    self.setAppearance(all[(index + 1) % all.count])
  }

  /// One zoom step in or out.
  func stepZoom(_ direction: Int) {
    let index = Self.zooms.firstIndex { $0 >= self.zoom } ?? 2
    self.setZoom(Self.zooms[max(0, min(Self.zooms.count - 1, index + direction))])
  }

  // MARK: - Settings

  func setAppearance(_ value: CanvasAppearance) {
    self.appearance = value
    self.storage?.set(value, for: Keys.appearance)
  }

  func setBackground(_ value: CanvasBackground) {
    self.background = value
    self.storage?.set(value, for: Keys.background)
  }

  func setViewport(_ value: Viewport) {
    self.viewport = value
    self.storage?.set(value, for: Keys.viewport)
  }

  func setZoom(_ value: Double) {
    self.zoom = value
    self.storage?.set(StoredText(rawValue: "\(value)"), for: Keys.zoom)
  }

  func setOutline(_ value: Bool) {
    self.outline = value
    self.storage?.set(StoredText(rawValue: value ? "1" : ""), for: Keys.outline)
  }

  func setMode(_ value: CanvasMode) {
    self.mode = value
    self.storage?.set(value, for: Keys.mode)
  }

  /// Keeps the canvas settings, as the toolbar's bindings set them, in the window's storage.
  func persistSettings() {
    guard let storage = self.storage else { return }
    storage.set(self.appearance, for: Keys.appearance)
    storage.set(self.background, for: Keys.background)
    storage.set(self.viewport, for: Keys.viewport)
    storage.set(StoredText(rawValue: "\(self.zoom)"), for: Keys.zoom)
    storage.set(StoredText(rawValue: self.outline ? "1" : ""), for: Keys.outline)
    storage.set(self.mode, for: Keys.mode)
  }

  /// Reads the window's settings back: at launch, and after a relaunch or a hot reload.
  func restore(from storage: UISceneStorage, catalog: StoryCatalog) {
    self.storage = storage
    self.appearance = storage.value(Keys.appearance, default: CanvasAppearance.window)
    self.background = storage.value(Keys.background, default: CanvasBackground.content)
    self.viewport = storage.value(Keys.viewport, default: Viewport.fit)
    self.zoom = Double(storage.value(Keys.zoom, default: StoredText(rawValue: "1")).rawValue) ?? 1
    self.outline = !storage.value(Keys.outline, default: StoredText(rawValue: "")).rawValue.isEmpty
    self.mode = storage.value(Keys.mode, default: CanvasMode.canvas)
    let first = catalog.components.first.map { $0.id(of: $0.stories[0]) } ?? self.selection
    let selection = storage.value(Keys.selection, default: first)
    self.select(catalog.find(selection) != nil ? selection : first, in: catalog)
  }

  func reset() {
    self.selection = StoryID(component: "Button", story: "Styles")
    self.args = [:]
    self.revision = 0
    self.formRevision = 0
    self.appearance = .window
    self.background = .content
    self.viewport = .fit
    self.zoom = 1
    self.outline = false
    self.mode = .canvas
    self.actions = []
    self.search = ""
    self.expanded = []
    self.nextAction = 0
    self.storage = nil
  }

  // MARK: - Stored args

  private func storeArgs() {
    guard let data = try? JSONEncoder().encode(self.args) else { return }
    self.storage?.set(StoredText(rawValue: String(decoding: data, as: UTF8.self)), for: Keys.args(self.selection))
  }

  private func storedArgs(for id: StoryID) -> [String: StoryValue]? {
    guard let raw = self.storage?.value(Keys.args(id), default: StoredText(rawValue: "")).rawValue, !raw.isEmpty else {
      return nil
    }
    return try? JSONDecoder().decode([String: StoryValue].self, from: Data(raw.utf8))
  }

  enum Keys {
    static let selection = "Storybook.selection"
    static let appearance = "Storybook.appearance"
    static let background = "Storybook.background"
    static let viewport = "Storybook.viewport"
    static let zoom = "Storybook.zoom"
    static let outline = "Storybook.outline"
    static let mode = "Storybook.mode"
    static func args(_ id: StoryID) -> String { "Storybook.args.\(id.rawValue)" }
  }
}

/// A string kept in storage as it is.
struct StoredText : RawRepresentable {
  var rawValue: String
}

/// Every component with stories, and lookups into them.
struct StoryCatalog : Sendable {
  let components: [ComponentStories]

  func find(_ id: StoryID) -> (ComponentStories, Story)? {
    guard let component = self.components.first(where: { $0.name == id.component }),
          let story = component.stories.first(where: { $0.name == id.story }) else { return nil }
    return (component, story)
  }

  func component(_ name: String) -> ComponentStories? {
    self.components.first { $0.name == name }
  }

  /// Every story in sidebar order.
  var allStories: [StoryID] {
    StoryGroup.allCases.flatMap { group in
      self.components.filter { $0.group == group }.flatMap { component in component.stories.map { component.id(of: $0) } }
    }
  }
}
