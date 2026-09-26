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

@Suite("Navigation")
struct NavigationMacroTests {

  @Test("path: $path lowers to the value, setPath, and an adapted write-back; the closure is the root")
  func stackPathBinding() {
    let (text, diagnostics) = expand(component(
      states: "  @State var path: [Int] = []",
      """
          NavigationStack(path: $path) {
            Text("Root")
          }
      """
    ))
    #expect(diagnostics.isEmpty)
    #expect(text.contains("let n0a = NavigationStack(path: self._path)"))
    #expect(text.contains("n.setPath(self._path, context, animation: transaction)"))
    #expect(text.contains("self.__n0a?.onPathChange = NavigationStack.adapt({\nself.path = $0\n})"))
    #expect(text.contains("self.__n0a?.onPathChange = nil"))
    #expect(text.contains("let n0_0a = Text(\"Root\")"))
    #expect(text.contains("owner.replaceChildren(children, context, animation: animation)"))
    // A path is not a list: no row-by-row door.
    #expect(!text.contains("insertRow"))
  }

  @Test("a stack without a path is built bare")
  func stackOwnsItsPath() {
    let (text, diagnostics) = expand(component(states: "", "    NavigationStack { Text(\"Root\") }"))
    #expect(diagnostics.isEmpty)
    #expect(text.contains("let n0a = NavigationStack()"))
  }

  @Test("NavigationLink(title, value:) binds both; NavigationLink(value:) { label } has its label as content")
  func valueLinks() {
    let (text, diagnostics) = expand(component(
      states: """
        @State var name: String = "Go"
        @State var target: Int = 1
      """,
      """
          VStack {
            NavigationLink(self.name, value: self.target)
            NavigationLink(value: self.target) {
              Text("Label")
            }
          }
      """
    ))
    #expect(diagnostics.isEmpty)
    #expect(text.contains("let n0_0a = NavigationLink(self._name, value: self._target)"))
    #expect(text.contains("n.setTitle(self._name, context, animation: transaction)"))
    #expect(text.contains("n.setValue(self._target, context)"))
    #expect(text.contains("let n0_1a = NavigationLink(value: self._target)"))
    #expect(text.contains("let n0_1_0a = Text(\"Label\")"))
    // The label is content, not a destination.
    #expect(!text.contains("?.destination ="))
  }

  @Test("a link's trailing destination is armed, not built, so it may build a component")
  func destinationLinks() {
    let (text, diagnostics) = expand(component(
      states: "",
      """
          VStack {
            NavigationLink("About") { AboutView(owner: self) }
            NavigationLink { DetailView() } label: {
              Text("Detail")
            }
          }
      """
    ))
    #expect(diagnostics.isEmpty)
    #expect(text.contains("let n0_0a = NavigationLink(\"About\")\n"))
    #expect(text.contains("self.__n0_0a?.destination = {\nAboutView(owner: self)\n}"))
    #expect(text.contains("self.__n0_0a?.destination = nil"))
    #expect(text.contains("let n0_1a = NavigationLink()\n"))
    #expect(text.contains("self.__n0_1a?.destination = {\nDetailView()\n}"))
    #expect(text.contains("Text(\"Detail\")"))
  }

  @Test("navigationDestination is typed by for:, built unarmed, and armed on mount")
  func navigationDestination() {
    let (text, diagnostics) = expand(component(
      states: "",
      """
          NavigationStack {
            Text("Root")
              .navigationTitle("Routes")
              .navigationDestination(for: Route.self) { route in RouteView(route: route) }
          }
      """
    ))
    #expect(diagnostics.isEmpty)
    #expect(text.contains("NavigationDestinationElement<Route>?"))
    // Built unarmed: no stand-in closure a waiting value could resolve to.
    #expect(text.contains(".navigationDestination(for: Route.self)\n"))
    #expect(text.contains("?.destination = { route in\nRouteView(route: route)\n}")
      || text.contains("?.destination = { route in RouteView(route: route) }"))
    #expect(text.contains(".navigationTitle(\"Routes\")"))
  }

  @Test("a reactive navigationTitle binds to setTitle")
  func reactiveTitle() {
    let (text, diagnostics) = expand(component(
      states: "  @State var title: String = \"A\"",
      "    Text(\"Body\").navigationTitle(self.title)"
    ))
    #expect(diagnostics.isEmpty)
    #expect(text.contains("n.setTitle(self._title, context)"))
  }

  @Test("a split view's sidebar and detail go through their doors")
  func splitView() {
    let (text, diagnostics) = expand(component(
      states: "  @State var ready: Bool = false",
      """
          NavigationSplitView {
            NavigationLink("Inbox", value: 1)
          } detail: {
            if self.ready {
              Text("Ready")
            } else {
              Text("Select")
            }
          }
      """
    ))
    #expect(diagnostics.isEmpty)
    #expect(text.contains("let n0a = NavigationSplitView()"))
    #expect(text.contains("owner.replaceChildren(children, context, animation: animation)"))
    #expect(text.contains("owner.replaceDetail(children, context, animation: animation)"))
  }

  @Test("selection: $selected lowers to the value, setSelection, and an adapted write-back")
  func splitViewSelection() {
    let (text, diagnostics) = expand(component(
      states: "  @State var selected: Demo = .text",
      """
          NavigationSplitView(selection: $selected) {
            NavigationLink("Text", value: Demo.text)
          } detail: {
            Text("Select")
          }
      """
    ))
    #expect(diagnostics.isEmpty)
    #expect(text.contains("let n0a = NavigationSplitView(selection: self._selected)"))
    #expect(text.contains("n.setSelection(self._selected, context)"))
    #expect(text.contains("self.__n0a?.onSelectionChange = NavigationSplitView.adapt({\nself.selected = $0\n})"))
    #expect(text.contains("owner.replaceDetail(children, context, animation: animation)"))
  }

  @Test("buttonStyle and disabled apply in place on a link")
  func linkStyling() {
    let (text, diagnostics) = expand(component(
      states: "  @State var off: Bool = false",
      """
          NavigationLink("Go", value: 1)
            .buttonStyle(.bordered)
            .disabled(self.off)
      """
    ))
    #expect(diagnostics.isEmpty)
    #expect(text.contains("let n0b = n0a.buttonStyle(.bordered)"))
    #expect(text.contains("n.setDisabled(self._off, context, animation: transaction)"))
  }

  // MARK: - Diagnostics

  @Test("F14: a path that is not a binding")
  func pathNotBinding() {
    let (_, diagnostics) = expand(component(
      states: "  @State var path: [Int] = []",
      "    NavigationStack(path: self.path) { Text(\"Root\") }"
    ))
    #expect(diagnostics.contains { $0.contains("'path:' is a binding") })
  }

  @Test("F4: a trailing closure the element has no door for")
  func unknownTrailingClosure() {
    let (_, diagnostics) = expand(component(
      states: "",
      """
          NavigationSplitView {
            Text("Sidebar")
          } content: {
            Text("Middle")
          } detail: {
            Text("Detail")
          }
      """
    ))
    #expect(diagnostics.contains { $0.contains("'content:' is not supported by NavigationSplitView") })
  }

  @Test("F19: for: that does not name a type")
  func destinationTypeNotSelf() {
    let (_, diagnostics) = expand(component(
      states: "",
      "    Text(\"Root\").navigationDestination(for: self.routeType) { route in RouteView(route: route) }"
    ))
    #expect(diagnostics.contains { $0.contains("'for:' must be written '<Type>.self'") })
  }
}
