//
//  GPURayMarchingApp.swift
//  GPURayMarching
//
//  Created by Nikolay Diahovets on 08.06.2024.
//

import SwiftUI
import MetalGraphicsLib

@main
struct GPURayMarchingApp: App {
  init() {
    Input.initialize()
  }
  var body: some Scene {
    WindowGroup {
      ContentView()
    }
  }
}
