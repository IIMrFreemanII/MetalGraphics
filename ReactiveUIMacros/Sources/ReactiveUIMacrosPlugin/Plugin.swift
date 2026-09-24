import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
enum PluginMain {
  static func main() throws {
    StdinFilter.install()
    try ReactiveUIMacrosPlugin.main()
  }
}

struct ReactiveUIMacrosPlugin: CompilerPlugin {
  let providingMacros: [Macro.Type] = [
    StateMacro.self,
    ComponentMacro.self,
  ]
}
