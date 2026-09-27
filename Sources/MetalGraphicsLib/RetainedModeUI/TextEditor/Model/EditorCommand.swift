/// How far a caret moves, or a deletion reaches.
public enum TextMotion: Hashable, Sendable {
  /// One user-perceived character.
  case character
  /// To a word's end going forward, its start going back (⌥→ ⌥←).
  case word
  /// As `word`, but also stopping inside camelCase and snake_case names (⌃⌥→ ⌃⌥←).
  case subword
  /// One line on screen up or down, keeping the x the caret aims for (↑ ↓).
  case visualLine
  /// A screenful up or down (Page Up, Page Down with ⌥).
  case page
  /// The start or end of the line on screen: a soft-wrapped line's piece (⌘← ⌘→).
  case lineBoundary
  /// The start or end of the whole line, the text between newlines (⌃A ⌃E).
  case paragraphBoundary
  /// To the start of this paragraph or the one before; the end of this one or the next (⌥↑ ⌥↓).
  case paragraph
  /// The start or end of the document (⌘↑ ⌘↓).
  case document
}

/// What an editor can be asked to do: by a key, through the input method's commands, or by the
/// app. `TextEditor.onCommand` sees each first and may take it over.
public enum EditorCommand: Hashable, Sendable {
  case move(TextMotion, forward: Bool, extend: Bool)
  case delete(TextMotion, forward: Bool)
  case deleteSelection
  case insertText(String)
  /// A newline, indented like the line it breaks.
  case insertNewline
  /// A newline and nothing else.
  case insertLineBreak
  case insertTab
  case insertBacktab
  case indent
  case outdent
  case toggleComment
  case selectAll
  case selectWord
  case selectLine
  case transpose
  /// Inserts what ⌃K last deleted.
  case yank
  case undo
  case redo
  case copy
  case cut
  case paste(String)
  /// Escape: drops extra cursors, else is left to the app.
  case cancel
  /// Scrolls without moving the caret (Home, End, Page Up, Page Down).
  case scrollToDocumentEdge(forward: Bool)
  case scrollPage(forward: Bool)
  case scrollLine(forward: Bool)
  case centerSelection

  /// The command an `NSResponder` action selector names, as input methods and the key bindings
  /// in `DefaultKeyBinding.dict` send them. Nil for one the editor does not do.
  public init?(selector: String) {
    var name = selector
    let extend = name.hasSuffix("AndModifySelection:")
    if extend { name = String(name.dropLast("AndModifySelection:".count)) + ":" }
    switch name {
    case "moveLeft:", "moveBackward:": self = .move(.character, forward: false, extend: extend)
    case "moveRight:", "moveForward:": self = .move(.character, forward: true, extend: extend)
    case "moveUp:": self = .move(.visualLine, forward: false, extend: extend)
    case "moveDown:": self = .move(.visualLine, forward: true, extend: extend)
    case "moveWordLeft:", "moveWordBackward:": self = .move(.word, forward: false, extend: extend)
    case "moveWordRight:", "moveWordForward:": self = .move(.word, forward: true, extend: extend)
    case "moveSubWordBackward:": self = .move(.subword, forward: false, extend: extend)
    case "moveSubWordForward:": self = .move(.subword, forward: true, extend: extend)
    case "moveToBeginningOfLine:", "moveToLeftEndOfLine:": self = .move(.lineBoundary, forward: false, extend: extend)
    case "moveToEndOfLine:", "moveToRightEndOfLine:": self = .move(.lineBoundary, forward: true, extend: extend)
    case "moveToBeginningOfParagraph:": self = .move(.paragraphBoundary, forward: false, extend: extend)
    case "moveToEndOfParagraph:": self = .move(.paragraphBoundary, forward: true, extend: extend)
    case "moveParagraphBackward:": self = .move(.paragraph, forward: false, extend: extend)
    case "moveParagraphForward:": self = .move(.paragraph, forward: true, extend: extend)
    case "moveToBeginningOfDocument:": self = .move(.document, forward: false, extend: extend)
    case "moveToEndOfDocument:": self = .move(.document, forward: true, extend: extend)
    case "pageUp:": self = .move(.page, forward: false, extend: extend)
    case "pageDown:": self = .move(.page, forward: true, extend: extend)
    case "deleteBackward:", "deleteBackwardByDecomposingPreviousCharacter:": self = .delete(.character, forward: false)
    case "deleteForward:": self = .delete(.character, forward: true)
    case "deleteWordBackward:": self = .delete(.word, forward: false)
    case "deleteWordForward:": self = .delete(.word, forward: true)
    case "deleteToBeginningOfLine:": self = .delete(.lineBoundary, forward: false)
    case "deleteToEndOfLine:": self = .delete(.lineBoundary, forward: true)
    case "deleteToBeginningOfParagraph:": self = .delete(.paragraphBoundary, forward: false)
    case "deleteToEndOfParagraph:": self = .delete(.paragraphBoundary, forward: true)
    case "insertNewline:", "insertParagraphSeparator:", "insertNewlineIgnoringFieldEditor:": self = .insertNewline
    case "insertLineBreak:": self = .insertLineBreak
    case "insertTab:", "insertTabIgnoringFieldEditor:": self = .insertTab
    case "insertBacktab:": self = .insertBacktab
    case "transpose:": self = .transpose
    case "yank:": self = .yank
    case "selectAll:": self = .selectAll
    case "selectWord:": self = .selectWord
    case "selectLine:", "selectParagraph:": self = .selectLine
    case "cancelOperation:": self = .cancel
    case "scrollToBeginningOfDocument:": self = .scrollToDocumentEdge(forward: false)
    case "scrollToEndOfDocument:": self = .scrollToDocumentEdge(forward: true)
    case "scrollPageUp:": self = .scrollPage(forward: false)
    case "scrollPageDown:": self = .scrollPage(forward: true)
    case "scrollLineUp:": self = .scrollLine(forward: false)
    case "scrollLineDown:": self = .scrollLine(forward: true)
    case "centerSelectionInVisibleArea:": self = .centerSelection
    case "indent:", "shiftRight:": self = .indent
    case "shiftLeft:": self = .outdent
    default: return nil
    }
  }
}

/// What the editor's layout answers for the moves that depend on where lines break on screen.
public protocol TextLayoutQueries: AnyObject {
  /// The caret `lines` lines on screen below `offset` (above, for a negative count), as near
  /// `goalX` as the line allows, or the caret's own x when there is none. Past the first line
  /// it is the document's start; past the last, its end.
  func verticalMove(from offset: Int, affinity: TextAffinity, goalX: Float?, lines: Int)
    -> (offset: Int, affinity: TextAffinity, goalX: Float)
  /// The start or end of the line on screen holding the caret.
  func visualLineBoundary(of offset: Int, affinity: TextAffinity, forward: Bool) -> (offset: Int, affinity: TextAffinity)
  /// How many lines a page move goes.
  var linesPerPage: Int { get }
}
