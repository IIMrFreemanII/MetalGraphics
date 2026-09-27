import EditorCore
import Foundation
import MetalGraphicsLib
import ReactiveUI

/// The language server of the open folder, shared by every window: started when the first Swift
/// file opens, started again (up to three times) if it stops, shut down when another folder
/// opens or the app quits.
final class LanguageClient: @unchecked Sendable {
  static let shared = LanguageClient()
  static let maxStarts = 3

  private let lock = NSLock()
  private var root = ""
  private var service: (any LanguageService)?
  private var starts = 0

  /// The server for `root`, started if it is not running; nil when there is none to start.
  func service(for root: String) -> (any LanguageService)? {
    let (service, old) = self.lock.withLock { () -> ((any LanguageService)?, (any LanguageService)?) in
      var old: (any LanguageService)? = nil
      if root != self.root {
        old = self.service
        self.service = nil
        self.root = root
        self.starts = 0
      }
      if self.service?.isAlive != true, self.starts < Self.maxStarts, !root.isEmpty {
        self.starts += 1
        let service = Services.makeLanguageService(root)
        service?.onDiagnostics = { path, version, diagnostics in
          LanguageModel.shared.publish(path, version: version, diagnostics: diagnostics)
        }
        self.service = service
      }
      return (self.service, old)
    }
    old?.shutdown()
    return service
  }

  func shutdown() {
    let service = self.lock.withLock { () -> (any LanguageService)? in
      defer { self.service = nil; self.root = ""; self.starts = 0 }
      return self.service
    }
    service?.shutdown()
  }
}

/// What the server reports about each file: its diagnostics, and the version they are for.
struct FileDiagnostics: Equatable, Sendable {
  var version: Int?
  var items: [LSPDiagnostic]
}

/// The server's diagnostics, by file, shared by every window: written from the server's queue,
/// read by each file's tab, which underlines its own.
@Model
final class LanguageModel {
  static let shared = LanguageModel()

  var diagnostics: [String: FileDiagnostics] = [:]

  func publish(_ path: String, version: Int?, diagnostics: [LSPDiagnostic]) {
    self.diagnostics[path] = diagnostics.isEmpty ? nil : FileDiagnostics(version: version, items: diagnostics)
  }

  func reset() {
    self.diagnostics = [:]
  }
}

/// One Swift file as the server sees it: opened with its text, then told of each edit as it is
/// made, in the text as it was before (`willApply`), last change first so each range is still
/// where it was. A change set of more than `fullTextThreshold` changes sends the whole text.
/// Closed when its tab goes.
final class LanguageDocument: TextDocumentListener {
  static let fullTextThreshold = 50

  let path: String
  let document: TextDocument
  let service: any LanguageService
  private(set) var version = 1
  private var pending: [LSPTextEdit]? = nil

  init(path: String, document: TextDocument, service: any LanguageService) {
    self.path = path
    self.document = document
    self.service = service
    service.open(path: path, text: document.string, version: 1)
    document.addListener(self)
  }

  deinit {
    self.service.close(path: self.path)
  }

  func document(_ document: TextDocument, willApply changes: ChangeSet, origin: EditOrigin) {
    guard changes.changes.count <= Self.fullTextThreshold else {
      self.pending = nil
      return
    }
    self.pending = changes.changes.reversed().map { change in
      LSPTextEdit(range: LSPRange(start: self.position(change.range.lowerBound), end: self.position(change.range.upperBound)),
                  text: String(decoding: change.text, as: UTF16.self))
    }
  }

  func document(_ document: TextDocument, didApply changes: ChangeSet, origin: EditOrigin) {
    self.version += 1
    if let edits = self.pending {
      self.service.change(path: self.path, version: self.version, edits: edits)
    } else {
      self.service.replace(path: self.path, version: self.version, text: document.string)
    }
    self.pending = nil
  }

  func saved() {
    self.service.save(path: self.path)
  }

  /// `offset` as a line and a UTF-16 column, which the protocol's positions are.
  func position(_ offset: Int) -> LSPPosition {
    let (line, column) = self.document.position(of: offset)
    return LSPPosition(line: line, character: column)
  }

  /// Whether what the server said for `version` is about the text as it is: nil (a server that
  /// does not say, as sourcekit-lsp) is taken to be. For an older version, fresh diagnostics
  /// are on their way: the server analyses again after every change.
  func isCurrent(_ version: Int?) -> Bool {
    version.map { $0 == self.version } ?? true
  }

  static func offset(_ position: LSPPosition, in document: TextDocument) -> Int {
    let line = min(max(position.line, 0), document.lineCount - 1)
    let column = min(max(position.character, 0), document.lineRange(line).count)
    return document.offset(line: line, column: column)
  }
}
