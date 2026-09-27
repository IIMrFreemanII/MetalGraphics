import Foundation

/// A document's text as UTF-16 code units, with a gap at the last edit: typing at one place is
/// O(1), and an edit elsewhere first moves the gap there, one `memmove` of the distance.
final class GapBuffer {
  private var storage: UnsafeMutablePointer<UInt16>
  private var capacity: Int
  private var gapStart: Int
  private var gapEnd: Int
  /// Where a range across the gap is copied to be read in one piece; kept, so a read allocates
  /// nothing once it has grown.
  private var scratch: [UInt16] = []

  init(_ units: some Collection<UInt16> = []) {
    self.capacity = max(64, units.count + units.count / 2)
    self.storage = .allocate(capacity: self.capacity)
    var i = 0
    for unit in units {
      self.storage[i] = unit
      i += 1
    }
    self.gapStart = i
    self.gapEnd = self.capacity
  }

  deinit {
    self.storage.deallocate()
  }

  var count: Int { self.capacity - (self.gapEnd - self.gapStart) }

  subscript(_ index: Int) -> UInt16 {
    index < self.gapStart ? self.storage[index] : self.storage[index + self.gapEnd - self.gapStart]
  }

  /// Replaces `range` with `units`.
  func replace(_ range: Range<Int>, with units: UnsafeBufferPointer<UInt16>) {
    precondition(range.lowerBound >= 0 && range.upperBound <= self.count, "range out of bounds")
    self.moveGap(to: range.upperBound)
    // The removed units join the gap.
    self.gapStart = range.lowerBound
    if units.count > self.gapEnd - self.gapStart {
      self.grow(toFit: units.count)
    }
    if let base = units.baseAddress, units.count > 0 {
      (self.storage + self.gapStart).update(from: base, count: units.count)
    }
    self.gapStart += units.count
  }

  func replace(_ range: Range<Int>, with units: [UInt16]) {
    units.withUnsafeBufferPointer { self.replace(range, with: $0) }
  }

  /// Runs `body` over the units in `range`, in one piece: in place when the range does not
  /// straddle the gap, else copied into a reused buffer.
  func withUnits<R>(in range: Range<Int>, _ body: (UnsafeBufferPointer<UInt16>) throws -> R) rethrows -> R {
    precondition(range.lowerBound >= 0 && range.upperBound <= self.count, "range out of bounds")
    if range.upperBound <= self.gapStart {
      return try body(UnsafeBufferPointer(start: self.storage + range.lowerBound, count: range.count))
    }
    let gap = self.gapEnd - self.gapStart
    if range.lowerBound >= self.gapStart {
      return try body(UnsafeBufferPointer(start: self.storage + range.lowerBound + gap, count: range.count))
    }
    self.scratch.removeAll(keepingCapacity: true)
    self.scratch.append(contentsOf: UnsafeBufferPointer(start: self.storage + range.lowerBound, count: self.gapStart - range.lowerBound))
    self.scratch.append(contentsOf: UnsafeBufferPointer(start: self.storage + self.gapEnd, count: range.upperBound - self.gapStart))
    return try self.scratch.withUnsafeBufferPointer { try body($0) }
  }

  /// A copy of the units in `range`.
  func units(in range: Range<Int>) -> [UInt16] {
    self.withUnits(in: range) { Array($0) }
  }

  private func moveGap(to position: Int) {
    if position < self.gapStart {
      let moved = self.gapStart - position
      (self.storage + self.gapEnd - moved).update(from: self.storage + position, count: moved)
      self.gapStart -= moved
      self.gapEnd -= moved
    } else if position > self.gapStart {
      let moved = position - self.gapStart
      (self.storage + self.gapStart).update(from: self.storage + self.gapEnd, count: moved)
      self.gapStart += moved
      self.gapEnd += moved
    }
  }

  /// Makes the gap at least `needed` long, with slack so a run of inserts rarely grows again.
  private func grow(toFit needed: Int) {
    let count = self.count
    let newCapacity = max(self.capacity * 2, count + needed + max(64, count / 2))
    let newStorage = UnsafeMutablePointer<UInt16>.allocate(capacity: newCapacity)
    newStorage.update(from: self.storage, count: self.gapStart)
    let tail = self.capacity - self.gapEnd
    (newStorage + newCapacity - tail).update(from: self.storage + self.gapEnd, count: tail)
    self.storage.deallocate()
    self.storage = newStorage
    self.gapEnd = newCapacity - tail
    self.capacity = newCapacity
  }
}
