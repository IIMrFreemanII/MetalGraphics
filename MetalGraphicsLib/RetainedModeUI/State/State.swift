import Combine

@MainActor
@propertyWrapper
public final class State<T> {
  private var handlers: [UUID : (T) -> Void] = [:]

  public var value: T {
    didSet {
      self.handlers.values.forEach { $0(self.value) }
    }
  }

  public var wrappedValue: T {
    get { self.value }
    set { self.value = newValue }
  }

  public var projectedValue: State<T> {
    self
  }

  public init(wrappedValue: T) {
    self.value = wrappedValue
  }

  public convenience init(_ value: T) {
    self.init(wrappedValue: value)
  }

  @discardableResult
  public func onChange(perform action: @escaping (T) -> Void) -> AnyCancellable {
    let id = UUID()
    self.handlers[id] = action
    return AnyCancellable { [weak self] in
      MainActor.assumeIsolated {
        _ = self?.handlers.removeValue(forKey: id)
      }
    }
  }
}
