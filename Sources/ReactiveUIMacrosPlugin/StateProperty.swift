import SwiftSyntax

// A `@State` declaration, reduced to what both macros need.
struct StateProperty {
  let name: String
  let type: TypeSyntax
  let binding: PatternBindingSyntax

  /// Recognises `@State` by spelling. That is sufficient because `@State` and `@Component`
  /// must appear in the same declaration for either to mean anything.
  static func isStateAttribute(_ attribute: AttributeSyntax) -> Bool {
    guard let name = attribute.attributeName.as(IdentifierTypeSyntax.self)?.name.text
      ?? attribute.attributeName.as(MemberTypeSyntax.self)?.name.text
    else { return false }
    return name == "State"
  }

  static func hasStateAttribute(_ decl: VariableDeclSyntax) -> Bool {
    decl.attributes.contains { attr in
      guard case .attribute(let a) = attr else { return false }
      return isStateAttribute(a)
    }
  }

  /// Extracts the single binding of a `@State var`, or reports why it cannot.
  /// `error` is nil when the declaration is well-formed.
  static func parse(_ decl: VariableDeclSyntax) -> (property: StateProperty?, error: (id: String, message: String, node: Syntax)?) {
    if decl.bindingSpecifier.tokenKind == .keyword(.let) {
      return (nil, ("F5", "@State requires a stored 'var'; 'let' can never change.", Syntax(decl.bindingSpecifier)))
    }
    if decl.modifiers.contains(where: { $0.name.tokenKind == .keyword(.static) }) {
      return (nil, ("F5", "@State cannot be applied to a 'static' property.", Syntax(decl)))
    }
    guard decl.bindings.count == 1, let binding = decl.bindings.first else {
      return (nil, ("F5", "@State must declare exactly one property.", Syntax(decl)))
    }
    guard let identifier = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text else {
      return (nil, ("F5", "@State requires a simple property name.", Syntax(binding.pattern)))
    }
    if let accessors = binding.accessorBlock {
      return (nil, ("F5", "@State requires a stored 'var'; '\(identifier)' already has accessors.", Syntax(accessors)))
    }
    guard let type = binding.typeAnnotation?.type else {
      // The peer needs a written type: a macro sees syntax only and cannot infer one.
      return (nil, ("F5", "@State requires an explicit type annotation, e.g. 'var \(identifier): Bool = …'.", Syntax(binding)))
    }
    return (StateProperty(name: identifier, type: type, binding: binding), nil)
  }

  /// Every `@State` in a type's member block. Malformed ones are skipped; `@State` itself
  /// reports those, so `@Component` does not duplicate the diagnostic.
  static func all(in members: MemberBlockItemListSyntax) -> [StateProperty] {
    members.compactMap { member in
      guard let decl = member.decl.as(VariableDeclSyntax.self), hasStateAttribute(decl) else { return nil }
      return parse(decl).property
    }
  }
}
