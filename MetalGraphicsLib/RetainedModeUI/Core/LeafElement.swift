public class LeafElement : UIElement {
  override func handleMount(_ context: UIContext) {
    if !self.mounted {
      self.mounted = true
      self.mount(context)
    }
  }
  
  override func handleUnmount(_ context: UIContext) {
    if self.mounted {
      self.mounted = false
      self.unmount(context)
    }
  }
}
