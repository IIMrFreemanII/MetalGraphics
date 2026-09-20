public final class HList<T : Identifiable> : HStack {
  public init(alignment: @autoclosure @escaping () -> VerticalAlignment = .center,
              spacing: @autoclosure @escaping () -> Float = 0,
              items: ObservableCollection<T>,
              onCreate: @escaping (T) -> UIElement) {
    super.init(alignment: alignment(), spacing: spacing())

    self.reactions.append(ListContent(self, items: items, create: onCreate))
  }
}
