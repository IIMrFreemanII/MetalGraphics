import Foundation

/// Where a server's bytes come from and go to: a child process's pipes, or, in tests, a fake
/// server in the same process.
public protocol LSPTransport: AnyObject, Sendable {
  /// Starts delivering what the server sends, as it arrives, and its end, once.
  func start(receive: @escaping @Sendable (Data) -> Void, closed: @escaping @Sendable () -> Void) throws
  func send(_ data: Data)
  func close()
}

/// A language server as a child process: its standard input and output carry the messages, its
/// standard error goes to `onLog`.
public final class ProcessTransport: LSPTransport, @unchecked Sendable {
  private let process = Process()
  private let input = Pipe()
  private let output = Pipe()
  private let errors = Pipe()
  private let lock = NSLock()
  /// Told what the server prints on standard error.
  public var onLog: (@Sendable (String) -> Void)?

  public init(executable: String, arguments: [String] = [], directory: String) {
    self.process.executableURL = URL(fileURLWithPath: executable)
    self.process.arguments = arguments
    self.process.currentDirectoryURL = URL(fileURLWithPath: directory)
    self.process.standardInput = self.input
    self.process.standardOutput = self.output
    self.process.standardError = self.errors
  }

  public func start(receive: @escaping @Sendable (Data) -> Void, closed: @escaping @Sendable () -> Void) throws {
    self.output.fileHandleForReading.readabilityHandler = { handle in
      let data = handle.availableData
      if data.isEmpty {
        handle.readabilityHandler = nil
      } else {
        receive(data)
      }
    }
    let log = self.onLog
    self.errors.fileHandleForReading.readabilityHandler = { handle in
      let data = handle.availableData
      if data.isEmpty {
        handle.readabilityHandler = nil
      } else {
        log?(String(decoding: data, as: UTF8.self))
      }
    }
    self.process.terminationHandler = { _ in closed() }
    try self.process.run()
  }

  public func send(_ data: Data) {
    self.lock.withLock {
      guard self.process.isRunning else { return }
      try? self.input.fileHandleForWriting.write(contentsOf: data)
    }
  }

  public func close() {
    self.lock.withLock {
      try? self.input.fileHandleForWriting.close()
    }
    let process = self.process
    DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
      if process.isRunning { process.terminate() }
    }
  }
}

public enum LSPError: Error, Equatable, Sendable {
  /// The server answered with an error.
  case response(code: Int, message: String)
  /// The connection ended before the answer came.
  case closed
}

/// JSON-RPC over a transport: requests matched to their answers by id, notifications both ways,
/// and the server's own requests answered. Everything runs on one serial queue; answers and
/// notifications are delivered there.
public final class LSPConnection: @unchecked Sendable {
  public typealias Reply = @Sendable (Result<JSON, LSPError>) -> Void

  private let transport: any LSPTransport
  private let queue = DispatchQueue(label: "LSPConnection", qos: .userInitiated)
  private var parser = LSPFrameParser()
  private var nextID = 1
  private var pending: [Int: Reply] = [:]
  private var isClosed = false

  /// A notification from the server: its method and params.
  public var onNotification: (@Sendable (String, JSON) -> Void)?
  /// A request from the server: its answer. Null by default.
  public var onRequest: (@Sendable (String, JSON) -> JSON)?
  /// The server went away.
  public var onClose: (@Sendable () -> Void)?

  public init(transport: any LSPTransport) {
    self.transport = transport
  }

  public func start() throws {
    try self.transport.start(receive: { [weak self] data in
      guard let self else { return }
      self.queue.async { self.received(data) }
    }, closed: { [weak self] in
      guard let self else { return }
      self.queue.async { self.closed() }
    })
  }

  /// Sends a request; `reply` gets its answer on the connection's queue. Returns its id.
  @discardableResult
  public func request(_ method: String, _ params: JSON, reply: @escaping Reply) -> Int {
    self.queue.sync {
      let id = self.nextID
      self.nextID += 1
      guard !self.isClosed else {
        self.queue.async { reply(.failure(.closed)) }
        return id
      }
      self.pending[id] = reply
      self.transport.send(LSPFraming.encode(["jsonrpc": "2.0", "id": .number(Double(id)), "method": .string(method), "params": params]))
      return id
    }
  }

  public func notify(_ method: String, _ params: JSON) {
    self.queue.async {
      guard !self.isClosed else { return }
      self.transport.send(LSPFraming.encode(["jsonrpc": "2.0", "method": .string(method), "params": params]))
    }
  }

  /// Asks the server to drop request `id`; its answer, if one still comes, is not delivered.
  public func cancel(_ id: Int) {
    self.queue.async {
      guard self.pending.removeValue(forKey: id) != nil, !self.isClosed else { return }
      self.transport.send(LSPFraming.encode(["jsonrpc": "2.0", "method": "$/cancelRequest", "params": ["id": .number(Double(id))]]))
    }
  }

  public func close() {
    self.transport.close()
  }

  // MARK: - On the queue

  private func received(_ data: Data) {
    for message in self.parser.append(data) {
      self.handle(message)
    }
  }

  private func handle(_ message: JSON) {
    let method = message["method"]?.string
    if let method, let id = message["id"] {
      // The server's request.
      let result = self.onRequest?(method, message["params"] ?? .null) ?? .null
      self.transport.send(LSPFraming.encode(["jsonrpc": "2.0", "id": id, "result": result]))
    } else if let method {
      self.onNotification?(method, message["params"] ?? .null)
    } else if let id = message["id"]?.int, let reply = self.pending.removeValue(forKey: id) {
      if let error = message["error"] {
        reply(.failure(.response(code: error["code"]?.int ?? 0, message: error["message"]?.string ?? "")))
      } else {
        reply(.success(message["result"] ?? .null))
      }
    }
  }

  private func closed() {
    guard !self.isClosed else { return }
    self.isClosed = true
    let pending = self.pending
    self.pending = [:]
    for reply in pending.values { reply(.failure(.closed)) }
    self.onClose?()
  }
}
