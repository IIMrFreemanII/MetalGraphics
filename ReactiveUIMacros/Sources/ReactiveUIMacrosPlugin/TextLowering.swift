import SwiftSyntax
import SwiftSyntaxMacros

// Text work done at compile time, where the macro can see it.
//
// - `Text("Hi ") + Text(self.name).bold()` becomes one `Text(runs:)`, with a setter per reactive
//   operand, so an update rebuilds no operand.
// - A constant text style set around texts the macro can all see — `VStack { Text(…) }.font(.title)`
//   — is written into those texts when they are built, and no `TextStyleElement` is made.
// - A run of constant text modifiers on one element is set with one `applyStyle`.
extension BodyParser {
  enum Concatenation {
    /// Not a `+` of texts.
    case none
    /// One, but not one that can be lowered: an error was reported.
    case failed
    /// The `Text(runs:)` it stands for, and the setters of its reactive operands.
    case lowered(FunctionCallExprSyntax, [BoundArg])
  }

  /// `Text(…) + Text(…)`, bare or in parentheses as the root of a chain, `(a + b).italic()`.
  func concatenation(_ expr: ExprSyntax) -> Concatenation {
    var sum = expr
    if let tuple = expr.as(TupleExprSyntax.self), tuple.elements.count == 1, let only = tuple.elements.first,
       only.label == nil
    {
      sum = only.expression
    }

    var operands: [ExprSyntax] = []
    if let sequence = sum.as(SequenceExprSyntax.self) {
      for (index, element) in sequence.elements.enumerated() {
        if index % 2 == 0 {
          operands.append(element)
          continue
        }
        guard let op = element.as(BinaryOperatorExprSyntax.self) else { return .none }
        guard op.operator.text == "+" else {
          context.error("F15", "only '+' joins texts into one; '\(op.operator.text)' does not.", at: op)
          return .failed
        }
      }
    } else if let infix = sum.as(InfixOperatorExprSyntax.self) {
      // Folded already: flatten the left-leaning tree of `+`.
      func flatten(_ expr: ExprSyntax) -> Bool {
        guard let infix = expr.as(InfixOperatorExprSyntax.self) else {
          operands.append(expr)
          return true
        }
        guard let op = infix.operator.as(BinaryOperatorExprSyntax.self), op.operator.text == "+" else {
          context.error("F15", "only '+' joins texts into one.", at: infix.operator)
          return false
        }
        return flatten(infix.leftOperand) && flatten(infix.rightOperand)
      }
      guard flatten(ExprSyntax(infix)) else { return .failed }
    } else {
      return .none
    }
    guard operands.count >= 2 else { return .none }

    var runs: [String] = []
    var bound: [BoundArg] = []
    for (index, operand) in operands.enumerated() {
      guard let run = self.run(operand) else { return .failed }
      runs.append("TextRun(\(run.string.trimmedDescription), style: \(run.style))")

      let (string, stringReads) = StateRewriter.scan(run.string, states: states)
      if !stringReads.isEmpty {
        bound.append(BoundArg(
          setter: "setRunText", value: "Text.RunText(\(raw: index), \(string))", reads: stringReads, animatable: true
        ))
      }
      let (style, styleReads) = StateRewriter.scan("\(raw: run.style)", states: states)
      if !styleReads.isEmpty {
        bound.append(BoundArg(
          setter: "setRunStyle", value: "Text.RunStyle(\(raw: index), \(style))", reads: styleReads, animatable: true
        ))
      }
    }

    let call: ExprSyntax = "Text(runs: [\(raw: runs.joined(separator: ", "))])"
    guard let lowered = call.as(FunctionCallExprSyntax.self) else { return .failed }
    return .lowered(lowered, bound)
  }

  /// One operand of `+`: a `Text` of a string, and the run modifiers on it as a
  /// `TextEnvironment` expression, not yet rewritten.
  private func run(_ operand: ExprSyntax) -> (string: ExprSyntax, style: String)? {
    var calls: [FunctionCallExprSyntax] = []
    var current = operand
    while let call = current.as(FunctionCallExprSyntax.self) {
      calls.append(call)
      guard let member = call.calledExpression.as(MemberAccessExprSyntax.self), let base = member.base else { break }
      current = base
    }
    calls.reverse()

    guard let root = calls.first,
          root.calledExpression.as(DeclReferenceExprSyntax.self)?.baseName.text == "Text",
          root.arguments.count == 1, let argument = root.arguments.first,
          argument.label == nil || argument.label?.text == "verbatim",
          root.trailingClosure == nil
    else {
      context.error(
        "F15",
        "'+' joins texts of strings: 'Text(\"…\")' or 'Text(verbatim:)', with run modifiers. "
          + "Format a value into the string, 'Text(\"\\(value.formatted())\")'.",
        at: operand
      )
      return nil
    }

    var style = "TextEnvironment()"
    for call in calls.dropFirst() {
      guard let member = call.calledExpression.as(MemberAccessExprSyntax.self) else { return nil }
      let name = member.declName.baseName.text
      if ElementCatalog.paragraphModifiers.contains(name) {
        context.error(
          "F16",
          "'.\(name)' styles a whole paragraph, not one run: call it on the joined text, '(a + b).\(name)(…)'.",
          at: member.declName
        )
        return nil
      }
      guard ElementCatalog.runModifiers.contains(name) else {
        context.error("F15", "'.\(name)' cannot style an operand of '+'; only a text's run modifiers can.", at: member.declName)
        return nil
      }
      style += Self.suffix(call)
    }
    return (argument.expression.trimmed, style)
  }

  /// `.font(.title)` — the call without its receiver, as written.
  static func suffix(_ call: FunctionCallExprSyntax) -> String {
    guard var member = call.calledExpression.as(MemberAccessExprSyntax.self) else { return "" }
    member.base = nil
    var copy = call
    copy.calledExpression = ExprSyntax(member)
    if copy.leftParen == nil {
      copy.leftParen = .leftParenToken()
      copy.rightParen = .rightParenToken()
    }
    return copy.trimmedDescription
  }

  // MARK: - Literals

  /// F17: a literal that the modifier cannot take.
  func checkTextLiteral(_ name: String, _ call: FunctionCallExprSyntax) -> Bool {
    guard let argument = call.arguments.first?.expression else { return true }
    func literal(_ expr: ExprSyntax) -> Double? {
      if let integer = expr.as(IntegerLiteralExprSyntax.self) { return Double(integer.literal.text) }
      if let float = expr.as(FloatLiteralExprSyntax.self) { return Double(float.literal.text) }
      if let prefix = expr.as(PrefixOperatorExprSyntax.self), prefix.operator.text == "-",
         let value = literal(prefix.expression)
      {
        return -value
      }
      return nil
    }
    guard let value = literal(argument) else { return true }
    switch name {
    case "lineLimit" where value < 1:
      context.error("F17", "'.lineLimit' needs at least 1 line; pass nil for as many as fit.", at: argument)
      return false
    case "minimumScaleFactor" where value <= 0 || value > 1:
      context.error("F17", "'.minimumScaleFactor' is a fraction of the font size, above 0 and at most 1.", at: argument)
      return false
    default:
      return true
    }
  }

  // MARK: - Folding

  /// Folds the element's constant text modifiers, once its children are parsed and folded.
  func foldTextStyles(_ element: inout ElementIR) {
    var index = 1
    while index < element.chain.count {
      let type = element.chain[index].type
      guard Self.isTextModifier(element.chain[index]), ElementCatalog.textStyled.contains(type) else {
        index += 1
        continue
      }
      // The links that style the same element: in place on it, one after another.
      var end = index + 1
      while end < element.chain.count, Self.isTextModifier(element.chain[end]),
            element.chain[end].type == type
      {
        end += 1
      }
      let wraps = type == "TextStyleElement" && element.chain[index - 1].type != "TextStyleElement"

      if wraps, self.foldIntoTexts(&element, links: index..<end) {
        index = end
        continue
      }
      // What stays: one `applyStyle` for a run of constant modifiers on one element. Only past
      // the wrapping link, which makes the element they style.
      let first = wraps ? index + 1 : index
      var runStart = first
      while runStart < end {
        guard element.chain[runStart].bound.isEmpty else {
          runStart += 1
          continue
        }
        var runEnd = runStart + 1
        while runEnd < end, element.chain[runEnd].bound.isEmpty { runEnd += 1 }
        if runEnd - runStart >= 2 {
          self.mergeIntoApplyStyle(&element, links: runStart..<runEnd, nearestFirst: type == "TextStyleElement")
        }
        runStart = runEnd
      }
      index = end
    }
  }

  /// Whether the link is a text modifier the macro may fold.
  private static func isTextModifier(_ link: ChainLink) -> Bool {
    guard case .modifier(_, let spec) = link.kind else { return false }
    return ElementCatalog.textModifiers.contains(spec.name) && link.handlers.isEmpty
  }

  /// A `TextEnvironment` expression of the links' modifiers. For a container the first link is
  /// the nearest, and must win, so it is applied last.
  private static func environment(_ chain: [ChainLink], _ links: Range<Int>, nearestFirst: Bool) -> String {
    let ordered = nearestFirst ? Array(links.reversed()) : Array(links)
    return "TextEnvironment()" + ordered.map { index -> String in
      guard case .modifier(let call, _) = chain[index].kind else { return "" }
      return suffix(call)
    }.joined()
  }

  /// A `static let` for a style that mentions neither `self` nor `Self`, or the expression
  /// itself, evaluated where it is built.
  private static func hoist(_ value: String, _ element: inout ElementIR, link: Int) -> String {
    let parsed: ExprSyntax = "\(raw: value)"
    let usesSelf = parsed.tokens(viewMode: .sourceAccurate).contains {
      $0.tokenKind == .keyword(.self) || $0.tokenKind == .keyword(.Self)
    }
    guard !usesSelf else { return value }
    let field = Naming.textStyle(element.path, link)
    element.styleConstants.append((field, value))
    return "Self.\(field)"
  }

  private func mergeIntoApplyStyle(_ element: inout ElementIR, links: Range<Int>, nearestFirst: Bool) {
    let style = Self.hoist(Self.environment(element.chain, links, nearestFirst: nearestFirst), &element, link: links.lowerBound)
    let call: ExprSyntax = "_.applyStyle(\(raw: style))"
    guard let applyCall = call.as(FunctionCallExprSyntax.self) else { return }
    element.chain[links.lowerBound].kind = .modifier(call: applyCall, spec: ElementCatalog.applyStyle)
    for index in links.dropFirst() {
      element.chain[index].kind = .passThrough
    }
  }

  /// Writes a constant style set around texts the macro can all see into those texts, and drops
  /// the `TextStyleElement` it would have made. False when it cannot: a setter to keep, or a
  /// subtree hiding texts of its own.
  private func foldIntoTexts(_ element: inout ElementIR, links: Range<Int>) -> Bool {
    guard links.allSatisfy({ element.chain[$0].bound.isEmpty }) else { return false }
    // A style set nearer, at runtime, must win over this one: it cannot be folded past.
    let nearer = element.chain[1..<links.lowerBound].contains { Self.isRuntimeStyle($0) }
    guard !nearer, let constructor = element.constructorType,
          constructor == "Text" || ElementCatalog.textFreeTypes.contains(constructor)
    else { return false }
    let covered = element.children + element.contents.filter { $0.link < links.lowerBound }.flatMap(\.children)
    guard Self.isVisible(covered) else { return false }

    let style = Self.hoist(Self.environment(element.chain, links, nearestFirst: true), &element, link: links.lowerBound)
    var texts = 0
    if constructor == "Text" {
      element.inheritedStyles.append(style)
      texts += 1
    }
    element.children = Self.inherit(style, element.children, &texts)
    for index in element.contents.indices where element.contents[index].link < links.lowerBound {
      element.contents[index] = LinkContent(
        link: element.contents[index].link, door: element.contents[index].door, path: element.contents[index].path,
        children: Self.inherit(style, element.contents[index].children, &texts)
      )
    }
    if texts == 0, case .modifier(let call, _) = element.chain[links.lowerBound].kind {
      context.warning("F18", "no Text is under this text style, so it styles nothing.", at: call.calledExpression)
    }

    let receiverType = element.chain[links.lowerBound - 1].type
    for index in links {
      element.chain[index].kind = .passThrough
      element.chain[index].type = receiverType
    }
    return true
  }

  /// A link that makes, or styles, a `TextStyleElement` at runtime.
  private static func isRuntimeStyle(_ link: ChainLink) -> Bool {
    if case .passThrough = link.kind { return false }
    return link.type == "TextStyleElement"
  }

  /// Whether every text under `nodes` is written in the body, with no runtime text style over it.
  private static func isVisible(_ nodes: [NodeIR]) -> Bool {
    nodes.allSatisfy { node in
      switch node {
      case .element(let element):
        guard let constructor = element.constructorType,
              constructor == "Text" || ElementCatalog.textFreeTypes.contains(constructor),
              !element.chain.contains(where: isRuntimeStyle)
        else { return false }
        return isVisible(element.allChildren)
      case .branch(let branch):
        return branch.arms.allSatisfy(isVisible)
      }
    }
  }

  /// `nodes` with `style` written into every text, after the styles nearer to it.
  private static func inherit(_ style: String, _ nodes: [NodeIR], _ texts: inout Int) -> [NodeIR] {
    nodes.map { node in
      switch node {
      case .element(var element):
        if element.constructorType == "Text" {
          element.inheritedStyles.append(style)
          texts += 1
        }
        element.children = inherit(style, element.children, &texts)
        for index in element.contents.indices {
          element.contents[index] = LinkContent(
            link: element.contents[index].link, door: element.contents[index].door, path: element.contents[index].path,
            children: inherit(style, element.contents[index].children, &texts)
          )
        }
        return .element(element)
      case .branch(let branch):
        return .branch(BranchIR(
          path: branch.path, kind: branch.kind, reads: branch.reads,
          arms: branch.arms.map { inherit(style, $0, &texts) }
        ))
      }
    }
  }
}
