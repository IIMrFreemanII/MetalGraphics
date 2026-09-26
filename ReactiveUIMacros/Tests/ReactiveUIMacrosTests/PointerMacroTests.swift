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

private func component(_ body: String) -> String {
  """
  @Component
  final class C: SingleChildElement {
    @State var on: Bool = false
    @State var taps: Int = 0

    @UIElementBuilder var body: [UIElement] {
  \(body)
    }
  }
  """
}

@Suite("Pointer")
struct PointerMacroTests {
  @Test("a tap gesture is built with a placeholder and armed through the adapter")
  func tapGesture() {
    let (text, diagnostics) = expand(component("    Rectangle(.red).onTapGesture(count: 2) { self.taps += 1 }"))
    #expect(diagnostics.isEmpty)
    #expect(text.contains("let n0b = n0a.onTapGesture(count: 2) { _ in\n}"))
    #expect(text.contains("self.__n0b?.tapAction = HittableView.tapAction({\nself.taps += 1\n})"))
    #expect(text.contains("self.__n0b?.tapAction = nil"))
  }

  @Test("continuous hover keeps its coordinate space and arms its handler")
  func continuousHover() {
    let (text, diagnostics) = expand(component(
      "    Rectangle(.red).onContinuousHover(coordinateSpace: .global) { phase in self.on = phase != .ended }"
    ))
    #expect(diagnostics.isEmpty)
    #expect(text.contains("let n0b = n0a.onContinuousHover(coordinateSpace: .global) { _ in\n}"))
    #expect(text.contains("self.__n0b?.onContinuousHover = { phase in\nself.on = phase != .ended\n}"))
  }

  @Test("a gesture is armed whole, and the chain built with an empty one")
  func gesture() {
    let (text, diagnostics) = expand(component(
      "    Rectangle(.red).gesture(DragGesture(minimumDistance: 4).onChanged { _ in self.on = true })"
    ))
    #expect(diagnostics.isEmpty)
    #expect(text.contains("let n0b = n0a.gesture(EmptyGesture())"))
    #expect(text.contains("self.__n0b?.gesture = DragGesture(minimumDistance: 4).onChanged { _ in\nself.on = true\n}"))
    #expect(text.contains("self.__n0b?.gesture = nil"))
  }

  @Test("pointer style binds to its setter, in place on a button")
  func pointerStyle() {
    let (text, diagnostics) = expand(component("""
          VStack {
            Rectangle(.red).pointerStyle(self.on ? .grabActive : .grabIdle)
            Button("Go").pointerStyle(.default)
          }
      """))
    #expect(diagnostics.isEmpty)
    #expect(text.contains("n.setPointerStyle(self._on ? .grabActive : .grabIdle, context)"))
    #expect(text.contains("private var __n0_0b: HittableView? = nil"))
    #expect(text.contains("private var __n0_1b: Button? = nil"))
  }

  @Test("allowsHitTesting is in place on anything, and contentShape makes a hit view")
  func hitTestControl() {
    let (text, diagnostics) = expand(component("    Rectangle(.red).allowsHitTesting(self.on).contentShape(.circle)"))
    #expect(diagnostics.isEmpty)
    #expect(text.contains("private var __n0b: Rectangle? = nil"))
    #expect(text.contains("n.setAllowsHitTesting(self._on, context)"))
    #expect(text.contains("let n0c = n0b.contentShape(.circle)"))
    #expect(text.contains("private var __n0c: HittableView? = nil"))
  }
}
