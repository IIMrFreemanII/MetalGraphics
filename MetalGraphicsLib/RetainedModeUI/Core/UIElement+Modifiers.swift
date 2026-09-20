extension UIElement {
  public func padding(_ inset: @autoclosure @escaping () -> Inset) -> Padding {
    Padding(inset()) {
      self
    }
  }
  
  public func frame(width: @autoclosure @escaping () -> Float, height: @autoclosure @escaping () -> Float) -> Frame {
    Frame(.init(width(), height())) {
      self
    }
  }
  
  public func background(_ color: @autoclosure @escaping () -> float4) -> Background {
    Background(color()) {
      self
    }
  }
  
  public func onTap(_ callback: @escaping (Input) -> Void) -> HittableView {
    HittableView(onTap: callback) {
      self
    }
  }
  
  public func onHover(_ callback: @escaping (Bool, Input) -> Void) -> HittableView {
    HittableView(onHover: callback) {
      self
    }
  }
}
