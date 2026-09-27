extension IMView {
  struct Alignment {
    let xOffset: Float
    let yOffset: Float
    
    var offset: float2 {
      float2(xOffset, yOffset)
    }
    
    init(_ xOffset: Float, _ yOffset: Float) {
      self.xOffset = xOffset
      self.yOffset = yOffset
    }
    
    static let topLeading: Self = .init(0.0, 0.0)
    static let top: Self = .init(0.5, 0.0)
    static let topTrailing: Self = .init(1.0, 0.0)
    static let leading: Self = .init(0.0, 0.5)
    static let center: Self = .init(0.5, 0.5)
    static let trailing: Self = .init(1.0, 0.5)
    static let bottomLeading: Self = .init(0.0, 1.0)
    static let bottom: Self = .init(0.5, 1.0)
    static let bottomTrailing: Self = .init(1.0, 1.0)
  }
  
  struct HorizontalAlignment {
    let offset: Float
    
    init(_ offset: Float) {
      self.offset = offset
    }
    
    static let leading: Self = .init(0.0)
    static let center: Self = .init(0.5)
    static let trailing: Self = .init(1.0)
  }
  
  struct VerticalAlignment {
    let offset: Float
    
    init(_ offset: Float) {
      self.offset = offset
    }
    
    static let top: Self = .init(0)
    static let center: Self = .init(0.5)
    static let bottom: Self = .init(1)
  }
}
