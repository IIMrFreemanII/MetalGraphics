import AppKit
import EditorCore
import MetalGraphicsLib
import ReactiveUI

/// The folder open, shared by every window: the navigator shows its tree, a file panel reads its
/// root. Written when a folder opens or is scanned again, never per frame.
@Model
final class WorkspaceModel {
  static let shared = WorkspaceModel()

  /// Absolute; "" while no folder is open.
  var rootPath: String = ""
  /// The folder's files, once scanned.
  var root: FileNode? = nil
  /// The file in the tab picked last, in any window: the navigator marks its row.
  var activeFile: String = ""

  func reset() {
    self.rootPath = ""
    self.root = nil
    self.activeFile = ""
  }
}

/// What the app does outside the window threads, swapped by tests for what runs at once and
/// asks no one.
enum Services {
  /// Runs `work` off every window's thread: scanning a folder.
  nonisolated(unsafe) static var background: @Sendable (@escaping @Sendable () -> Void) -> Void = { work in
    DispatchQueue.global(qos: .userInitiated).async(execute: work)
  }

  /// Asks the user for a folder, then calls back with its path, on the main thread; never when
  /// they cancel.
  nonisolated(unsafe) static var chooseFolder: @Sendable (@escaping @Sendable (String) -> Void) -> Void = { done in
    performOnMain {
      let panel = NSOpenPanel()
      panel.canChooseFiles = false
      panel.canChooseDirectories = true
      panel.allowsMultipleSelection = false
      panel.prompt = "Open"
      panel.message = "Choose a folder to edit, such as a Swift package."
      panel.begin { response in
        guard response == .OK, let url = panel.url else { return }
        done(url.path)
      }
    }
  }

  static func resetForTesting() {
    self.background = { $0() }
    self.chooseFolder = { _ in }
  }
}

/// A string kept in panel or app storage.
struct StoredText: RawRepresentable {
  var rawValue: String
}
