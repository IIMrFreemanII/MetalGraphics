import Combine

// Keeps a stack's children in sync with an `ObservableCollection`. Shared by `VList` and `HList`.
// It is an `AnyReaction`, so the element lifecycle subscribes it on mount and cancels on unmount.
@MainActor
final class ListContent<T : Identifiable> : AnyReaction {
  private unowned let stack: MultiChildElement
  private let items: ObservableCollection<T>
  private let create: (T) -> UIElement

  // One element per item, so remounts and replacements reuse instances and keep their state.
  private var elementsById: [T.ID : UIElement] = [:]
  private var subscription: AnyCancellable?

  init(_ stack: MultiChildElement, items: ObservableCollection<T>, create: @escaping (T) -> UIElement) {
    self.stack = stack
    self.items = items
    self.create = create
  }

  func activate(_ context: UIContext) -> Void {
    self.subscription = self.items.observeChanges { [weak self] change in
      self?.apply(change, context)
    }

    // Also repairs anything missed while unmounted, when no subscription was active.
    self.sync(context)
  }

  func deactivate() -> Void {
    self.subscription?.cancel()
    self.subscription = nil
  }

  private func apply(_ change: ObservableCollection<T>.Change, _ context: UIContext) -> Void {
    switch change {
    case .insert(let item, let index):
      self.stack.insertChild(self.element(for: item), at: index, context)

    case .remove(let item, _):
      // Located by identity rather than by the collection's index, which can't desync.
      guard let element = self.elementsById.removeValue(forKey: item.id),
            let index = self.stack.children.firstIndex(where: { $0 === element }) else { return }
      self.stack.remove(at: index, context)

    case .replaceAll:
      self.sync(context)
    }
  }

  private func sync(_ context: UIContext) -> Void {
    let items = self.items.items
    let elements = items.map { self.element(for: $0) }

    let ids = Set(items.map { $0.id })
    self.elementsById = self.elementsById.filter { ids.contains($0.key) }

    self.stack.setChildren(elements, context)
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

public final class VList<T : Identifiable> : VStack {
  public init(alignment: @autoclosure @escaping () -> HorizontalAlignment = .center,
              spacing: @autoclosure @escaping () -> Float = 0,
              items: ObservableCollection<T>,
              onCreate: @escaping (T) -> UIElement) {
    super.init(alignment: alignment(), spacing: spacing())

    self.reactions.append(ListContent(self, items: items, create: onCreate))
  }
}
