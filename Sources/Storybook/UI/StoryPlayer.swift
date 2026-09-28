import MetalGraphicsLib
import simd

/// Runs a story's play function against the canvas: a step per frame or so, with the window's
/// own pointer events, as the user's would arrive. Its results go to `StorybookModel.playResults`.
/// On the window's thread; one run at a time.
final class StoryPlayer : WakeTarget {
  /// The window the canvas is in: what the clicks are sent to. Set by `StorybookRoot`.
  nonisolated(unsafe) static var handle: WindowHandle?
  nonisolated(unsafe) static let shared = StoryPlayer()

  static let stepDelay: Double = 0.15

  private var steps: [PlayStep] = []
  private var index = 0
  private weak var context: UIContext?
  private(set) var isRunning = false

  /// Resets the story's args and runs its steps from the first.
  func run(_ steps: [PlayStep], _ context: UIContext) {
    let model = StorybookModel.shared
    model.resetArgs(in: StoryRegistry.catalog())
    self.steps = steps
    self.index = 0
    self.context = context
    self.isRunning = true
    model.playResults = Array(repeating: "", count: steps.count)
    // After the reset's rebuild is laid out.
    context.requestWake(at: context.clock() + Self.stepDelay, for: self)
  }

  func wake(_ context: UIContext, now: Double) {
    guard self.isRunning, self.index < self.steps.count else {
      self.isRunning = false
      return
    }
    let model = StorybookModel.shared
    let step = self.steps[self.index]
    var results = model.playResults
    let result = self.perform(step)
    if results.indices.contains(self.index) { results[self.index] = result }
    model.playResults = results
    self.index += 1
    // A failure ends the run, as a failed assertion ends a play function.
    if result != "pass" || self.index == self.steps.count {
      self.isRunning = false
      return
    }
    context.requestWake(at: now + Self.stepDelay, for: self)
  }

  private func perform(_ step: PlayStep) -> String {
    let model = StorybookModel.shared
    switch step {
    case .click(let label), .hover(let label):
      guard let center = Self.center(of: label) else { return "no “\(label)” in the story" }
      guard let handle = Self.handle else { return "no window to click in" }
      handle.send(.pointer(center, inView: true))
      if case .click = step {
        handle.send(.mouseDown(.left, center, inView: true, clickCount: 1))
        handle.send(.mouseUp(.left, center, inView: true))
      }
      return "pass"
    case .expect(let text):
      return Self.texts().contains(text) ? "pass" : "“\(text)” is not shown"
    case .expectArg(let name, let value):
      let actual = model.args[name]
      return actual == value ? "pass" : "\(name) is \(actual?.display ?? "unset")"
    case .expectAction(let name):
      let newest = model.actions.first?.name
      return newest == name ? "pass" : "newest action is \(newest.map { "“\($0)”" } ?? "none")"
    }
  }

  /// Every text the story shows.
  static func texts() -> [String] {
    guard let story = StoryFrame.shown, story.mounted else { return [] }
    return ElementInspector.snapshot(of: story).compactMap(\.text)
  }

  /// The middle of the story's text `label`, in the window.
  static func center(of label: String) -> float2? {
    guard let story = StoryFrame.shown, story.mounted else { return nil }
    let info = ElementInspector.snapshot(of: story).first { $0.text == label && $0.frame != nil }
    return info?.frame.map { $0.origin + $0.size * 0.5 }
  }
}

/// The story's play function: its steps, each with how it went, and Run.
final class InteractionsPanel : ModelWatcher {
  static let font = TextFont.system(size: 12)

  override var watched: [String] { ["playResults", "selection"] }

  override init() {
    super.init()
    self.child = self.make()
  }

  override func update(_ token: Int, _ context: UIContext) {
    self.show(self.make(), context)
  }

  private func make() -> UIElement {
    let catalog = StoryRegistry.catalog()
    guard let (_, story) = catalog.find(self.model.selection) else { return EmptyElement() }
    guard !story.play.isEmpty else {
      return Text("This story has no play function.").font(.system(size: 11)).foregroundColor(.secondaryLabel)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    let results = self.model.playResults
    let rows: [UIElement] = story.play.enumerated().map { index, step in
      let result = results.indices.contains(index) ? results[index] : ""
      let status: ListRowStatus? = result == "pass" ? .note : result.isEmpty ? nil : .error
      let label = result == "pass" ? "✓ \(step)" : step.description
      return ListRow(label, subtitle: result.isEmpty || result == "pass" ? nil : result, status: status,
                     height: result.isEmpty || result == "pass" ? 24 : ListRowMetrics.twoLineHeight, spacing: 10)
    }
    let passed = results.count { $0 == "pass" }
    let failed = results.contains { !$0.isEmpty && $0 != "pass" }
    let summary = results.allSatisfy(\.isEmpty) ? "\(story.play.count) steps"
      : failed ? "Failed at step \(passed + 1)" : passed == story.play.count ? "Passed" : "Running…"
    let list = VStack(alignment: .leading, spacing: 0) { () -> [UIElement] in return rows }
    return VStack(alignment: .leading, spacing: 0) {
      HStack {
        Text(summary).font(.system(size: 11)).foregroundColor(failed ? .destructive : .secondaryLabel)
        Spacer()
        Button("Run") { [weak self] in
          guard let self, let context = self.context else { return }
          StoryPlayer.shared.run(story.play, context)
        }
        .buttonStyle(.bordered)
      }
      .padding(Inset(vertical: 6, horizontal: 12))
      Rectangle(.separator).frame(height: 0.5)
      ScrollView(.vertical) { list.padding(Inset(vertical: 4)) }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(.contentBackground)
  }
}
