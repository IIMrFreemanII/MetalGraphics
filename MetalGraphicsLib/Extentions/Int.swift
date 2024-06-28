//
//  Int.swift
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 12.02.2023.
//

extension Int {
  public init(_ boolean: Bool) {
    self = boolean ? 1 : 0
  }
  
  public func isBetween(_ range: ClosedRange<Int>) -> Bool {
    range.contains(self)
  }
}
