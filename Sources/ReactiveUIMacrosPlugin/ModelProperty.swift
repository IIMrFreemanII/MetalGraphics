import SwiftSyntax

/// Attributes recognised by spelling, as `@State` is: they mean something only next to
/// `@Model` or `@Component`, which read them in the same declaration.
enum AttributeName {
  static func named(_ attribute: AttributeSyntax) -> String? {
    attribute.attributeName.as(IdentifierTypeSyntax.self)?.name.text
      ?? attribute.attributeName.as(MemberTypeSyntax.self)?.name.text
  }

  static func has(_ name: String, in attributes: AttributeListSyntax) -> Bool {
    attributes.contains { element in
      guard case .attribute(let attribute) = element else { return false }
      return Self.named(attribute) == name
    }
  }
}

/// A stored property of a `@Model`, reduced to what `@Model` and `@ModelTracked` need.
struct TrackedProperty {
  let name: String
  let type: TypeSyntax

  /// Whether `@Model` tracks `decl`: every stored instance `var` not marked `@ModelIgnored`.
  /// Computed properties are left alone. One with `willSet`/`didSet` is tracked, so that
  /// `@ModelTracked` reports it rather than it silently not updating.
  static func isTracked(_ decl: VariableDeclSyntax) -> Bool {
    guard decl.bindingSpecifier.tokenKind == .keyword(.var) else { return false }
    let skipped: [Keyword] = [.static, .class, .lazy]
    if decl.modifiers.contains(where: { modifier in skipped.contains { modifier.name.tokenKind == .keyword($0) } }) {
      return false
    }
    if AttributeName.has("ModelIgnored", in: decl.attributes) || AttributeName.has("ModelTracked", in: decl.attributes) {
      return false
    }
    // An accessor macro cannot attach to `var a = 0, b = 1`; `@Model` reports it instead.
    guard decl.bindings.count == 1 else { return false }
    for binding in decl.bindings {
      guard let accessors = binding.accessorBlock else { continue }
      switch accessors.accessors {
      case .getter:
        return false
      case .accessors(let list):
        let observersOnly = list.allSatisfy {
          $0.accessorSpecifier.tokenKind == .keyword(.willSet) || $0.accessorSpecifier.tokenKind == .keyword(.didSet)
        }
        if !observersOnly { return false }
      }
    }
    return true
  }

  /// The single binding of a tracked `var`, or why it cannot be tracked.
  static let severalBindings = "@Model tracks one property per declaration; declare each on its own line."

  /// A stored instance `var` declaring several properties at once, which `@Model` cannot track.
  static func declaresSeveral(_ decl: VariableDeclSyntax) -> Bool {
    decl.bindingSpecifier.tokenKind == .keyword(.var) && decl.bindings.count > 1
      && !decl.modifiers.contains { $0.name.tokenKind == .keyword(.static) || $0.name.tokenKind == .keyword(.class) }
      && !AttributeName.has("ModelIgnored", in: decl.attributes)
      && decl.bindings.allSatisfy { $0.accessorBlock == nil }
  }

  static func parse(_ decl: VariableDeclSyntax) -> (property: TrackedProperty?, error: (message: String, node: Syntax)?) {
    guard decl.bindings.count == 1, let binding = decl.bindings.first else {
      return (nil, (Self.severalBindings, Syntax(decl)))
    }
    guard let name = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text else {
      return (nil, ("@Model requires a simple property name.", Syntax(binding.pattern)))
    }
    if let accessors = binding.accessorBlock {
      return (nil, (
        "@Model cannot track '\(name)', which has 'willSet'/'didSet'. Mark it '@ModelIgnored', or move the observer into a method.",
        Syntax(accessors)
      ))
    }
    guard let type = binding.typeAnnotation?.type else {
      return (nil, (
        "@Model requires an explicit type annotation, e.g. 'var \(name): Int = …', or '@ModelIgnored'.",
        Syntax(binding)
      ))
    }
    return (TrackedProperty(name: name, type: type), nil)
  }

  /// Every well-formed tracked property of a `@Model` class; `@ModelTracked` reports the rest.
  static func all(in members: MemberBlockItemListSyntax) -> [TrackedProperty] {
    members.compactMap { member in
      guard let decl = member.decl.as(VariableDeclSyntax.self), isTracked(decl) else { return nil }
      return parse(decl).property
    }
  }
}

/// A `@Bindable let model: AppModel` in a component: a `@Model` its body reads.
struct ModelProperty {
  let name: String
  let type: TypeSyntax

  static func hasBindableAttribute(_ decl: VariableDeclSyntax) -> Bool {
    AttributeName.has("Bindable", in: decl.attributes)
  }

  static func parse(_ decl: VariableDeclSyntax) -> (property: ModelProperty?, error: (message: String, node: Syntax)?) {
    if decl.bindingSpecifier.tokenKind != .keyword(.let) {
      return (nil, (
        "@Bindable requires a 'let': the component subscribes to the model it was mounted with, so the model cannot be swapped.",
        Syntax(decl.bindingSpecifier)
      ))
    }
    if decl.modifiers.contains(where: { $0.name.tokenKind == .keyword(.static) }) {
      return (nil, ("@Bindable cannot be applied to a 'static' property.", Syntax(decl)))
    }
    guard decl.bindings.count == 1, let binding = decl.bindings.first else {
      return (nil, ("@Bindable must declare exactly one property.", Syntax(decl)))
    }
    guard let name = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text else {
      return (nil, ("@Bindable requires a simple property name.", Syntax(binding.pattern)))
    }
    guard let type = binding.typeAnnotation?.type else {
      return (nil, ("@Bindable requires an explicit type annotation, e.g. 'let \(name): AppModel = .shared'.", Syntax(binding)))
    }
    return (ModelProperty(name: name, type: type), nil)
  }

  /// Every well-formed `@Bindable` in a component; `@Bindable` reports the rest.
  static func all(in members: MemberBlockItemListSyntax) -> [ModelProperty] {
    members.compactMap { member in
      guard let decl = member.decl.as(VariableDeclSyntax.self), hasBindableAttribute(decl) else { return nil }
      return parse(decl).property
    }
  }
}
