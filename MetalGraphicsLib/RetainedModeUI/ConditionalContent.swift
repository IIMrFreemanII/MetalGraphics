import Combine

public class ConditionalContent : SingleChildElement {
  public var subject: any Subject<Bool, Never>
  public var content: UIElement
  public var cancellable: AnyCancellable?
  
  public init(_ subject: any Subject<Bool, Never>, @UIElementBuilder content: () -> UIElement) {
    self.subject = subject
    self.content = content()
  }
  
  public override func mount() {
    self.cancellable = subject.sink { isEnabled in
      if isEnabled {
        self.setChild(self.content)
      } else {
        self.removeChild()
      }
    }
  }
  
  public override func unmount() {
    cancellable?.cancel()
    removeChild()
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
  
  public override func mount() {
    self.cancellable = subject.sink { isEnabled in
      isEnabled ? self.setChild(self.trueContent) : self.setChild(self.falseContent)
    }
  }
  
  public override func unmount() {
    cancellable?.cancel()
    removeChild()
  }
}
