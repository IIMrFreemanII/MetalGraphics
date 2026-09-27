/// What kind of edit a step is, for coalescing: a run of typing, or of deleting backwards, is one
/// step to undo.
public enum EditKind: Sendable {
  case typing
  case deleting
  case other
}

/// An editor's undo and redo stacks. A step holds the change sets it applied, those that undo
/// them, and the selection before and after.
///
/// Steps coalesce as in AppKit's text views: typing, or deleting backwards, continues the last
/// step when it is of the same kind, starts where the last one left the caret, and comes within
/// `coalescingInterval` of it.
final class UndoHistory {
  struct Step {
    var forward: [ChangeSet]
    var inverse: [ChangeSet]
    var selectionBefore: EditorSelection
    var selectionAfter: EditorSelection
    var kind: EditKind
    var time: Double
    var size: Int
  }

  private(set) var undoStack: [Step] = []
  private(set) var redoStack: [Step] = []
  /// Whether the next edit may join the last step. Cleared by anything that is not an edit of
  /// the same run: a move of the caret, an undo.
  private var open = false
  private var group: Step? = nil
  private var groupDepth = 0
  private var totalSize = 0

  static let stepLimit = 1000
  static let sizeLimit = 16 << 20
  static let coalescingInterval: Double = 2

  var canUndo: Bool { !self.undoStack.isEmpty }
  var canRedo: Bool { !self.redoStack.isEmpty }

  /// Ends the current run: the next edit starts a step of its own.
  func breakCoalescing() {
    self.open = false
  }

  func record(_ forward: ChangeSet, inverse: ChangeSet, before: EditorSelection, after: EditorSelection,
              kind: EditKind, time: Double) {
    let size = forward.changes.reduce(0) { $0 + $1.text.count } + inverse.changes.reduce(0) { $0 + $1.text.count }
    self.redoStack.removeAll()
    if self.groupDepth > 0 {
      if self.group == nil {
        self.group = Step(forward: [], inverse: [], selectionBefore: before, selectionAfter: after, kind: .other, time: time, size: 0)
      }
      self.group!.forward.append(forward)
      self.group!.inverse.append(inverse)
      self.group!.selectionAfter = after
      self.group!.size += size
      return
    }
    if self.open, kind != .other, var last = self.undoStack.last, last.kind == kind,
       time - last.time < Self.coalescingInterval, last.selectionAfter == before {
      last.forward.append(forward)
      last.inverse.append(inverse)
      last.selectionAfter = after
      last.time = time
      last.size += size
      self.undoStack[self.undoStack.count - 1] = last
      self.totalSize += size
    } else {
      self.push(Step(forward: [forward], inverse: [inverse], selectionBefore: before, selectionAfter: after,
                     kind: kind, time: time, size: size))
    }
    self.open = kind != .other
  }

  private func push(_ step: Step) {
    self.undoStack.append(step)
    self.totalSize += step.size
    while self.undoStack.count > Self.stepLimit || (self.totalSize > Self.sizeLimit && self.undoStack.count > 1) {
      self.totalSize -= self.undoStack.removeFirst().size
    }
  }

  /// Edits between `beginGroup` and the matching `endGroup` undo as one step.
  func beginGroup() {
    self.groupDepth += 1
  }

  func endGroup() {
    self.groupDepth -= 1
    guard self.groupDepth == 0, let group = self.group else { return }
    self.group = nil
    self.push(group)
    self.open = false
  }

  func popUndo() -> Step? {
    self.open = false
    guard let step = self.undoStack.popLast() else { return nil }
    self.totalSize -= step.size
    self.redoStack.append(step)
    return step
  }

  func popRedo() -> Step? {
    self.open = false
    guard let step = self.redoStack.popLast() else { return nil }
    self.undoStack.append(step)
    self.totalSize += step.size
    return step
  }

  func removeAll() {
    self.undoStack.removeAll()
    self.redoStack.removeAll()
    self.totalSize = 0
    self.open = false
  }

  /// Keeps the steps valid across an edit that is not recorded, an app's: one entirely after
  /// everything they touch leaves them as they are, one entirely before shifts them, and one
  /// among them drops the history, which no longer leads to this text.
  func rebase(through changes: ChangeSet) {
    guard !self.undoStack.isEmpty || !self.redoStack.isEmpty else { return }
    var low = Int.max
    var high = Int.min
    for step in self.undoStack + self.redoStack {
      for set in step.forward + step.inverse {
        let bounds = set.touchedBounds
        low = min(low, bounds.low)
        high = max(high, bounds.high)
      }
      for range in step.selectionBefore.ranges + step.selectionAfter.ranges {
        low = min(low, range.lowerBound)
        high = max(high, range.upperBound)
      }
    }
    let first = changes.changes.first!.range.lowerBound
    let last = changes.changes.last!.range.upperBound
    if first >= high { return }
    if last <= low && first < low {
      let delta = changes.changes.reduce(0) { $0 + $1.delta }
      func shift(_ step: Step) -> Step {
        var step = step
        step.forward = step.forward.map { $0.shifted(by: delta) }
        step.inverse = step.inverse.map { $0.shifted(by: delta) }
        step.selectionBefore = step.selectionBefore.map { Self.shift($0, delta) }
        step.selectionAfter = step.selectionAfter.map { Self.shift($0, delta) }
        return step
      }
      self.undoStack = self.undoStack.map(shift)
      self.redoStack = self.redoStack.map(shift)
      return
    }
    self.removeAll()
  }

  private static func shift(_ range: SelectionRange, _ delta: Int) -> SelectionRange {
    SelectionRange(anchor: range.anchor + delta, head: range.head + delta, affinity: range.affinity)
  }
}
