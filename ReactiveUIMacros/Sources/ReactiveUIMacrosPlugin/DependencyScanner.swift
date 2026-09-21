import SwiftSyntax

// Turns an expression written in `body` into the expression the generated setter uses, and
// reports which `@State` properties it reads.
//
// The rewrite is deliberately minimal: `self.color` (or a bare `color`) becomes `self._color`,
// and nothing else is touched. The expression is otherwise copied verbatim, which is what makes
// `Rectangle(self.isOn ? .red : .blue)` work without the macro understanding ternaries.
//
// Closure literals are skipped entirely. A read inside `onTap { self.isLoggedIn.toggle() }` is
// not a dependency — it runs at event time against live storage, and must keep going through
// the public setter so it triggers an update.
final class StateRewriter: SyntaxRewriter {
  private let states: Set<String>
  private(set) var reads: Set<String> = []

  init(states: Set<String>) {
    self.states = states
    super.init()
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

  /// Rewrites `expr` and returns it together with the states it read.
  static func scan(
    _ expr: ExprSyntax, states: Set<String>
  ) -> (expr: ExprSyntax, reads: Set<String>) {
    let rewriter = StateRewriter(states: states)
    let rewritten = rewriter.rewrite(Syntax(expr)).as(ExprSyntax.self) ?? expr
    return (rewritten, rewriter.reads)
  }
}
