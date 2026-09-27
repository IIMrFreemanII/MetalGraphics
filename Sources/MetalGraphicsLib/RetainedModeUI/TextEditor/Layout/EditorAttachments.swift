import simd

/// Makes the elements an editor shows inside its text: inline ones where a U+FFFC with an
/// attachment mark sits (`TextEditor.insertAttachment`), and blocks below lines a styler puts
/// them under (a markdown image).
///
/// The space reserved for one is what `size` says, whatever its element measures: the text is
/// laid out once, not again when an element settles. `size` must not read the document.
public protocol TextAttachmentProvider: AnyObject {
  /// The element for `id`: made when it first comes into view, and kept while it is used.
  /// `source` is what a styler gave a block, such as an image's name; nil for an inline one.
  func makeElement(for id: TextAttachmentID, source: String?) -> UIElement
  /// Its size: an inline one sits on the baseline, a block spans at most `maxWidth`.
  func size(for id: TextAttachmentID, source: String?, maxWidth: Float) -> float2
}

/// The elements of the attachments in view, children of the editor's text. Mounted as their
/// lines scroll into view and unmounted as they leave, like a lazy stack's rows, and placed
/// where their lines put them.
final class EditorAttachmentLayer : MultiChildElement {
  private struct Key: Hashable {
    var id: TextAttachmentID
    /// Which of several showing the same id at once.
    var occurrence: Int
  }

  weak var context: UIContext?
  private var elements: [Key: UIElement] = [:]
  private var mountedKeys: [Key] = []
  private var nextKeys: [Key] = []
  private var nextChildren: [UIElement] = []
  private var occurrences: [TextAttachmentID: Int] = [:]
  /// Retired elements kept for when they scroll back, at most this many.
  static let retainedLimit = 64
  private var retired: [Key] = []

  override func mount(_ context: UIContext) {
    self.context = context
  }

  private(set) var position: float2 = .zero

  override func sizeThatFits(_ proposal: ProposedSize) -> float2 { .zero }

  override func calcSize(_ proposal: ProposedSize) -> float2 {
    // Its children are sized as they are placed, at what their lines reserved.
    .zero
  }

  override func calcPosition(_ position: float2) {
    self.position = position
  }

  /// Shows `wanted` — each an attachment, where it goes in the window and at what size — and
  /// nothing else, building, mounting and unmounting as needed. Returns whether anything moved
  /// or came and went, which the hit grid must see.
  @discardableResult
  func show(_ wanted: [(attachment: PlacedAttachment, origin: float2)], provider: (any TextAttachmentProvider)?,
            scope: TextEnvironment) -> Bool {
    guard let provider else {
      return self.clear()
    }
    self.nextKeys.removeAll(keepingCapacity: true)
    self.nextChildren.removeAll(keepingCapacity: true)
    self.occurrences.removeAll(keepingCapacity: true)
    for entry in wanted {
      let occurrence = self.occurrences[entry.attachment.id, default: 0]
      self.occurrences[entry.attachment.id] = occurrence + 1
      let key = Key(id: entry.attachment.id, occurrence: occurrence)
      let element: UIElement
      if let existing = self.elements[key] {
        element = existing
      } else {
        element = provider.makeElement(for: key.id, source: entry.attachment.source)
        self.elements[key] = element
      }
      self.nextKeys.append(key)
      self.nextChildren.append(element)
    }
    var changed = self.nextKeys != self.mountedKeys
    if changed, let context = self.mounted ? self.context : nil {
      let kept = Set(self.nextKeys)
      for (key, child) in zip(self.mountedKeys, self.children) where !kept.contains(key) {
        child.handleUnmount(context)
        self.retired.append(key)
      }
      let old = Set(self.mountedKeys)
      swap(&self.children, &self.nextChildren)
      swap(&self.mountedKeys, &self.nextKeys)
      for (key, child) in zip(self.mountedKeys, self.children) where !old.contains(key) {
        child.handleMount(context, in: self)
      }
      self.dropRetired()
      context.invalidate(.treeOrder)
    } else if changed {
      swap(&self.children, &self.nextChildren)
      swap(&self.mountedKeys, &self.nextKeys)
    }
    // Sized at what their lines reserved, under the text's style, and placed there.
    TextScope.with(scope) {
      for (entry, child) in zip(wanted, self.children) {
        let size = child.getSize()
        if size != entry.attachment.size {
          _ = child.calcSize(ProposedSize(entry.attachment.size))
        }
        child.calcPosition(entry.origin)
      }
    }
    // Moved under a still pointer: what is under it changed.
    if self.lastOrigins.count != wanted.count || zip(self.lastOrigins, wanted).contains(where: { $0 != $1.origin }) {
      changed = true
      self.lastOrigins = wanted.map(\.origin)
    }
    return changed
  }

  private var lastOrigins: [float2] = []

  private func clear() -> Bool {
    guard !self.children.isEmpty else { return false }
    if let context = self.mounted ? self.context : nil {
      for child in self.children { child.handleUnmount(context) }
      context.invalidate(.treeOrder)
    }
    self.children.removeAll()
    self.mountedKeys.removeAll()
    self.elements.removeAll()
    return true
  }

  /// Forgets elements unused for longest, past the limit.
  private func dropRetired() {
    let mounted = Set(self.mountedKeys)
    self.retired.removeAll { mounted.contains($0) }
    while self.retired.count > Self.retainedLimit {
      let key = self.retired.removeFirst()
      if !mounted.contains(key) { self.elements.removeValue(forKey: key) }
    }
  }

  /// Forgets every element: the provider changed.
  func reset() {
    _ = self.clear()
    self.retired.removeAll()
  }
}
