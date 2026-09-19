import Combine

public class HList<T: Identifiable> : SingleChildElement {
  private var hStack: HStack
  private var items: ObservableCollection<T>
  private var onCreate: (T) -> UIElement
  
  private var appendCancelable: AnyCancellable?
  private var insertCancelable: AnyCancellable?
  private var removeCancelable: AnyCancellable?
  
  public init(alignment: VerticalAlignment = .center, spacing: Float = 0, items: ObservableCollection<T>, onCreate: @escaping (T) -> UIElement) {
    self.hStack = HStack(alignment: alignment, spacing: spacing)
    self.items = items
    self.onCreate = onCreate
  }
  
  public override func mount(_ context: UIContext) {
    self.hStack.setChildren(self.items.collection.map { self.onCreate($0) }, context)
    
    self.appendCancelable = self.items.onAppend { self.hStack.appendChild(self.onCreate($0), context) }
    self.insertCancelable = self.items.onInsert { self.hStack.insertChild(self.onCreate($0), at: $1, context) }
    self.removeCancelable = self.items.onRemove { self.hStack.remove(at: $1, context) }
    
    self.setChild(self.hStack, context)
  }
  
  public override func unmount(_ context: UIContext) {
    self.appendCancelable?.cancel()
    self.insertCancelable?.cancel()
    self.removeCancelable?.cancel()
    
    self.hStack.removeAll(context)
    self.removeChild(context)
  }
}
