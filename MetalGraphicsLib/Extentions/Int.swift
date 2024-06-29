//
//  Int.swift
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 12.02.2023.
//

public extension Int {
  init(_ boolean: Bool) {
    self = boolean ? 1 : 0
  }

  func isBetween(_ range: ClosedRange<Int>) -> Bool {
    range.contains(self)
  }
}
