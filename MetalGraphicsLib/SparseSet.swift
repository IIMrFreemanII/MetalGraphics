///
/// A sparse set maps non-negative integer keys to values with O(1) insert,
/// remove, and lookup, while keeping the stored values densely packed so they
/// can be iterated contiguously (cache friendly, no holes).
///
/// It trades memory for speed: a `sparse` array indexed by key points into a
/// `dense` array that holds the packed (key, value) pairs. Removal is done by
/// swapping the removed slot with the last dense element, so it never shifts
/// the whole array.
///
public struct SparseSet<Element> {
  /// For each key, the index into `dense`/`keys` where its entry lives.
  /// Entries are only valid when the key currently belongs to the set.
  private var sparse: [Int]
  /// Densely packed values, no gaps.
  private var dense: [Element]
  /// The key stored at each dense index (parallel to `dense`).
  private var keys: [Int]

  public init() {
    self.sparse = []
    self.dense = []
    self.keys = []
  }

  /// Reserves capacity for keys in `0..<capacity` so inserts up to that key
  /// avoid reallocating the sparse array.
  public init(capacity: Int) {
    let reserved = Swift.max(0, capacity)
    self.sparse = Array(repeating: 0, count: reserved)
    self.dense = []
    self.keys = []
    self.dense.reserveCapacity(reserved)
    self.keys.reserveCapacity(reserved)
  }

  /// Number of elements currently stored.
  public var count: Int { self.dense.count }

  public var isEmpty: Bool { self.dense.isEmpty }

  /// The keys currently in the set, in dense (insertion-influenced) order.
  public var storedKeys: [Int] { self.keys }

  /// Returns true if `key` is currently in the set.
  public func contains(_ key: Int) -> Bool {
    guard key >= 0, key < self.sparse.count else { return false }
    let index = self.sparse[key]
    return index < self.dense.count && self.keys[index] == key
  }

  /// Read/write the value for `key`. Reading a missing key returns nil.
  /// Setting a value inserts or overwrites; setting nil removes the key.
  public subscript(key: Int) -> Element? {
    get {
      guard self.contains(key) else { return nil }
      return self.dense[self.sparse[key]]
    }
    set {
      if let newValue {
        self.insert(newValue, forKey: key)
      } else {
        self.remove(key)
      }
    }
  }

  /// Inserts `value` for `key`, overwriting any existing value.
  /// Returns the previous value if the key was already present.
  @discardableResult
  public mutating func insert(_ value: Element, forKey key: Int) -> Element? {
    precondition(key >= 0, "SparseSet keys must be non-negative")

    if self.contains(key) {
      let index = self.sparse[key]
      let old = self.dense[index]
      self.dense[index] = value
      return old
    }

    if key >= self.sparse.count {
      self.sparse.append(contentsOf: repeatElement(0, count: key - self.sparse.count + 1))
    }

    self.sparse[key] = self.dense.count
    self.dense.append(value)
    self.keys.append(key)
    return nil
  }

  /// Removes `key` if present and returns its value.
  @discardableResult
  public mutating func remove(_ key: Int) -> Element? {
    guard self.contains(key) else { return nil }

    let index = self.sparse[key]
    let removed = self.dense[index]
    let lastIndex = self.dense.count - 1

    // Swap the removed slot with the last dense element to keep `dense` packed.
    if index != lastIndex {
      let lastKey = self.keys[lastIndex]
      self.dense[index] = self.dense[lastIndex]
      self.keys[index] = lastKey
      self.sparse[lastKey] = index
    }

    self.dense.removeLast()
    self.keys.removeLast()
    return removed
  }

  /// Removes all elements. Keeps allocated capacity so it can be reused.
  public mutating func removeAll() {
    self.dense.removeAll(keepingCapacity: true)
    self.keys.removeAll(keepingCapacity: true)
  }
}

// MARK: - Sequence

extension SparseSet: Sequence {
  /// Iterates the stored (key, value) pairs in dense order.
  public func makeIterator() -> AnyIterator<(key: Int, value: Element)> {
    var index = 0
    return AnyIterator {
      guard index < self.dense.count else { return nil }
      defer { index += 1 }
      return (key: self.keys[index], value: self.dense[index])
    }
  }

  /// The stored values in dense order (fast, contiguous).
  public var values: [Element] { self.dense }
}
