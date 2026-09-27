import AppKit

/// What an input method asks of the focused text, as `NSTextInputClient` hears it on the main
/// thread, sent to the window's thread to be applied there.
///
/// Ranges are UTF-16, in the text as the main thread last knew it. Nil means the marked text,
/// or the selection when nothing is marked.
public enum TextInputAction: Sendable, Equatable {
  /// Text to insert for good: a typed character, a committed composition, a dictated phrase.
  case insert(String, replacement: NSRange?)
  /// The composition so far, and what the input method selects in it.
  case setMarked(String, selected: NSRange, replacement: NSRange?)
  /// Ends the composition, keeping its text.
  case unmark
  /// An `NSResponder` action selector's name: "moveLeft:", "insertNewline:", "deleteBackward:".
  case command(String)
}

/// The focused text as the main thread needs it to answer an input method at once: the
/// selection, the marked text, some text around them, and where the caret is. Published by the
/// window's thread after every frame that changed it. The main thread never waits for that
/// thread, so it answers from this, and updates it itself for what it has just sent.
public struct TextInputSnapshot: Sendable, Equatable {
  /// Whether the focused element takes text through an input method.
  public var isActive = false
  /// UTF-16, in the focused text.
  public var selection = NSRange(location: 0, length: 0)
  public var marked: NSRange? = nil
  /// Text around the selection, starting at `textStart`: what `attributedSubstring` can answer.
  public var text = ""
  public var textStart = 0
  public var length = 0
  /// The caret, or the start of the marked text, in the view: top left origin, y down, points.
  public var caretRect = CGRect.zero
  /// The last batch of actions the window's thread applied. A snapshot from before the last
  /// batch sent is stale: the main thread's own copy is ahead of it.
  public var appliedSequence: UInt64 = 0
  /// The text's revision, for mapping the ranges of actions sent against it.
  public var revision: UInt64 = 0

  public init() {}

  public static let inactive = TextInputSnapshot()

  /// How much text around the selection a snapshot carries, each way.
  static let contextLength = 512

  /// This snapshot after `action`, as the window's thread will make it: what the main thread
  /// answers with until the thread's own snapshot arrives.
  public func applying(_ action: TextInputAction) -> TextInputSnapshot {
    var next = self
    switch action {
    case let .insert(string, replacement):
      let target = replacement ?? self.marked ?? self.selection
      let count = string.utf16.count
      next.replace(target, with: string)
      next.selection = NSRange(location: target.location + count, length: 0)
      next.marked = nil
    case let .setMarked(string, selected, replacement):
      let target = replacement ?? self.marked ?? self.selection
      let count = string.utf16.count
      next.replace(target, with: string)
      if count == 0 {
        next.marked = nil
        next.selection = NSRange(location: target.location, length: 0)
      } else {
        next.marked = NSRange(location: target.location, length: count)
        let low = min(max(selected.location, 0), count)
        let high = min(max(selected.location + selected.length, low), count)
        next.selection = NSRange(location: target.location + low, length: high - low)
      }
    case .unmark:
      if let marked = self.marked {
        next.selection = NSRange(location: marked.location + marked.length, length: 0)
      }
      next.marked = nil
    case .command:
      break
    }
    return next
  }

  /// Replaces `range` of the text with `string`, in the carried text too when it covers it.
  private mutating func replace(_ range: NSRange, with string: String) {
    let count = string.utf16.count
    self.length += count - range.length
    let local = range.location - self.textStart
    var units = Array(self.text.utf16)
    if local >= 0, local + range.length <= units.count {
      units.replaceSubrange(local ..< local + range.length, with: string.utf16)
      self.text = String(decoding: units, as: UTF16.self)
    }
  }

  /// The carried text in `range`, and the part of `range` it covers; nil outside it.
  public func substring(_ range: NSRange) -> (String, NSRange)? {
    let units = Array(self.text.utf16)
    let low = max(range.location, self.textStart)
    let high = min(range.location + range.length, self.textStart + units.count)
    guard low <= high else { return nil }
    let slice = units[(low - self.textStart) ..< (high - self.textStart)]
    return (String(decoding: slice, as: UTF16.self), NSRange(location: low, length: high - low))
  }
}

/// An element that takes text through input methods: the focused one's snapshot is published to
/// the main thread, and what input methods ask for comes back to it. Set as a
/// `FocusableElement`'s `textInputClient`.
protocol TextInputClient: AnyObject {
  /// The text as it is now; `appliedSequence` is filled in by the caller.
  func textInputSnapshot() -> TextInputSnapshot
  /// Applies what an input method asked for, sent against the text at `revision`.
  func applyTextInput(_ actions: [TextInputAction], revision: UInt64)
}
