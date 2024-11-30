import Combine

public class VList<T> : SingleChildElement {
  private var vStack: VStack
  private var items: ObservableCollection<T>
  private var onCreate: (T, Int) -> UIElement
  
  private var appendCancelable: AnyCancellable?
  private var insertCancelable: AnyCancellable?
  private var removeCancelable: AnyCancellable?
  
  public init(alignment: HorizontalAlignment = .center, spacing: Float = 0, items: ObservableCollection<T>, onCreate: @escaping (T, Int) -> UIElement) {
    self.vStack = VStack(alignment: alignment, spacing: spacing)
    self.items = items
    self.onCreate = onCreate
  }
  
  public override func mount() {
    self.vStack.setChildren(self.items.collection.enumerated().map { self.onCreate($0.element, $0.offset) })
    
    self.appendCancelable = self.items.onAppend { self.vStack.appendChild(self.onCreate($0, $1)) }
    self.insertCancelable = self.items.onInsert { self.vStack.insertChild(self.onCreate($0, $1), at: $1) }
    self.removeCancelable = self.items.onRemove { self.vStack.remove(at: $1) }
    
    self.setChild(self.vStack)
  }
  
  public override func unmount() {
    self.appendCancelable?.cancel()
    self.insertCancelable?.cancel()
    self.removeCancelable?.cancel()
    
    self.vStack.removeAll()
    self.removeChild()
  }
}
