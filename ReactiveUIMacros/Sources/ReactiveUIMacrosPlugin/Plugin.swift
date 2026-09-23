import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct ReactiveUIMacrosPlugin: CompilerPlugin {
  let providingMacros: [Macro.Type] = [
    StateMacro.self,
    ComponentMacro.self,
  ]
}
