//
//  Array.swift
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 17.05.2024.
//

import Foundation

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


extension Array {
  /// Moves the elements at `source` to before the element that was at `destination`, as
  /// SwiftUI's `move(fromOffsets:toOffset:)`, which `.onMove` hands its arguments for. Named
  /// apart from it so a file importing both modules is not ambiguous.
  public mutating func moveElements(fromOffsets source: IndexSet, toOffset destination: Int) {
    let destination = Swift.min(Swift.max(destination, 0), self.count)
    let moving = source.filter { $0 < self.count }
    guard !moving.isEmpty else { return }
    let moved = moving.map { self[$0] }
    let before = moving.count(where: { $0 < destination })
    for index in moving.reversed() {
      self.remove(at: index)
    }
    self.insert(contentsOf: moved, at: destination - before)
  }
}
