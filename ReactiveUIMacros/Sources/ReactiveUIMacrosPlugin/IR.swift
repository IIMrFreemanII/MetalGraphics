import SwiftSyntax

// What a parsed `body` becomes. Names are derived from `path`, so they are stable across
// rebuilds and readable in a debugger: `__n0_1a` is the first link of the chain at top-level
// statement 0, child 1.

/// One reactive argument: the setter to call, the already-rewritten expression, and the states
/// that expression reads. The same line is emitted into each of those states' update methods.
struct BoundArg {
  let setter: String
  let value: ExprSyntax
  let reads: Set<String>
  /// True for a list's `items:` binding. Those are the only bindings with an incremental
  /// form: `setItems` rebuilds every row, while `insertRow`/`removeRow` touch exactly one.
  /// Everything else (a count read, a branch condition) has to re-run its expression whole.
  let isRows: Bool

  init(setter: String, value: ExprSyntax, reads: Set<String>, isRows: Bool = false) {
    self.setter = setter
    self.value = value
    self.reads = reads
    self.isRows = isRows
  }
}

/// A handler bound to a link: which property to assign, and the closure the user wrote.
///
/// Kept out of the emitted chain on purpose. The closure is assigned in `__armHandlers` and
/// cleared in `__disarmHandlers`, so the component's strong capture of `self` only exists while
/// the element is mounted.
struct BoundHandler {
  let property: String
  let closure: ExprSyntax
}

/// One link in a modifier chain. The root link is a constructor call; the rest are modifiers
/// applied to the previous link.
struct ChainLink {
  enum Kind {
    /// `Rectangle(self.color)` — emitted as the constructor, minus any content closure.
    case constructor(call: FunctionCallExprSyntax, type: TypeSpec)
    /// `.frame(width: 100, height: 100)` — emitted as the modifier call on the previous link.
    case modifier(call: FunctionCallExprSyntax, spec: ModifierSpec)
  }

  let field: String       // "__n0a"
  let local: String       // "n0a"
  let type: String        // the Swift type of the node field
  let kind: Kind
  let bound: [BoundArg]
  /// Set only for `.onTap`/`.onHover` links.
  let handler: BoundHandler?

  init(
    field: String, local: String, type: String,
    kind: Kind, bound: [BoundArg], handler: BoundHandler? = nil
  ) {
    self.field = field
    self.local = local
    self.type = type
    self.kind = kind
    self.bound = bound
    self.handler = handler
  }
}

struct ElementIR {
  let path: String
  let chain: [ChainLink]  // innermost (the constructor) first
  let children: [NodeIR]
  let arity: Arity

  /// What the parent attaches — the outermost link of the chain.
  var outermost: ChainLink { chain[chain.count - 1] }
  /// What owns the children — the constructor, before any wrapping modifiers.
  var innermost: ChainLink { chain[0] }
}

/// An `if` / `if else` / `if let` in the body. Exactly one arm is built at a time; the others
/// have no node fields at all, which is why a state update targeting an untaken branch is a
/// no-op by construction rather than by a runtime check.
struct BranchIR {
  enum Kind {
    case condition(ExprSyntax)
    /// `if let name = expr` — swaps only when the value flips between nil and non-nil,
    /// matching the current runtime's semantics.
    case optional(name: String, value: ExprSyntax)
  }

  let path: String
  let kind: Kind
  let reads: Set<String>
  let arms: [[NodeIR]]    // arms[tag]; for `if` with no else, arm 1 is empty
}

indirect enum NodeIR {
  case element(ElementIR)
  case branch(BranchIR)

  var path: String {
    switch self {
    case .element(let e): return e.path
    case .branch(let b): return b.path
    }
  }
}
