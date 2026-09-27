import Foundation

/// What the editor asks of a language: kept in sync with open files, it answers completions,
/// hovers and definitions, and reports diagnostics. Callback-based and thread-safe: the editor
/// calls it from window threads, and gets answers on any thread. Tests use a fake that answers at
/// once.
public protocol LanguageService: AnyObject, Sendable {
  /// A file opened, with its text as `version`.
  func open(path: String, text: String, version: Int)
  /// Edits made to it, applied in order, each in the text as the ones before left it.
  func change(path: String, version: Int, edits: [LSPTextEdit])
  /// Its whole text, when sending the edits one by one is not worth it.
  func replace(path: String, version: Int, text: String)
  func save(path: String)
  func close(path: String)

  /// Completions at `position`. Returns an id to `cancel` with.
  @discardableResult
  func completion(path: String, at position: LSPPosition, reply: @escaping @Sendable ([LSPCompletionItem]) -> Void) -> Int
  /// What the symbol at `position` is, as plain text; nil for nothing.
  func hover(path: String, at position: LSPPosition, reply: @escaping @Sendable (String?) -> Void)
  /// Where the symbol at `position` is declared.
  func definition(path: String, at position: LSPPosition, reply: @escaping @Sendable ([LSPLocation]) -> Void)
  func cancel(_ request: Int)
  func shutdown()

  /// Where diagnostics go: the file, the version they are for (nil when the server does not
  /// say), and the diagnostics, all of them, replacing the file's last. Set before the first
  /// `open`.
  var onDiagnostics: (@Sendable (_ path: String, _ version: Int?, _ diagnostics: [LSPDiagnostic]) -> Void)? { get set }
  /// What the server says about itself: its log, and its end.
  var onLog: (@Sendable (String) -> Void)? { get set }
  /// Whether it still runs.
  var isAlive: Bool { get }
}

/// sourcekit-lsp, or any server speaking the protocol, over a transport.
///
/// Messages sent before the server answered `initialize` wait for it, in order, as the protocol
/// asks.
public final class LSPLanguageService: LanguageService, @unchecked Sendable {
  private let connection: LSPConnection
  private let root: String
  private let lock = NSLock()
  private var ready = false
  private var waiting: [() -> Void] = []
  private var alive = true
  private var diagnosticsHandler: (@Sendable (String, Int?, [LSPDiagnostic]) -> Void)?
  private var logHandler: (@Sendable (String) -> Void)?

  public var onDiagnostics: (@Sendable (String, Int?, [LSPDiagnostic]) -> Void)? {
    get { self.lock.withLock { self.diagnosticsHandler } }
    set { self.lock.withLock { self.diagnosticsHandler = newValue } }
  }

  public var onLog: (@Sendable (String) -> Void)? {
    get { self.lock.withLock { self.logHandler } }
    set { self.lock.withLock { self.logHandler = newValue } }
  }

  public var isAlive: Bool { self.lock.withLock { self.alive } }

  /// Starts the server for the package at `root`. Throws when the transport cannot start.
  public init(root: String, transport: any LSPTransport) throws {
    self.root = root
    self.connection = LSPConnection(transport: transport)
    self.connection.onNotification = { [weak self] method, params in self?.notification(method, params) }
    self.connection.onRequest = { method, params in
      // `workspace/configuration` asks for one value per item: none of ours.
      if method == "workspace/configuration" {
        return .array(Array(repeating: .null, count: params["items"]?.array?.count ?? 0))
      }
      return .null
    }
    self.connection.onClose = { [weak self] in
      guard let self else { return }
      self.lock.withLock { self.alive = false }
      self.onLog?("The language server stopped.\n")
    }
    try self.connection.start()
    self.connection.request("initialize", Self.initializeParams(root: root)) { [weak self] result in
      guard let self else { return }
      if case .failure(let error) = result {
        self.onLog?("The language server did not start: \(error)\n")
        return
      }
      self.connection.notify("initialized", [:])
      let waiting = self.lock.withLock {
        self.ready = true
        defer { self.waiting = [] }
        return self.waiting
      }
      for send in waiting { send() }
    }
  }

  static func initializeParams(root: String) -> JSON {
    [
      "processId": .number(Double(ProcessInfo.processInfo.processIdentifier)),
      "rootUri": .string(LSPURI.uri(root)),
      "rootPath": .string(root),
      "capabilities": [
        "general": ["positionEncodings": ["utf-16"]],
        "textDocument": [
          "synchronization": ["didSave": true, "dynamicRegistration": false],
          "completion": ["completionItem": ["snippetSupport": false], "contextSupport": true],
          "hover": ["contentFormat": ["plaintext", "markdown"]],
          "definition": ["linkSupport": false],
          "publishDiagnostics": ["versionSupport": true],
        ],
        "window": ["workDoneProgress": false],
      ],
    ]
  }

  /// Sends at once when the server is ready, else once it is.
  private func whenReady(_ send: @escaping () -> Void) {
    let now = self.lock.withLock { () -> Bool in
      if !self.ready { self.waiting.append(send) }
      return self.ready
    }
    if now { send() }
  }

  private func notification(_ method: String, _ params: JSON) {
    switch method {
    case "textDocument/publishDiagnostics":
      guard let uri = params["uri"]?.string, let path = LSPURI.path(uri) else { return }
      let diagnostics = params["diagnostics"]?.array?.compactMap(LSPDiagnostic.init) ?? []
      self.onDiagnostics?(path, params["version"]?.int, diagnostics)
    case "window/logMessage", "window/showMessage":
      if let message = params["message"]?.string { self.onLog?(message + "\n") }
    default:
      break
    }
  }

  private func document(_ path: String) -> JSON {
    ["uri": .string(LSPURI.uri(path))]
  }

  // MARK: - Documents

  public func open(path: String, text: String, version: Int) {
    let params: JSON = ["textDocument": [
      "uri": .string(LSPURI.uri(path)), "languageId": "swift", "version": .number(Double(version)), "text": .string(text),
    ]]
    self.whenReady { self.connection.notify("textDocument/didOpen", params) }
  }

  public func change(path: String, version: Int, edits: [LSPTextEdit]) {
    let changes = JSON.array(edits.map { ["range": $0.range.json, "text": .string($0.text)] })
    let params: JSON = ["textDocument": ["uri": .string(LSPURI.uri(path)), "version": .number(Double(version))],
                        "contentChanges": changes]
    self.whenReady { self.connection.notify("textDocument/didChange", params) }
  }

  public func replace(path: String, version: Int, text: String) {
    let params: JSON = ["textDocument": ["uri": .string(LSPURI.uri(path)), "version": .number(Double(version))],
                        "contentChanges": [["text": .string(text)]]]
    self.whenReady { self.connection.notify("textDocument/didChange", params) }
  }

  public func save(path: String) {
    let params: JSON = ["textDocument": self.document(path)]
    self.whenReady { self.connection.notify("textDocument/didSave", params) }
  }

  public func close(path: String) {
    let params: JSON = ["textDocument": self.document(path)]
    self.whenReady { self.connection.notify("textDocument/didClose", params) }
  }

  // MARK: - Questions

  private func position(_ path: String, _ position: LSPPosition) -> JSON {
    ["textDocument": self.document(path), "position": position.json]
  }

  @discardableResult
  public func completion(path: String, at position: LSPPosition, reply: @escaping @Sendable ([LSPCompletionItem]) -> Void) -> Int {
    guard self.lock.withLock({ self.ready }) else {
      reply([])
      return 0
    }
    return self.connection.request("textDocument/completion", self.position(path, position)) { result in
      guard case .success(let json) = result else { return reply([]) }
      // A `CompletionList` or a bare array.
      let items = json["items"]?.array ?? json.array ?? []
      reply(items.enumerated().compactMap { LSPCompletionItem($1, index: $0) })
    }
  }

  public func hover(path: String, at position: LSPPosition, reply: @escaping @Sendable (String?) -> Void) {
    guard self.lock.withLock({ self.ready }) else { return reply(nil) }
    self.connection.request("textDocument/hover", self.position(path, position)) { result in
      guard case .success(let json) = result else { return reply(nil) }
      reply(LSPHover.text(json))
    }
  }

  public func definition(path: String, at position: LSPPosition, reply: @escaping @Sendable ([LSPLocation]) -> Void) {
    guard self.lock.withLock({ self.ready }) else { return reply([]) }
    self.connection.request("textDocument/definition", self.position(path, position)) { result in
      guard case .success(let json) = result else { return reply([]) }
      let locations = json.array?.compactMap(LSPLocation.init) ?? LSPLocation(json).map { [$0] } ?? []
      reply(locations)
    }
  }

  public func cancel(_ request: Int) {
    self.connection.cancel(request)
  }

  public func shutdown() {
    self.connection.request("shutdown", .null) { [connection] _ in
      connection.notify("exit", .null)
      connection.close()
    }
  }
}

/// Finds sourcekit-lsp in the selected Xcode's toolchain.
public enum SourceKitLSP {
  private static let located = LocatedPath()

  /// The server's path, looked up once (`xcrun --find` takes a moment): call it off the window
  /// threads first, as the app does at launch.
  public static func locate() -> String? {
    self.located.value { Self.find() }
  }

  private static func find() -> String? {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
    process.arguments = ["--find", "sourcekit-lsp"]
    let output = Pipe()
    process.standardOutput = output
    process.standardError = FileHandle.nullDevice
    guard (try? process.run()) != nil else { return nil }
    let data = output.fileHandleForReading.readDataToEndOfFile()
    process.waitUntilExit()
    let path = String(decoding: data, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
    return process.terminationStatus == 0 && !path.isEmpty ? path : nil
  }

  /// A service for the package at `root`, or nil when sourcekit-lsp is not there or does not
  /// start.
  public static func start(root: String, log: (@Sendable (String) -> Void)? = nil) -> LanguageService? {
    guard let executable = self.locate() else { return nil }
    let transport = ProcessTransport(executable: executable, directory: root)
    transport.onLog = log
    let service = try? LSPLanguageService(root: root, transport: transport)
    service?.onLog = log
    return service
  }
}

/// A path found once, from any thread.
private final class LocatedPath: @unchecked Sendable {
  private let lock = NSLock()
  private var found: String?? = nil

  func value(_ find: () -> String?) -> String? {
    self.lock.withLock {
      if let found = self.found { return found }
      let path = find()
      self.found = .some(path)
      return path
    }
  }
}
