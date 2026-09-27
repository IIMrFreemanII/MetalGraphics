/// What a styler knows at the start of a line: inside a block comment, a multi-line string, a
/// fenced code block. Packed by the styler into 64 bits; `initial` is the start of a document.
public struct StyleState: Hashable, Sendable {
  public var raw: UInt64

  public init(_ raw: UInt64 = 0) {
    self.raw = raw
  }

  public static let initial = StyleState()
}

/// Something shown below a line, taking height of its own: a markdown image. A
/// `TextAttachmentProvider` makes its element from `source`.
public struct BlockDecoration: Hashable, Sendable {
  public var attachment: TextAttachmentID
  public var source: String?

  public init(_ attachment: TextAttachmentID, source: String? = nil) {
    self.attachment = attachment
    self.source = source
  }
}

/// Turns lines of text into tokens: a language's highlighter.
///
/// A styler sees one line at a time, with the state the line before left, and returns the state
/// it leaves: what a construct spanning lines — a block comment, a multi-line string — needs.
/// Its output for a line must depend on nothing else, which is what lets an editor restyle only
/// the lines an edit can change: typing in a function restyles its line; opening `/*` restyles
/// the lines below until the states agree with what they were again.
public protocol TextStyler: AnyObject {
  /// The tokens of `text`, one line without its newline, starting in `state`, in order and not
  /// overlapping, into `spans`. Returns the state at its end.
  func styleLine(_ text: UnsafeBufferPointer<UInt16>, state: StyleState, into spans: inout [TextSpan]) -> StyleState
  /// What ⌘/ puts before a line; nil for none.
  var lineComment: String? { get }
  /// Units, besides letters, digits and `_`, that words are made of.
  var wordCharacters: Set<UInt16> { get }
  /// What is shown below a line in `state` with `text`: an image. None by default.
  func blocks(_ text: UnsafeBufferPointer<UInt16>, state: StyleState, into blocks: inout [BlockDecoration])
}

public extension TextStyler {
  var lineComment: String? { nil }
  var wordCharacters: Set<UInt16> { [] }
  func blocks(_ text: UnsafeBufferPointer<UInt16>, state: StyleState, into blocks: inout [BlockDecoration]) {}
}
