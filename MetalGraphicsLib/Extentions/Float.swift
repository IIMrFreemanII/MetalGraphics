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
}

extension Float {
    public func isBetween(_ range: ClosedRange<Float>) -> Bool {
        return range.contains(self)
    }
}

extension Float {
  public var radiansToDegrees: Float {
    (self / π) * 180
  }
  public var degreesToRadians: Float {
    (self / 180) * π
  }
  public var isNegative: Bool {
    return self.sign == .minus
  }
}
