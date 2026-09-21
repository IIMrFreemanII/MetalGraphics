import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import Testing

@testable import ReactiveUIMacrosPlugin

let testMacros: [String: Macro.Type] = [
  "State": StateMacro.self,
  "Component": ComponentMacro.self,
]

@Suite("@State expansion")
struct StateMacroTests {

  // NOTE: assertMacroExpansion renders accessor-macro output with the original initializer
  // stripped. The real compiler keeps it — that is what the init accessor is for — and the app
  // build is the authoritative check.
  @Test("value type expands to an init accessor over private storage")
  func valueType() {
    assertMacroExpansion(
      """
      class C {
        @State var color: float4 = .blue
      }
      """,
      expandedSource: """
      class C {
        var color: float4 {
            @storageRestrictions(initializes: _color)
            init(initialValue) {
              _color = initialValue
            }
            get {
              _color
            }
            set {
              _color = newValue
              self.__update_color()
            }
            _modify {
              yield &_color
              self.__update_color()
            }
        }

        private var _color: float4

        private func __requiresComponent_color() {
          let _: any ReactiveComponent = self
        }
      }
      """,
      macros: testMacros
    )
  }

  @Test("optional type")
  func optionalType() {
    assertMacroExpansion(
      """
      class C {
        @State var selected: Item? = nil
      }
      """,
      expandedSource: """
      class C {
        var selected: Item? {
            @storageRestrictions(initializes: _selected)
            init(initialValue) {
              _selected = initialValue
            }
            get {
              _selected
            }
            set {
              _selected = newValue
              self.__update_selected()
            }
            _modify {
              yield &_selected
              self.__update_selected()
            }
        }

        private var _selected: Item?

        private func __requiresComponent_selected() {
          let _: any ReactiveComponent = self
        }
      }
      """,
      macros: testMacros
    )
  }

  @Test("an inferred type is rejected: a macro sees syntax only")
  func inferredTypeIsRejected() {
    assertMacroExpansion(
      """
      class C {
        @State var isLoggedIn = false
      }
      """,
      expandedSource: """
      class C {
        var isLoggedIn = false
      }
      """,
      diagnostics: [
        DiagnosticSpec(
          message: "@State requires an explicit type annotation, e.g. 'var isLoggedIn: Bool = …'.",
          line: 2,
          column: 14
        )
      ],
      macros: testMacros
    )
  }

  @Test("'let' is rejected")
  func letIsRejected() {
    assertMacroExpansion(
      """
      class C {
        @State let color: float4 = .blue
      }
      """,
      expandedSource: """
      class C {
        let color: float4 = .blue
      }
      """,
      diagnostics: [
        DiagnosticSpec(
          message: "@State requires a stored 'var'; 'let' can never change.",
          line: 2,
          column: 10
        )
      ],
      macros: testMacros
    )
  }
}
