extension UIElement {
  public func padding(_ inset: Inset) -> Padding {
    Padding(inset) {
      self
    }
  }
  
  public func frame(width: Float, height: Float) -> Frame {
    Frame(.init(width, height)) {
      self
    }
  }
  
  public func background(_ color: float4) -> Background {
    Background(color) {
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
