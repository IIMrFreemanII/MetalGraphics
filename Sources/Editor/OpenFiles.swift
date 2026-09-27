import EditorCore
import Foundation
import MetalGraphicsLib

/// One open file: its document, read from disk when its panel is made, and whether it has
/// changed since. Belongs to the panel's window thread, as its document does.
final class FileBinding: TextDocumentListener {
  let path: String
  let document: TextDocument
  /// Why the file could not be shown; nil when it was.
  let loadError: String?
  private(set) var isDirty = false
  /// Told when `isDirty` flips.
  var onDirtyChange: ((Bool) -> Void)?

  private var encoding: String.Encoding = .utf8
  private var hasBOM = false

  /// Reads `path`, or starts from `unsaved`: the edits its panel carried from another window.
  init(path: String, unsaved: String? = nil) {
    self.path = path
    var text = ""
    var problem: String? = nil
    do {
      let contents = try TextFileIO.read(URL(fileURLWithPath: path))
      text = contents.text
      self.encoding = contents.encoding
      self.hasBOM = contents.hasBOM
    } catch let failure as TextFileError {
      problem = failure.description
    } catch {
      problem = "\(error)"
    }
    self.loadError = problem
    self.document = TextDocument(unsaved ?? text)
    self.isDirty = unsaved != nil
    self.document.addListener(self)
  }

  var name: String { (self.path as NSString).lastPathComponent }

  func document(_ document: TextDocument, didApply changes: ChangeSet, origin: EditOrigin) {
    // An app's own edit (a reload) leaves the file as it is on disk.
    guard origin != .program, !self.isDirty else { return }
    self.isDirty = true
    self.onDirtyChange?(true)
  }

  /// Writes the text to the file, with the line endings, encoding and byte order mark it came
  /// with. Throws what went wrong, and stays dirty then.
  func save() throws {
    let contents = TextFileContents(
      text: self.document.stringWithOriginalLineEndings, encoding: self.encoding, hasBOM: self.hasBOM
    )
    try TextFileIO.write(contents, to: URL(fileURLWithPath: self.path))
    guard self.isDirty else { return }
    self.isDirty = false
    self.onDirtyChange?(false)
  }
}

/// The files open in every window: for Save All, which saves each on its own window's thread,
/// and for the unsaved text of a panel moving to another window, whose tree cannot follow it.
final class OpenFiles: @unchecked Sendable {
  static let shared = OpenFiles()

  private struct Entry {
    weak var binding: FileBinding?
    let executor: ThreadExecutor
  }

  private let lock = NSLock()
  private var entries: [Entry] = []
  /// A dirty panel's text as it left its window, by panel id.
  private var unsaved: [String: String] = [:]

  /// Adds `binding`, on its window's thread, until it is freed.
  func register(_ binding: FileBinding) {
    let executor = ThreadState.current.executor
    self.lock.withLock {
      self.entries.removeAll { $0.binding == nil || $0.binding === binding }
      self.entries.append(Entry(binding: binding, executor: executor))
    }
  }

  /// Saves every dirty file, each on its window's thread.
  func saveAll() {
    let entries = self.lock.withLock { self.entries }
    for entry in entries {
      let box = WeakBinding(entry.binding)
      entry.executor.post {
        guard let binding = box.binding, binding.isDirty else { return }
        try? binding.save()
      }
    }
  }

  /// Keeps a panel's unsaved text as it leaves its window.
  func keepUnsaved(_ text: String, panel: String) {
    self.lock.withLock { self.unsaved[panel] = text }
  }

  /// The unsaved text a panel left with, once: its next tree takes it.
  func takeUnsaved(panel: String) -> String? {
    self.lock.withLock { self.unsaved.removeValue(forKey: panel) }
  }

  func forgetUnsaved(panel: String) {
    self.lock.withLock { self.unsaved[panel] = nil }
  }

  func reset() {
    self.lock.withLock {
      self.entries = []
      self.unsaved = [:]
    }
  }
}

/// A binding handed to its own thread, and read only there.
private final class WeakBinding: @unchecked Sendable {
  weak var binding: FileBinding?
  init(_ binding: FileBinding?) { self.binding = binding }
}
