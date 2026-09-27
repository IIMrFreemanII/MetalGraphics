import AppKit
import EditorCore
import SwiftCodeModel
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
  /// A place to show, for the tab of its file to take: a problem picked in the list.
  var reveal: RevealRequest? = nil

  func reset() {
    self.rootPath = ""
    self.root = nil
    self.activeFile = ""
    self.reveal = nil
  }
}

/// A place in a file to select and scroll to. `serial` tells two requests for the same place
/// apart.
struct RevealRequest: Equatable, Sendable {
  let path: String
  /// From 1.
  var line: Int = 1
  /// From 1, in UTF-8 bytes, as compilers count.
  var column: Int = 1
  /// A UTF-16 offset in the text, which wins over the line and column when set: a symbol from
  /// the outline.
  var offset: Int? = nil
  let serial: Int
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

  /// What runs builds: `swift build` and `swift run` in the app.
  nonisolated(unsafe) static var makeBuildService: @Sendable () -> any BuildService = { SwiftPMBuildService() }

  /// What a package declares, for its executables. Slow: run in the background.
  nonisolated(unsafe) static var describePackage: @Sendable (String) -> PackageInfo? = { PackageInfo.describe($0) }

  /// Watches the open folder, calling back with the paths that changed; nil for no watching.
  nonisolated(unsafe) static var watchFolder: @Sendable (String, @escaping @Sendable ([String]) -> Void) -> AnyObject? = {
    root, changed in DirectoryWatcher(root, onChange: changed)
  }

  /// Parses Swift for the outline and folding: off the window threads.
  nonisolated(unsafe) static var analyzeCode: @Sendable (String) -> CodeAnalysis = { CodeModel.analyze($0) }
  /// Where parsing runs.
  nonisolated(unsafe) static var parseQueue: @Sendable (@escaping @Sendable () -> Void) -> Void = { work in
    DispatchQueue.global(qos: .utility).async(execute: work)
  }
  /// How long a pause in typing is before the file is parsed again; 0 parses at once.
  nonisolated(unsafe) static var parseDelay: Double = 0.3

  /// How long build output waits to reach the windows, so a burst of lines is one update. 0
  /// delivers each piece at once, as tests want.
  nonisolated(unsafe) static var outputDelay: Double = 0.05
}

/// A string kept in panel or app storage.
struct StoredText: RawRepresentable {
  var rawValue: String
}
