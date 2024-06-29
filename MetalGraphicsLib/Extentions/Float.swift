//
//  Float.swift
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 12.02.2023.
//

public extension Float {
  init(_ boolean: Bool) {
    self = boolean ? 1 : 0
  }

  func isBetween(_ range: ClosedRange<Float>) -> Bool {
    range.contains(self)
  }

  /// Converts radians to degrees
  var degrees: Float {
    (self / π) * 180
  }

  /// Converts degrees to radians
  var radians: Float {
    (self / 180) * π
  }

  var isNegative: Bool {
    sign == .minus
  }
}
