import MetalGraphicsLib
import ReactiveUI
import simd

/// The editor window's tree: the dock area, and the keys that act on the whole window. ⌘O opens
/// a folder, ⌘P a file by name, ⌘⌥S saves every file; ⌘B builds, ⌘R runs, ⌘U tests, ⌘. stops.
/// A file's own keys are its panel's.
@Component
final class IDERoot : SingleChildElement {
  @State var quickOpen: Bool = false

  @UIElementBuilder var body: [UIElement] {
    DockArea(IDE.space, host: IDE.host)
      .onKeyPress(phases: .down) { press in self.key(press) }
      .sheet(isPresented: $quickOpen) {
        QuickOpenSheet()
      }
  }

  private func key(_ press: KeyPress) -> KeyPress.Result {
    guard press.modifiers.contains(.command) else { return .ignored }
    switch press.key {
    case "o":
      IDE.chooseFolder()
      return .handled
    case "p" where WorkspaceModel.shared.root != nil:
      self.quickOpen = true
      return .handled
    case "s" where press.modifiers.contains(.option):
      OpenFiles.shared.saveAll()
      return .handled
    case "b":
      BuildController.shared.start(.build)
      return .handled
    case "r":
      BuildController.shared.start(.run(product: nil))
      return .handled
    case "u":
      BuildController.shared.start(.test)
      return .handled
    case ".":
      BuildController.shared.stop()
      return .handled
    default:
      return .ignored
    }
  }
}

/// What the file area shows before any file is open.
@Component
final class WelcomePanel : SingleChildElement {
  private static let titleFont = TextFont.system(size: 20, weight: .semibold)
  private static let captionFont = TextFont.system(size: 13)
  private static let captionColor = float4(0.45, 0.45, 0.47, 1)

  @UIElementBuilder var body: [UIElement] {
    VStack(alignment: .leading, spacing: 10) {
      Text("Swift Editor")
        .font(Self.titleFont)
      Text("Open a folder (⌘O), then pick a file in the navigator or by name (⌘P). ⌘S saves it, ⌘⌥S saves all.")
        .font(Self.captionFont)
        .foregroundColor(Self.captionColor)
      Button("Open Folder…") { IDE.chooseFolder() }
        .buttonStyle(.borderedProminent)
    }
    .padding(24)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
  }
}
