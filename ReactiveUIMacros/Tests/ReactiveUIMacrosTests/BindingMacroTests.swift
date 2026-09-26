import Foundation
import SwiftParser
import SwiftSyntax
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacros
import Testing

@testable import ReactiveUIMacrosPlugin

/// The component's expansion, whitespace-normalised, and its diagnostics.
///
/// These tests assert on the lines a binding lowers to rather than on the whole expansion:
/// everything else in it is covered by the other suites, and would only bury the point here.
private func expand(_ source: String) -> (text: String, diagnostics: [String]) {
  let file = Parser.parse(source: source)
  let context = BasicMacroExpansionContext()
  let expanded = file.expand(
    macroSpecs: ["Component": MacroSpec(type: ComponentMacro.self), "State": MacroSpec(type: StateMacro.self)],
    contextGenerator: { syntax in
      BasicMacroExpansionContext(sharingWith: context, lexicalContext: syntax.allMacroLexicalContexts())
    },
    indentationWidth: .spaces(2)
  )
  let text = expanded.description
    .split(separator: "\n").map { $0.trimmingCharacters(in: .whitespaces) }
    .filter { !$0.isEmpty }.joined(separator: "\n")
  return (text, context.diagnostics.map(\.message))
}

private func component(states: String, _ body: String) -> String {
  """
  @Component
  final class C: SingleChildElement {
  \(states)

    @UIElementBuilder var body: [UIElement] {
  \(body)
    }
  }
  """
}

@Suite("Bindings")
struct BindingMacroTests {

  @Test("$state lowers to the current value, a setter line, and an armed write-back")
  func stateBinding() {
    let (text, diagnostics) = expand(component(
      states: "  @State var wifi: Bool = false",
      "    Toggle(\"Wi-Fi\", isOn: $wifi)"
    ))
    #expect(diagnostics.isEmpty)
    // Built with the value, not the binding.
    #expect(text.contains("let n0a = Toggle(\"Wi-Fi\", isOn: self._wifi)"))
    // State to control: an ordinary bound argument.
    #expect(text.contains("if let n = self.__n0a {\nn.setIsOn(self._wifi, context, animation: transaction)\n}"))
    // Control to state: armed on mount, cleared on unmount.
    #expect(text.contains("self.__n0a?.onIsOnChange = {\nself.wifi = $0\n}"))
    #expect(text.contains("self.__n0a?.onIsOnChange = nil"))
    // `$wifi` itself is declared by `@State`, for use outside a body.
    #expect(text.contains("var $wifi: Binding<Bool> {\nBinding(unowned: self, \\.wifi)\n}"))
  }

  @Test("self.$state and a member path lower through the path; a numeric binding is adapted")
  func memberPath() {
    let (text, diagnostics) = expand(component(
      states: "  @State var settings: Settings = Settings()",
      """
          VStack {
            Slider("Volume", value: self.$settings.audio.volume, in: 0 ... 1)
            Toggle("Mute", isOn: $settings.audio.muted)
          }
      """
    ))
    #expect(diagnostics.isEmpty)
    #expect(text.contains("let n0_0a = Slider(\"Volume\", value: self._settings.audio.volume, in: 0 ... 1)"))
    #expect(text.contains("n.setValue(self._settings.audio.volume, context, animation: transaction)"))
    #expect(text.contains("self.__n0_0a?.onValueChange = Slider.adapt({\nself.settings.audio.volume = $0\n})"))
    #expect(text.contains("self.__n0_1a?.onIsOnChange = {\nself.settings.audio.muted = $0\n}"))
    // Both bindings read the one state, so both land in its update.
    #expect(text.contains("n.setIsOn(self._settings.audio.muted, context, animation: transaction)"))
  }

  @Test(".constant lowers to the value alone: nothing to write back")
  func constant() {
    let (text, diagnostics) = expand(component(
      states: "  @State var label: String = \"\"",
      "    Toggle(self.label, isOn: .constant(true))"
    ))
    #expect(diagnostics.isEmpty)
    #expect(text.contains("let n0a = Toggle(self._label, isOn: true)"))
    #expect(!text.contains("onIsOnChange"))
    #expect(!text.contains("__armHandlers"))
  }

  @Test("a callback argument is armed like a handler and dropped from the constructor")
  func buttonAction() {
    let (text, diagnostics) = expand(component(
      states: "  @State var count: Int = 0",
      "    Button(\"Add\", role: .destructive) { self.count += 1 }"
    ))
    #expect(diagnostics.isEmpty)
    #expect(text.contains("let n0a = Button(\"Add\", role: .destructive)\n"))
    #expect(text.contains("self.__n0a?.action = {\nself.count += 1\n}"))
    #expect(text.contains("self.__n0a?.action = nil"))
  }

  @Test("with action: passed, a button's trailing closure is its label")
  func buttonLabelAfterAction() {
    let (text, diagnostics) = expand(component(
      states: "  @State var count: Int = 0",
      "    Button(action: { self.count += 1 }) { Text(\"Add\") }"
    ))
    #expect(diagnostics.isEmpty)
    #expect(text.contains("let n0a = Button()\n"))
    #expect(text.contains("self.__n0a?.action = {\nself.count += 1\n}"))
    #expect(text.contains("let n0_0a = Text(\"Add\")"))
    #expect(text.contains("owner.replaceChildren(children, context, animation: animation)"))
  }

  @Test("Button { … } label: { … }: the action, then a reactive label through its door")
  func buttonNamedLabel() {
    let (text, diagnostics) = expand(component(
      states: "  @State var count: Int = 0",
      """
          Button(role: .destructive) { self.count += 1 } label: {
            Text("Tapped \\(self.count)")
          }
      """
    ))
    #expect(diagnostics.isEmpty)
    #expect(text.contains("let n0a = Button(role: .destructive)\n"))
    #expect(text.contains("self.__n0a?.action = {\nself.count += 1\n}"))
    #expect(text.contains("owner.replaceChildren(children, context, animation: animation)"))
    #expect(text.contains("n.setText(\"Tapped \\(self._count)\", context, animation: transaction)"))
  }

  @Test("an action given as a reference is armed and cleared like a closure")
  func buttonActionReference() {
    let (text, diagnostics) = expand(component(
      states: "  @State var count: Int = 0",
      "    Button(action: self.reset) { Text(\"Reset\") }"
    ))
    #expect(diagnostics.isEmpty)
    #expect(text.contains("let n0a = Button()\n"))
    #expect(text.contains("self.__n0a?.action = self.reset"))
    #expect(text.contains("self.__n0a?.action = nil"))
  }

  @Test("buttonStyle is in place, and binds to setButtonStyle when it reads state")
  func buttonStyle() {
    let (text, diagnostics) = expand(component(
      states: "  @State var prominent: Bool = false",
      """
          Button("Go") { self.prominent.toggle() }
            .buttonStyle(self.prominent ? .borderedProminent : .bordered)
      """
    ))
    #expect(diagnostics.isEmpty)
    #expect(text.contains("let n0b = n0a.buttonStyle(self._prominent ? .borderedProminent : .bordered)"))
    #expect(text.contains("n.setButtonStyle(self._prominent ? .borderedProminent : .bordered, context, animation: transaction)"))
  }

  @Test("a picker's options are content, tagged in place; onSubmit and disabled are in place")
  func pickerAndModifiers() {
    let (text, diagnostics) = expand(component(
      states: """
        @State var level: Int = 0
        @State var name: String = ""
      """,
      """
          VStack {
            Picker("Level", selection: $level) {
              Text("Easy").tag(0)
              Text("Hard").tag(1)
            }
            .pickerStyle(.inline)
            TextField("Name", text: $name)
              .onSubmit { self.level = 1 }
              .disabled(self.level == 0)
          }
      """
    ))
    #expect(diagnostics.isEmpty)
    #expect(text.contains("let n0_0a = Picker(\"Level\", selection: self._level)"))
    #expect(text.contains("let n0_0_0b = n0_0_0a.tag(0)"))
    #expect(text.contains("owner.replaceChildren(children, context, animation: animation)"))
    #expect(text.contains("self.__n0_0a?.onSelectionChange = Picker.adapt({\nself.level = $0\n})"))
    #expect(text.contains("self.__n0_1b?.onSubmit = {\nself.level = 1\n}"))
    #expect(text.contains("n.setDisabled(self._level == 0, context, animation: transaction)"))
    #expect(text.contains("n.setText(self._name, context, animation: transaction)"))
  }

  @Test("F14: a binding that cannot be lowered at compile time")
  func unlowerable() {
    let (_, diagnostics) = expand(component(
      states: "  @State var wifi: Bool = false",
      "    Toggle(\"Wi-Fi\", isOn: self.makeBinding())"
    ))
    #expect(diagnostics == [
      "'isOn:' is a binding, lowered at compile time: write '$<state>' for a @State property "
        + "(or a member of one, '$<state>.<member>'), or '.constant(<value>)'."
    ])
  }

  @Test("F14: $name of something that is not a @State")
  func notAState() {
    let (_, diagnostics) = expand(component(
      states: "  @State var wifi: Bool = false",
      "    Toggle(\"Wi-Fi\", isOn: $other)"
    ))
    #expect(diagnostics.count == 1)
    #expect(diagnostics.first?.hasPrefix("'isOn:' is a binding") == true)
  }
}

@Suite("Named content")
struct NamedContentTests {

  @Test("header: and footer: closures are content, applied through their own doors")
  func sectionHeaderFooter() {
    let (text, diagnostics) = expand(component(
      states: "  @State var pro: Bool = false",
      """
          Section {
            Text("Row")
          } header: {
            Text("Account")
            if self.pro {
              Text("Pro")
            }
          } footer: {
            Text("Shown to others.")
          }
      """
    ))
    #expect(diagnostics.isEmpty)
    // The closures are gone from the constructor.
    #expect(text.contains("let n0a = Section()"))
    #expect(text.contains("owner.replaceHeader(children, context, animation: animation)"))
    #expect(text.contains("owner.replaceFooter(children, context, animation: animation)"))
    #expect(text.contains("let n0k0_0a = Text(\"Account\")"))
    // A branch in the header re-applies the header.
    #expect(text.contains("self.__applyChildren0k0(context, animation: animation)"))
    #expect(text.contains("owner.replaceChildren(children, context, animation: animation)"))
  }

  @Test("a date and a colour bind like any control")
  func dateAndColor() {
    let (text, diagnostics) = expand(component(
      states: """
        @State var due: Date = Date()
        @State var tint: float4 = .blue
      """,
      """
          VStack {
            DatePicker("Due", selection: $due, displayedComponents: .date)
              .datePickerStyle(.graphical)
            ColorPicker("Tint", selection: $tint, supportsOpacity: false)
          }
      """
    ))
    #expect(diagnostics.isEmpty)
    #expect(text.contains("let n0_0a = DatePicker(\"Due\", selection: self._due, displayedComponents: .date)"))
    #expect(text.contains("self.__n0_0a?.onSelectionChange = {\nself.due = $0\n}"))
    #expect(text.contains("n.setSelection(self._tint, context, animation: transaction)"))
    #expect(text.contains("self.__n0_1a?.onSelectionChange = {\nself.tint = $0\n}"))
  }
}
