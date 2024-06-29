//
//  Array.swift
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 17.05.2024.
//

public extension Array {
  var byteCount: Int {
    MemoryLayout<Element>.stride * count
  }

  mutating func forEach(_ body: (inout Element) -> Void) {
    withUnsafeMutableBufferPointer { buffer in
      for i in 0..<buffer.count {
        var elem = buffer[i]
        body(&elem)
        buffer[i] = elem
      }
    }
  }
}
