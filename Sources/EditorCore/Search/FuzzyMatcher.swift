/// Ranks paths against what is typed in a quick-open field: the query's characters in order,
/// anywhere, ignoring case; `edfp` finds `Sources/Editor/FileEditorPanel.swift`.
///
/// Matches score higher the more of them are:
/// - in the file's name rather than its folders;
/// - at the start of a word (after `/`, `.`, `_`, `-` or a space, or a capital after a
///   lowercase letter);
/// - right after the one before.
///
/// A shorter path wins a tie.
public enum FuzzyMatcher {
  /// How well `query` matches `path`, higher is better; nil when it does not. An empty query
  /// matches everything, equally.
  public static func score(_ query: String, _ path: String) -> Int? {
    let needle = Array(query.lowercased().unicodeScalars.filter { $0 != " " })
    guard !needle.isEmpty else { return 0 }
    let scalars = Array(path.unicodeScalars)
    let lower = Array(path.lowercased().unicodeScalars)
    // Lowercasing can change the count (rarely): then match without the word-start bonuses.
    let aligned = lower.count == scalars.count
    let nameStart = (scalars.lastIndex(of: "/").map { $0 + 1 }) ?? 0

    // In the name alone first: the best matches are there.
    if let inName = self.match(needle, lower, scalars, from: aligned ? nameStart : 0, aligned: aligned) {
      return inName + (aligned && nameStart > 0 ? 100 : 0) - path.count / 8
    }
    guard let anywhere = self.match(needle, lower, scalars, from: 0, aligned: aligned) else { return nil }
    return anywhere - path.count / 8
  }

  /// `paths` that match `query`, best first, at most `limit`.
  public static func rank(_ query: String, _ paths: [String], limit: Int = 50) -> [String] {
    var scored: [(path: String, score: Int)] = []
    scored.reserveCapacity(min(paths.count, 1024))
    for path in paths {
      if let score = self.score(query, path) { scored.append((path, score)) }
    }
    scored.sort { $0.score != $1.score ? $0.score > $1.score : $0.path.count < $1.path.count }
    return scored.prefix(limit).map(\.path)
  }

  /// Greedy, preferring word starts: each query character goes to the next word start that has
  /// it when one is ahead, else to its next occurrence.
  private static func match(
    _ needle: [Unicode.Scalar], _ lower: [Unicode.Scalar], _ original: [Unicode.Scalar], from start: Int, aligned: Bool
  ) -> Int? {
    var score = 0
    var position = start
    var previous = -2
    for character in needle {
      var found: Int? = nil
      var fallback: Int? = nil
      var i = position
      while i < lower.count {
        if lower[i] == character {
          if fallback == nil { fallback = i }
          // Right after the last match: take it, a run is best.
          if i == previous + 1 || (aligned && self.isWordStart(original, i)) {
            found = i
            break
          }
        }
        i += 1
      }
      guard let at = found ?? fallback else { return nil }
      score += 1
      if at == previous + 1 { score += 6 }
      if aligned && self.isWordStart(original, at) { score += 8 }
      previous = at
      position = at + 1
    }
    return score
  }

  private static func isWordStart(_ scalars: [Unicode.Scalar], _ i: Int) -> Bool {
    guard i > 0 else { return true }
    let before = scalars[i - 1]
    if "/._- ".unicodeScalars.contains(before) { return true }
    return scalars[i].properties.isUppercase && before.properties.isLowercase
  }
}
