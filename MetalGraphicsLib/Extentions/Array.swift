//
//  Array.swift
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 17.05.2024.
//

extension Array {
  mutating func forEach(_ body: (inout Element) -> Void) {
    self.withUnsafeMutableBufferPointer { buffer in
      for i in 0..<buffer.count {
        var elem = buffer[i]
        body(&elem)
        buffer[i] = elem
      }
    }
  }
}
