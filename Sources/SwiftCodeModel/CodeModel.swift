import SwiftParser
import SwiftSyntax

/// A declaration in a Swift file, as an outline lists it.
public struct CodeSymbol: Sendable, Hashable, Identifiable {
  public enum Kind: String, Sendable {
    case `class`, `struct`, `enum`, `protocol`, `extension`, actor
    case function, initializer, variable, enumCase, `typealias`, `subscript`, macro
    /// A `// MARK: -` comment.
    case mark
  }

  public let name: String
  public let kind: Kind
  /// The whole declaration, in UTF-16 offsets.
  public let range: Range<Int>
  /// Its name: what the outline selects.
  public let nameRange: Range<Int>
  /// How many types and extensions it is inside.
  public let depth: Int

  public var id: String { "\(self.nameRange.lowerBound):\(self.kind.rawValue):\(self.name)" }

  public init(name: String, kind: Kind, range: Range<Int>, nameRange: Range<Int>, depth: Int) {
    self.name = name
    self.kind = kind
    self.range = range
    self.nameRange = nameRange
    self.depth = depth
  }
}

/// What a Swift file holds, as the editor uses it.
public struct CodeAnalysis: Sendable, Equatable {
  /// Declarations and marks, in the order they appear: a tree flattened with each one's depth.
  public var symbols: [CodeSymbol]
  /// What can be folded, in UTF-16 offsets, sorted by start: braces spanning lines, from the
  /// opening one through the closing one; block comments spanning lines.
  public var foldingRanges: [Range<Int>]

  public init(symbols: [CodeSymbol] = [], foldingRanges: [Range<Int>] = []) {
    self.symbols = symbols
    self.foldingRanges = foldingRanges
  }
}

/// Parses Swift with swift-syntax. A pure function of the text: run it off the window's thread.
/// The parser recovers from errors, so a file being typed still has an outline.
public enum CodeModel {
  public static func analyze(_ source: String) -> CodeAnalysis {
    var source = source
    return source.withUTF8 { utf8 in
      let tree = Parser.parse(source: utf8)
      let visitor = OutlineVisitor(utf8: utf8)
      visitor.walk(tree)
      visitor.findMarks()
      return visitor.analysis()
    }
  }
}

/// Collects symbols and folding ranges in UTF-8 offsets, then converts them all to UTF-16 in one
/// pass over the text.
private final class OutlineVisitor: SyntaxVisitor {
  private let utf8: UnsafeBufferPointer<UInt8>
  private var depth = 0
  private var symbols: [(name: String, kind: CodeSymbol.Kind, range: Range<Int>, nameRange: Range<Int>, depth: Int)] = []
  private var folds: [Range<Int>] = []

  init(utf8: UnsafeBufferPointer<UInt8>) {
    self.utf8 = utf8
    super.init(viewMode: .sourceAccurate)
  }

  // MARK: - Types

  override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
    self.enter(node, node.name, .class, node.memberBlock)
  }

  override func visitPost(_ node: ClassDeclSyntax) { self.depth -= 1 }

  override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
    self.enter(node, node.name, .struct, node.memberBlock)
  }

  override func visitPost(_ node: StructDeclSyntax) { self.depth -= 1 }

  override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
    self.enter(node, node.name, .enum, node.memberBlock)
  }

  override func visitPost(_ node: EnumDeclSyntax) { self.depth -= 1 }

  override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
    self.enter(node, node.name, .protocol, node.memberBlock)
  }

  override func visitPost(_ node: ProtocolDeclSyntax) { self.depth -= 1 }

  override func visit(_ node: ActorDeclSyntax) -> SyntaxVisitorContinueKind {
    self.enter(node, node.name, .actor, node.memberBlock)
  }

  override func visitPost(_ node: ActorDeclSyntax) { self.depth -= 1 }

  override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
    let type = node.extendedType
    self.add(type.trimmedDescription, .extension, node, nameStart: type.positionAfterSkippingLeadingTrivia,
             nameEnd: type.endPositionBeforeTrailingTrivia)
    self.fold(node.memberBlock.leftBrace, node.memberBlock.rightBrace)
    self.depth += 1
    return .visitChildren
  }

  override func visitPost(_ node: ExtensionDeclSyntax) { self.depth -= 1 }

  private func enter(_ node: some SyntaxProtocol, _ name: TokenSyntax, _ kind: CodeSymbol.Kind,
                     _ members: MemberBlockSyntax) -> SyntaxVisitorContinueKind {
    self.add(name, kind, node)
    self.fold(members.leftBrace, members.rightBrace)
    self.depth += 1
    return .visitChildren
  }

  // MARK: - Members

  override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
    let parameters = node.signature.parameterClause.parameters.map { ($0.firstName.text) + ":" }.joined()
    self.add(node.name, .function, node, display: "\(node.name.text)(\(parameters))")
    return .visitChildren
  }

  override func visit(_ node: InitializerDeclSyntax) -> SyntaxVisitorContinueKind {
    let parameters = node.signature.parameterClause.parameters.map { ($0.firstName.text) + ":" }.joined()
    self.add(node.initKeyword, .initializer, node, display: "init\(node.optionalMark?.text ?? "")(\(parameters))")
    return .visitChildren
  }

  override func visit(_ node: SubscriptDeclSyntax) -> SyntaxVisitorContinueKind {
    self.add(node.subscriptKeyword, .subscript, node)
    return .visitChildren
  }

  override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
    // Only members and globals: a local variable is no part of an outline.
    guard self.isOutlineLevel(node) else { return .visitChildren }
    for binding in node.bindings {
      if let identifier = binding.pattern.as(IdentifierPatternSyntax.self) {
        self.add(identifier.identifier, .variable, node)
      }
    }
    return .visitChildren
  }

  override func visit(_ node: EnumCaseDeclSyntax) -> SyntaxVisitorContinueKind {
    for element in node.elements {
      self.add(element.name, .enumCase, element)
    }
    return .skipChildren
  }

  override func visit(_ node: TypeAliasDeclSyntax) -> SyntaxVisitorContinueKind {
    self.add(node.name, .typealias, node)
    return .skipChildren
  }

  override func visit(_ node: MacroDeclSyntax) -> SyntaxVisitorContinueKind {
    self.add(node.name, .macro, node)
    return .skipChildren
  }

  /// A declaration directly in a file or a type's member block, not in a function's body.
  private func isOutlineLevel(_ node: some SyntaxProtocol) -> Bool {
    var parent = node.parent
    while let current = parent {
      if current.is(MemberBlockSyntax.self) || current.is(SourceFileSyntax.self) { return true }
      if current.is(CodeBlockSyntax.self) || current.is(ClosureExprSyntax.self) || current.is(AccessorBlockSyntax.self) {
        return false
      }
      parent = current.parent
    }
    return true
  }

  // MARK: - Folding

  override func visit(_ node: CodeBlockSyntax) -> SyntaxVisitorContinueKind {
    self.fold(node.leftBrace, node.rightBrace)
    return .visitChildren
  }

  override func visit(_ node: ClosureExprSyntax) -> SyntaxVisitorContinueKind {
    self.fold(node.leftBrace, node.rightBrace)
    return .visitChildren
  }

  override func visit(_ node: AccessorBlockSyntax) -> SyntaxVisitorContinueKind {
    self.fold(node.leftBrace, node.rightBrace)
    return .visitChildren
  }

  override func visit(_ node: SwitchExprSyntax) -> SyntaxVisitorContinueKind {
    self.fold(node.leftBrace, node.rightBrace)
    return .visitChildren
  }

  override func visit(_ node: TokenSyntax) -> SyntaxVisitorContinueKind {
    // Block comments spanning lines, in the trivia before a token.
    var position = node.position.utf8Offset
    for piece in node.leadingTrivia {
      let length = piece.sourceLength.utf8Length
      if case .blockComment = piece, self.spansLines(position, position + length) {
        self.folds.append(position ..< position + length)
      }
      if case .docBlockComment = piece, self.spansLines(position, position + length) {
        self.folds.append(position ..< position + length)
      }
      position += length
    }
    return .skipChildren
  }

  private func fold(_ left: TokenSyntax, _ right: TokenSyntax) {
    guard left.presence == .present, right.presence == .present else { return }
    let start = left.positionAfterSkippingLeadingTrivia.utf8Offset
    let end = right.endPositionBeforeTrailingTrivia.utf8Offset
    guard self.spansLines(start, end) else { return }
    self.folds.append(start ..< end)
  }

  private func spansLines(_ start: Int, _ end: Int) -> Bool {
    var i = start
    while i < end && i < self.utf8.count {
      if self.utf8[i] == 0x0A { return true }
      i += 1
    }
    return false
  }

  // MARK: - Symbols

  private func add(_ name: TokenSyntax, _ kind: CodeSymbol.Kind, _ node: some SyntaxProtocol, display: String? = nil) {
    guard name.presence == .present else { return }
    self.add(display ?? name.text, kind, node, nameStart: name.positionAfterSkippingLeadingTrivia,
             nameEnd: name.endPositionBeforeTrailingTrivia)
  }

  private func add(_ name: String, _ kind: CodeSymbol.Kind, _ node: some SyntaxProtocol,
                   nameStart: AbsolutePosition, nameEnd: AbsolutePosition) {
    self.symbols.append((
      name, kind,
      node.positionAfterSkippingLeadingTrivia.utf8Offset ..< node.endPositionBeforeTrailingTrivia.utf8Offset,
      nameStart.utf8Offset ..< nameEnd.utf8Offset, self.depth
    ))
  }

  /// `// MARK: name` and `// MARK: - name` lines, at the depth of the types around them.
  func findMarks() {
    let marker = Array("// MARK:".utf8)
    var lineStart = 0
    let count = self.utf8.count
    while lineStart < count {
      var lineEnd = lineStart
      while lineEnd < count && self.utf8[lineEnd] != 0x0A { lineEnd += 1 }
      var i = lineStart
      while i < lineEnd && (self.utf8[i] == 0x20 || self.utf8[i] == 0x09) { i += 1 }
      if lineEnd - i >= marker.count && (0 ..< marker.count).allSatisfy({ self.utf8[i + $0] == marker[$0] }) {
        var nameStart = i + marker.count
        while nameStart < lineEnd && (self.utf8[nameStart] == 0x20 || self.utf8[nameStart] == 0x2D) { nameStart += 1 }
        let name = String(decoding: UnsafeBufferPointer(rebasing: self.utf8[nameStart ..< lineEnd]), as: UTF8.self)
        let depth = self.symbols.count { symbol in
          symbol.range.contains(i) && [.class, .struct, .enum, .protocol, .actor, .extension].contains(symbol.kind)
        }
        if !name.isEmpty {
          self.symbols.append((name, .mark, i ..< lineEnd, nameStart ..< lineEnd, depth))
        }
      }
      lineStart = lineEnd + 1
    }
    self.symbols.sort { $0.range.lowerBound < $1.range.lowerBound }
  }

  // MARK: - UTF-16

  func analysis() -> CodeAnalysis {
    var offsets: [Int] = []
    offsets.reserveCapacity(self.symbols.count * 4 + self.folds.count * 2)
    for symbol in self.symbols {
      offsets += [symbol.range.lowerBound, symbol.range.upperBound, symbol.nameRange.lowerBound, symbol.nameRange.upperBound]
    }
    for fold in self.folds {
      offsets += [fold.lowerBound, fold.upperBound]
    }
    let table = Self.utf16Offsets(of: Array(Set(offsets)).sorted(), in: self.utf8)
    func map(_ range: Range<Int>) -> Range<Int> {
      let low = table[range.lowerBound] ?? 0
      return low ..< max(low, table[range.upperBound] ?? low)
    }
    let symbols = self.symbols.map { symbol in
      CodeSymbol(name: symbol.name, kind: symbol.kind, range: map(symbol.range), nameRange: map(symbol.nameRange),
                 depth: symbol.depth)
    }
    let folds = self.folds.map(map).sorted { $0.lowerBound != $1.lowerBound ? $0.lowerBound < $1.lowerBound : $0.upperBound > $1.upperBound }
    return CodeAnalysis(symbols: symbols, foldingRanges: folds)
  }

  /// The UTF-16 offset of each UTF-8 offset in `sorted`, in one walk over the text.
  static func utf16Offsets(of sorted: [Int], in utf8: UnsafeBufferPointer<UInt8>) -> [Int: Int] {
    var table: [Int: Int] = [:]
    table.reserveCapacity(sorted.count)
    var byte = 0
    var unit = 0
    for target in sorted {
      while byte < target && byte < utf8.count {
        let lead = utf8[byte]
        let width = lead < 0x80 ? 1 : lead < 0xE0 ? 2 : lead < 0xF0 ? 3 : 4
        byte += width
        unit += width == 4 ? 2 : 1
      }
      table[target] = unit
    }
    return table
  }
}
