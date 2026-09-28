import MetalGraphicsLib
import SwiftUI

/// The Storybook's menu: its keys, each a write to the model, which every window hears.
struct StorybookCommands: Commands {
  var body: some Commands {
    CommandMenu("Story") {
      Button("Next Story") { StorybookModel.shared.selectNeighbour(1, in: StoryRegistry.catalog()) }
        .keyboardShortcut(.downArrow, modifiers: [.command, .option])
      Button("Previous Story") { StorybookModel.shared.selectNeighbour(-1, in: StoryRegistry.catalog()) }
        .keyboardShortcut(.upArrow, modifiers: [.command, .option])
      Divider()
      Button("Canvas") { StorybookModel.shared.setMode(.canvas) }
        .keyboardShortcut("1", modifiers: .command)
      Button("Docs") { StorybookModel.shared.setMode(.docs) }
        .keyboardShortcut("2", modifiers: .command)
      Divider()
      Button("Cycle Appearance") { StorybookModel.shared.cycleAppearance() }
        .keyboardShortcut("l", modifiers: [.command, .shift])
      Button("Actual Size") { StorybookModel.shared.setZoom(1) }
        .keyboardShortcut("0", modifiers: .command)
      Button("Zoom In") { StorybookModel.shared.stepZoom(1) }
        .keyboardShortcut("=", modifiers: .command)
      Button("Zoom Out") { StorybookModel.shared.stepZoom(-1) }
        .keyboardShortcut("-", modifiers: .command)
      Button("Toggle Outline") { StorybookModel.shared.setOutline(!StorybookModel.shared.outline) }
        .keyboardShortcut("o", modifiers: [.command, .option])
      Divider()
      Button("Reset Args") { StorybookModel.shared.resetArgs(in: StoryRegistry.catalog()) }
        .keyboardShortcut("r", modifiers: [.command, .option])
      Button("Clear Actions") { StorybookModel.shared.clearActions() }
        .keyboardShortcut("k", modifiers: .command)
    }
  }
}
