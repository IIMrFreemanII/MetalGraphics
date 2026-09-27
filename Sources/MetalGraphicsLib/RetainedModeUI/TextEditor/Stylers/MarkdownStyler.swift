/// Styles Markdown as it is written: headings larger and bold, emphasis, strong, code spans,
/// strikethrough, links, quotes, list markers and rules, the markup itself dimmed but kept.
/// Fenced code blocks are code, and Swift ones are highlighted by a `SwiftStyler`. An image,
/// `![alt](name)`, is shown below its line when the editor has an attachment provider: a block
/// whose source is `name`.
///
/// Forward only, a line at a time, so not all of CommonMark: no setext headings (they need the
/// line after), no emphasis nested in emphasis, no reference links.
public final class MarkdownStyler: TextStyler {
  private let swift = SwiftStyler()

  public init() {}

  // State: bit 0 set inside a fence; bits 1–8 the fence's length, bit 9 a tilde fence, bit 10
  // a Swift fence; the Swift styler's own state above bit 16.
  private static let inFence: UInt64 = 1
  private static let tildeFence: UInt64 = 1 << 9
  private static let swiftFence: UInt64 = 1 << 10

  public func styleLine(_ text: UnsafeBufferPointer<UInt16>, state: StyleState, into spans: inout [TextSpan]) -> StyleState {
    let count = text.count
    var indent = 0
    while indent < count && indent < 4 && text[indent] == 0x20 { indent += 1 }

    if state.raw & Self.inFence != 0 {
      let length = Int((state.raw >> 1) & 0xFF)
      let fence: UInt16 = state.raw & Self.tildeFence != 0 ? 0x7E : 0x60
      if indent < 4, Self.run(of: fence, in: text, from: indent) >= length,
         Self.isBlank(text, from: indent + Self.run(of: fence, in: text, from: indent)) {
        spans.append(TextSpan(start: 0, end: Int32(count), token: .markup))
        return .initial
      }
      if state.raw & Self.swiftFence != 0 {
        let inner = self.swift.styleLine(text, state: StyleState(state.raw >> 16), into: &spans)
        return StyleState((state.raw & 0xFFFF) | inner.raw << 16)
      }
      if count > 0 { spans.append(TextSpan(start: 0, end: Int32(count), token: .code)) }
      return state
    }

    guard indent < 4, indent < count else {
      // Indented code, or a blank line.
      if count > 0 && indent >= 4 { spans.append(TextSpan(start: 0, end: Int32(count), token: .code)) }
      return .initial
    }
    let first = text[indent]

    // A fence opens: ``` or ~~~, three or more, then the language.
    if first == 0x60 || first == 0x7E {
      let length = Self.run(of: first, in: text, from: indent)
      if length >= 3 {
        spans.append(TextSpan(start: 0, end: Int32(count), token: .markup))
        let language = Self.word(text, from: indent + length)
        var raw = Self.inFence | UInt64(min(length, 255)) << 1
        if first == 0x7E { raw |= Self.tildeFence }
        if language == Array("swift".utf16) { raw |= Self.swiftFence }
        return StyleState(raw)
      }
    }

    // # Heading
    if first == 0x23 {
      let level = Self.run(of: 0x23, in: text, from: indent)
      if level <= 6 && (indent + level == count || text[indent + level] == 0x20) {
        spans.append(TextSpan(start: 0, end: Int32(indent + level), token: .markup))
        if indent + level < count {
          spans.append(TextSpan(start: Int32(indent + level), end: Int32(count), token: .heading(level)))
        }
        return .initial
      }
    }

    // A rule: three or more of -, * or _, and nothing else.
    if first == 0x2D || first == 0x2A || first == 0x5F {
      var marks = 0
      var onlyMarks = true
      for i in indent ..< count {
        if text[i] == first { marks += 1 } else if text[i] != 0x20 { onlyMarks = false; break }
      }
      if onlyMarks && marks >= 3 {
        spans.append(TextSpan(start: 0, end: Int32(count), token: .markup))
        return .initial
      }
    }

    // > quote
    if first == 0x3E {
      spans.append(TextSpan(start: Int32(indent), end: Int32(indent + 1), token: .markup))
      if indent + 1 < count {
        spans.append(TextSpan(start: Int32(indent + 1), end: Int32(count), token: .quote))
      }
      return .initial
    }

    // - item, * item, + item, 1. item
    var body = indent
    if (first == 0x2D || first == 0x2A || first == 0x2B) && indent + 1 < count && text[indent + 1] == 0x20 {
      spans.append(TextSpan(start: Int32(indent), end: Int32(indent + 1), token: .listMarker))
      body = indent + 2
    } else if first >= 0x30 && first <= 0x39 {
      var i = indent
      while i < count && text[i] >= 0x30 && text[i] <= 0x39 { i += 1 }
      if i < count - 1 && (text[i] == 0x2E || text[i] == 0x29) && text[i + 1] == 0x20 {
        spans.append(TextSpan(start: Int32(indent), end: Int32(i + 1), token: .listMarker))
        body = i + 2
      }
    }
    self.inline(text, from: body, into: &spans)
    return .initial
  }

  public func blocks(_ text: UnsafeBufferPointer<UInt16>, state: StyleState, into blocks: inout [BlockDecoration]) {
    guard state.raw & Self.inFence == 0 else { return }
    // Each ![alt](source) on the line.
    var i = 0
    let count = text.count
    while i + 1 < count {
      if text[i] == 0x21 && text[i + 1] == 0x5B, let (_, target, end) = Self.link(text, from: i + 1) {
        let source = String(decoding: UnsafeBufferPointer(rebasing: text[target]), as: UTF16.self)
        blocks.append(BlockDecoration(TextAttachmentID(Self.hash(source) ^ i), source: source))
        i = end
      } else {
        i += 1
      }
    }
  }

  // MARK: - Inline

  /// Code spans, strong, emphasis, strikethrough, links and images, from `start`.
  private func inline(_ text: UnsafeBufferPointer<UInt16>, from start: Int, into spans: inout [TextSpan]) {
    let count = text.count
    var i = start
    while i < count {
      let c = text[i]
      switch c {
      case 0x60:   // `code`
        let ticks = Self.run(of: 0x60, in: text, from: i)
        if let close = Self.find(run: 0x60, length: ticks, in: text, from: i + ticks) {
          spans.append(TextSpan(start: Int32(i), end: Int32(close + ticks), token: .code))
          i = close + ticks
          continue
        }
        i += ticks
      case 0x2A, 0x5F, 0x7E:   // * _ ~
        let length = min(Self.run(of: c, in: text, from: i), c == 0x7E ? 2 : 3)
        if c == 0x7E && length < 2 { i += 1; continue }
        // Emphasis opens before text, not before a space.
        guard i + length < count, text[i + length] != 0x20,
              let close = Self.find(run: c, length: length, in: text, from: i + length), close > i + length
        else { i += length; continue }
        let token: TextToken = c == 0x7E ? .strikethrough : length == 1 ? .emphasis : length == 2 ? .strong : .strongEmphasis
        spans.append(TextSpan(start: Int32(i), end: Int32(i + length), token: .markup))
        spans.append(TextSpan(start: Int32(i + length), end: Int32(close), token: token))
        spans.append(TextSpan(start: Int32(close), end: Int32(close + length), token: .markup))
        i = close + length
      case 0x21 where i + 1 < count && text[i + 1] == 0x5B:   // ![alt](source)
        if let (_, _, end) = Self.link(text, from: i + 1) {
          spans.append(TextSpan(start: Int32(i), end: Int32(end), token: .markup))
          i = end
        } else {
          i += 1
        }
      case 0x5B:   // [text](url)
        if let (label, _, end) = Self.link(text, from: i) {
          spans.append(TextSpan(start: Int32(i), end: Int32(label.lowerBound), token: .markup))
          spans.append(TextSpan(start: Int32(label.lowerBound), end: Int32(label.upperBound), token: .link))
          spans.append(TextSpan(start: Int32(label.upperBound), end: Int32(end), token: .markup))
          i = end
        } else {
          i += 1
        }
      default:
        i += 1
      }
    }
  }

  /// `[label](target)` from the `[` at `start`: the label's range, the target's, and the end.
  private static func link(_ text: UnsafeBufferPointer<UInt16>, from start: Int) -> (Range<Int>, Range<Int>, Int)? {
    let count = text.count
    var i = start + 1
    while i < count && text[i] != 0x5D { i += 1 }
    guard i + 1 < count, text[i + 1] == 0x28 else { return nil }
    let label = start + 1 ..< i
    var j = i + 2
    while j < count && text[j] != 0x29 { j += 1 }
    guard j < count else { return nil }
    return (label, i + 2 ..< j, j + 1)
  }

  /// Where the next run of exactly `length` of `unit` starts, from `start`.
  private static func find(run unit: UInt16, length: Int, in text: UnsafeBufferPointer<UInt16>, from start: Int) -> Int? {
    var i = start
    while i < text.count {
      if text[i] == unit {
        let run = Self.run(of: unit, in: text, from: i)
        if run == length { return i }
        i += run
      } else {
        i += 1
      }
    }
    return nil
  }

  private static func run(of unit: UInt16, in text: UnsafeBufferPointer<UInt16>, from start: Int) -> Int {
    var i = start
    while i < text.count && text[i] == unit { i += 1 }
    return i - start
  }

  private static func isBlank(_ text: UnsafeBufferPointer<UInt16>, from start: Int) -> Bool {
    for i in start ..< max(start, text.count) where text[i] != 0x20 { return false }
    return true
  }

  /// The word at `start` after spaces, lowercased ASCII.
  private static func word(_ text: UnsafeBufferPointer<UInt16>, from start: Int) -> [UInt16] {
    var i = start
    while i < text.count && text[i] == 0x20 { i += 1 }
    var word: [UInt16] = []
    while i < text.count && text[i] != 0x20 {
      let c = text[i]
      word.append(c >= 0x41 && c <= 0x5A ? c + 0x20 : c)
      i += 1
    }
    return word
  }

  private static func hash(_ string: String) -> Int {
    var hash: UInt64 = 0xCBF2_9CE4_8422_2325
    for unit in string.utf16 {
      hash ^= UInt64(unit)
      hash = hash &* 0x100_0000_01B3
    }
    return Int(truncatingIfNeeded: hash)
  }
}
