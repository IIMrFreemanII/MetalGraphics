//
//  Float.swift
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 12.02.2023.
//

extension Float {
  public init(_ boolean: Bool) {
    self = boolean ? 1 : 0
  }
  
  public func isBetween(_ range: ClosedRange<Float>) -> Bool {
    range.contains(self)
  }
  
  /// Converts radians to degrees
  public var degrees: Float {
    (self / π) * 180
  }
  
  /// Converts degrees to radians
  public var radians: Float {
    (self / 180) * π
  }
  
  public var isNegative: Bool {
    sign == .minus
  }
}
