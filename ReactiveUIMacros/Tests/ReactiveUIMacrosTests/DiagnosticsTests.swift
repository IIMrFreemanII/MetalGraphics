import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import Testing

@testable import ReactiveUIMacrosPlugin

/// The expansion when the body failed to parse: just the stubs `@State`'s setters need,
/// so the only errors the user sees are the real ones.
private func stubsOnly(_ body: String) -> String {
  """
  final class C: SingleChildElement {
    @State var color: float4 = .blue

    @UIElementBuilder var body: [UIElementNode] {
  \(body)
    }

      private func __update_color() {
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

    @UIElementBuilder var body: [UIElementNode] {
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

        @UIElementBuilder var body: [UIElementNode] {
          VList(items: self.rows.filter { $0.visible }) { item in
            RowView(item: item)
          }
        }
      }
      """,
      expandedSource: """
      final class C: SingleChildElement {
        @State var rows: [Item] = []

        @UIElementBuilder var body: [UIElementNode] {
          VList(items: self.rows.filter { $0.visible }) { item in
            RowView(item: item)
          }
        }

          private func __update_rows() {
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

        @UIElementBuilder var body: [UIElementNode] {
          VList(items: self.rows) { item in
            RowView(item: item)
          }
        }
      }
      """,
      expandedSource: """
      final class C: SingleChildElement {
        @State var rows: Set<Item> = []

        @UIElementBuilder var body: [UIElementNode] {
          VList(items: self.rows) { item in
            RowView(item: item)
          }
        }

          private func __update_rows() {
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

          private func __update_rows() {
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

  // F9 is a warning, not an error: the expansion is still emitted. The suggested capture is
  // `weak` rather than `unowned` because a handler really can outlive its component — a list row
  // removed while the pointer is inside it is the ordinary case, not a bug — and `unowned` makes
  // that a crash where `weak` makes it a no-op.
  @Test("F9: a stored handler capturing self strongly")
  func handlerRetainCycle() {
    assertMacroExpansion(
      """
      @Component
      final class C: SingleChildElement {
        @State var color: float4 = .blue

        @UIElementBuilder var body: [UIElementNode] {
          Rectangle(self.color)
            .onTap { _ in
              self.color = .red
            }
        }
      }
      """,
      expandedSource: """
      final class C: SingleChildElement {
        @State var color: float4 = .blue

        @UIElementBuilder var body: [UIElementNode] {
          Rectangle(self.color)
            .onTap { _ in
              self.color = .red
            }
        }

          private var __context: UIContext? = nil

          private var __needsRefresh: Bool = false

          private var __built: Bool = false

          private var __n0a: Rectangle? = nil

          private var __n0b: HittableView? = nil

          public override func mount(_ context: UIContext) {
            self.__context = context
            if !self.__built {
              self.__built = true
              self.setChild(self.__build(context), context)
            } else if self.__needsRefresh {
              self.__needsRefresh = false
              self.__refreshAll()
            }
          }

          public override func unmount(_ context: UIContext) {
            self.__context = nil
          }

          private func __refreshAll() {
            self.__update_color()
          }

          private func __build(_ context: UIContext) -> UIElement {
            let n0a = Rectangle(self._color)
            self.__n0a = n0a
            let n0b = n0a.onTap { _ in
                  self.color = .red
                }
            self.__n0b = n0b
            var root: [UIElement] = []
            if let e = self.__n0b {
                root.append(e)
            }
            return root.first ?? EmptyElement()
          }

          private func __applyChildrenRoot(_ context: UIContext) {
            var children: [UIElement] = []
            if let e = self.__n0b {
                children.append(e)
            }
            self.setChild(children.first ?? EmptyElement(), context)
          }

          private func __update_color() {
            guard let context = self.__context else {
              self.__needsRefresh = true
              return
            }
            if let n = self.__n0a {
                n.setColor(self._color, context)
            }
          }
      }

      extension C: ReactiveComponent {
      }
      """,
      diagnostics: [
        DiagnosticSpec(
          message: "this handler is stored by the element, so capturing 'self' strongly creates a "
            + "reference cycle. Add '[weak self]'.",
          line: 7, column: 14, severity: .warning
        )
      ],
      macros: ["Component": ComponentMacro.self],
      applyFixIts: [], fixedSource: nil
    )
  }
}
