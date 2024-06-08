//
//  Bool.swift
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 12.02.2023.
//

extension Int {
  init(_ boolean: Bool) {
    self = boolean ? 1 : 0
  }
}

extension Int {
    func isBetween(_ range: ClosedRange<Int>) -> Bool {
        return range.contains(self)
    }
}
