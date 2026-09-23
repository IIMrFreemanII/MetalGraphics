import SwiftSyntax

// Turns the IR into the members `@Component` adds to the class.
//
// The output is deliberately dumb and verbose: one optional field per node, straight-line
// construction, and per-state methods that assign directly into the nodes that state feeds.
// Nothing here inspects anything at runtime. The one optional check in each setter doubles as
// the "is this subtree currently built?" test, because an untaken branch has nil fields.
struct CodeGen {
  let states: [StateProperty]
  let nodes: [NodeIR]

  /// Where a child list is attached: the component itself, or a container node.
  private enum Owner {
    case component
    case node(field: String, arity: Arity)
  }

  func generate() -> [DeclSyntax] {
    var decls: [DeclSyntax] = []
    decls.append(contentsOf: storage())
    decls.append(lifecycleMount())
    decls.append(lifecycleUnmount())
    decls.append(refreshAll())
    decls.append(buildRoot())
    decls.append(contentsOf: handlerMethods())
    decls.append(contentsOf: containerAppliers())
    decls.append(contentsOf: branchMethods())
    decls.append(contentsOf: updates())
    decls.append(contentsOf: mutations())
    return decls
  }

  // MARK: - Storage

  private func storage() -> [DeclSyntax] {
    var decls: [DeclSyntax] = [
      "private var \(raw: Naming.context): UIContext? = nil",
      // Set when a state changes while unmounted; replayed on the next mount. This is the
      // compile-time stand-in for Reaction's "re-evaluate on remount".
      "private var \(raw: Naming.needsRefresh): Bool = false",
      // Tracks the first mount. Node fields survive an unmount so a remount reuses instances,
      // which is why a nil check on them cannot answer "has this been built yet?".
      "private var __built: Bool = false",
    ]
    forEachElement { element in
      for link in element.chain {
        decls.append("private var \(raw: link.field): \(raw: link.type)? = nil")
      }
    }
    forEachBranch { branch in
      decls.append("private var \(raw: Naming.tag(branch.path)): Int = -1")
      decls.append("private var \(raw: Naming.slot(branch.path)): [UIElement] = []")
    }
    // A constant animation is built once. For a spring that also means its coefficients are.
    forEachElement { element in
      for scope in element.scopes {
        guard let field = scope.constantField else { continue }
        decls.append("private static let \(raw: field): UIAnimation? = \(raw: scope.animation.trimmedDescription)")
      }
    }
    return decls
  }

  // MARK: - Lifecycle

  private func lifecycleMount() -> DeclSyntax {
    // Re-armed on every mount, not just the first: an unmounted element had its handlers
    // cleared, and a remounted one has to get them back.
    let armCall = armedHandlers.isEmpty ? "" : "\n  self.\(Naming.armHandlers)()"
    return """
    public override func mount(_ context: UIContext) {
      self.\(raw: Naming.context) = context
      if !self.__built {
        self.__built = true
        self.setChild(self.\(raw: Naming.build)(context), context)
      } else if self.\(raw: Naming.needsRefresh) {
        self.\(raw: Naming.needsRefresh) = false
        self.\(raw: Naming.refreshAll)()
      }\(raw: armCall)
    }
    """
  }

  private func lifecycleUnmount() -> DeclSyntax {
    let disarmCall = armedHandlers.isEmpty ? "" : "self.\(Naming.disarmHandlers)()\n  "
    return """
    public override func unmount(_ context: UIContext) {
      \(raw: disarmCall)self.\(raw: Naming.context) = nil
    }
    """
  }

  /// Replays every setter after a remount, picking up changes made while detached. Never
  /// animated: the changes happened while nothing was on screen.
  private func refreshAll() -> DeclSyntax {
    let calls = reactiveNames.map { "self.\(Naming.update($0))(false)" }.joined(separator: "\n  ")
    return """
    private func \(raw: Naming.refreshAll)() {
      \(raw: calls)
    }
    """
  }

  // MARK: - Construction

  private func buildRoot() -> DeclSyntax {
    var lines = nodes.flatMap { buildLines($0) }
    lines.append("\(nodes.isEmpty ? "let" : "var") root: [UIElement] = []")
    lines.append(contentsOf: collectLines(nodes, into: "root"))
    return """
    private func \(raw: Naming.build)(_ context: UIContext) -> UIElement {
      \(raw: lines.joined(separator: "\n  "))
      return root.first ?? EmptyElement()
    }
    """
  }

  private func buildLines(_ node: NodeIR) -> [String] {
    switch node {
    case .element(let element): return buildElementLines(element)
    case .branch(let branch):
      // Entering a branch is the same work whether it is the first build or a later swap.
      return [
        "self.\(Naming.tag(branch.path)) = self.\(Naming.evalTag(branch.path))()",
        "self.\(Naming.slot(branch.path)) = self.\(Naming.enterBranch(branch.path))(self.\(Naming.tag(branch.path)), context)",
      ]
    }
  }

  private func buildElementLines(_ element: ElementIR) -> [String] {
    var lines: [String] = []

    for (index, link) in element.chain.enumerated() {
      switch link.kind {
      case .constructor(let call, let type):
        // Re-emit the constructor without its content closure; children are attached below
        // through the public setChild/replaceChildren door. A list keeps its trailing closure,
        // which is a row factory rather than content.
        lines.append("let \(link.local) = \(constructorExpr(call, stripContent: type.takesContent))")
      case .modifier(let call, let spec):
        // Call the modifier itself rather than its wrapper's constructor: the modifiers are
        // public, the wrappers' initializers are not, and this preserves the chain exactly.
        let previous = element.chain[index - 1].local
        lines.append("let \(link.local) = \(previous)\(modifierSuffix(call, spec))")
      }
      lines.append("self.\(link.field) = \(link.local)")
    }

    for child in element.children {
      lines.append(contentsOf: buildLines(child))
    }
    if !element.children.isEmpty {
      lines.append("self.\(Naming.applyChildren(element.path))(context, animation: nil)")
    }
    return lines
  }

  /// Appends the elements a node contributes to a child array.
  private func collectLines(_ nodes: [NodeIR], into array: String) -> [String] {
    nodes.map { node in
      switch node {
      case .element(let element):
        return "if let e = self.\(element.outermost.field) { \(array).append(e) }"
      case .branch(let branch):
        // A branch contributes however many elements its current arm produced.
        return "\(array).append(contentsOf: self.\(Naming.slot(branch.path)))"
      }
    }
  }

  // MARK: - Handlers

  /// `onTap`/`onHover` are assigned here rather than in `__build`, and cleared again on unmount.
  ///
  /// The closure captures `self` strongly and the element stores it, so while it is assigned the
  /// component is reachable from its own tree. That is only true between mount and unmount, when
  /// something above is holding the subtree anyway; the moment the element unmounts the closure
  /// goes and the component can be released. This is what lets a body be written without a
  /// capture list.
  private func handlerMethods() -> [DeclSyntax] {
    let armed = self.armedHandlers
    guard !armed.isEmpty else { return [] }

    let arm = armed.map { entry in
      "self.\(entry.field)?.\(entry.handler.property) = \(entry.handler.closure.trimmedDescription)"
    }
    let disarm = armed.map { entry in
      "self.\(entry.field)?.\(entry.handler.property) = nil"
    }

    return [
      """
      private func \(raw: Naming.armHandlers)() {
        \(raw: arm.joined(separator: "\n  "))
      }
      """,
      """
      private func \(raw: Naming.disarmHandlers)() {
        \(raw: disarm.joined(separator: "\n  "))
      }
      """,
    ]
  }

  /// Every handler in the tree, paired with the node field that holds it. Empty for a component
  /// with no `onTap`/`onHover`, which is what keeps the arm/disarm machinery out of its expansion.
  private var armedHandlers: [(field: String, handler: BoundHandler)] {
    var armed: [(field: String, handler: BoundHandler)] = []
    forEachElement { element in
      for link in element.chain {
        if let handler = link.handler { armed.append((link.field, handler)) }
      }
    }
    return armed
  }

  // MARK: - Child lists

  /// One method per container, rebuilding its children from the slots. Called on first build
  /// and again whenever a branch under it swaps.
  private func containerAppliers() -> [DeclSyntax] {
    var decls: [DeclSyntax] = []

    func applier(path: String, owner: Owner, children: [NodeIR]) -> DeclSyntax {
      var lines = ["\(children.isEmpty ? "let" : "var") children: [UIElement] = []"]
      lines.append(contentsOf: collectLines(children, into: "children"))
      switch owner {
      case .component:
        lines.append("self.setChild(children.first ?? EmptyElement(), context, animation: animation)")
      case .node(let field, let arity):
        switch arity {
        case .single:
          lines.append("if let owner = self.\(field) { owner.setChild(children.first ?? EmptyElement(), context, animation: animation) }")
        case .multi:
          // replaceChildren already diffs by identity, unmounts what went, mounts what came
          // and invalidates layout — so a branch swap needs no new runtime. With an animation
          // it also plays the transitions of what came and went.
          lines.append("if let owner = self.\(field) { owner.replaceChildren(children, context, animation: animation) }")
        case .leaf:
          break
        }
      }
      return """
      private func \(raw: Naming.applyChildren(path))(_ context: UIContext, animation: UIAnimation?) {
        \(raw: lines.joined(separator: "\n  "))
      }
      """
    }

    func walk(_ node: NodeIR) {
      guard case .element(let element) = node else {
        if case .branch(let branch) = node { branch.arms.forEach { $0.forEach(walk) } }
        return
      }
      if !element.children.isEmpty {
        decls.append(applier(
          path: element.path,
          owner: .node(field: element.innermost.field, arity: element.arity),
          children: element.children
        ))
      }
      element.children.forEach(walk)
    }

    // The component's own child list, so a branch at the root can swap too.
    decls.append(applier(path: "", owner: .component, children: nodes))
    nodes.forEach(walk)
    return decls
  }

  // MARK: - Branches

  private func branchMethods() -> [DeclSyntax] {
    var decls: [DeclSyntax] = []

    let enclosing = enclosingBranches()
    let enclosingPaths = Set(enclosing.values.flatMap { $0.map(\.path) })

    forEachBranchWithParent { branch, parentPath in
      // --- which arm is current ---
      let tagExpr: String
      switch branch.kind {
      case .condition(let expr):
        tagExpr = "(\(expr.trimmedDescription)) ? 0 : 1"
      case .optional(_, let value):
        // `if let` swaps only on a nil/non-nil flip, matching the runtime it replaces.
        tagExpr = "((\(value.trimmedDescription)) != nil) ? 0 : 1"
      }
      decls.append("""
      private func \(raw: Naming.evalTag(branch.path))() -> Int {
        \(raw: tagExpr)
      }
      """)

      // --- build the arm ---
      var enterCases: [String] = []
      for (tag, arm) in branch.arms.enumerated() {
        var lines: [String] = []
        if case .optional(let name, let value) = branch.kind, tag == 0 {
          lines.append("guard let \(name) = \(value.trimmedDescription) else { return [] }")
          lines.append("_ = \(name)")
        }
        lines.append(contentsOf: arm.flatMap { buildLines($0) })
        lines.append("\(arm.isEmpty ? "let" : "var") elements: [UIElement] = []")
        lines.append(contentsOf: collectLines(arm, into: "elements"))
        lines.append("return elements")
        enterCases.append("case \(tag):\n    " + lines.joined(separator: "\n    "))
      }
      decls.append("""
      private func \(raw: Naming.enterBranch(branch.path))(_ tag: Int, _ context: UIContext) -> [UIElement] {
        switch tag {
        \(raw: enterCases.joined(separator: "\n  "))
        default:
          return []
        }
      }
      """)

      // --- drop the arm we are leaving ---
      var leaveCases: [String] = []
      for (tag, arm) in branch.arms.enumerated() {
        var fields: [String] = []
        func walk(_ node: NodeIR) {
          switch node {
          case .element(let element):
            fields.append(contentsOf: element.chain.map { "self.\($0.field) = nil" })
            element.children.forEach(walk)
          case .branch(let nested):
            fields.append("self.\(Naming.tag(nested.path)) = -1")
            fields.append("self.\(Naming.slot(nested.path)) = []")
            nested.arms.forEach { $0.forEach(walk) }
          }
        }
        arm.forEach(walk)
        leaveCases.append("case \(tag):\n    " + (fields.isEmpty ? "break" : fields.joined(separator: "\n    ")))
      }
      decls.append("""
      private func \(raw: Naming.leaveBranch(branch.path))(_ tag: Int) {
        switch tag {
        \(raw: leaveCases.joined(separator: "\n  "))
        default:
          break
        }
      }
      """)

      // --- re-read the current arm, for a branch with a nested one sitting directly in it ---
      if enclosingPaths.contains(branch.path) {
        var collectCases: [String] = []
        for (tag, arm) in branch.arms.enumerated() {
          var lines = ["\(arm.isEmpty ? "let" : "var") elements: [UIElement] = []"]
          lines.append(contentsOf: collectLines(arm, into: "elements"))
          lines.append("return elements")
          collectCases.append("case \(tag):\n    " + lines.joined(separator: "\n    "))
        }
        decls.append("""
        private func \(raw: Naming.recollect(branch.path))() -> [UIElement] {
          switch self.\(raw: Naming.tag(branch.path)) {
          \(raw: collectCases.joined(separator: "\n  "))
          default:
            return []
          }
        }
        """)
      }

      // --- the swap itself ---
      // The arm's nodes were built just now and have never been through a mount, so this is the
      // only place their handlers get armed.
      let swapArmCall = armedHandlers.isEmpty ? "" : "self.\(Naming.armHandlers)()\n  "
      // An `else if` is a branch in the else arm of another, sharing its container. The
      // container is rebuilt from the outer branch's slot, so that slot has to be re-read
      // first, innermost outwards, or the old arm's elements would be applied again.
      let recollectCalls = (enclosing[branch.path] ?? []).map {
        "self.\(Naming.slot($0.path)) = self.\(Naming.recollect($0.path))()\n  "
      }.joined()
      decls.append("""
      private func \(raw: Naming.swapBranch(branch.path))(_ context: UIContext, animation: UIAnimation?) {
        let tag = self.\(raw: Naming.evalTag(branch.path))()
        guard tag != self.\(raw: Naming.tag(branch.path)) else {
          return
        }
        let previous = self.\(raw: Naming.tag(branch.path))
        self.\(raw: Naming.tag(branch.path)) = tag
        self.\(raw: Naming.slot(branch.path)) = self.\(raw: Naming.enterBranch(branch.path))(tag, context)
        self.\(raw: Naming.leaveBranch(branch.path))(previous)
        \(raw: recollectCalls)\(raw: swapArmCall)self.\(raw: Naming.applyChildren(parentPath))(context, animation: animation)
      }
      """)
    }
    return decls
  }

  // MARK: - Updates

  /// How a list's `items:` binding is applied.
  ///
  /// Only that binding has an incremental form. A count read or a branch condition has to
  /// re-run its expression whole however the array changed, so those lines are identical in
  /// all three modes — which is why the incremental appliers are just `__update_` with the
  /// list lines swapped out.
  private enum RowsMode {
    case full       // setItems: rebuild every row
    case insert     // insertRow: one child added at `index`
    case remove     // removeRow: one child dropped at `index`
  }

  /// The body of one update method.
  private struct Dependents {
    var lines: [String] = []
    /// A line animates with `UITransaction.animation`, so the method declares the local it reads.
    var usesTransaction = false
  }

  /// Every line a write to `stateName` runs, each with its animation resolved here, at compile
  /// time.
  ///
  /// A binding that can animate — an animatable setter, a list's rows, a branch swap — takes
  /// the animation of the innermost `.animation(_:value:)` scope that covers it and that
  /// `stateName` triggers. No such scope means `withAnimation`'s, read from the transaction; outside
  /// `withAnimation` that is nil and the binding snaps, as it always did. `animated` is false for
  /// the remount replay, which is never animated.
  private func dependents(for stateName: String, rows: RowsMode) -> Dependents {
    var result = Dependents()
    var branchLines: [String] = []

    func animationArgument(_ scope: AnimationScope?) -> String {
      guard let scope else {
        result.usesTransaction = true
        return Naming.transaction
      }
      if let field = scope.constantField {
        return "animated ? Self.\(field) : nil"
      }
      return "animated ? (\(scope.animation.trimmedDescription)) as UIAnimation? : nil"
    }

    func walk(_ node: NodeIR, inherited: AnimationScope?) {
      switch node {
      case .element(let element):
        // The scopes this state triggers, innermost first: the parser records them in chain
        // order, so the first whose `upToLink` covers a link is the one written closest to it.
        let own = element.scopes.filter { $0.triggers.contains(stateName) }

        for (index, link) in element.chain.enumerated() {
          let scope = own.first { $0.upToLink > index } ?? inherited
          for bound in link.bound where bound.reads.contains(stateName) {
            let call: String
            switch rows {
            case .insert where bound.isRows:
              call = "insertRow(element, at: index, context, animation: \(animationArgument(scope)))"
            case .remove where bound.isRows:
              call = "removeRow(element, at: index, context, animation: \(animationArgument(scope)))"
            default:
              let value = bound.value.trimmedDescription
              call = bound.animatable || bound.isRows
                ? "\(bound.setter)(\(value), context, animation: \(animationArgument(scope)))"
                : "\(bound.setter)(\(value), context)"
            }
            result.lines.append("if let n = self.\(link.field) { n.\(call) }")
          }
        }

        // Every scope on an element covers its children.
        let childScope = own.first ?? inherited
        element.children.forEach { walk($0, inherited: childScope) }

      case .branch(let branch):
        if branch.reads.contains(stateName) {
          branchLines.append(
            "self.\(Naming.swapBranch(branch.path))(context, animation: \(animationArgument(inherited)))"
          )
        }
        branch.arms.forEach { $0.forEach { walk($0, inherited: inherited) } }
      }
    }

    nodes.forEach { walk($0, inherited: nil) }
    result.lines.append(contentsOf: branchLines)
    return result
  }

  /// True when at least one list binds this state, i.e. there is something to apply
  /// incrementally. Without it the mutation methods just call the full update.
  private func hasRowsBinding(_ stateName: String) -> Bool {
    var found = false
    forEachElement { element in
      for link in element.chain {
        for bound in link.bound where bound.isRows && bound.reads.contains(stateName) {
          found = true
        }
      }
    }
    return found
  }

  /// The shared shape of every applier: capture the context or note a missed update, then
  /// straight-line assignments.
  private func applier(_ name: String, _ parameters: String, _ dependents: Dependents) -> DeclSyntax {
    var lines = dependents.lines
    if dependents.usesTransaction {
      lines.insert("let \(Naming.transaction) = animated ? UITransaction.animation : nil", at: 0)
    }
    return """
    private func \(raw: name)(\(raw: parameters)) {
      guard let context = self.\(raw: Naming.context) else {
        self.\(raw: Naming.needsRefresh) = true
        return
      }
      \(raw: lines.joined(separator: "\n  "))
    }
    """
  }

  /// The trailing parameter every applier takes. Defaulted, so `@State`'s setter and the
  /// mutation methods call them without it.
  static let animatedParameter = "_ animated: Bool = true"

  /// One method per state. A state that no node reads still gets one \u{2014} otherwise `@State`'s
  /// setter cannot resolve its call.
  private func updates() -> [DeclSyntax] {
    reactiveNames.map { stateName in
      let dependents = dependents(for: stateName, rows: .full)

      guard !dependents.lines.isEmpty else {
        // Nothing depends on it yet; still note an unmounted change so a remount replays it.
        return """
        private func \(raw: Naming.update(stateName))(\(raw: Self.animatedParameter)) {
          if self.\(raw: Naming.context) == nil {
            self.\(raw: Naming.needsRefresh) = true
          }
        }
        """
      }
      return applier(Naming.update(stateName), Self.animatedParameter, dependents)
    }
  }

  // MARK: - Mutations

  /// `@State` arrays that feed something, paired with their element type.
  private var arrayStates: [(state: StateProperty, element: String)] {
    states.compactMap { state in
      BodyParser.arrayElementType(state.type).map { (state, $0) }
    }
  }

  /// Mutation methods for each `@State` array.
  ///
  /// This is where the operation survives the trip from the call site into the tree. A plain
  /// `self.items = …` can only say "the array is different now", so it rebuilds every row;
  /// `self.appendItems(x)` says exactly what happened, and one `insertChild` follows.
  func mutations() -> [DeclSyntax] {
    arrayStates.flatMap { state, element -> [DeclSyntax] in
      let name = state.name
      let storage = Naming.storage(name)
      let update = "self.\(Naming.update(name))()"
      // Without a list to update incrementally there is nothing to specialise, so the
      // mutation methods fall through to the ordinary full update. The bindings an
      // incremental call would need are then omitted too, rather than left unused.
      let incremental = hasRowsBinding(name)
      let didInsert = "self.\(Naming.didInsert(name))(element, at: index)"
      let didRemove = "self.\(Naming.didRemove(name))(removed, at: index)"

      func method(_ signature: String, _ lines: [String]) -> DeclSyntax {
        """
        \(raw: signature) {
          \(raw: lines.joined(separator: "\n  "))
        }
        """
      }

      var decls: [DeclSyntax] = [
        method(
          "public func \(Naming.mutationAppend(name))(_ element: \(element))",
          incremental
            ? ["let index = self.\(storage).count",
               "self.\(storage).append(element)",
               didInsert]
            : ["self.\(storage).append(element)", update]
        ),
        // The clamp matches the collection this replaced; `Array.insert(at:)` would trap.
        // The index is computed before the mutation, not inside the call, so the read of
        // `count` does not overlap the write.
        method(
          "public func \(Naming.mutationInsert(name))(_ element: \(element), at position: Int)",
          ["let index = Swift.min(Swift.max(position, 0), self.\(storage).count)",
           "self.\(storage).insert(element, at: index)",
           incremental ? didInsert : update]
        ),
        method(
          "@discardableResult\npublic func \(Naming.mutationRemove(name))(at index: Int) -> \(element)?",
          ["guard self.\(storage).indices.contains(index) else { return nil }",
           "let removed = self.\(storage).remove(at: index)",
           incremental ? didRemove : update,
           "return removed"]
        ),
        // One match takes the incremental path. Several would mean re-running every other
        // dependent expression once per removal, so a single full rebuild is both simpler
        // and cheaper there.
        method(
          "public func \(Naming.mutationRemove(name))(where predicate: (\(element)) -> Bool)",
          ["let matches = self.\(storage).indices.filter { predicate(self.\(storage)[$0]) }",
           "guard matches.count == 1, let index = matches.first else {",
           "  guard !matches.isEmpty else { return }",
           "  self.\(storage).removeAll(where: predicate)",
           "  \(update)",
           "  return",
           "}"]
            + (incremental
               ? ["let removed = self.\(storage).remove(at: index)", didRemove]
               : ["self.\(storage).remove(at: index)", update])
        ),
        // Sugar for `self.<name> = new`, which goes down exactly the same path.
        method(
          "public func \(Naming.mutationReplace(name))(_ newValue: [\(element)])",
          ["self.\(storage) = newValue", update]
        ),
      ]

      if incremental {
        decls.append(applier(
          Naming.didInsert(name), "_ element: \(element), at index: Int, \(Self.animatedParameter)",
          dependents(for: name, rows: .insert)
        ))
        decls.append(applier(
          Naming.didRemove(name), "_ element: \(element), at index: Int, \(Self.animatedParameter)",
          dependents(for: name, rows: .remove)
        ))
      }
      return decls
    }
  }

  // MARK: - Emitting expressions

  /// The constructor call with any trailing/`content:` closure removed, and state reads
  /// rewritten to the backing storage.
  private func constructorExpr(_ call: FunctionCallExprSyntax, stripContent: Bool) -> String {
    var copy = call
    if stripContent {
      copy.trailingClosure = nil
      copy.additionalTrailingClosures = []
    }
    let kept = copy.arguments.filter { argument in
      !(stripContent && argument.label?.text == "content" && argument.expression.is(ClosureExprSyntax.self))
    }
    copy.arguments = LabeledExprListSyntax(kept.enumerated().map { index, argument in
      var a = argument
      a.expression = StateRewriter.scan(argument.expression, states: stateNames).expr
      a.trailingComma = index == kept.count - 1 ? nil : a.trailingComma
      return a
    })
    if copy.arguments.isEmpty {
      copy.leftParen = .leftParenToken()
      copy.rightParen = .rightParenToken()
    }
    return copy.trimmedDescription
  }

  /// `.frame(width: 100, height: 100)` — everything after the receiver, verbatim apart from
  /// state reads. Closure arguments are copied byte-for-byte.
  private func modifierSuffix(_ call: FunctionCallExprSyntax, _ spec: ModifierSpec) -> String {
    guard let member = call.calledExpression.as(MemberAccessExprSyntax.self) else { return "" }

    // A handler's real closure is assigned in `__armHandlers`; the chain only needs something of
    // the right arity to produce the element with.
    if let handler = spec.handler {
      return ".\(member.declName.baseName.text)\(handler.placeholder)"
    }

    var copy = call
    var newMember = member
    newMember.base = nil
    copy.calledExpression = ExprSyntax(newMember)
    copy.arguments = LabeledExprListSyntax(copy.arguments.map { argument in
      var a = argument
      a.expression = StateRewriter.scan(argument.expression, states: stateNames).expr
      return a
    })
    return copy.trimmedDescription
  }

  // MARK: - Walking

  private var stateNames: Set<String> { Set(states.map(\.name)) }
  private var reactiveNames: [String] { states.map(\.name) }

  private func forEachElement(_ body: (ElementIR) -> Void) {
    func walk(_ node: NodeIR) {
      switch node {
      case .element(let element):
        body(element)
        element.children.forEach(walk)
      case .branch(let branch):
        branch.arms.forEach { $0.forEach(walk) }
      }
    }
    nodes.forEach(walk)
  }

  private func forEachBranch(_ body: (BranchIR) -> Void) {
    forEachBranchWithParent { branch, _ in body(branch) }
  }

  /// For each branch, the branches whose arms it sits in within the same container, innermost
  /// first. Empty for most branches; an `else if` chain is the common way to get one.
  private func enclosingBranches() -> [String: [BranchIR]] {
    var result: [String: [BranchIR]] = [:]
    func walk(_ nodes: [NodeIR], enclosing: [BranchIR]) {
      for node in nodes {
        switch node {
        case .element(let element):
          // A new container: its branches re-apply it, not the one outside.
          walk(element.children, enclosing: [])
        case .branch(let branch):
          if !enclosing.isEmpty { result[branch.path] = enclosing }
          branch.arms.forEach { walk($0, enclosing: [branch] + enclosing) }
        }
      }
    }
    walk(nodes, enclosing: [])
    return result
  }

  /// Every branch, with the path of the container whose children it belongs to. That container
  /// is what a swap must re-apply.
  private func forEachBranchWithParent(_ body: (BranchIR, String) -> Void) {
    func walk(_ nodes: [NodeIR], parent: String) {
      for node in nodes {
        switch node {
        case .element(let element):
          walk(element.children, parent: element.path)
        case .branch(let branch):
          body(branch, parent)
          // An arm's own contents sit in the same container as the branch.
          branch.arms.forEach { walk($0, parent: parent) }
        }
      }
    }
    walk(nodes, parent: "")
  }
}
