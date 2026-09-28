import Foundation
import MetalGraphicsLib
import simd

/// The story's args as form controls, one row per prop, chosen by its `ControlKind`. Editing one
/// draws the story again; a value the story writes back shows here.
final class ControlsPanel : ModelWatcher {
  override var watched: [String] { ["formRevision"] }

  override init() {
    super.init()
    self.child = self.make()
  }

  override func update(_ token: Int, _ context: UIContext) {
    self.show(self.make(), context)
  }

  private func make() -> UIElement {
    let catalog = StoryRegistry.catalog()
    guard let (component, _) = catalog.find(self.model.selection) else { return EmptyElement() }
    let model = self.model
    var rows: [UIElement] = []
    if component.argTypes.isEmpty {
      rows.append(LabeledContent("Props", value: "This component takes none."))
    }
    for arg in component.argTypes {
      rows.append(Self.control(for: arg, model))
    }
    let form = Form {
      Section { () -> [UIElement] in return rows }
      Section {
        HStack {
          Text("Changes are kept for each story.").font(.system(size: 11)).foregroundColor(.secondaryLabel)
          Spacer()
          Button("Reset") { model.resetArgs(in: StoryRegistry.catalog()) }.buttonStyle(.bordered)
        }
      }
    }
    return form.frame(maxWidth: .infinity, maxHeight: .infinity).background(.groupedBackground)
  }

  /// The control that edits `arg`, bound to the model's value of it.
  static func control(for arg: ArgType, _ model: StorybookModel) -> UIElement {
    let name = arg.name
    let read = { StoryArgs(values: model.args) }
    switch arg.control {
    case .text:
      return TextField(name, text: Binding(get: { read().string(name) }, set: { model.setArg(name, .text($0)) }), prompt: "")
    case .lines:
      return TextField(name, text: Binding(get: { read().string(name) }, set: { model.setArg(name, .text($0)) }), prompt: "a, b, c")
    case .bool:
      return Toggle(name, isOn: Binding(get: { read().bool(name) }, set: { model.setArg(name, .bool($0)) }))
    case .number(let range, let step):
      let binding = Binding(get: { read().number(name) }, set: { model.setArg(name, .number($0)) })
      if (range.upperBound - range.lowerBound) / step <= 40 {
        return Stepper("\(name): \(StoryValue.number(read().number(name)).display)", value: binding, in: range, step: step)
      }
      return Slider(name, value: binding, in: range)
    case .options(let options):
      let picker = Picker(name, selection: Binding(get: { read().option(name) }, set: { model.setArg(name, .option($0)) }), content: {
        return options.map { Text($0).tag($0) as UIElement }
      })
      return options.count <= 3 && options.joined().count <= 24 ? picker.pickerStyle(.segmented) : picker
    case .date:
      return DatePicker(name, selection: Binding(get: { read().date(name) }, set: { model.setArg(name, .date($0)) }))
    case .color:
      return ColorPicker(name, selection: Binding(get: { read().color(name) }, set: { model.setArg(name, .color($0)) }))
    }
  }
}

/// What the story's callbacks reported, newest first: time, name and value.
final class ActionsPanel : ModelWatcher {
  static let font = TextFont.system(size: 12)
  static let codeFont = TextFont.system(size: 11.5, design: .monospaced)

  override var watched: [String] { ["actions"] }

  override init() {
    super.init()
    self.child = self.make()
  }

  override func update(_ token: Int, _ context: UIContext) {
    self.show(self.make(), context)
  }

  private func make() -> UIElement {
    let model = self.model
    let actions = model.actions
    let rows: [UIElement] = actions.map { entry in
      HStack(spacing: 10) {
        Text(entry.time).font(Self.codeFont).foregroundColor(.tertiaryLabel)
        Text(entry.name).font(Self.font)
        Text(entry.value).font(Self.codeFont).foregroundColor(.secondaryLabel).lineLimit(1)
        Spacer()
      }
      .padding(Inset(vertical: 3, horizontal: 12))
    }
    let list = VStack(alignment: .leading, spacing: 0) { () -> [UIElement] in return rows }
    return VStack(alignment: .leading, spacing: 0) {
      HStack {
        Text(actions.isEmpty ? "Nothing yet: use the story" : "\(actions.count) action\(actions.count == 1 ? "" : "s")")
          .font(.system(size: 11)).foregroundColor(.secondaryLabel)
        Spacer()
        Button("Clear") { model.clearActions() }.buttonStyle(.borderless).disabled(actions.isEmpty)
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

/// The Swift that makes the story with its args, as it is edited.
final class SourcePanel : ModelWatcher {
  private let document = TextDocument("")

  override var watched: [String] { ["revision", "formRevision"] }

  override init() {
    super.init()
    self.document.setText(self.source())
    self.child = TextEditor(document: self.document)
      .styler(SwiftStyler())
      .lineNumbers(true)
      .editable(false)
      .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  override func update(_ token: Int, _ context: UIContext) {
    let text = self.source()
    if text != self.document.string { self.document.setText(text) }
  }

  private func source() -> String {
    let catalog = StoryRegistry.catalog()
    guard let (component, _) = catalog.find(self.model.selection) else { return "" }
    return component.snippet(StoryArgs(values: self.model.args))
  }
}
