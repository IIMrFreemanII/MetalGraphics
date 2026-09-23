public final class VList<T : Identifiable> : VStack {
  // `ListRows` needs `self`, which is only available after `super.init`.
  private var rows: ListRows<T>!

  public init(alignment: HorizontalAlignment = .center,
              spacing: Float = 0,
              items: [T],
              onCreate: @escaping (T) -> UIElement) {
    super.init(alignment: alignment, spacing: spacing)

    self.rows = ListRows(self, create: onCreate)
    self.applyContent(self.rows.initialElements(items))
  }

  public func setItems(_ items: [T], _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.rows.setItems(items, context, animation: animation)
  }

  public func insertRow(_ item: T, at index: Int, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.rows.insertRow(item, at: index, context, animation: animation)
  }

  public func removeRow(_ item: T, at index: Int, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.rows.removeRow(item, at: index, context, animation: animation)
  }
}
