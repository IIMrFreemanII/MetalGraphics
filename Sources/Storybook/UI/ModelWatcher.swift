import MetalGraphicsLib

/// A hand-built element that watches some of `StorybookModel.shared`'s properties while mounted,
/// and redoes its content when one changes: what the canvas and the addon panels are, since what
/// they show is made from a story, which a body cannot hold.
///
/// Subclasses name the properties in `watched`, build their first content at the end of their
/// init (`child = …`), and replace or update it in `update(_:_:)`. Writes reach them once per
/// burst (`ModelObservers`), never per frame.
class ModelWatcher : SingleChildElement {
  let model = StorybookModel.shared
  private(set) weak var context: UIContext?

  /// The model's properties, by name; the token `update` is given is the index here.
  var watched: [String] { [] }

  override init() {
    super.init()
    self.child = EmptyElement()
  }

  override func mount(_ context: UIContext) {
    self.context = context
    for (token, name) in self.watched.enumerated() {
      self.model.__observers(named: name).add(self, token: token)
    }
  }

  override func unmount(_ context: UIContext) {
    for name in self.watched {
      self.model.__observers(named: name).remove(self)
    }
    self.context = nil
  }

  override func __modelDidChange(_ token: Int, _ animated: Bool) {
    guard let context = self.context else { return }
    self.update(token, context)
  }

  /// Updates the content: `token` is the watched property that changed.
  func update(_ token: Int, _ context: UIContext) {}

  /// Shows `element`.
  func show(_ element: UIElement, _ context: UIContext) {
    self.setChild(element, context)
  }
}
