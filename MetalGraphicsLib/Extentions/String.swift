//
//  String.swift
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 20.01.2023.
//

import Foundation

extension String {
  var uint32: [UInt32] {
    return self.unicodeScalars.map { $0.value }
  }
  
  init(values: [UInt32])  {
    self = String(values.map { Character(Unicode.Scalar($0)!) })
  }
  
  init(values: inout [UInt32])  {
    self = String(values.map { Character(Unicode.Scalar($0)!) })
  }
}
