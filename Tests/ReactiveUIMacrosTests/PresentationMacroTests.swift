import Foundation
import SwiftParser
import SwiftSyntax
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacros
import Testing

@testable import ReactiveUIMacrosPlugin

/// The component's expansion, whitespace-normalised, and its diagnostics.
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

@Suite("Presentations")
struct PresentationMacroTests {
  @Test("isPresented: $state lowers to the value, setIsPresented, and a write-back; the content is armed")
  func sheetBinding() {
    let (text, diagnostics) = expand(component(
      states: "  @State var editing: Bool = false",
      """
          Button("Edit") { self.editing = true }
            .sheet(isPresented: $editing) {
              EditSheet()
            }
      """
    ))
    #expect(diagnostics.isEmpty)
    #expect(text.contains("private var __n0b: PresentationElement? = nil"))
    #expect(text.contains("let n0b = n0a.sheet(isPresented: self._editing)"))
    #expect(text.contains("n.setIsPresented(self._editing, context)"))
    #expect(text.contains("self.__n0b?.onIsPresentedChange = {\nself.editing = $0\n}"))
    #expect(text.contains("self.__n0b?.content = presentationContent({\nEditSheet()\n})"))
    #expect(text.contains("self.__n0b?.content = nil"))
    #expect(text.contains("self.__n0b?.onIsPresentedChange = nil"))
    // Built when presented, not with the tree.
    #expect(!text.contains("let n0_0a = EditSheet()"))
  }

  @Test("a member of a state lowers through its path")
  func memberBinding() {
    let (text, diagnostics) = expand(component(
      states: "  @State var settings: Settings = Settings()",
      """
          Text("Hi").fullScreenCover(isPresented: $settings.showsIntro) { Intro() }
      """
    ))
    #expect(diagnostics.isEmpty)
    #expect(text.contains("n0a.fullScreenCover(isPresented: self._settings.showsIntro)"))
    #expect(text.contains("self.settings.showsIntro = $0"))
  }

  @Test(".constant(v) binds the value alone, with no write-back")
  func constantBinding() {
    let (text, diagnostics) = expand(component(
      states: "",
      """
          Text("Hi").sheet(isPresented: .constant(true)) { Text("Always") }
      """
    ))
    #expect(diagnostics.isEmpty)
    #expect(text.contains("n0a.sheet(isPresented: true)"))
    #expect(!text.contains("onIsPresentedChange"))
  }

  @Test("onDismiss is armed, as a closure or a reference, and left out of the chain")
  func onDismiss() {
    let (text, diagnostics) = expand(component(
      states: "  @State var a: Bool = false\n  @State var b: Bool = false",
      """
          VStack {
            Text("A").sheet(isPresented: $a, onDismiss: { self.log("a") }) { Text("Sheet") }
            Text("B").sheet(isPresented: $b, onDismiss: self.cleanup) { Text("Sheet") }
          }
      """
    ))
    #expect(diagnostics.isEmpty)
    #expect(text.contains("n0_0a.sheet(isPresented: self._a)\n"))
    #expect(text.contains("n0_1a.sheet(isPresented: self._b)\n"))
    #expect(text.contains("self.__n0_0b?.onDismiss = {\nself.log(\"a\")\n}"))
    #expect(text.contains("self.__n0_1b?.onDismiss = self.cleanup"))
    #expect(text.contains("self.__n0_1b?.onDismiss = nil"))
  }

  @Test("an alert's title follows its state, and its actions and message are armed")
  func alert() {
    let (text, diagnostics) = expand(component(
      states: "  @State var confirming: Bool = false\n  @State var name: String = \"Notes\"",
      """
          Button("Delete") { self.confirming = true }
            .alert("Delete \\(self.name)?", isPresented: $confirming) {
              Button("Delete", role: .destructive) { self.delete() }
            } message: {
              Text("This cannot be undone.")
            }
      """
    ))
    #expect(diagnostics.isEmpty)
    #expect(text.contains("let n0b = n0a.alert(\"Delete \\(self._name)?\", isPresented: self._confirming)"))
    #expect(text.contains("n.setTitle(\"Delete \\(self._name)?\", context)"))
    #expect(text.contains("n.setIsPresented(self._confirming, context)"))
    #expect(text.contains("self.__n0b?.content = presentationContent({\nButton(\"Delete\", role: .destructive) {\nself.delete()\n}\n})"))
    #expect(text.contains("self.__n0b?.message = presentationContent({\nText(\"This cannot be undone.\")\n})"))
  }

  @Test("a dialog keeps its title visibility, and takes its actions labelled")
  func confirmationDialog() {
    let (text, diagnostics) = expand(component(
      states: "  @State var asking: Bool = false",
      """
          Text("Hi").confirmationDialog("Save?", isPresented: $asking, titleVisibility: .visible, actions: {
            Button("Save") { self.save() }
          })
      """
    ))
    #expect(diagnostics.isEmpty)
    #expect(text.contains("n0a.confirmationDialog(\"Save?\", isPresented: self._asking, titleVisibility: .visible)"))
    #expect(text.contains("self.__n0b?.content = presentationContent({\nButton(\"Save\") {\nself.save()\n}\n})"))
  }

  @Test("a popover keeps its anchor and edge")
  func popover() {
    let (text, diagnostics) = expand(component(
      states: "  @State var showing: Bool = false",
      """
          Button("Info") { self.showing = true }
            .popover(isPresented: $showing, arrowEdge: .bottom) { Text("Details") }
      """
    ))
    #expect(diagnostics.isEmpty)
    #expect(text.contains("n0a.popover(isPresented: self._showing, arrowEdge: .bottom)"))
    #expect(text.contains("self.__n0b?.content = presentationContent({\nText(\"Details\")\n})"))
  }

  @Test("item: $state types the element from the optional state, and writes nil back")
  func itemSheet() {
    let (text, diagnostics) = expand(component(
      states: "  @State var selected: Route? = nil",
      """
          Text("List").sheet(item: $selected) { route in
            Detail(route: route)
          }
      """
    ))
    #expect(diagnostics.isEmpty)
    #expect(text.contains("private var __n0b: ItemPresentationElement<Route>? = nil"))
    #expect(text.contains("let n0b = n0a.sheet(item: self._selected)"))
    #expect(text.contains("n.setItem(self._selected, context)"))
    #expect(text.contains("self.__n0b?.onItemChange = {\nself.selected = $0\n}"))
    #expect(text.contains("self.__n0b?.itemContent = presentationItemContent({ route in\nDetail(route: route)\n})"))
  }

  @Test("Optional<T> types an item presentation as T? does")
  func itemSheetOptionalSpelledOut() {
    let (text, diagnostics) = expand(component(
      states: "  @State var selected: Optional<Route> = nil",
      """
          Text("List").fullScreenCover(item: $selected) { route in Detail(route: route) }
      """
    ))
    #expect(diagnostics.isEmpty)
    #expect(text.contains("private var __n0b: ItemPresentationElement<Route>? = nil"))
  }

  @Test("presentationWindow follows its state")
  func presentationWindow() {
    let (text, diagnostics) = expand(component(
      states: "  @State var style: PresentationWindowStyle = .inline\n  @State var editing: Bool = false",
      """
          Text("Hi")
            .sheet(isPresented: $editing) { Text("Sheet") }
            .presentationWindow(self.style)
      """
    ))
    #expect(diagnostics.isEmpty)
    #expect(text.contains("private var __n0c: PresentationWindowStyleElement? = nil"))
    #expect(text.contains("n.setStyle(self._style, context)"))
  }

  @Test("@Environment(\\.dismiss) is a plain property to the macro: read in a handler, never bound")
  func environmentDismiss() {
    let (text, diagnostics) = expand(component(
      states: "  @Environment(\\.dismiss) private var dismiss",
      """
          Button("Done") { self.dismiss() }
      """
    ))
    #expect(diagnostics.isEmpty)
    #expect(text.contains("self.__n0a?.action = {\nself.dismiss()\n}"))
  }

  @Test("F14: isPresented: takes a binding")
  func isPresentedNotABinding() {
    let (_, diagnostics) = expand(component(
      states: "  @State var editing: Bool = false",
      """
          Text("Hi").sheet(isPresented: self.editing) { Text("Sheet") }
      """
    ))
    #expect(diagnostics.count == 1)
    #expect(diagnostics.first?.contains("'isPresented:' is a binding") == true)
  }

  @Test("F22: item: takes an optional state's binding")
  func itemNotOptional() {
    let (_, notOptional) = expand(component(
      states: "  @State var selected: Route = Route()",
      """
          Text("Hi").sheet(item: $selected) { route in Detail(route: route) }
      """
    ))
    #expect(notOptional.count == 1)
    #expect(notOptional.first?.contains("which is not optional") == true)

    let (_, constant) = expand(component(
      states: "",
      """
          Text("Hi").sheet(item: .constant(nil)) { route in Detail(route: route) }
      """
    ))
    #expect(constant.count == 1)
    #expect(constant.first?.contains("'.sheet(item:)' needs '$<state>'") == true)
  }
}
