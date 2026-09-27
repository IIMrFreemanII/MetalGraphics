import Foundation
import SwiftParser
import SwiftSyntax
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacros
import Testing

@testable import ReactiveUIMacrosPlugin

private let modelMacros: [String: MacroSpec] = [
  "Component": MacroSpec(type: ComponentMacro.self),
  "State": MacroSpec(type: StateMacro.self),
  "Model": MacroSpec(type: ModelMacro.self, conformances: ["ReactiveModel"]),
  "ModelTracked": MacroSpec(type: ModelTrackedMacro.self),
  "ModelIgnored": MacroSpec(type: ModelIgnoredMacro.self),
  "Bindable": MacroSpec(type: BindableMacro.self),
]

/// The expansion, whitespace-normalised, and its diagnostics.
private func expand(_ source: String) -> (text: String, diagnostics: [String]) {
  let file = Parser.parse(source: source)
  let context = BasicMacroExpansionContext()
  let expanded = file.expand(
    macroSpecs: modelMacros,
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

private func component(members: String, _ body: String) -> String {
  """
  @Component
  final class C: SingleChildElement {
  \(members)

    @UIElementBuilder var body: [UIElement] {
  \(body)
    }
  }
  """
}

@Suite("@Model")
struct ModelMacroTests {

  @Test("a tracked property is behind the model's lock, notifies its own list and the any-list, and skips equal writes")
  func expansion() {
    assertMacroExpansion(
      """
      @Model final class AppModel {
        var count: Int = 0
      }
      """,
      expandedSource: """
      final class AppModel {
        var count: Int {
            @storageRestrictions(initializes: _count)
            init(initialValue) {
              _count = initialValue
            }
            get {
              self.__lock.lock()
              defer {
                self.__lock.unlock()
              }
              return _count
            }
            set {
              self.__lock.lock()
              let changed = ModelObservers.changed(_count, newValue)
              _count = newValue
              self.__lock.unlock()
              if changed {
                self.__observers_count.notify(also: self.__observers_any)
              }
            }
            _modify {
              self.__lock.lock()
              defer {
                self.__lock.unlock()
                self.__observers_count.notify(also: self.__observers_any)
              }
              yield &_count
            }
        }

        private var _count: Int

        private let __observers_count = ModelObservers()

          private let __lock = ModelLock()

          private let __observers_any = ModelObservers()

          public func __observers(named name: String) -> ModelObservers {
            switch name {
            case "count":
                return self.__observers_count
            default:
                return self.__observers_any
            }
          }
      }

      extension AppModel: ReactiveModel, @unchecked Sendable {
      }
      """,
      macros: [
        "Model": ModelMacro.self, "ModelTracked": ModelTrackedMacro.self, "ModelIgnored": ModelIgnoredMacro.self,
      ]
    )
  }

  @Test("static, let, computed, lazy and @ModelIgnored properties are not tracked")
  func skipped() {
    let (text, diagnostics) = expand("""
      @Model final class M {
        static let shared = M()
        let id: Int = 1
        var total: Int { 2 }
        lazy var cache: [Int] = []
        @ModelIgnored var scratch: Int = 0
        var tracked: Bool = false
      }
      """)
    #expect(diagnostics.isEmpty)
    #expect(text.contains("private var _tracked: Bool"))
    #expect(text.contains("case \"tracked\":\nreturn self.__observers_tracked"))
    for name in ["shared", "id", "total", "cache", "scratch"] {
      #expect(!text.contains("__observers_\(name)"), "\(name) should not be tracked")
    }
  }

  @Test("F20: not a class, @MainActor, no type, willSet/didSet, several bindings")
  func diagnostics() {
    #expect(expand("@Model struct S { var x: Int = 0 }").diagnostics == [
      "@Model can only be applied to a class: components share one instance, by reference."
    ])
    #expect(expand("@MainActor @Model final class M { var x: Int = 0 }").diagnostics == [
      "@Model is read and written by windows that each run on a thread of their own; remove '@MainActor'."
    ])
    #expect(expand("@Model final class M { var x = 0 }").diagnostics == [
      "@Model requires an explicit type annotation, e.g. 'var x: Int = …', or '@ModelIgnored'."
    ])
    #expect(expand("@Model final class M { var x: Int = 0 { didSet { } } }").diagnostics == [
      "@Model cannot track 'x', which has 'willSet'/'didSet'. Mark it '@ModelIgnored', or move the observer into a method."
    ])
    #expect(expand("@Model final class M { var a: Int = 0, b: Int = 1 }").diagnostics == [
      "@Model tracks one property per declaration; declare each on its own line."
    ])
  }
}

@Suite("@Bindable models in a component")
struct BindableComponentTests {

  @Test("a read subscribes on mount, updates through its own method, and unsubscribes on unmount")
  func read() {
    let (text, diagnostics) = expand(component(
      members: "  @Bindable let model: AppModel = .shared",
      "    Text(\"Count: \\(self.model.count)\")"
    ))
    #expect(diagnostics.isEmpty)
    // Built with the model's current value, read through its getter.
    #expect(text.contains("let n0a = Text(\"Count: \\(self.model.count)\")"))
    // One update method for the key, like a state's.
    #expect(text.contains("private func __modelUpdate_model_count(_ animated: Bool = true) {"))
    #expect(text.contains("n.setText(\"Count: \\(self.model.count)\", context, animation: transaction)"))
    // Dispatch from the model, by token.
    #expect(text.contains("public override func __modelDidChange(_ token: Int, _ animated: Bool) {\nswitch token {\ncase 0:\nself.__modelUpdate_model_count(animated)"))
    #expect(text.contains("self.model.__observers(named: \"count\").add(self, token: 0)"))
    #expect(text.contains("self.model.__observers(named: \"count\").remove(self)"))
    // A remount replays the model reads, then subscribes; unmount unsubscribes first.
    #expect(text.contains("""
      } else {
      if self.__needsRefresh {
      self.__needsRefresh = false
      self.__refreshAll()
      }
      self.__refreshModels()
      }
      self.__subscribeModels()
      """))
    #expect(text.contains("public override func unmount(_ context: UIContext) {\nself.__unsubscribeModels()\nself.__context = nil"))
    #expect(text.contains("private func __refreshModels() {\nself.__modelUpdate_model_count(false)\n}"))
    // `$model` for use outside a body.
    #expect(text.contains("var $model: ModelBindings<AppModel> {\nModelBindings(self.model)\n}"))
  }

  @Test("$model.property lowers to a setter line and an armed write-back into the model")
  func binding() {
    let (text, diagnostics) = expand(component(
      members: "  @Bindable let model: AppModel = .shared",
      "    Toggle(\"Highlight\", isOn: $model.highlighted)"
    ))
    #expect(diagnostics.isEmpty)
    #expect(text.contains("let n0a = Toggle(\"Highlight\", isOn: self.model.highlighted)"))
    #expect(text.contains("n.setIsOn(self.model.highlighted, context, animation: transaction)"))
    #expect(text.contains("self.__n0a?.onIsOnChange = {\nself.model.highlighted = $0\n}"))
    #expect(text.contains("self.model.__observers(named: \"highlighted\").add(self, token: 0)"))
  }

  @Test("a branch on a model property swaps from the model's update method")
  func branch() {
    let (text, _) = expand(component(
      members: "  @Bindable let model: AppModel = .shared",
      """
          VStack {
            if self.model.highlighted {
              Text("On")
            }
          }
      """
    ))
    #expect(text.contains("private func __modelUpdate_model_highlighted(_ animated: Bool = true) {"))
    #expect(text.contains("self.__swap0_0(context, animation: transaction)"))
  }

  @Test("an animation scope triggered by a model property animates what it feeds")
  func animationScope() {
    let (text, _) = expand(component(
      members: "  @Bindable let model: AppModel = .shared",
      """
          Text("\\(self.model.count)")
            .animation(.easeOut, value: self.model.count)
      """
    ))
    #expect(text.contains("n.setText(\"\\(self.model.count)\", context, animation: animated ? Self.__anim0_0 : nil)"))
  }

  @Test("a method call subscribes by its name, which the model resolves to any write")
  func methodCall() {
    let (text, _) = expand(component(
      members: "  @Bindable let model: AppModel = .shared",
      "    Text(self.model.summary())"
    ))
    #expect(text.contains("private func __modelUpdate_model_summary(_ animated: Bool = true) {"))
    #expect(text.contains("self.model.__observers(named: \"summary\").add(self, token: 0)"))
  }

  @Test("reads inside a handler are not dependencies")
  func handlerRead() {
    let (text, _) = expand(component(
      members: "  @Bindable let model: AppModel = .shared",
      "    Button(\"+\") { self.model.count += 1 }"
    ))
    #expect(!text.contains("__modelUpdate_"))
    #expect(!text.contains("__subscribeModels"))
    #expect(text.contains("self.__n0a?.action = {\nself.model.count += 1\n}"))
  }

  @Test("states and model properties get their own methods, tokens in key order")
  func mixed() {
    let (text, diagnostics) = expand(component(
      members: """
        @Bindable let model: AppModel = .shared
        @State var local: Int = 0
      """,
      """
          VStack {
            Text("\\(self.local)")
            Text(self.model.message)
            Text("\\(self.model.count)")
          }
      """
    ))
    #expect(diagnostics.isEmpty)
    #expect(text.contains("private func __update_local(_ animated: Bool = true) {"))
    #expect(text.contains("case 0:\nself.__modelUpdate_model_count(animated)\ncase 1:\nself.__modelUpdate_model_message(animated)"))
    // The state's method touches no model node, and the reverse.
    #expect(text.contains("private func __refreshAll() {\nself.__update_local(false)\n}"))
  }

  @Test("a component without models expands without any model machinery")
  func noModels() {
    let (text, _) = expand(component(
      members: "  @State var n: Int = 0",
      "    Text(\"\\(self.n)\")"
    ))
    #expect(!text.contains("Models"))
    #expect(!text.contains("__modelDidChange"))
  }

  @Test("F21 and F14: a model property must be a typed let; a model binds through a property")
  func diagnostics() {
    #expect(expand(component(members: "  @Bindable var model: AppModel = .shared", "    Text(\"x\")")).diagnostics == [
      "@Bindable requires a 'let': the component subscribes to the model it was mounted with, so the model cannot be swapped."
    ])
    #expect(expand(component(members: "  @Bindable let model = AppModel.shared", "    Text(\"x\")")).diagnostics == [
      "@Bindable requires an explicit type annotation, e.g. 'let model: AppModel = .shared'."
    ])
    #expect(expand(component(
      members: "  @Bindable let model: AppModel = .shared",
      "    Toggle(\"x\", isOn: $model)"
    )).diagnostics == [
      "'isOn:' is a binding, lowered at compile time: write '$<state>' for a @State property "
        + "(or a member of one, '$<state>.<member>'), '$<model>.<property>' for a @Bindable model's "
        + "property, or '.constant(<value>)'."
    ])
  }
}
