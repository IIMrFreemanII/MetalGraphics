import SwiftSyntax

// Turns an expression written in `body` into the expression the generated setter uses, and
// reports which `@State` properties it reads, and which properties of `@Bindable` models.
//
// The rewrite is deliberately minimal: `self.color` (or a bare `color`) becomes `self._color`,
// and nothing else is touched. The expression is otherwise copied verbatim, which is what makes
// `Rectangle(self.isOn ? .red : .blue)` work without the macro understanding ternaries.
//
// A model read, `self.model.count` (or a bare `model.count`), is left as written and reported as
// the key "model.count": it goes through the model's getter, and the component subscribes to
// `count` on mount. A method call, `self.model.total()`, reports "model.total", which the
// model resolves to the list every write notifies.
//
// Closure literals are skipped entirely. A read inside `onTap { self.isLoggedIn.toggle() }` is
// not a dependency — it runs at event time against live storage, and must keep going through
// the public setter so it triggers an update.
final class StateRewriter: SyntaxRewriter {
  private let states: Set<String>
  private let models: Set<String>
  private(set) var reads: Set<String> = []

  init(states: Set<String>, models: Set<String>) {
    self.states = states
    self.models = models
    super.init()
  }

  /// The model `base` names, when it is `self.<model>` or a bare `<model>`.
  private func modelName(_ base: ExprSyntax) -> String? {
    guard !models.isEmpty else { return nil }
    if let member = base.as(MemberAccessExprSyntax.self),
       member.base?.as(DeclReferenceExprSyntax.self)?.baseName.tokenKind == .keyword(.self)
    {
      let name = member.declName.baseName.text
      return models.contains(name) ? name : nil
    }
    if let reference = base.as(DeclReferenceExprSyntax.self) {
      let name = reference.baseName.text
      return models.contains(name) ? name : nil
    }
    return nil
  }

  /// Substitutes an expression, carrying the original's surrounding trivia across. Without
  /// this, `self.hovered ? .black : x` loses the space and re-parses as optional chaining.
  private func substitute(_ replacement: ExprSyntax, for node: some SyntaxProtocol) -> ExprSyntax {
    var copy = replacement
    copy.leadingTrivia = node.leadingTrivia
    copy.trailingTrivia = node.trailingTrivia
    return copy
  }

  private func storageRef(_ name: String, at node: some SyntaxProtocol) -> ExprSyntax {
    reads.insert(name)
    return substitute("self.\(raw: Naming.storage(name))", for: node)
  }

  override func visit(_ node: ClosureExprSyntax) -> ExprSyntax {
    ExprSyntax(node)
  }

  override func visit(_ node: MemberAccessExprSyntax) -> ExprSyntax {
    let member = node.declName.baseName.text

    let isSelfBase = node.base?.as(DeclReferenceExprSyntax.self)?.baseName.tokenKind == .keyword(.self)

    // `self.color` -> `self._color`
    if isSelfBase, states.contains(member) {
      return storageRef(member, at: node)
    }

    // `self.model.count` -> itself, read through the model's getter.
    if let base = node.base, let model = modelName(base) {
      reads.insert(Self.modelKey(model, member))
      return ExprSyntax(node)
    }

    // Anything else: rewrite the base only, and never touch `declName` (it is a member
    // name, not a reference to a property of this component).
    guard let base = node.base else { return ExprSyntax(node) }
    var copy = node
    copy.base = rewrite(Syntax(base)).as(ExprSyntax.self) ?? base
    return ExprSyntax(copy)
  }

  override func visit(_ node: DeclReferenceExprSyntax) -> ExprSyntax {
    // A bare `color` inside `body`, where an explicit `self.` is not required.
    let name = node.baseName.text
    if states.contains(name) { return storageRef(name, at: node) }
    return ExprSyntax(node)
  }

  /// The read key of `model.member`. States never contain a dot, so the two cannot clash.
  static func modelKey(_ model: String, _ member: String) -> String { "\(model).\(member)" }

  /// A read key split back into model and member; nil for a state's.
  static func splitModelKey(_ key: String) -> (model: String, member: String)? {
    guard let dot = key.firstIndex(of: ".") else { return nil }
    return (String(key[..<dot]), String(key[key.index(after: dot)...]))
  }

  /// Rewrites `expr` and returns it together with the states and model properties it read.
  static func scan(
    _ expr: ExprSyntax, states: Set<String>, models: Set<String> = []
  ) -> (expr: ExprSyntax, reads: Set<String>) {
    let rewriter = StateRewriter(states: states, models: models)
    let rewritten = rewriter.rewrite(Syntax(expr)).as(ExprSyntax.self) ?? expr
    return (rewritten, rewriter.reads)
  }
}
