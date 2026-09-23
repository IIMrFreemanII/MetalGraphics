import SwiftSyntaxMacros
import SwiftSyntaxMacrosGenericTestSupport
import Testing

@testable import ReactiveUIMacrosPlugin

/// The expansion when the body failed to parse: just the stubs `@State`'s setters need,
/// so the only errors the user sees are the real ones.
private func stubsOnly(_ body: String) -> String {
  """
  final class C: SingleChildElement {
    @State var color: float4 = .blue

    @UIElementBuilder var body: [UIElement] {
  \(body)
    }

      private func __update_color(_ animated: Bool = true) {
      }
  }

  extension C: ReactiveComponent {
  }
  """
}

private func component(_ body: String) -> String {
  """
  @Component
  final class C: SingleChildElement {
    @State var color: float4 = .blue

    @UIElementBuilder var body: [UIElement] {
  \(body)
    }
  }
  """
}

@Suite("Diagnostics")
struct DiagnosticsTests {

  @Test("F1: a helper method the macro cannot see into")
  func helperMethod() {
    assertMacroExpansion(
      component("    self.row()"),
      expandedSource: stubsOnly("    self.row()"),
      diagnostics: [
        DiagnosticSpec(
          message: "@Component resolves state at compile time and cannot see inside 'row'. "
            + "Write the element inline, or extract it into its own @Component.",
          line: 6, column: 5
        )
      ],
      macros: ["Component": ComponentMacro.self],
      applyFixIts: [], fixedSource: nil
    )
  }

  @Test("F3: a local binding captures its value once — today this fails silently")
  func localBinding() {
    assertMacroExpansion(
      component("    let c = self.color\n    Rectangle(c)"),
      expandedSource: stubsOnly("    let c = self.color\n    Rectangle(c)"),
      diagnostics: [
        DiagnosticSpec(
          message: "a local binding in a component body captures its value once and will never "
            + "update. Use the state directly in the element argument instead.",
          line: 6, column: 5
        )
      ],
      macros: ["Component": ComponentMacro.self],
      applyFixIts: [], fixedSource: nil
    )
  }

  @Test("F4: an element that is not in the catalog")
  func unknownElement() {
    assertMacroExpansion(
      component("    Triangle(.red)"),
      expandedSource: stubsOnly("    Triangle(.red)"),
      diagnostics: [
        DiagnosticSpec(
          message: "'Triangle' is not known to @Component. Add it to ElementCatalog.swift, "
            + "or extract it into its own @Component.",
          line: 6, column: 5
        )
      ],
      macros: ["Component": ComponentMacro.self],
      applyFixIts: [], fixedSource: nil
    )
  }

  @Test("F8: generated storage is not something to write in a body")
  func backingStorage() {
    assertMacroExpansion(
      component("    Rectangle(self._color)"),
      expandedSource: stubsOnly("    Rectangle(self._color)"),
      diagnostics: [
        DiagnosticSpec(
          message: "'_color' is generated storage. Write 'self.color' instead.",
          line: 6, column: 15
        )
      ],
      macros: ["Component": ComponentMacro.self],
      applyFixIts: [], fixedSource: nil
    )
  }

  // This restriction is load-bearing twice over: it is what makes the generic argument
  // resolvable at all, and it is also what lets the generated mutation methods update the
  // list incrementally \u{2014} children can only be assumed index-for-index with the array
  // if the list is bound to exactly that array.
  @Test("F10: a list's items must be the @State array itself, not an expression")
  func listItemsExpression() {
    assertMacroExpansion(
      """
      @Component
      final class C: SingleChildElement {
        @State var rows: [Item] = []

        @UIElementBuilder var body: [UIElement] {
          VList(items: self.rows.filter { $0.visible }) { item in
            RowView(item: item)
          }
        }
      }
      """,
      expandedSource: """
      final class C: SingleChildElement {
        @State var rows: [Item] = []

        @UIElementBuilder var body: [UIElement] {
          VList(items: self.rows.filter { $0.visible }) { item in
            RowView(item: item)
          }
        }

          private func __update_rows(_ animated: Bool = true) {
          }

          public func appendRows(_ element: Item) {
            self._rows.append(element)
            self.__update_rows()
          }

          public func insertRows(_ element: Item, at position: Int) {
            let index = Swift.min(Swift.max(position, 0), self._rows.count)
            self._rows.insert(element, at: index)
            self.__update_rows()
          }

          @discardableResult
          public func removeRows(at index: Int) -> Item? {
            guard self._rows.indices.contains(index) else {
                return nil
            }
            let removed = self._rows.remove(at: index)
            self.__update_rows()
            return removed
          }

          public func removeRows(where predicate: (Item) -> Bool) {
            let matches = self._rows.indices.filter {
                predicate(self._rows[$0])
            }
            guard matches.count == 1, let index = matches.first else {
              guard !matches.isEmpty else {
                  return
              }
              self._rows.removeAll(where: predicate)
              self.__update_rows()
              return
            }
            self._rows.remove(at: index)
            self.__update_rows()
          }

          public func replaceRows(_ newValue: [Item]) {
            self._rows = newValue
            self.__update_rows()
          }
      }

      extension C: ReactiveComponent {
      }
      """,
      diagnostics: [
        DiagnosticSpec(
          message: "'VList' needs its 'items:' to be a @State array property, written directly as 'self.<name>' \u{2014} 'self.rows.filter { $0.visible }' is an expression, not a property.",
          line: 6, column: 18
        )
      ],
      macros: ["Component": ComponentMacro.self],
      applyFixIts: [], fixedSource: nil
    )
  }

  // The element type comes from the written annotation, so it has to be one the macro can
  // take apart: `[X]` or `Array<X>`.
  @Test("F10: a list's items must be annotated as an array")
  func listItemsNotAnArray() {
    assertMacroExpansion(
      """
      @Component
      final class C: SingleChildElement {
        @State var rows: Set<Item> = []

        @UIElementBuilder var body: [UIElement] {
          VList(items: self.rows) { item in
            RowView(item: item)
          }
        }
      }
      """,
      expandedSource: """
      final class C: SingleChildElement {
        @State var rows: Set<Item> = []

        @UIElementBuilder var body: [UIElement] {
          VList(items: self.rows) { item in
            RowView(item: item)
          }
        }

          private func __update_rows(_ animated: Bool = true) {
          }
      }

      extension C: ReactiveComponent {
      }
      """,
      diagnostics: [
        DiagnosticSpec(
          message: "'VList' needs its 'items:' to be a @State array property, written directly as 'self.<name>' \u{2014} 'rows' is annotated 'Set<Item>', which is not an array.",
          line: 6, column: 18
        )
      ],
      macros: ["Component": ComponentMacro.self],
      applyFixIts: [], fixedSource: nil
    )
  }

  // Reported against the component, rather than left to surface as a redeclaration error
  // pointing into generated source the user never wrote. Note the stubs are still emitted:
  // one real error should not drag a page of \"cannot find\" errors along with it.
  @Test("F11: a generated mutation method collides with one the user wrote")
  func mutationNameCollision() {
    assertMacroExpansion(
      """
      @Component
      final class C: SingleChildElement {
        @State var rows: [Item] = []

        func appendRows(_ item: Item) {
        }
      }
      """,
      expandedSource: """
      final class C: SingleChildElement {
        @State var rows: [Item] = []

        func appendRows(_ item: Item) {
        }

          private func __update_rows(_ animated: Bool = true) {
          }

          public func appendRows(_ element: Item) {
            self._rows.append(element)
            self.__update_rows()
          }

          public func insertRows(_ element: Item, at position: Int) {
            let index = Swift.min(Swift.max(position, 0), self._rows.count)
            self._rows.insert(element, at: index)
            self.__update_rows()
          }

          @discardableResult
          public func removeRows(at index: Int) -> Item? {
            guard self._rows.indices.contains(index) else {
                return nil
            }
            let removed = self._rows.remove(at: index)
            self.__update_rows()
            return removed
          }

          public func removeRows(where predicate: (Item) -> Bool) {
            let matches = self._rows.indices.filter {
                predicate(self._rows[$0])
            }
            guard matches.count == 1, let index = matches.first else {
              guard !matches.isEmpty else {
                  return
              }
              self._rows.removeAll(where: predicate)
              self.__update_rows()
              return
            }
            self._rows.remove(at: index)
            self.__update_rows()
          }

          public func replaceRows(_ newValue: [Item]) {
            self._rows = newValue
            self.__update_rows()
          }
      }

      extension C: ReactiveComponent {
      }
      """,
      diagnostics: [
        DiagnosticSpec(
          message: "@Component generates 'appendRows' for the @State array 'rows'. Rename your own method, or the property.",
          line: 2, column: 13
        )
      ],
      macros: ["Component": ComponentMacro.self],
      applyFixIts: [], fixedSource: nil
    )
  }

  @Test("F12: an animation scope whose value reads no state would never fire")
  func animationValueReadsNoState() {
    assertMacroExpansion(
      component("    Rectangle(.red).animation(.spring(), value: 1)"),
      expandedSource: stubsOnly("    Rectangle(.red).animation(.spring(), value: 1)"),
      diagnostics: [
        DiagnosticSpec(
          message: "'.animation(_:value:)' animates the changes a write to the states 'value:' reads "
            + "makes, so 'value:' must read a @State property, e.g. 'value: self.isOn'.",
          line: 6, column: 49
        )
      ],
      macros: ["Component": ComponentMacro.self],
      applyFixIts: [], fixedSource: nil
    )
  }

  @Test("F12: an animation scope needs its value")
  func animationWithoutValue() {
    assertMacroExpansion(
      component("    Rectangle(.red).animation(.spring())"),
      expandedSource: stubsOnly("    Rectangle(.red).animation(.spring())"),
      diagnostics: [
        DiagnosticSpec(
          message: "write '.animation(<animation>, value: self.<state>)'.",
          line: 6, column: 5
        )
      ],
      macros: ["Component": ComponentMacro.self],
      applyFixIts: [], fixedSource: nil
    )
  }

  @Test("F13: an in-place modifier must be called on its own type, not on a wrapper")
  func inPlaceModifierOnWrapper() {
    assertMacroExpansion(
      component("    Text(\"a\").padding(Inset(all: 1)).font(.system(size: 12))"),
      expandedSource: stubsOnly("    Text(\"a\").padding(Inset(all: 1)).font(.system(size: 12))"),
      diagnostics: [
        DiagnosticSpec(
          message: "'.font' applies to Text only; call it directly on the Text, before 'Padding' wraps it.",
          line: 6, column: 38
        )
      ],
      macros: ["Component": ComponentMacro.self],
      applyFixIts: [], fixedSource: nil
    )
  }
}
