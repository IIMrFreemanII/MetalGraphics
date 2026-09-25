import simd

/// Rows of `items` in a line, built only while they are near what a scroll view shows. What
/// `LazyVStack` and `LazyHStack` share.
///
/// Each row is made by `onCreate` the first time it comes into view, mounted while it is within
/// the visible part of the enclosing scroll views plus some overscan, and unmounted, but kept
/// with its state, once it is well out of it. Rows never built take the average length of the
/// rows measured so far, so the stack's length is an estimate until every row has been seen;
/// when a newly built row turns out longer or shorter than that, layout runs again on the next
/// frame. Outside a scroll view every row is built.
///
/// Along its axis a lazy stack is as long as its rows and spacing; across it, it takes what it
/// is offered, or its widest row when asked for its ideal size. Rows are offered the stack's
/// breadth and their ideal length.
///
/// Rows are found by id: `ScrollViewProxy.scrollTo` reaches only rows that are built.
public class LazyStack<T: Identifiable> : MultiChildElement {
  /// 0 for a horizontal stack, 1 for a vertical one.
  let axis: Int
  public var spacing: Float
  public private(set) var items: [T]
  private let create: (T) -> UIElement

  /// Where rows narrower than the stack sit across it, from 0 (top or leading) to 1.
  var crossAlignment: Float { 0.5 }

  /// How many rows scrolled out of view are kept, unmounted, before the oldest are dropped.
  public var retainedRowLimit = 256

  // Rows built so far, which item each is, and the length each was last measured at.
  private var elements: [T.ID: UIElement] = [:]
  private var ids: [ObjectIdentifier: T.ID] = [:]
  private var lengths: [T.ID: Float] = [:]
  private var measuredTotal: Float = 0
  // Rows no longer shown, oldest first, from `retiredHead` on.
  private var retired: [T.ID] = []
  private var retiredHead = 0

  /// Where each row starts along the axis, then the end: `items.count + 1` entries.
  private var starts: [Float] = []
  /// The rows built and mounted: `children`, in item order.
  private var built: Range<Int> = 0..<0
  /// The part of the stack a scroll view last showed, along its axis, from its start.
  private var visible: ClosedRange<Float>? = nil
  private var crossProposal: Float? = nil
  private var crossLength: Float = 0
  private var mainLength: Float = 0
  private weak var context: UIContext? = nil
  // Scratch for `build`, reused so building allocates nothing once warmed up.
  private var nextChildren: [UIElement] = []
  private var kept: Set<ObjectIdentifier> = []

  /// How far before and after the visible part rows are built.
  private static var overscan: Float { 200 }
  /// How much is built before any scroll view has said what it shows.
  private static var initialExtent: Float { 1000 }
  private static var defaultLength: Float { 40 }

  init(axis: Int, spacing: Float, items: [T], onCreate: @escaping (T) -> UIElement) {
    self.axis = axis
    self.spacing = spacing
    self.items = items
    self.create = onCreate
    super.init()
  }

  public override func mount(_ context: UIContext) {
    self.context = context
  }

  public override func getSize() -> float2 {
    var size = float2()
    size[self.axis] = self.mainLength
    size[1 - self.axis] = self.crossLength
    return size
  }

  // MARK: - Items

  public func setItems(_ items: [T], _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.items = items
    let ids = Set(items.map(\.id))
    for id in self.elements.keys where !ids.contains(id) {
      self.forget(id)
    }
    context.invalidate([.layout, .treeOrder], animation: animation)
  }

  public func insertRow(_ item: T, at index: Int, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.items.insert(item, at: min(max(index, 0), self.items.count))
    context.invalidate([.layout, .treeOrder], animation: animation)
  }

  public func removeRow(_ item: T, at index: Int, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    guard self.items.indices.contains(index) else { return }
    self.items.remove(at: index)
    self.forget(item.id)
    context.invalidate([.layout, .treeOrder], animation: animation)
  }

  private func forget(_ id: T.ID) {
    if let element = self.elements.removeValue(forKey: id) {
      self.ids.removeValue(forKey: ObjectIdentifier(element))
      if element.mounted, let context = self.context {
        element.handleUnmount(context)
      }
    }
    if let length = self.lengths.removeValue(forKey: id) {
      self.measuredTotal -= length
    }
  }

  // MARK: - Lengths

  private var estimatedLength: Float {
    self.lengths.isEmpty ? Self.defaultLength : self.measuredTotal / Float(self.lengths.count)
  }

  private func record(_ id: T.ID, _ length: Float) {
    self.measuredTotal += length - (self.lengths[id] ?? 0)
    self.lengths[id] = length
  }

  /// Where each row starts, from what is measured and estimated now. O(rows), with no
  /// allocation once `starts` has grown.
  private func rebuildStarts() {
    let estimate = self.estimatedLength
    self.starts.removeAll(keepingCapacity: true)
    var offset: Float = 0
    for item in self.items {
      self.starts.append(offset)
      offset += (self.lengths[item.id] ?? estimate) + self.spacing
    }
    self.starts.append(self.items.isEmpty ? 0 : offset - self.spacing)
  }

  /// The first row that ends after `offset`.
  private func row(at offset: Float) -> Int {
    var low = 0
    var high = self.items.count
    while low < high {
      let middle = (low + high) / 2
      if self.starts[middle + 1] <= offset { low = middle + 1 } else { high = middle }
    }
    return low
  }

  /// The rows to build: those within the visible part plus overscan, all of them outside a
  /// scroll view, or the first ones before a scroll view has said anything.
  private func wantedRows() -> Range<Int> {
    let count = self.items.count
    guard count > 0 else { return 0..<0 }
    let range: ClosedRange<Float>
    if let visible = self.visible {
      range = (visible.lowerBound - Self.overscan)...(visible.upperBound + Self.overscan)
    } else if LazyStackViewport.inScrollView {
      range = 0...Self.initialExtent
    } else {
      return 0..<count
    }
    let first = self.row(at: max(range.lowerBound, 0))
    let last = self.row(at: range.upperBound)
    return first ..< min(max(last + 1, first + 1), count)
  }

  // MARK: - Building rows

  /// Builds and mounts the rows in `range`, and unmounts those outside it. Returns whether a
  /// row was added, which then needs sizing. O(rows built); allocates only for rows new to it.
  @discardableResult
  private func build(_ range: Range<Int>) -> Bool {
    self.nextChildren.removeAll(keepingCapacity: true)
    var same = self.children.count == range.count
    for index in range {
      let item = self.items[index]
      let element: UIElement
      if let existing = self.elements[item.id] {
        element = existing
      } else {
        element = self.create(item)
        self.elements[item.id] = element
        self.ids[ObjectIdentifier(element)] = item.id
      }
      same = same && self.children[self.nextChildren.count] === element
      self.nextChildren.append(element)
    }
    self.built = range
    guard !same else { return false }

    let context = self.mounted ? self.context : nil
    self.kept.removeAll(keepingCapacity: true)
    for element in self.nextChildren {
      self.kept.insert(ObjectIdentifier(element))
    }
    for child in self.children where !self.kept.contains(ObjectIdentifier(child)) {
      if let context { child.handleUnmount(context) }
      if let id = self.ids[ObjectIdentifier(child)] {
        self.retired.append(id)
      }
    }
    // What was shown, to tell which rows are new.
    self.kept.removeAll(keepingCapacity: true)
    for child in self.children {
      self.kept.insert(ObjectIdentifier(child))
    }
    swap(&self.children, &self.nextChildren)
    self.nextChildren.removeAll(keepingCapacity: true)

    var added = false
    for child in self.children where !self.kept.contains(ObjectIdentifier(child)) {
      added = true
      if let context { child.handleMount(context) }
    }
    self.dropRetired()
    context?.invalidate(.treeOrder)
    return added
  }

  /// Drops the oldest rows no longer shown, beyond `retainedRowLimit`.
  private func dropRetired() {
    while self.retired.count - self.retiredHead > self.retainedRowLimit {
      let id = self.retired[self.retiredHead]
      self.retiredHead += 1
      if let element = self.elements[id], !element.mounted {
        self.elements.removeValue(forKey: id)
        self.ids.removeValue(forKey: ObjectIdentifier(element))
      }
    }
    if self.retiredHead > 1024 {
      self.retired.removeFirst(self.retiredHead)
      self.retiredHead = 0
    }
  }

  /// Sizes the built rows for good and records their lengths. Returns whether any length changed.
  @discardableResult
  private func sizeBuiltRows() -> Bool {
    var changed = false
    var cross: Float = 0
    let proposal = ProposedSize.unspecified.with(1 - self.axis, self.crossProposal)
    // What a row not measured before was laid out at.
    let estimate = self.estimatedLength
    for (offset, child) in self.children.enumerated() {
      let size = child.calcSize(proposal)
      let id = self.items[self.built.lowerBound + offset].id
      let length = size[self.axis]
      if abs((self.lengths[id] ?? estimate) - length) > 0.01 {
        changed = true
      }
      if self.lengths[id] != length {
        self.record(id, length)
      }
      cross = max(cross, size[1 - self.axis])
    }
    self.crossLength = self.crossProposal ?? cross
    return changed
  }

  // MARK: - Layout

  public override func sizeThatFits(_ proposal: ProposedSize) -> float2 {
    self.rebuildStarts()
    var size = float2()
    size[self.axis] = self.starts.last ?? 0
    size[1 - self.axis] = proposal[1 - self.axis] ?? self.crossLength
    return size
  }

  public override func calcSize(_ proposal: ProposedSize) -> float2 {
    self.crossProposal = proposal[1 - self.axis]
    self.rebuildStarts()
    self.build(self.wantedRows())
    self.sizeBuiltRows()
    self.rebuildStarts()
    self.mainLength = self.starts.last ?? 0
    return self.getSize()
  }

  public override func calcPosition(_ position: float2) {
    let axis = self.axis
    if let viewport = LazyStackViewport.current {
      let from = viewport.min[axis] - position[axis]
      self.visible = from...max(from, viewport.max[axis] - position[axis])
    } else {
      self.visible = nil
    }

    // Scrolled to rows that are not built: build them now, so this frame shows them.
    let wanted = self.wantedRows()
    if !wanted.isEmpty && (wanted.lowerBound < self.built.lowerBound || wanted.upperBound > self.built.upperBound
        || self.built.count > wanted.count + 64) {
      let added = self.build(wanted)
      if added && self.sizeBuiltRows() {
        // Measured unlike their estimate: the stack's length is not what was laid out.
        self.rebuildStarts()
        self.context?.invalidate(.layout)
      }
    }

    for (offset, child) in self.children.enumerated() {
      let index = self.built.lowerBound + offset
      let childSize = child.getSize()
      var origin = float2()
      origin[axis] = position[axis] + (index < self.starts.count ? self.starts[index] : 0)
      origin[1 - axis] = position[1 - axis] + (self.crossLength - childSize[1 - axis]) * self.crossAlignment
      self.place(child, at: origin, in: position)
    }
  }
}

/// Rows of `items`, top to bottom, built only near what the enclosing scroll view shows. See
/// `LazyStack`.
public final class LazyVStack<T: Identifiable> : LazyStack<T> {
  public var alignment: HorizontalAlignment

  override var crossAlignment: Float { self.alignment.offset }

  public init(alignment: HorizontalAlignment = .center, spacing: Float = 0, items: [T], onCreate: @escaping (T) -> UIElement) {
    self.alignment = alignment
    super.init(axis: 1, spacing: spacing, items: items, onCreate: onCreate)
  }

  public func setAlignment(_ value: HorizontalAlignment, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.alignment = value
    context.invalidate(.layout, animation: animation)
  }
}

/// Rows of `items`, left to right, built only near what the enclosing scroll view shows. See
/// `LazyStack`.
public final class LazyHStack<T: Identifiable> : LazyStack<T> {
  public var alignment: VerticalAlignment

  override var crossAlignment: Float { self.alignment.offset }

  public init(alignment: VerticalAlignment = .center, spacing: Float = 0, items: [T], onCreate: @escaping (T) -> UIElement) {
    self.alignment = alignment
    super.init(axis: 0, spacing: spacing, items: items, onCreate: onCreate)
  }

  public func setAlignment(_ value: VerticalAlignment, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.alignment = value
    context.invalidate(.layout, animation: animation)
  }
}

extension LazyStack {
  public func setSpacing(_ value: Float, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.spacing = value
    context.invalidate(.layout, animation: animation)
  }
}

/// What the scroll views around the content being positioned show, in window coordinates: set
/// by each `ScrollView` around positioning its content, and read by lazy stacks.
@MainActor
enum LazyStackViewport {
  static var current: ClipRect? = nil
  /// True while a scroll view's content is being sized, before it has a place.
  static var inScrollView = false
}
