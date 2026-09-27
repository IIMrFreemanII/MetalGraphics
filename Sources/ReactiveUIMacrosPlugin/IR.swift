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
  /// True when the setter takes an `animation:`, i.e. the property can be interpolated.
  let animatable: Bool

  init(setter: String, value: ExprSyntax, reads: Set<String>, isRows: Bool = false, animatable: Bool = false) {
    self.setter = setter
    self.value = value
    self.reads = reads
    self.isRows = isRows
    self.animatable = animatable
  }
}

/// `.animation(A, value: V)` in a chain. Not a link: it adds no node and no field.
///
/// It animates, in the update method of each state `V` reads, the bindings of the links before
/// it in the chain and everything under the element. Which scope wins for a binding is decided
/// per state: the innermost one whose triggers include that state.
struct AnimationScope {
  /// Applies to chain links `0 ..< upToLink`, and to the element's children.
  let upToLink: Int
  /// The animation, with state reads rewritten to storage.
  let animation: ExprSyntax
  /// The states `value:` reads. A write to any of them animates this scope.
  let triggers: Set<String>
  /// The `static let` holding the animation when it is a constant, so it is built once rather
  /// than on every update; nil when it reads state or `self` and must be evaluated in place.
  let constantField: String?
}

/// A handler bound to a link: which property to assign, and the closure the user wrote.
///
/// Kept out of the emitted chain on purpose. The closure is assigned in `__armHandlers` and
/// cleared in `__disarmHandlers`, so the component's strong capture of `self` only exists while
/// the element is mounted.
struct BoundHandler {
  let property: String
  let closure: ExprSyntax
  /// See `HandlerSpec.adapter`.
  let adapter: String?
}

/// One link in a modifier chain. The root link is a constructor call; the rest are modifiers
/// applied to the previous link.
struct ChainLink {
  enum Kind {
    /// `Rectangle(self.color)` — emitted as the constructor, minus any content closure.
    case constructor(call: FunctionCallExprSyntax, type: TypeSpec)
    /// `.frame(width: 100, height: 100)` — emitted as the modifier call on the previous link.
    case modifier(call: FunctionCallExprSyntax, spec: ModifierSpec)
    /// A modifier folded away at compile time: the previous link's element, as is. A constant
    /// text style set around texts the macro can see is written into them instead
    /// (`ElementIR.inheritedStyles`), and a run of constant text modifiers becomes one
    /// `applyStyle`. Kept as a link, so the links after it keep their names and positions.
    case passThrough
  }

  let field: String       // "__n0a"
  let local: String       // "n0a"
  var type: String        // the Swift type of the node field
  var kind: Kind
  let bound: [BoundArg]
  /// A handler modifier's closure (`.onTap`), or a constructor's callbacks and binding
  /// write-backs (`Button { … }`, `isOn: $wifi`).
  let handlers: [BoundHandler]

  init(
    field: String, local: String, type: String,
    kind: Kind, bound: [BoundArg], handlers: [BoundHandler] = []
  ) {
    self.field = field
    self.local = local
    self.type = type
    self.kind = kind
    self.bound = bound
    self.handlers = handlers
  }
}

/// A content closure other than the constructor's own — a modifier's, `.overlay { … }`, or a
/// named one, `Section { … } header: { … }` — parsed like a container's children and applied to
/// that link's element through `door`.
struct LinkContent {
  /// The chain link whose element owns the content.
  let link: Int
  /// The method the children are applied with: `replaceContent`, `replaceHeader`, …
  let door: String
  /// Its own path, so its nodes, branches and applier are named apart from the element's.
  let path: String
  let children: [NodeIR]
}

/// One list of children under an element, and how it is attached.
struct ChildList {
  enum Attach {
    /// The constructor's content, through `setChild` or `replaceChildren` by arity.
    case arity(Arity)
    /// Any other content closure's, through the method named: a content modifier's
    /// `replaceContent`, a section's `replaceHeader`.
    case door(String)
  }

  let path: String
  let ownerField: String
  let attach: Attach
  let children: [NodeIR]
  /// The index of the link the children hang from: scopes before it do not cover them.
  let link: Int?
}

struct ElementIR {
  let path: String
  var chain: [ChainLink]  // innermost (the constructor) first
  var children: [NodeIR]
  let arity: Arity
  let scopes: [AnimationScope]
  var contents: [LinkContent] = []
  /// For a `Text`: the constant styles of the containers around it that the macro folded away,
  /// innermost first, each an expression of a `TextEnvironment`. Written into it with
  /// `inheritStyle` when it is built.
  var inheritedStyles: [String] = []
  /// The `static let`s holding the folded styles this element's chain defines: name, value.
  var styleConstants: [(field: String, value: String)] = []

  /// The type of the constructor, as the catalog names it.
  var constructorType: String? {
    if case .constructor(_, let type) = chain[0].kind { return type.name }
    return nil
  }

  /// Every non-empty list of children under this element: the constructor's content, then each
  /// content modifier's, in chain order.
  var childLists: [ChildList] {
    var lists: [ChildList] = []
    if !children.isEmpty {
      lists.append(ChildList(path: path, ownerField: innermost.field, attach: .arity(arity), children: children, link: nil))
    }
    for content in contents where !content.children.isEmpty {
      lists.append(ChildList(
        path: content.path, ownerField: chain[content.link].field, attach: .door(content.door),
        children: content.children, link: content.link
      ))
    }
    return lists
  }

  /// Every child node, from every list.
  var allChildren: [NodeIR] { childLists.flatMap(\.children) }

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
