// Marker protocol so `bind(_:to:)` can use `Self` in its key path type.
public protocol StateBindable : SingleChildElement {}
extension SingleChildElement : StateBindable {}

@MainActor
extension StateBindable {
  
  // Subscribes to state changes; call from `mount`. Bindings are cancelled automatically on unmount.
  public func bind<T>(_ state: State<T>, _ context: UIContext, layout: Bool = false, apply: @escaping (T) -> Void) -> Void {
    apply(state.value)
    self.bindings.append(state.onChange { value in
      apply(value)
      context.invalidate(layout: layout)
    })
  }
  
  // Binds `state` to a property of self; no-op when `state` is nil.
  public func bind<T>(_ state: State<T>?, to keyPath: ReferenceWritableKeyPath<Self, T>, _ context: UIContext, layout: Bool = false) -> Void {
    guard let state else { return }
    self.bind(state, context, layout: layout) { [weak self] in self?[keyPath: keyPath] = $0 }
  }
}
