public typealias uchar4 = SIMD4<UInt8>
public typealias Color = uchar4

public extension uchar4 {
  static let transparent = uchar4(0, 0, 0, 0)
  static let red = uchar4(255, 0, 0, 255)
  static let green = uchar4(0, 255, 0, 255)
  static let blue = uchar4(0, 0, 255, 255)
  static let black = uchar4(0, 0, 0, 255)
  static let gray = uchar4(127, 127, 127, 255)
  static let lightGray = uchar4(150, 150, 150, 255)
  static let white = uchar4(255, 255, 255, 255)
  
  var r: UInt8 {
    get { self.x }
    set { self.x = newValue }
  }
  
  var g: UInt8 {
    get { self.y }
    set { self.y = newValue }
  }
  
  var b: UInt8 {
    get { self.z }
    set { self.z = newValue }
  }
  
  var a: UInt8 {
    get { self.w }
    set { self.w = newValue }
  }
}
