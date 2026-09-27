import simd

// Folding: a range's lines after its first are hidden — height 0 in the line tree, so y and line
// lookups, scrolling and the content's size need nothing more — and skipped where lines are drawn
// and the caret moves up and down. The first line ends in a "⋯" marker; a click on it, or on the
// chevron in the gutter, unfolds. Folds are marks that move with edits: an edit inside one, or a
// caret landing in one, unfolds it.
//
// Costs: folding and unfolding are O(lines in the fold); an edit is O(folds) to see whether it
// touched one, and nothing more otherwise. With nothing folded, nothing runs.
extension TextEditor {
  /// Folds `range`: hides its lines after the first. Returns whether it did (it spans lines and
  /// is not folded already). A caret inside moves to the end of the first line.
  @discardableResult
  public func fold(_ range: Range<Int>) -> Bool {
    let document = self.document
    let range = range.clamped(to: 0 ..< document.length)
    let first = document.line(containing: range.lowerBound)
    let last = document.line(containing: max(range.lowerBound, range.upperBound - 1))
    guard last > first, !self.folds.marks.contains(where: { $0.range == range }) else { return false }
    self.folds.add(range, ())
    self.setHidden(true, lines: first + 1 ..< last + 1)
    // Carets and selection ends in what is now hidden go to the end of the first line.
    let hidden = document.lineRange(first).upperBound + 1 ... document.lineRange(last, includingNewline: false).upperBound
    let end = document.lineRange(first).upperBound
    let selection = self.state.selection.map { range -> SelectionRange in
      let anchor = hidden.contains(range.anchor) ? end : range.anchor
      let head = hidden.contains(range.head) ? end : range.head
      return SelectionRange(anchor: anchor, head: head)
    }
    if selection != self.state.selection { self.state.setSelection(selection) }
    self.foldsChanged()
    return true
  }

  /// Unfolds every fold holding `offset`, or starting on its line. Returns whether any unfolded.
  @discardableResult
  public func unfold(at offset: Int) -> Bool {
    let line = self.document.line(containing: offset)
    let lineRange = self.document.lineRange(line, includingNewline: true)
    let touched = self.folds.marks.filter { $0.range.contains(offset) || lineRange.contains($0.range.lowerBound) }
    guard !touched.isEmpty else { return false }
    for mark in touched { self.removeFold(mark.id) }
    self.foldsChanged()
    return true
  }

  public func unfoldAll() {
    guard !self.folds.isEmpty else { return }
    for mark in self.folds.marks { self.removeFold(mark.id) }
    self.foldsChanged()
  }

  /// What is folded now.
  public var foldedRanges: [Range<Int>] { self.folds.marks.map(\.range) }

  /// A gutter click: unfolds what is folded on `line`, else folds the outermost range starting
  /// on it.
  func toggleFold(atLine line: Int) {
    let range = self.document.lineRange(line, includingNewline: false)
    if let folded = self.folds.marks.first(where: { range.contains($0.range.lowerBound) || $0.range.lowerBound == range.upperBound }) {
      self.removeFold(folded.id)
      self.foldsChanged()
    } else if let candidate = self.foldingRanges.first(where: { range.contains($0.lowerBound) }) {
      self.fold(candidate)
    }
  }

  /// Folds the innermost range around the caret not folded yet.
  @discardableResult
  func foldAtCaret() -> Bool {
    let head = self.state.selection.primary.head
    let folded = Set(self.folds.marks.map(\.range))
    let candidates = self.foldingRanges.filter { $0.lowerBound < head && head <= $0.upperBound && !folded.contains($0) }
    guard let innermost = candidates.min(by: { $0.count < $1.count }) else { return false }
    return self.fold(innermost)
  }

  @discardableResult
  func unfoldAtCaret() -> Bool {
    self.unfold(at: self.state.selection.primary.head)
  }

  /// Whether a fold chevron shows by `line`: nil for none, else whether what starts there is
  /// folded. O(log ranges): for the lines drawn.
  func foldState(ofLine line: Int) -> Bool? {
    let range = self.document.lineRange(line, includingNewline: false)
    if !self.folds.isEmpty, self.folds.marks.contains(where: { range.contains($0.range.lowerBound) }) { return true }
    // The first range starting at or after the line's start.
    var low = 0
    var high = self.foldingRanges.count
    while low < high {
      let mid = (low + high) / 2
      if self.foldingRanges[mid].lowerBound < range.lowerBound { low = mid + 1 } else { high = mid }
    }
    guard low < self.foldingRanges.count, self.foldingRanges[low].lowerBound <= range.upperBound else { return nil }
    return false
  }

  /// The "⋯" after the text of `line` when a fold starts on it, in the window's coordinates.
  func foldMarkerRect(forLine line: Int) -> ClipRect? {
    let range = self.document.lineRange(line, includingNewline: false)
    guard self.folds.marks.contains(where: { range.contains($0.range.lowerBound) || $0.range.lowerBound == range.upperBound }),
          let visible = self.content.visible.first(where: { $0.line == line })
    else { return nil }
    let origin = self.content.textOrigin
    let height = min(self.layout.rowHeight - 2, 14)
    let x = origin.x + visible.layout.width + 6
    let y = origin.y + Float(visible.top) + (visible.layout.rowTops[1] - height) * 0.5
    return ClipRect(position: float2(x, y), size: float2(22, height))
  }

  /// A click on a "⋯": unfolds that fold. Returns whether the click was on one.
  func pressedFoldMarker(at point: float2) -> Bool {
    let origin = self.content.textOrigin
    let line = self.layout.line(atY: Double(point.y - origin.y))
    guard let rect = self.foldMarkerRect(forLine: line), rect.contains(point) else { return false }
    let range = self.document.lineRange(line, includingNewline: false)
    for mark in self.folds.marks where range.contains(mark.range.lowerBound) || mark.range.lowerBound == range.upperBound {
      self.removeFold(mark.id)
    }
    self.foldsChanged()
    return true
  }

  // MARK: - Keeping folds with the text

  /// After an edit: the offered ranges move with it, and folds it touched unfold.
  func foldsDidApply(_ changes: ChangeSet) {
    if !self.foldingRanges.isEmpty {
      self.foldingRanges = self.foldingRanges.compactMap { range in
        let low = changes.map(range.lowerBound, .after)
        let high = changes.map(range.upperBound, .before)
        return low < high ? low ..< high : nil
      }
    }
    guard !self.folds.isEmpty else { return }
    // Marks and changes are both in the text as it was: which folds did the edit reach into?
    let touched = self.folds.marks.filter { mark in
      changes.changes.contains { change in
        change.range.isEmpty ? mark.range.lowerBound < change.range.lowerBound && change.range.lowerBound < mark.range.upperBound
                             : change.range.overlaps(mark.range)
      }
    }.map(\.id)
    self.folds.map(through: changes)
    guard !touched.isEmpty else { return }
    for id in touched { self.removeFold(id) }
    self.foldsChanged()
  }

  /// Unfolds folds that the selection reached into: a find, a jump, a move past the first line's
  /// end.
  func unfoldAroundSelection() {
    let document = self.document
    var reached: [Int] = []
    for mark in self.folds.marks {
      let first = document.line(containing: mark.range.lowerBound)
      let hidden = document.lineRange(first).upperBound + 1 ... mark.range.upperBound
      if self.state.selection.ranges.contains(where: { hidden.contains($0.head) || hidden.contains($0.anchor) }) {
        reached.append(mark.id)
      }
    }
    guard !reached.isEmpty else { return }
    for id in reached { self.removeFold(id) }
    self.foldsChanged()
  }

  /// Takes a fold away and shows its lines, but for those another fold still hides.
  private func removeFold(_ id: Int) {
    guard let mark = self.folds.mark(id) else { return }
    self.folds.remove(id)
    let document = self.document
    let first = document.line(containing: mark.range.lowerBound)
    let last = document.line(containing: max(mark.range.lowerBound, mark.range.upperBound - 1))
    guard last > first else { return }
    self.setHidden(false, lines: first + 1 ..< last + 1)
    for other in self.folds.marks where other.range.overlaps(mark.range) {
      let otherFirst = document.line(containing: other.range.lowerBound)
      let otherLast = document.line(containing: max(other.range.lowerBound, other.range.upperBound - 1))
      if otherLast > otherFirst { self.setHidden(true, lines: otherFirst + 1 ..< otherLast + 1) }
    }
  }

  /// Hides lines, or shows them again at their estimated heights until they are shaped.
  private func setHidden(_ hidden: Bool, lines: Range<Int>) {
    let layout = self.layout
    var shown: [UInt32] = []
    self.document.lines.forEach(in: lines) { _, record, height, length in
      if hidden {
        record.flags.insert(.hidden)
        height = 0
      } else if record.flags.contains(.hidden) {
        record.flags.remove(.hidden)
        record.flags.remove(.measured)
        height = layout.estimatedHeight(length: Int(length))
        shown.append(record.id)
      }
    }
    // Shaped again when shown, which measures them.
    for id in shown { layout.invalidate(lineID: id) }
  }

  /// Brings the view up to date with a fold or unfold: content height, gutter, drawing.
  private func foldsChanged() {
    self.refresh(revealCaret: false)
    self.context?.invalidate(.layout)
  }
}
