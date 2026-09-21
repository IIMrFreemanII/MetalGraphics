import SwiftSyntax
import SwiftSyntaxMacros

// Reads the component's declarative `body` and emits straight-line code that owns the element
// tree: one field per node, and one `__update_<state>` per `@State` that assigns directly into
// the nodes that state feeds. Nothing is decided at runtime.
//
// `body` itself is never executed. It stays in the source only so the declarative form keeps
// type-checking, which is why every library initializer must keep its @autoclosure signature.
public struct ComponentMacro {}

extension ComponentMacro: MemberMacro {
  public static func expansion(
    of node: AttributeSyntax,
    providingMembersOf declaration: some DeclGroupSyntax,
    conformingTo protocols: [TypeSyntax],
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    guard let classDecl = declaration.as(ClassDeclSyntax.self) else {
      context.error("F6", "@Component can only be applied to a class.", at: declaration)
      return []
    }

    let states = StateProperty.all(in: classDecl.memberBlock.members)

    // A component's tree lives in `body`. Until one exists the macro does not own the
    // lifecycle, so it leaves a hand-written `mount` alone.
    let hasBody = classDecl.memberBlock.members.contains { member in
      member.decl.as(VariableDeclSyntax.self)?
        .bindings.first?.pattern.as(IdentifierPatternSyntax.self)?.identifier.text == "body"
    }

    let declaredFunctions = Set(classDecl.memberBlock.members.compactMap {
      $0.decl.as(FunctionDeclSyntax.self)?.name.text
    })

    // F7: once the macro generates the lifecycle, the user's own hooks are onMount/onUnmount.
    // Catch an override before it silently shadows the generated one.
    for member in classDecl.memberBlock.members where hasBody {
      guard let fn = member.decl.as(FunctionDeclSyntax.self) else { continue }
      let name = fn.name.text
      if name == "mount" || name == "unmount" {
        context.error(
          "F7",
          "@Component generates '\(name)(_:)'. Put your own logic in 'on\(name.prefix(1).uppercased() + name.dropFirst())(_:)' instead.",
          at: fn.name
        )
      }
    }

    // F11: the mutation methods are the one piece of generated code that lands in the
    // component's own namespace, so a clash with a hand-written method is reported here
    // rather than as a redeclaration error pointing at generated source.
    for state in states {
      guard BodyParser.arrayElementType(state.type) != nil else { continue }
      let generated = [
        Naming.mutationAppend(state.name), Naming.mutationInsert(state.name),
        Naming.mutationRemove(state.name), Naming.mutationReplace(state.name),
      ]
      for name in generated where declaredFunctions.contains(name) {
        context.error(
          "F11",
          "@Component generates '\(name)' for the @State array '\(state.name)'. "
            + "Rename your own method, or the property.",
          at: classDecl.name
        )
      }
    }

    // Without a body there is no tree to own: emit the update stubs the @State setters need
    // and nothing else.
    guard let (_, statements) = BodyParser.findBody(in: classDecl.memberBlock.members) else {
      return stubs(states)
    }

    let parser = BodyParser(stateProperties: states, context: context)
    guard let nodes = parser.parse(statements, path: "") else {
      // The parser already diagnosed the problem. Still emit the stubs so the only errors
      // the user sees are the real ones, not a cascade of "cannot find __update_x".
      return stubs(states)
    }

    guard nodes.count == 1 else {
      context.error("F6", "a component body must produce exactly one root element, got \(nodes.count).", at: classDecl.name)
      return []
    }

    // `onMount`/`onUnmount` are not generated: they are `open` members of `UIElement`, called by
    // its mount traversal. Declaring them there rather than here is what lets Xcode offer them as
    // overrides — a member injected into the class is invisible until the macro has expanded.
    return CodeGen(states: states, nodes: nodes).generate()
  }
}

extension ComponentMacro {
  /// What to emit when there is no tree to generate against, either because the component has
  /// no `body` yet or because parsing it failed.
  ///
  /// Every name the rest of the file can already refer to has to keep existing, or one real
  /// error turns into a page of "cannot find" ones: `@State`'s setter calls `__update_x`, and
  /// any call site of a mutation method is expecting it to be there. With no nodes to bind,
  /// `CodeGen` emits exactly the non-incremental form of those methods.
  fileprivate static func stubs(_ states: [StateProperty]) -> [DeclSyntax] {
    let updates: [DeclSyntax] = states.map(\.name).map { name in
      """
      private func \(raw: Naming.update(name))() {
      }
      """
    }
    return updates + CodeGen(states: states, nodes: []).mutations()
  }
}

extension ComponentMacro: ExtensionMacro {
  public static func expansion(
    of node: AttributeSyntax,
    attachedTo declaration: some DeclGroupSyntax,
    providingExtensionsOf type: some TypeSyntaxProtocol,
    conformingTo protocols: [TypeSyntax],
    in context: some MacroExpansionContext
  ) throws -> [ExtensionDeclSyntax] {
    guard declaration.is(ClassDeclSyntax.self) else { return [] }
    return [
      try ExtensionDeclSyntax("extension \(type.trimmed): \(raw: Naming.componentProtocol) {}")
    ]
  }
}
