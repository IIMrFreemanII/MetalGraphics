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
  /// Told when the file on disk changed: nil when the text was read again, else why it was not.
  var onDiskChange: ((String?) -> Void)?
  /// Told of every edit, with who made it: a completion list follows typing.
  var onEdit: ((EditOrigin) -> Void)?
  /// Told when it was saved, from its tab or with the others.
  var onSaved: (() -> Void)?

  private var encoding: String.Encoding = .utf8
  private var hasBOM = false
  /// When the file on disk was last written, as read or saved here.
  private var modified: Date?

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
    self.modified = Self.modificationDate(path)
    self.document.addListener(self)
  }

  static func modificationDate(_ path: String) -> Date? {
    (try? FileManager.default.attributesOfItem(atPath: path))?[.modificationDate] as? Date
  }

  /// Reads the file again if it changed on disk since it was read or saved here, unless it has
  /// edits of its own, which stay: the panel says so instead.
  func reloadIfChanged() {
    guard self.loadError == nil else { return }
    let modified = Self.modificationDate(self.path)
    guard modified != self.modified else { return }
    guard let modified else {
      self.onDiskChange?("Deleted on disk")
      return
    }
    guard !self.isDirty else {
      self.onDiskChange?("Changed on disk; saving will replace it")
      return
    }
    guard let contents = try? TextFileIO.read(URL(fileURLWithPath: self.path)) else { return }
    self.modified = modified
    self.encoding = contents.encoding
    self.hasBOM = contents.hasBOM
    // The app's edit: not dirty, and the undo history moves over it.
    if contents.text != self.document.stringWithOriginalLineEndings {
      self.document.setText(contents.text)
    }
    self.onDiskChange?(nil)
  }

  var name: String { (self.path as NSString).lastPathComponent }

  func document(_ document: TextDocument, didApply changes: ChangeSet, origin: EditOrigin) {
    self.onEdit?(origin)
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
    self.modified = Self.modificationDate(self.path)
    self.onSaved?()
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

  /// Saves every dirty file, each on its window's thread, then runs `then` once all are saved,
  /// on the thread of the last.
  func saveAll(then: (@Sendable () -> Void)? = nil) {
    self.forEachFile(then: then) { binding in
      guard binding.isDirty else { return }
      try? binding.save()
    }
  }

  /// Has every open file read its file again if it changed on disk.
  func reloadChangedFiles() {
    self.forEachFile { binding in binding.reloadIfChanged() }
  }

  /// Runs `body` with each open file on its window's thread, then `then`.
  private func forEachFile(then: (@Sendable () -> Void)? = nil, _ body: @escaping @Sendable (FileBinding) -> Void) {
    let entries = self.lock.withLock {
      self.entries.removeAll { $0.binding == nil }
      return self.entries
    }
    guard !entries.isEmpty else {
      then?()
      return
    }
    let remaining = Countdown(entries.count)
    for entry in entries {
      let box = WeakBinding(entry.binding)
      entry.executor.post {
        if let binding = box.binding { body(binding) }
        if remaining.finishOne() { then?() }
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

/// Counts down from any thread; true for the one that reaches zero.
private final class Countdown: @unchecked Sendable {
  private let lock = NSLock()
  private var count: Int

  init(_ count: Int) { self.count = count }

  func finishOne() -> Bool {
    self.lock.withLock {
      self.count -= 1
      return self.count == 0
    }
  }
}

/// A binding handed to its own thread, and read only there.
private final class WeakBinding: @unchecked Sendable {
  weak var binding: FileBinding?
  init(_ binding: FileBinding?) { self.binding = binding }
}
