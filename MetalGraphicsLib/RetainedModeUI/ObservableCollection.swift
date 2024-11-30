import Combine
public class ObservableCollection<T> {
  public var collection: [T] = []
  
  private var appendHandlers: [UUID : (T, Int) -> Void] = [:]
  private var removeHandlers: [UUID : (T, Int) -> Void] = [:]
  private var insertHandlers: [UUID : (T, Int) -> Void] = [:]
  
  public init(_ collection: [T]) {
    self.collection = collection
  }
  
  @discardableResult
  public func onAppend(perform action: @escaping (T, Int) -> Void) -> AnyCancellable {
    let id = UUID()
    self.appendHandlers[id] = action
    return AnyCancellable {
      self.appendHandlers.removeValue(forKey: id)
    }
  }
  
  @discardableResult
  public func onRemove(perform action: @escaping (T, Int) -> Void) -> AnyCancellable {
    let id = UUID()
    self.removeHandlers[id] = action
    return AnyCancellable {
      self.removeHandlers.removeValue(forKey: id)
    }
  }
  
  @discardableResult
  public func onInsert(perform action: @escaping (T, Int) -> Void) -> AnyCancellable {
    let id = UUID()
    self.insertHandlers[id] = action
    return AnyCancellable {
      self.insertHandlers.removeValue(forKey: id)
    }
  }
  
  public func insert(_ element: T, at index: Int) {
    self.collection.insert(element, at: index)
    self.insertHandlers.values.forEach { $0(element, index) }
  }
  
  public func append(_ element: T) {
    let index = self.collection.count
    self.collection.append(element)
    self.appendHandlers.values.forEach { $0(element, index) }
  }
  
  public func remove(at index: Int) {
    let removedElement = self.collection.remove(at: index)
    self.removeHandlers.values.forEach { $0(removedElement, index) }
  }
}
