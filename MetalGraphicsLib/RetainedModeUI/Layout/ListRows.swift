// Keeps a stack's children aligned with an array of items. Shared by `VList` and `HList`.
//
// This is a cache, not a reactivity mechanism. `elementsById` is what lets a row keep its own
// element — and with it its own `@State` — across a reorder. *Which* rows exist is decided by
// the component that owns the array; this type is only told, never asked.
//
// It is told in one of two ways. `setItems` is a full resync, correct from any starting state.
// `insertRow` / `removeRow` are the incremental forms, used when the caller already knows what
// changed and so no diff is needed. The generated mutation methods on a `@Component` pick the
// incremental form; a plain assignment to the state falls back to `setItems`.
@MainActor
final class ListRows<T : Identifiable> {
  private unowned let stack: MultiChildElement
  private let create: (T) -> UIElement

  // One element per item, so replacements and reorders reuse instances and keep their state.
  private var elementsById: [T.ID : UIElement] = [:]

  init(_ stack: MultiChildElement, create: @escaping (T) -> UIElement) {
    self.stack = stack
    self.create = create
  }

  /// The children a freshly built list starts with, before there is a `UIContext` to mount
  /// against. `handleMount` mounts whatever children it finds, exactly as for static content.
  func initialElements(_ items: [T]) -> [UIElement] {
    items.map { self.element(for: $0) }
  }

  /// Rebuilds every child from `items`. O(n), and the only path that can repair a list whose
  /// children have drifted out of step with the array.
  func setItems(_ items: [T], _ context: UIContext, animation: UIAnimation?) -> Void {
    let elements = items.map { self.element(for: $0) }

    let ids = Set(items.map { $0.id })
    self.elementsById = self.elementsById.filter { ids.contains($0.key) }

    self.stack.replaceChildren(elements, context, animation: animation)
  }

  func insertRow(_ item: T, at index: Int, _ context: UIContext, animation: UIAnimation?) -> Void {
    self.stack.insertChild(self.element(for: item), at: index, context, animation: animation)
  }

  /// `item` is the row that was just removed from the array — it is passed rather than looked
  /// up so dropping the cache entry stays O(1).
  ///
  /// `index` is logical: rows still playing a removal transition are not counted, so it stays
  /// aligned with the array while they animate out.
  func removeRow(_ item: T, at index: Int, _ context: UIContext, animation: UIAnimation?) -> Void {
    guard index >= 0, index < self.stack.liveChildrenCount else { return }

    self.elementsById.removeValue(forKey: item.id)
    self.stack.remove(at: index, context, animation: animation)
  }

  private func element(for item: T) -> UIElement {
    if let element = self.elementsById[item.id] {
      return element
    }

    let element = self.create(item)
    self.elementsById[item.id] = element

    return element
  }
}
