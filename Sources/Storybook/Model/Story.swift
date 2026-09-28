import Foundation
import MetalGraphicsLib
import simd

/// One value a story's control edits: what `ArgType.control` shows and a story's args hold.
enum StoryValue : Hashable, Sendable, Codable {
  case text(String)
  case bool(Bool)
  case number(Double)
  /// One of a control's options, by name: a style, a role, a hue, an icon.
  case option(String)
  case date(Date)
  /// A plain colour, as a `ColorPicker` edits.
  case color(SIMD4<Float>)

  /// How the Actions panel and the Source panel print it.
  var display: String {
    switch self {
    case .text(let value): "\"\(value)\""
    case .bool(let value): "\(value)"
    case .number(let value): value.rounded() == value ? "\(Int(value))" : String(format: "%.2f", value)
    case .option(let value): value
    case .date(let value): value.formatted(date: .abbreviated, time: .shortened)
    case .color(let value): String(format: "(%.2f, %.2f, %.2f, %.2f)", value.x, value.y, value.z, value.w)
    }
  }
}

/// How the Controls panel edits an arg.
enum ControlKind : Sendable {
  case text
  /// Several items, separated by commas: a list's rows.
  case lines
  case bool
  case number(ClosedRange<Double>, step: Double)
  /// A segmented control when there are few, else a menu.
  case options([String])
  case date
  case color
}

/// One of a component's props, as its Controls row and its Docs table show it.
struct ArgType : Sendable {
  let name: String
  let control: ControlKind
  let summary: String
  let defaultValue: StoryValue

  init(_ name: String, _ control: ControlKind, _ defaultValue: StoryValue, _ summary: String) {
    self.name = name
    self.control = control
    self.summary = summary
    self.defaultValue = defaultValue
  }

  /// The type the Docs table names for it.
  var typeName: String {
    switch self.control {
    case .text: "String"
    case .lines: "[String]"
    case .bool: "Bool"
    case .number: "Float"
    case .options(let options): options.count <= 6 ? options.joined(separator: " | ") : "one of \(options.count)"
    case .date: "Date"
    case .color: "float4"
    }
  }
}

/// How a story sits on the canvas.
enum StoryLayout : Sendable {
  /// In the middle, at its own size.
  case centered
  /// At the top leading corner, 24 points in, as wide as the viewport.
  case padded
  /// Edge to edge.
  case fullscreen
}

/// One step of a story's play function: what the Interactions panel does to the story, with
/// real pointer input, and what it checks after.
enum PlayStep : Sendable, CustomStringConvertible {
  /// A click at the middle of the text `label` in the story.
  case click(String)
  /// The pointer over the text `label`.
  case hover(String)
  /// The story shows the text.
  case expect(String)
  /// The arg has the value, as the story wrote it back.
  case expectArg(String, StoryValue)
  /// The Actions panel's newest entry is named so.
  case expectAction(String)

  var description: String {
    switch self {
    case .click(let label): "click “\(label)”"
    case .hover(let label): "hover “\(label)”"
    case .expect(let text): "expect “\(text)” shown"
    case .expectArg(let name, let value): "expect \(name) = \(value.display)"
    case .expectAction(let name): "expect action “\(name)”"
    }
  }
}

/// One state of a component: a name, the args it changes from the defaults, and optionally a
/// play function the Interactions panel runs.
struct Story : Sendable {
  let name: String
  let args: [String: StoryValue]
  let layout: StoryLayout
  let play: [PlayStep]

  init(_ name: String, layout: StoryLayout = .centered, _ args: [String: StoryValue] = [:], play: [PlayStep] = []) {
    self.name = name
    self.args = args
    self.layout = layout
    self.play = play
  }
}

/// Where a component sits in the sidebar: the design system's groups.
enum StoryGroup : String, CaseIterable, Sendable {
  case foundations = "Foundations"
  case controls = "Controls"
  case pickers = "Pickers"
  case lists = "Lists"
  case forms = "Forms"
  case surfaces = "Surfaces"
  case navigation = "Navigation"
  case docking = "Docking"
  case window = "Window"
  case editor = "Editor"
}

/// A story's args, with typed reads that fall back to the defaults.
struct StoryArgs : Sendable {
  var values: [String: StoryValue]

  func string(_ name: String) -> String {
    switch self.values[name] {
    case .text(let value)?: value
    case .option(let value)?: value
    default: ""
    }
  }

  /// A `.lines` arg's items: what the commas separate, trimmed.
  func lines(_ name: String) -> [String] {
    self.string(name).split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
  }

  func bool(_ name: String) -> Bool {
    if case .bool(let value)? = self.values[name] { return value }
    return false
  }

  func number(_ name: String) -> Double {
    if case .number(let value)? = self.values[name] { return value }
    return 0
  }

  func float(_ name: String) -> Float { Float(self.number(name)) }

  func option(_ name: String) -> String { self.string(name) }

  func date(_ name: String) -> Date {
    if case .date(let value)? = self.values[name] { return value }
    return StoryFixtures.now
  }

  func color(_ name: String) -> float4 {
    if case .color(let value)? = self.values[name] { return value }
    return .accent
  }
}

/// What a story is rendered with: where it reports its callbacks, and how it writes a two-way
/// value back to its args. Used on the window's thread, as the story is.
final class StoryContext {
  private let model: StorybookModel

  init(model: StorybookModel) {
    self.model = model
  }

  /// A callback that logs `name` in the Actions panel.
  func action(_ name: String) -> () -> Void {
    let model = self.model
    return { model.log(name, "") }
  }

  /// A callback that logs `name` and its value.
  func action<T>(_ name: String, _ type: T.Type = T.self) -> (T) -> Void {
    let model = self.model
    return { value in model.log(name, "\(value)") }
  }

  /// A binding's write-back: logs the change and keeps it in the args, so the Controls panel
  /// shows it. The canvas already shows it, so it is not rebuilt.
  func write(_ arg: String, _ value: StoryValue) {
    self.model.log("\(arg) changed", value.display)
    self.model.setArg(arg, value, rebuild: false)
  }

  /// A two-way binding to an arg, for a control in the story: what it reads is the arg, what it
  /// writes goes back to it.
  func bool(_ arg: String) -> Binding<Bool> {
    let model = self.model
    return Binding(get: { StoryArgs(values: model.args).bool(arg) }, set: { self.write(arg, .bool($0)) })
  }

  func text(_ arg: String) -> Binding<String> {
    let model = self.model
    return Binding(get: { StoryArgs(values: model.args).string(arg) }, set: { self.write(arg, .text($0)) })
  }

  func number(_ arg: String) -> Binding<Double> {
    let model = self.model
    return Binding(get: { StoryArgs(values: model.args).number(arg) }, set: { self.write(arg, .number($0)) })
  }

  func option(_ arg: String) -> Binding<String> {
    let model = self.model
    return Binding(get: { StoryArgs(values: model.args).option(arg) }, set: { self.write(arg, .option($0)) })
  }

  func date(_ arg: String) -> Binding<Date> {
    let model = self.model
    return Binding(get: { StoryArgs(values: model.args).date(arg) }, set: { self.write(arg, .date($0)) })
  }

  func color(_ arg: String) -> Binding<float4> {
    let model = self.model
    return Binding(get: { StoryArgs(values: model.args).color(arg) }, set: { self.write(arg, .color($0)) })
  }
}

/// A component and its stories: what the sidebar lists, the canvas draws, the controls edit and
/// the docs page describes.
struct ComponentStories : Sendable {
  let group: StoryGroup
  let name: String
  /// Its name in the web mirror (`DesignSystemWeb/meta.mjs`), when it differs.
  let webName: String?
  let summary: String
  /// The Swift file it is in, from the package root.
  let source: String
  let argTypes: [ArgType]
  let stories: [Story]
  /// The component, drawn with `args`.
  let render: @Sendable (StoryArgs, StoryContext) -> UIElement
  /// The Swift that makes it with `args`.
  let snippet: @Sendable (StoryArgs) -> String

  init(
    _ group: StoryGroup, _ name: String, web: String? = nil, summary: String, source: String,
    args: [ArgType], stories: [Story],
    render: @escaping @Sendable (StoryArgs, StoryContext) -> UIElement,
    snippet: @escaping @Sendable (StoryArgs) -> String
  ) {
    self.group = group
    self.name = name
    self.webName = web
    self.summary = summary
    self.source = source
    self.argTypes = args
    self.stories = stories.isEmpty ? [Story("Default")] : stories
    self.render = render
    self.snippet = snippet
  }

  /// The story's args: the defaults, with the story's own over them.
  func args(for story: Story) -> StoryArgs {
    var values: [String: StoryValue] = [:]
    for arg in self.argTypes { values[arg.name] = arg.defaultValue }
    values.merge(story.args) { _, new in new }
    return StoryArgs(values: values)
  }

  func id(of story: Story) -> StoryID { StoryID(component: self.name, story: story.name) }
}

/// A story's address: its component and its name.
struct StoryID : Hashable, Sendable, Codable, RawRepresentable, CustomStringConvertible {
  let component: String
  let story: String

  init(component: String, story: String) {
    self.component = component
    self.story = story
  }

  init?(rawValue: String) {
    let parts = rawValue.split(separator: "/", maxSplits: 1).map(String.init)
    guard parts.count == 2 else { return nil }
    self.init(component: parts[0], story: parts[1])
  }

  var rawValue: String { "\(self.component)/\(self.story)" }
  var description: String { self.rawValue }
}

/// Fixed values stories draw with, so goldens never follow the wall clock.
enum StoryFixtures {
  static let now = Calendar.current.date(from: DateComponents(year: 2026, month: 9, day: 28, hour: 14, minute: 30))!
  static let due = Calendar.current.date(from: DateComponents(year: 2026, month: 10, day: 1, hour: 14, minute: 30))!
}
