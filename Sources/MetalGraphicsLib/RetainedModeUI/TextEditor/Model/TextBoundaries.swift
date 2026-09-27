import CoreFoundation
import Foundation

/// Where carets may stop and words begin and end, in a document's UTF-16 text.
///
/// A caret never splits a user-perceived character: a surrogate pair, a letter and its combining
/// marks, an emoji sequence. ASCII text next to ASCII takes a fast path; anything else asks
/// CoreFoundation for the composed character around it, within its line.
enum TextBoundaries {
  /// The character class a word is made of.
  enum CharacterClass {
    case word
    case space
    case punctuation
    case newline
  }

  static func characterClass(_ unit: UInt16, wordCharacters: Set<UInt16> = []) -> CharacterClass {
    switch unit {
    case 0x0A: return .newline
    case 0x20, 0x09: return .space
    case 0x30 ... 0x39, 0x41 ... 0x5A, 0x61 ... 0x7A, 0x5F: return .word
    case 0 ..< 0x80:
      return wordCharacters.contains(unit) ? .word : .punctuation
    case 0xD800 ... 0xDFFF:
      // Mostly CJK extensions and emoji: word enough.
      return .word
    default:
      guard let scalar = Unicode.Scalar(unit) else { return .punctuation }
      if scalar.properties.isWhitespace { return .space }
      if scalar.properties.isAlphabetic || scalar.properties.numericType != nil || scalar.properties.isDiacritic {
        return .word
      }
      return wordCharacters.contains(unit) ? .word : .punctuation
    }
  }

  /// The caret stop after `offset`: the end of the character that starts there.
  static func next(after offset: Int, in document: TextDocument) -> Int {
    let length = document.length
    guard offset < length else { return length }
    let unit = document.unit(at: offset)
    if unit < 0x300 && (offset + 1 >= length || document.unit(at: offset + 1) < 0x300) {
      return offset + 1
    }
    return self.composedRange(at: offset, in: document).upperBound
  }

  /// The caret stop before `offset`: the start of the character that ends there.
  static func previous(before offset: Int, in document: TextDocument) -> Int {
    guard offset > 0 else { return 0 }
    let unit = document.unit(at: offset - 1)
    if unit < 0x300 && (offset - 2 < 0 || document.unit(at: offset - 2) < 0x300) && (offset >= document.length || document.unit(at: offset) < 0x300) {
      return offset - 1
    }
    return self.composedRange(at: offset - 1, in: document).lowerBound
  }

  /// `offset`, moved back to the start of the character it falls inside, if it splits one.
  static func snap(_ offset: Int, in document: TextDocument) -> Int {
    let offset = offset.clamped(to: 0 ... document.length)
    guard offset > 0 && offset < document.length else { return offset }
    let unit = document.unit(at: offset)
    let before = document.unit(at: offset - 1)
    if unit < 0x300 && before < 0x300 { return offset }
    let range = self.composedRange(at: offset, in: document)
    return range.lowerBound == offset ? offset : range.lowerBound
  }

  /// The composed character sequence holding the unit at `offset`, which lies within its line.
  private static func composedRange(at offset: Int, in document: TextDocument) -> Range<Int> {
    let line = document.line(containing: offset)
    let range = document.lineRange(line, includingNewline: true)
    // Enough context around the unit, never the whole of a long line.
    let low = max(range.lowerBound, offset - 64)
    let high = min(range.upperBound, offset + 64)
    return document.withUTF16(in: low ..< high) { units -> Range<Int> in
      guard let base = units.baseAddress, units.count > 0 else { return offset ..< offset + 1 }
      guard let string = CFStringCreateWithCharactersNoCopy(nil, base, units.count, kCFAllocatorNull) else {
        return offset ..< offset + 1
      }
      let composed = CFStringGetRangeOfComposedCharactersAtIndex(string, offset - low)
      return low + composed.location ..< low + composed.location + composed.length
    }
  }

  // MARK: - Words

  /// Where ⌥→ goes: over any spaces and punctuation, then to the end of the word.
  static func wordEnd(after offset: Int, in document: TextDocument, wordCharacters: Set<UInt16> = []) -> Int {
    let length = document.length
    var i = offset
    // Skip what is not a word, then the word; a run of punctuation counts as one if no word follows on the line.
    while i < length {
      let kind = self.characterClass(document.unit(at: i), wordCharacters: wordCharacters)
      if kind == .word { break }
      if kind == .punctuation {
        var j = i
        while j < length && self.characterClass(document.unit(at: j), wordCharacters: wordCharacters) == .punctuation { j += 1 }
        return j
      }
      i += 1
    }
    while i < length && self.characterClass(document.unit(at: i), wordCharacters: wordCharacters) == .word { i += 1 }
    return i
  }

  /// Where ⌥← goes: back over any spaces, then to the start of the word or punctuation run.
  static func wordStart(before offset: Int, in document: TextDocument, wordCharacters: Set<UInt16> = []) -> Int {
    var i = offset
    while i > 0 {
      let kind = self.characterClass(document.unit(at: i - 1), wordCharacters: wordCharacters)
      if kind == .word { break }
      if kind == .punctuation {
        while i > 0 && self.characterClass(document.unit(at: i - 1), wordCharacters: wordCharacters) == .punctuation { i -= 1 }
        return i
      }
      i -= 1
    }
    while i > 0 && self.characterClass(document.unit(at: i - 1), wordCharacters: wordCharacters) == .word { i -= 1 }
    return i
  }

  /// The word, space run or punctuation run under `offset`, for a double-click. At the end of a
  /// line, the run before it.
  static func word(at offset: Int, in document: TextDocument, wordCharacters: Set<UInt16> = []) -> Range<Int> {
    let length = document.length
    guard length > 0 else { return 0 ..< 0 }
    var at = min(offset, length - 1)
    if document.unit(at: at) == 0x0A && at > 0 && document.unit(at: at - 1) != 0x0A { at -= 1 }
    let kind = self.characterClass(document.unit(at: at), wordCharacters: wordCharacters)
    if kind == .newline { return at ..< at }
    var low = at
    var high = at + 1
    while low > 0 && self.characterClass(document.unit(at: low - 1), wordCharacters: wordCharacters) == kind { low -= 1 }
    while high < length && self.characterClass(document.unit(at: high), wordCharacters: wordCharacters) == kind { high += 1 }
    return self.snap(low, in: document) ..< self.next(after: max(low, self.snap(high - 1, in: document)), in: document)
  }

  /// Where a camelCase-aware move (⌃⌥→) stops: also at each lower-to-upper case change and `_`.
  static func subwordEnd(after offset: Int, in document: TextDocument) -> Int {
    let length = document.length
    var i = offset
    while i < length && self.characterClass(document.unit(at: i)) != .word { i += 1 }
    guard i < length else { return length }
    let start = i
    i += 1
    while i < length {
      let unit = document.unit(at: i)
      if self.characterClass(unit) != .word || unit == 0x5F { break }
      let previous = document.unit(at: i - 1)
      if Self.isUpper(unit) && !Self.isUpper(previous) && i > start { break }
      i += 1
    }
    return i
  }

  static func subwordStart(before offset: Int, in document: TextDocument) -> Int {
    var i = offset
    while i > 0 && self.characterClass(document.unit(at: i - 1)) != .word { i -= 1 }
    guard i > 0 else { return 0 }
    i -= 1
    while i > 0 {
      let unit = document.unit(at: i)
      let previous = document.unit(at: i - 1)
      if Self.isUpper(unit) && !Self.isUpper(previous) { break }
      if self.characterClass(previous) != .word || previous == 0x5F { break }
      i -= 1
    }
    return i
  }

  private static func isUpper(_ unit: UInt16) -> Bool {
    unit >= 0x41 && unit <= 0x5A
  }

  // MARK: - Lines and paragraphs

  /// The start of `offset`'s line.
  static func lineStart(_ offset: Int, in document: TextDocument) -> Int {
    document.lineStart(document.line(containing: offset))
  }

  /// The end of `offset`'s line, before its newline.
  static func lineEnd(_ offset: Int, in document: TextDocument) -> Int {
    document.lineRange(document.line(containing: offset)).upperBound
  }

  /// The first non-space unit on `offset`'s line, or the line's end.
  static func firstNonSpace(onLineOf offset: Int, in document: TextDocument) -> Int {
    let range = document.lineRange(document.line(containing: offset))
    var i = range.lowerBound
    while i < range.upperBound, self.characterClass(document.unit(at: i)) == .space { i += 1 }
    return i
  }

  /// ⌥↑ and ⌥↓: the start of this paragraph (line), or of the one before when already there;
  /// the end of this one, or of the next.
  static func paragraphBoundary(from offset: Int, forward: Bool, in document: TextDocument) -> Int {
    let line = document.line(containing: offset)
    let range = document.lineRange(line)
    if forward {
      if offset < range.upperBound { return range.upperBound }
      return line + 1 < document.lineCount ? document.lineRange(line + 1).upperBound : range.upperBound
    } else {
      if offset > range.lowerBound { return range.lowerBound }
      return line > 0 ? document.lineStart(line - 1) : 0
    }
  }
}
