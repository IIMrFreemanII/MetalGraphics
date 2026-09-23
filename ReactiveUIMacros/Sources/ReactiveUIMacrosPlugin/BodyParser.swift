import SwiftSyntax
import SwiftSyntaxMacros

// Reads a component's `body` and produces the IR the code generator walks.
//
// `body` is never executed. Parsing it is purely syntactic: the macro resolves *spellings*
// against the catalog, not types. Anything it does not recognise is rejected rather than
// guessed at, so a silently-wrong expansion is not a possible outcome.
struct BodyParser {
  /// Full declarations, not just names: resolving a list's generic argument needs the written
  /// type annotation of the `@State` its `items:` refers to.
  let stateProperties: [StateProperty]
  let context: any MacroExpansionContext

  var states: Set<String> { Set(stateProperties.map(\.name)) }

  /// Finds the `@UIElementBuilder var body` member.
  static func findBody(in members: MemberBlockItemListSyntax) -> (decl: VariableDeclSyntax, statements: CodeBlockItemListSyntax)? {
    for member in members {
      guard let decl = member.decl.as(VariableDeclSyntax.self),
            let binding = decl.bindings.first,
            binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text == "body",
            let accessor = binding.accessorBlock
      else { continue }

      switch accessor.accessors {
      case .getter(let statements):
        return (decl, statements)
      case .accessors(let list):
        for a in list where a.accessorSpecifier.tokenKind == .keyword(.get) {
          if let body = a.body { return (decl, body.statements) }
        }
      }
    }
    return nil
  }

  // MARK: - Statements

  /// Parses a builder block into one node per statement.
  func parse(_ statements: CodeBlockItemListSyntax, path: String) -> [NodeIR]? {
    var result: [NodeIR] = []
    var index = 0

    for statement in statements {
      let childPath = path.isEmpty ? "\(index)" : "\(path)_\(index)"

      switch statement.item {
      case .expr(let expr):
        if let ifExpr = expr.as(IfExprSyntax.self) {
          guard let branch = parseBranch(ifExpr, path: childPath) else { return nil }
          result.append(.branch(branch))
        } else {
          guard let element = parseElement(expr, path: childPath) else { return nil }
          result.append(.element(element))
        }
        index += 1

      case .stmt(let stmt):
        // `if` can reach us wrapped in an ExpressionStmt depending on how it was written.
        if let exprStmt = stmt.as(ExpressionStmtSyntax.self), let ifExpr = exprStmt.expression.as(IfExprSyntax.self) {
          guard let branch = parseBranch(ifExpr, path: childPath) else { return nil }
          result.append(.branch(branch))
          index += 1
          continue
        }
        context.error(
          "F2",
          "only 'if', 'if else' and 'if let' are supported in a component body. "
            + "Use VList/HList for collections.",
          at: stmt
        )
        return nil

      case .decl(let decl):
        // F3: today this fails *silently* — the value is captured once and the element keeps a
        // stale value forever. Turn it into a compile error.
        context.error(
          "F3",
          "a local binding in a component body captures its value once and will never update. "
            + "Use the state directly in the element argument instead.",
          at: decl
        )
        return nil
      }
    }
    return result
  }

  // MARK: - Branches

  private func parseBranch(_ ifExpr: IfExprSyntax, path: String) -> BranchIR? {
    guard ifExpr.conditions.count == 1, let condition = ifExpr.conditions.first else {
      context.error("F2", "a component body supports a single condition per 'if'.", at: ifExpr.conditions)
      return nil
    }

    let kind: BranchIR.Kind
    let reads: Set<String>

    switch condition.condition {
    case .expression(let expr):
      let scanned = StateRewriter.scan(expr, states: states)
      kind = .condition(scanned.expr)
      reads = scanned.reads

    case .optionalBinding(let binding):
      guard let name = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text else {
        context.error("F2", "'if let' requires a simple name.", at: binding.pattern)
        return nil
      }
      // `if let x { … }` is shorthand for `if let x = x`.
      let value = binding.initializer?.value ?? "\(raw: name)"
      let scanned = StateRewriter.scan(value, states: states)
      kind = .optional(name: name, value: scanned.expr)
      reads = scanned.reads

    default:
      context.error("F2", "only 'if' and 'if let' conditions are supported in a component body.", at: condition)
      return nil
    }

    guard let thenArm = parse(ifExpr.body.statements, path: "\(path)_0") else { return nil }

    var elseArm: [NodeIR] = []
    if let elseBody = ifExpr.elseBody {
      switch elseBody {
      case .codeBlock(let block):
        guard let parsed = parse(block.statements, path: "\(path)_1") else { return nil }
        elseArm = parsed
      case .ifExpr(let nested):
        // `else if` — one more branch, occupying the else arm's single slot.
        guard let parsed = parseBranch(nested, path: "\(path)_1_0") else { return nil }
        elseArm = [.branch(parsed)]
      }
    }

    return BranchIR(path: path, kind: kind, reads: reads, arms: [thenArm, elseArm])
  }

  // MARK: - Elements

  /// F8: things that are legal Swift but wrong in a component body.
  /// Returns false when it reported an error, so parsing stops rather than generating
  /// code the user will never want.
  private func checkExpression(_ expr: ExprSyntax) -> Bool {
    final class Checker: SyntaxVisitor {
      let parser: BodyParser
      var ok = true
      init(_ parser: BodyParser) {
        self.parser = parser
        super.init(viewMode: .sourceAccurate)
      }

      override func visit(_ node: MemberAccessExprSyntax) -> SyntaxVisitorContinueKind {
        let name = node.declName.baseName.text
        if node.base?.as(DeclReferenceExprSyntax.self)?.baseName.tokenKind == .keyword(.self),
           name.hasPrefix("_"), parser.states.contains(String(name.dropFirst()))
        {
          parser.context.error(
            "F8",
            "'\(name)' is generated storage. Write 'self.\(name.dropFirst())' instead.",
            at: node
          )
          ok = false
        }
        return .visitChildren
      }

      // Reads inside a closure are not dependency sites, and `self.color` there is correct.
      override func visit(_ node: ClosureExprSyntax) -> SyntaxVisitorContinueKind {
        .skipChildren
      }
    }
    let checker = Checker(self)
    checker.walk(expr)
    return checker.ok
  }

  /// The closure a handler modifier was given, for `__armHandlers` to assign later.
  ///
  /// It is deliberately taken out of the chain rather than emitted with it. A handler captures
  /// `self` strongly and the element stores it, so an emitted-in-place closure would make the
  /// component reach itself and never deallocate. Assigning on mount and clearing on unmount
  /// confines that loop to the window where the tree is live anyway — which is what lets a body
  /// be written without a capture list.
  private func handlerClosure(_ call: FunctionCallExprSyntax, _ spec: ModifierSpec) -> BoundHandler? {
    guard let handler = spec.handler else { return nil }
    let closure = call.trailingClosure
      ?? call.arguments.compactMap { $0.expression.as(ClosureExprSyntax.self) }.first
    guard let closure else { return nil }

    return BoundHandler(property: handler.property, closure: ExprSyntax(closure))
  }

  private func parseElement(_ expr: ExprSyntax, path: String) -> ElementIR? {
    guard checkExpression(expr) else { return nil }

    // Peel the chain from the outside in, then reverse so the constructor comes first.
    var calls: [FunctionCallExprSyntax] = []
    var current = expr

    while true {
      guard let call = current.as(FunctionCallExprSyntax.self) else {
        context.error(
          "F4",
          "'\(current.trimmedDescription)' is not an element the component macro recognises.",
          at: current
        )
        return nil
      }
      calls.append(call)

      // A modifier is applied to another call. `self.row()` is a member access too, but its
      // base is not a call — that is a helper method, and it is the root we report on.
      if let member = call.calledExpression.as(MemberAccessExprSyntax.self),
         let base = member.base, base.is(FunctionCallExprSyntax.self)
      {
        current = base            // a modifier: keep peeling
        continue
      }
      break                        // reached the root
    }
    calls.reverse()

    guard let ctorCall = calls.first else { return nil }
    guard let ctorName = ctorCall.calledExpression.as(DeclReferenceExprSyntax.self)?.baseName.text else {
      // `self.row(item)` and friends land here.
      if let member = ctorCall.calledExpression.as(MemberAccessExprSyntax.self) {
        context.error(
          "F1",
          "@Component resolves state at compile time and cannot see inside '\(member.declName.baseName.text)'. "
            + "Write the element inline, or extract it into its own @Component.",
          at: ctorCall
        )
      } else {
        context.error("F4", "unrecognised element expression.", at: ctorCall)
      }
      return nil
    }
    guard let typeSpec = ElementCatalog.types[ctorName] else {
      context.error(
        "F4",
        "'\(ctorName)' is not known to @Component. Add it to ElementCatalog.swift, "
          + "or extract it into its own @Component.",
        at: ctorCall
      )
      return nil
    }

    var chain: [ChainLink] = []
    var scopes: [AnimationScope] = []

    // A generic element (`VList<T>`) needs its argument spelled out in the node field's type,
    // and the macro can only get it from the written annotation of the @State being passed.
    var fieldType = typeSpec.fieldType
    if let label = typeSpec.genericOverItemsOf {
      guard let element = elementTypeOfItemsArgument(ctorCall, label: label, typeSpec: typeSpec)
      else { return nil }
      fieldType = "\(typeSpec.name)<\(element)>"
    }

    let (ctorBound, contentClosure) = parseConstructorArgs(ctorCall, typeSpec)
    chain.append(
      ChainLink(
        field: Naming.node(path, 0), local: Naming.local(path, 0),
        type: fieldType, kind: .constructor(call: ctorCall, type: typeSpec), bound: ctorBound
      )
    )

    for call in calls.dropFirst() {
      guard let member = call.calledExpression.as(MemberAccessExprSyntax.self) else { return nil }
      let name = member.declName.baseName.text
      guard let spec = ElementCatalog.modifiers[name] else {
        context.error(
          "F4",
          "'.\(name)' is not a modifier known to @Component. Add it to ElementCatalog.swift.",
          at: member.declName
        )
        return nil
      }
      if spec.isScope {
        guard let scope = parseAnimationScope(call, path: path, upToLink: chain.count, index: scopes.count)
        else { return nil }
        scopes.append(scope)
        continue
      }
      // F13: an in-place modifier sets a property of what it is called on, so it has to be
      // called on that type, not on a wrapper around it.
      if let target = spec.inPlaceOn, let receiver = chain.last, receiver.type != target {
        context.error(
          "F13",
          "'.\(name)' applies to \(target) only; call it directly on the \(target), before '\(receiver.type)' wraps it.",
          at: member.declName
        )
        return nil
      }
      // Named by position among the links, so a scope marker leaves no gap in the lettering.
      chain.append(
        ChainLink(
          field: Naming.node(path, chain.count), local: Naming.local(path, chain.count),
          type: spec.produces, kind: .modifier(call: call, spec: spec),
          bound: parseModifierArgs(call, spec), handler: handlerClosure(call, spec)
        )
      )
    }

    var children: [NodeIR] = []
    if let contentClosure {
      guard let parsed = parse(contentClosure.statements, path: path) else { return nil }
      children = parsed
      if typeSpec.arity == .leaf, !children.isEmpty {
        context.error("F6", "'\(typeSpec.name)' does not take content.", at: contentClosure)
        return nil
      }
      if typeSpec.arity == .single, children.count > 1 {
        context.error("F6", "'\(typeSpec.name)' takes a single child, got \(children.count).", at: contentClosure)
        return nil
      }
    }

    return ElementIR(path: path, chain: chain, children: children, arity: typeSpec.arity, scopes: scopes)
  }

  // MARK: - Animation scopes

  /// F12: `.animation(A, value: V)` animates writes to the states `V` reads, so `V` has to read
  /// at least one. Anything else would be a scope that never fires.
  private func parseAnimationScope(
    _ call: FunctionCallExprSyntax, path: String, upToLink: Int, index: Int
  ) -> AnimationScope? {
    let arguments = Array(call.arguments)
    guard arguments.count == 2, arguments[0].label == nil, arguments[1].label?.text == "value" else {
      context.error("F12", "write '.animation(<animation>, value: self.<state>)'.", at: call)
      return nil
    }

    let triggers = StateRewriter.scan(arguments[1].expression, states: states).reads
    guard !triggers.isEmpty else {
      context.error(
        "F12",
        "'.animation(_:value:)' animates the changes a write to the states 'value:' reads makes, "
          + "so 'value:' must read a @State property, e.g. 'value: self.isOn'.",
        at: arguments[1].expression
      )
      return nil
    }

    let (animation, reads) = StateRewriter.scan(arguments[0].expression, states: states)
    return AnimationScope(
      upToLink: upToLink, animation: animation, triggers: triggers,
      constantField: Self.isConstant(animation, reads: reads)
        ? Naming.animationConstant(path, index) : nil
    )
  }

  /// True for an expression that can be evaluated once, in a `static let`: it reads no state and
  /// mentions neither `self` (which a static context has no instance for) nor `Self`, which a
  /// stored property's initializer cannot reference. `Self.x` names a static already, so
  /// evaluating it in place costs nothing.
  private static func isConstant(_ expr: ExprSyntax, reads: Set<String>) -> Bool {
    guard reads.isEmpty else { return false }
    return !expr.tokens(viewMode: .sourceAccurate).contains {
      $0.tokenKind == .keyword(.self) || $0.tokenKind == .keyword(.Self)
    }
  }

  // MARK: - Generic arguments

  /// F10: resolves `items: self.items` to the `DemoItem` in `@State var items: [DemoItem]`.
  ///
  /// The argument must be a direct reference to a `@State` array. That is not only what makes
  /// the type resolvable — it is also what lets the generated mutation methods update the list
  /// incrementally, since the list's children can then be assumed index-for-index with that
  /// array. Anything else is rejected rather than quietly falling back.
  private func elementTypeOfItemsArgument(
    _ call: FunctionCallExprSyntax, label: String, typeSpec: TypeSpec
  ) -> String? {
    func reject(_ reason: String, at node: some SyntaxProtocol) -> String? {
      context.error(
        "F10",
        "'\(typeSpec.name)' needs its '\(label):' to be a @State array property, written "
          + "directly as 'self.<name>' \u{2014} \(reason).",
        at: node
      )
      return nil
    }

    guard let argument = call.arguments.first(where: { $0.label?.text == label }) else {
      return reject("no '\(label):' argument was given", at: call)
    }

    // `self.items`, or a bare `items` inside the builder.
    let expr = argument.expression
    var name: String? = nil
    if let member = expr.as(MemberAccessExprSyntax.self),
       member.base?.as(DeclReferenceExprSyntax.self)?.baseName.tokenKind == .keyword(.self)
    {
      name = member.declName.baseName.text
    } else if let reference = expr.as(DeclReferenceExprSyntax.self) {
      name = reference.baseName.text
    }

    guard let name else {
      return reject("'\(expr.trimmedDescription)' is an expression, not a property", at: expr)
    }
    guard let property = stateProperties.first(where: { $0.name == name }) else {
      return reject("'\(name)' is not a @State property of this component", at: expr)
    }
    guard let element = Self.arrayElementType(property.type) else {
      return reject(
        "'\(name)' is annotated '\(property.type.trimmedDescription)', which is not an array",
        at: expr
      )
    }
    return element
  }

  /// `[DemoItem]` or `Array<DemoItem>` -> `DemoItem`.
  static func arrayElementType(_ type: TypeSyntax) -> String? {
    if let array = type.as(ArrayTypeSyntax.self) {
      return array.element.trimmedDescription
    }
    if let identifier = type.as(IdentifierTypeSyntax.self), identifier.name.text == "Array",
       let arguments = identifier.genericArgumentClause?.arguments, arguments.count == 1,
       let only = arguments.first
    {
      return only.trimmedDescription
    }
    return nil
  }

  // MARK: - Arguments

  /// Reactive constructor arguments, plus the content closure if there is one.
  private func parseConstructorArgs(
    _ call: FunctionCallExprSyntax, _ spec: TypeSpec
  ) -> ([BoundArg], ClosureExprSyntax?) {
    var bound: [BoundArg] = []

    for (position, argument) in call.arguments.enumerated() {
      let label = argument.label?.text
      guard let argSpec = spec.spec(forLabel: label, position: position), let setter = argSpec.setter
      else { continue }

      let (rewritten, reads) = StateRewriter.scan(argument.expression, states: states)
      if !reads.isEmpty {
        bound.append(BoundArg(
          setter: setter, value: rewritten, reads: reads,
          isRows: label != nil && label == spec.genericOverItemsOf,
          animatable: argSpec.animatable
        ))
      }
    }

    // `VStack(spacing: 10) { ... }` — the builder closure is the content, not an argument.
    // For the lists it is `onCreate`, which is opaque and stays part of the constructor.
    guard spec.takesContent else { return (bound, nil) }
    let content = call.trailingClosure
      ?? call.arguments.first(where: { $0.label?.text == "content" })?.expression.as(ClosureExprSyntax.self)

    return (bound, content)
  }

  private func parseModifierArgs(_ call: FunctionCallExprSyntax, _ spec: ModifierSpec) -> [BoundArg] {
    guard let setter = spec.setter else { return [] }   // onTap/onHover: the handler is opaque

    var arguments = Array(call.arguments)
    if case .labeled(let label) = spec.combine {
      arguments = arguments.filter { $0.label?.text == label }
    }

    var rewritten: [ExprSyntax] = []
    var reads: Set<String> = []
    for argument in arguments {
      let (expr, found) = StateRewriter.scan(argument.expression, states: states)
      rewritten.append(expr)
      reads.formUnion(found)
    }
    guard !reads.isEmpty else { return [] }

    let value: ExprSyntax
    switch spec.combine {
    case .identity, .labeled:
      guard let first = rewritten.first else { return [] }
      value = first
    case .float2:
      // `.frame(width:height:)` collapses into the single property `Frame.size`.
      guard rewritten.count == 2 else { return [] }
      value = "float2(\(rewritten[0]), \(rewritten[1]))"
    }
    return [BoundArg(setter: setter, value: value, reads: reads, animatable: spec.animatable)]
  }
}
