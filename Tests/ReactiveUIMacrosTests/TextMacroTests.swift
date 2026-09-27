import Foundation
import SwiftParser
import SwiftSyntax
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacros
import Testing

@testable import ReactiveUIMacrosPlugin

/// The component's expansion, whitespace-normalised, and its diagnostics.
///
/// Like the binding tests, these assert on the lines the text work lowers to: what is folded at
/// compile time, and what is left to the runtime.
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
    @State var name: String = ""
    @State var count: Double = 0
    @State var color: float4 = .blue

    @UIElementBuilder var body: [UIElement] {
  \(body)
    }
  }
  """
}

@Suite("Text")
struct TextMacroTests {

  // MARK: - In place

  @Test("constant modifiers on a Text fold into one applyStyle, built once")
  func constantTextChain() {
    let (text, diagnostics) = expand(component("    Text(\"a\").bold().italic().underline()"))
    #expect(diagnostics.isEmpty)
    #expect(text.contains("private static let __style0_1: TextEnvironment = TextEnvironment().bold().italic().underline()"))
    #expect(text.contains("let n0b = n0a.applyStyle(Self.__style0_1)"))
    #expect(text.contains("let n0c = n0b"))
    #expect(text.contains("let n0d = n0c"))
    #expect(text.contains("private var __n0d: Text? = nil"))
  }

  @Test("a reactive modifier on a Text stays its own link, with its setter")
  func reactiveTextModifier() {
    let (text, diagnostics) = expand(component("    Text(\"a\").bold(self.on).lineLimit(2)"))
    #expect(diagnostics.isEmpty)
    #expect(text.contains("let n0b = n0a.bold(self._on)"))
    #expect(text.contains("n.setBold(self._on, context, animation: transaction)"))
    // One constant link alone is left as written.
    #expect(text.contains("let n0c = n0b.lineLimit(2)"))
  }

  @Test("underline binds its flag and its colour apart")
  func underlineArguments() {
    let (text, diagnostics) = expand(component("    Text(\"a\").underline(self.on, color: self.color)"))
    #expect(diagnostics.isEmpty)
    #expect(text.contains("n.setUnderline(self._on, context, animation: transaction)"))
    #expect(text.contains("n.setUnderlineColor(self._color, context, animation: transaction)"))
  }

  @Test("a formatted text reformats its value")
  func formattedText() {
    let (text, diagnostics) = expand(component("    Text(self.count, format: .number)"))
    #expect(diagnostics.isEmpty)
    #expect(text.contains("let n0a = Text(self._count, format: .number)"))
    #expect(text.contains("n.setText(self._count, context, animation: transaction)"))
  }

  // MARK: - Around texts

  @Test("a constant style around texts the macro sees is written into them, with no wrapper")
  func foldedIntoTexts() {
    let (text, diagnostics) = expand(component("""
          VStack {
            Text("a")
            Rectangle(.red)
            Text("b")
          }
          .font(.title)
          .foregroundStyle(.red)
      """))
    #expect(diagnostics.isEmpty)
    #expect(!text.contains("TextStyleElement"))
    // The first modifier is the nearest, and wins: applied last.
    #expect(text.contains("private static let __style0_1: TextEnvironment = TextEnvironment().foregroundStyle(.red).font(.title)"))
    #expect(text.contains("_ = n0_0a.inheritStyle(Self.__style0_1)"))
    #expect(text.contains("_ = n0_2a.inheritStyle(Self.__style0_1)"))
    #expect(text.contains("let n0b = n0a\n"))
    #expect(text.contains("private var __n0c: VStack? = nil"))
  }

  @Test("nested styles are written innermost first, so the nearer one wins")
  func nestedFolds() {
    let (text, diagnostics) = expand(component("""
          VStack {
            VStack {
              Text("a")
            }
            .font(.caption)
          }
          .font(.title)
      """))
    #expect(diagnostics.isEmpty)
    let inner = text.range(of: "_ = n0_0_0a.inheritStyle(Self.__style0_0_1)")
    let outer = text.range(of: "_ = n0_0_0a.inheritStyle(Self.__style0_1)")
    #expect(inner != nil && outer != nil)
    if let inner, let outer { #expect(inner.lowerBound < outer.lowerBound) }
  }

  @Test("a style on a Text's wrapper folds into the Text itself")
  func foldedIntoOwnText() {
    let (text, diagnostics) = expand(component("    Text(\"a\").padding(4).font(.title)"))
    #expect(diagnostics.isEmpty)
    #expect(text.contains("_ = n0a.inheritStyle(Self.__style0_2)"))
    #expect(text.contains("let n0c = n0b\n"))
  }

  @Test("texts in both arms of a branch are folded into")
  func foldedIntoBranches() {
    let (text, diagnostics) = expand(component("""
          VStack {
            if self.on {
              Text("yes")
            } else {
              Text("no")
            }
          }
          .bold()
      """))
    #expect(diagnostics.isEmpty)
    #expect(text.contains("_ = n0_0_0_0a.inheritStyle(Self.__style0_1)"))
    #expect(text.contains("_ = n0_0_1_0a.inheritStyle(Self.__style0_1)"))
  }

  @Test("a subtree hiding texts, or a reactive style, keeps the runtime wrapper")
  func runtimeFallback() {
    let (hidden, hiddenDiagnostics) = expand(component("""
          VStack {
            Button("Save")
          }
          .font(.title)
          .bold()
          .italic()
      """))
    #expect(hiddenDiagnostics.isEmpty)
    #expect(hidden.contains("let n0b = n0a.font(.title)"))
    #expect(hidden.contains("private var __n0b: TextStyleElement? = nil"))
    // The modifiers after it add to the wrapper in one call, farther out first.
    #expect(hidden.contains("private static let __style0_2: TextEnvironment = TextEnvironment().italic().bold()"))
    #expect(hidden.contains("let n0c = n0b.applyStyle(Self.__style0_2)"))

    let (reactive, reactiveDiagnostics) = expand(component("""
          VStack {
            Text("a")
          }
          .font(self.on ? .title : .body)
      """))
    #expect(reactiveDiagnostics.isEmpty)
    #expect(reactive.contains("let n0b = n0a.font(self._on ? .title : .body)"))
    #expect(reactive.contains("n.setFont(self._on ? .title : .body, context, animation: transaction)"))
    #expect(!reactive.contains("inheritStyle"))
  }

  @Test("a constant style is not folded past a runtime one nearer the texts")
  func noFoldPastRuntimeStyle() {
    let (text, diagnostics) = expand(component("""
          VStack {
            VStack {
              Text("a")
            }
            .font(self.on ? .title : .body)
          }
          .bold()
      """))
    #expect(diagnostics.isEmpty)
    #expect(!text.contains("inheritStyle"))
    #expect(text.contains("let n0b = n0a.bold()"))
  }

  @Test("a style that names Self is written in place, not hoisted")
  func selfStyleInPlace() {
    let (text, diagnostics) = expand(component("""
          VStack {
            Text("a")
          }
          .font(Self.font)
      """))
    #expect(diagnostics.isEmpty)
    #expect(text.contains("_ = n0_0a.inheritStyle(TextEnvironment().font(Self.font))"))
    #expect(!text.contains("__style"))
  }

  // MARK: - Text + Text

  @Test("Text + Text lowers to one Text of runs, with a setter per reactive operand")
  func concatenation() {
    let (text, diagnostics) = expand(component("    Text(\"Hi \") + Text(self.name).bold() + Text(\"!\").foregroundColor(self.color)"))
    #expect(diagnostics.isEmpty)
    #expect(text.contains(
      "let n0a = Text(runs: [TextRun(\"Hi \", style: TextEnvironment()), TextRun(self._name, style: TextEnvironment().bold()), "
        + "TextRun(\"!\", style: TextEnvironment().foregroundColor(self._color))])"
    ))
    #expect(text.contains("n.setRunText(Text.RunText(1, self._name), context, animation: transaction)"))
    #expect(text.contains("n.setRunStyle(Text.RunStyle(2, TextEnvironment().foregroundColor(self._color)), context, animation: transaction)"))
  }

  @Test("a parenthesised sum takes the paragraph's modifiers")
  func concatenationModifiers() {
    let (text, diagnostics) = expand(component("    (Text(\"a\") + Text(\"b\")).lineLimit(1).padding(4)"))
    #expect(diagnostics.isEmpty)
    #expect(text.contains("let n0a = Text(runs: [TextRun(\"a\", style: TextEnvironment()), TextRun(\"b\", style: TextEnvironment())])"))
    #expect(text.contains("let n0b = n0a.lineLimit(1)"))
    #expect(text.contains("let n0c = n0b.padding(4)"))
  }

  // MARK: - Diagnostics

  @Test("F15: only + joins texts, and only texts of strings")
  func joinDiagnostics() {
    let (_, minus) = expand(component("    Text(\"a\") - Text(\"b\")"))
    #expect(minus == ["only '+' joins texts into one; '-' does not."])

    let (_, formatted) = expand(component("    Text(\"a\") + Text(self.count, format: .number)"))
    #expect(formatted.count == 1)
    #expect(formatted.first?.hasPrefix("'+' joins texts of strings") == true)

    let (_, wrapped) = expand(component("    Text(\"a\") + Text(\"b\").padding(4)"))
    #expect(wrapped == ["'.padding' cannot style an operand of '+'; only a text's run modifiers can."])
  }

  @Test("F16: a paragraph modifier on an operand")
  func paragraphOnOperand() {
    let (_, diagnostics) = expand(component("    Text(\"a\").lineLimit(1) + Text(\"b\")"))
    #expect(diagnostics == [
      "'.lineLimit' styles a whole paragraph, not one run: call it on the joined text, '(a + b).lineLimit(…)'."
    ])
  }

  @Test("F17: literals a text modifier cannot take")
  func literalDiagnostics() {
    let (_, lines) = expand(component("    Text(\"a\").lineLimit(0)"))
    #expect(lines == ["'.lineLimit' needs at least 1 line; pass nil for as many as fit."])
    let (_, scale) = expand(component("    Text(\"a\").minimumScaleFactor(2)"))
    #expect(scale == ["'.minimumScaleFactor' is a fraction of the font size, above 0 and at most 1."])
    let (_, fine) = expand(component("    Text(\"a\").lineLimit(nil).minimumScaleFactor(0.5)"))
    #expect(fine.isEmpty)
  }

  @Test("F18: a text style over no text warns")
  func styleOverNothing() {
    let (text, diagnostics) = expand(component("    VStack { Rectangle(.red) }.font(.title)"))
    #expect(diagnostics == ["no Text is under this text style, so it styles nothing."])
    #expect(!text.contains("TextStyleElement"))
  }
}
