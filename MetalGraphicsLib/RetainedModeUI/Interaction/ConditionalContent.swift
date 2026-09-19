import Combine

public class ConditionalContent : SingleChildElement {
  public var subject: any Subject<Bool, Never>
  public var content: UIElement
  public var cancellable: AnyCancellable?
  
  public init(_ subject: any Subject<Bool, Never>, @UIElementBuilder content: () -> UIElement) {
    self.subject = subject
    self.content = content()
  }
  
  public override func mount(_ context: UIContext) {
    self.cancellable = subject.sink { isEnabled in
      if isEnabled {
        self.setChild(self.content, context)
      } else {
        self.removeChild(context)
      }
    }
  }
  
  public override func unmount(_ context: UIContext) {
    cancellable?.cancel()
    removeChild(context)
  }
}

public class ConditionalElseContent : SingleChildElement {
  public var subject: any Subject<Bool, Never>
  public var trueContent: UIElement
  public var falseContent: UIElement
  public var cancellable: AnyCancellable?
  
  public init(_ subject: any Subject<Bool, Never>, @UIElementBuilder _ trueContent: () -> UIElement, @UIElementBuilder _ falseContent: () -> UIElement) {
    self.subject = subject
    self.trueContent = trueContent()
    self.falseContent = falseContent()
  }
  
  public override func mount(_ context: UIContext) {
    self.cancellable = subject.sink { isEnabled in
      isEnabled ? self.setChild(self.trueContent, context) : self.setChild(self.falseContent, context)
    }
  }
  
  public override func unmount(_ context: UIContext) {
    cancellable?.cancel()
    removeChild(context)
  }
}
