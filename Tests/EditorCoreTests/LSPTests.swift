@testable import EditorCore
import Foundation
import XCTest

final class JSONTests: XCTestCase {
  func testEncodingIsCompactSortedAndEscaped() {
    let json: JSON = ["b": [1, true, nil], "a": "x\"y\n\u{1}", "c": .number(1.5)]
    XCTAssertEqual(String(decoding: json.data, as: UTF8.self), #"{"a":"x\"y\n\u0001","b":[1,true,null],"c":1.5}"#)
  }

  func testDecodingKeepsBooleansApartFromNumbers() throws {
    let json = try XCTUnwrap(JSON(data: Data(#"{"t": true, "n": 1, "s": "é", "l": [null, {"k": 2}]}"#.utf8)))
    XCTAssertEqual(json["t"], .bool(true))
    XCTAssertEqual(json["n"]?.int, 1)
    XCTAssertEqual(json["s"]?.string, "é")
    XCTAssertEqual(json["l"]?[1]?["k"]?.int, 2)
    XCTAssertTrue(json["l"]?[0]?.isNull == true)
    XCTAssertNil(JSON(data: Data("{".utf8)))
  }
}

final class LSPFramingTests: XCTestCase {
  func testMessagesSplitAnywhereAndJoinedComeOutWhole() {
    let first = LSPFraming.encode(["id": 1, "text": "héllo"])
    let second = LSPFraming.encode(["id": 2])
    var stream = first + second
    var parser = LSPFrameParser()
    var messages: [JSON] = []
    // A byte at a time: headers and multibyte text split.
    while !stream.isEmpty {
      messages += parser.append(stream.prefix(1))
      stream = stream.dropFirst()
    }
    XCTAssertEqual(messages.map { $0["id"]?.int }, [1, 2])
    XCTAssertEqual(messages.first?["text"]?.string, "héllo")
    // Content-Length counts bytes: "é" is two.
    XCTAssertTrue(String(decoding: first, as: UTF8.self).hasPrefix("Content-Length: 24\r\n\r\n"))
  }

  func testAFrameWithoutALengthIsSkipped() {
    var parser = LSPFrameParser()
    let messages = parser.append(Data("Bogus: 1\r\n\r\n".utf8) + LSPFraming.encode(["id": 3]))
    XCTAssertEqual(messages.map { $0["id"]?.int }, [3])
  }
}

/// A server in the process: answers what the client sends through `answer`, a message at a time,
/// on its own queue as a real server's pipe would.
final class ScriptedServer: LSPTransport, @unchecked Sendable {
  private let lock = NSLock()
  private var parser = LSPFrameParser()
  private var receive: (@Sendable (Data) -> Void)?
  private var closed: (@Sendable () -> Void)?
  private(set) var received: [JSON] = []
  /// What to answer a request with, by method; nil answers nothing.
  var answer: @Sendable (String, JSON) -> JSON? = { _, _ in .null }
  private let queue = DispatchQueue(label: "ScriptedServer")

  func start(receive: @escaping @Sendable (Data) -> Void, closed: @escaping @Sendable () -> Void) throws {
    self.lock.withLock {
      self.receive = receive
      self.closed = closed
    }
  }

  func send(_ data: Data) {
    let messages = self.lock.withLock { () -> [JSON] in
      let messages = self.parser.append(data)
      self.received += messages
      return messages
    }
    for message in messages {
      guard let method = message["method"]?.string, let id = message["id"] else { continue }
      guard let result = self.answer(method, message["params"] ?? .null) else { continue }
      self.push(["jsonrpc": "2.0", "id": id, "result": result])
    }
  }

  /// Sends the client a message, as the server.
  func push(_ message: JSON) {
    let receive = self.lock.withLock { self.receive }
    self.queue.async { receive?(LSPFraming.encode(message)) }
  }

  func close() {}

  func end() {
    let closed = self.lock.withLock { self.closed }
    self.queue.async { closed?() }
  }

  /// The methods received, in order.
  var methods: [String] {
    self.lock.withLock { self.received.compactMap { $0["method"]?.string } }
  }

  func waitFor(_ method: String, timeout: Double = 5) -> JSON? {
    let deadline = Date().addingTimeInterval(timeout)
    while Date() < deadline {
      if let message = self.lock.withLock({ self.received.last { $0["method"]?.string == method } }) { return message }
      Thread.sleep(forTimeInterval: 0.005)
    }
    return nil
  }
}

final class LSPConnectionTests: XCTestCase {
  private final class Box<T>: @unchecked Sendable {
    let lock = NSLock()
    var value: T
    init(_ value: T) { self.value = value }
  }

  func testRequestsGetTheirOwnAnswers() throws {
    let server = ScriptedServer()
    server.answer = { method, params in .string("\(method):\(params["n"]?.int ?? 0)") }
    let connection = LSPConnection(transport: server)
    try connection.start()
    let answers = Box<[String]>([])
    let done = self.expectation(description: "answers")
    done.expectedFulfillmentCount = 2
    for n in [1, 2] {
      connection.request("m", ["n": .number(Double(n))]) { result in
        answers.lock.withLock { answers.value.append((try? result.get())?.string ?? "") }
        done.fulfill()
      }
    }
    self.wait(for: [done], timeout: 5)
    XCTAssertEqual(Set(answers.lock.withLock { answers.value }), ["m:1", "m:2"])
  }

  func testServerRequestsAreAnsweredAndNotificationsDelivered() throws {
    let server = ScriptedServer()
    let connection = LSPConnection(transport: server)
    let notified = self.expectation(description: "notified")
    connection.onNotification = { method, params in
      XCTAssertEqual(method, "window/logMessage")
      XCTAssertEqual(params["message"]?.string, "hi")
      notified.fulfill()
    }
    connection.onRequest = { method, _ in method == "ping" ? "pong" : .null }
    try connection.start()
    server.push(["jsonrpc": "2.0", "method": "window/logMessage", "params": ["message": "hi"]])
    server.push(["jsonrpc": "2.0", "id": 7, "method": "ping"])
    self.wait(for: [notified], timeout: 5)
    let deadline = Date().addingTimeInterval(5)
    while server.lock_received().first(where: { $0["id"]?.int == 7 }) == nil && Date() < deadline {
      Thread.sleep(forTimeInterval: 0.005)
    }
    XCTAssertEqual(server.lock_received().first { $0["id"]?.int == 7 }?["result"]?.string, "pong")
  }

  func testCancelSendsCancelAndDropsTheAnswer() throws {
    let server = ScriptedServer()
    server.answer = { _, _ in nil }  // never answers by itself
    let connection = LSPConnection(transport: server)
    try connection.start()
    let id = connection.request("slow", [:]) { _ in XCTFail("a cancelled request is not answered") }
    connection.cancel(id)
    XCTAssertEqual(server.waitFor("$/cancelRequest")?["params"]?["id"]?.int, id)
    server.push(["jsonrpc": "2.0", "id": .number(Double(id)), "result": "late"])
    Thread.sleep(forTimeInterval: 0.1)
  }

  func testTheEndFailsWhatIsPending() throws {
    let server = ScriptedServer()
    server.answer = { _, _ in nil }
    let connection = LSPConnection(transport: server)
    let closed = self.expectation(description: "closed")
    connection.onClose = { closed.fulfill() }
    try connection.start()
    let failed = self.expectation(description: "failed")
    connection.request("x", [:]) { result in
      if case .failure(.closed) = result { failed.fulfill() }
    }
    server.end()
    self.wait(for: [failed, closed], timeout: 5)
  }
}

extension ScriptedServer {
  func lock_received() -> [JSON] { self.received }
}

final class LanguageServiceTests: XCTestCase {
  private func startedService(_ server: ScriptedServer) throws -> LSPLanguageService {
    try LSPLanguageService(root: "/pkg", transport: server)
  }

  func testNothingIsSentBeforeTheServerIsInitialized() throws {
    let server = ScriptedServer()
    // Holds `initialize` until the test lets it through.
    let gate = DispatchSemaphore(value: 0)
    server.answer = { method, _ in
      if method == "initialize" { gate.wait() }
      return ["capabilities": [:]]
    }
    let queue = DispatchQueue(label: "start")
    let started = self.expectation(description: "started")
    let box = ServiceBox()
    queue.async {
      box.service = try? self.startedService(server)
      started.fulfill()
    }
    // Initialize is sent before the answer comes back.
    XCTAssertNotNil(server.waitFor("initialize"))
    gate.signal()
    self.wait(for: [started], timeout: 5)
    let service = try XCTUnwrap(box.service)
    service.open(path: "/pkg/a.swift", text: "let a = 1", version: 1)
    XCTAssertNotNil(server.waitFor("textDocument/didOpen"))
    XCTAssertEqual(server.methods.prefix(3), ["initialize", "initialized", "textDocument/didOpen"])
    let initialize = try XCTUnwrap(server.waitFor("initialize"))
    XCTAssertEqual(initialize["params"]?["rootUri"]?.string, "file:///pkg/")
    XCTAssertEqual(initialize["params"]?["capabilities"]?["general"]?["positionEncodings"], ["utf-16"])
    let open = try XCTUnwrap(server.waitFor("textDocument/didOpen"))
    XCTAssertEqual(open["params"]?["textDocument"]?["text"]?.string, "let a = 1")
    XCTAssertEqual(open["params"]?["textDocument"]?["uri"]?.string, "file:///pkg/a.swift")
  }

  func testChangesAreSentAsRanges() throws {
    let server = ScriptedServer()
    let service = try self.startedService(server)
    let edit = LSPTextEdit(range: LSPRange(start: LSPPosition(line: 0, character: 4), end: LSPPosition(line: 0, character: 5)), text: "b")
    service.change(path: "/pkg/a.swift", version: 2, edits: [edit])
    let change = try XCTUnwrap(server.waitFor("textDocument/didChange"))
    XCTAssertEqual(change["params"]?["textDocument"]?["version"]?.int, 2)
    XCTAssertEqual(change["params"]?["contentChanges"]?[0]?["range"]?["start"]?["character"]?.int, 4)
    XCTAssertEqual(change["params"]?["contentChanges"]?[0]?["text"]?.string, "b")
  }

  func testCompletionsHoversAndDefinitionsAreRead() throws {
    let server = ScriptedServer()
    server.answer = { method, _ in
      switch method {
      case "initialize": return ["capabilities": [:]]
      case "textDocument/completion":
        return ["isIncomplete": false, "items": [
          ["label": "print(_:)", "kind": 3, "insertText": "print(${1:items})", "detail": "Void"],
          ["label": "precondition", "kind": 3],
        ]]
      case "textDocument/hover":
        return ["contents": ["kind": "markdown", "value": "```swift\nfunc print(_ items: Any...)\n```\n**Prints** it."]]
      case "textDocument/definition":
        return [["uri": "file:///pkg/Sources/b.swift", "range": ["start": ["line": 3, "character": 2], "end": ["line": 3, "character": 5]]]]
      default: return .null
      }
    }
    let service = try self.startedService(server)
    XCTAssertNotNil(server.waitFor("initialized"))
    let position = LSPPosition(line: 0, character: 2)

    let completed = self.expectation(description: "completion")
    service.completion(path: "/pkg/a.swift", at: position) { items in
      XCTAssertEqual(items.map(\.label), ["print(_:)", "precondition"])
      XCTAssertEqual(items.first?.textToInsert, "print(items)")
      XCTAssertEqual(items.first?.kind, .function)
      completed.fulfill()
    }
    let hovered = self.expectation(description: "hover")
    service.hover(path: "/pkg/a.swift", at: position) { text in
      XCTAssertEqual(text, "func print(_ items: Any...)\nPrints it.")
      hovered.fulfill()
    }
    let defined = self.expectation(description: "definition")
    service.definition(path: "/pkg/a.swift", at: position) { locations in
      XCTAssertEqual(locations.first?.path, "/pkg/Sources/b.swift")
      XCTAssertEqual(locations.first?.range.start, LSPPosition(line: 3, character: 2))
      defined.fulfill()
    }
    self.wait(for: [completed, hovered, defined], timeout: 5)
  }

  func testPublishedDiagnosticsReachTheHandler() throws {
    let server = ScriptedServer()
    let service = try self.startedService(server)
    let published = self.expectation(description: "diagnostics")
    service.onDiagnostics = { path, version, diagnostics in
      XCTAssertEqual(path, "/pkg/a.swift")
      XCTAssertEqual(version, 4)
      XCTAssertEqual(diagnostics.map(\.message), ["cannot find 'x' in scope"])
      XCTAssertEqual(diagnostics.first?.severity, .error)
      published.fulfill()
    }
    server.push(["jsonrpc": "2.0", "method": "textDocument/publishDiagnostics", "params": [
      "uri": "file:///pkg/a.swift", "version": 4,
      "diagnostics": [["range": ["start": ["line": 0, "character": 0], "end": ["line": 0, "character": 1]],
                       "severity": 1, "message": "cannot find 'x' in scope"]],
    ]])
    self.wait(for: [published], timeout: 5)
  }

  func testShutdownThenExit() throws {
    let server = ScriptedServer()
    let service = try self.startedService(server)
    service.shutdown()
    XCTAssertNotNil(server.waitFor("exit"))
  }

  func testPlaceholdersAreReducedToTheirText() {
    XCTAssertEqual(LSPCompletionItem.strippingPlaceholders("f(${1:x}, ${2:y})$0"), "f(x, y)")
    XCTAssertEqual(LSPCompletionItem.strippingPlaceholders("plain"), "plain")
    XCTAssertEqual(LSPCompletionItem.strippingPlaceholders("g(${1:{ $0 }})"), "g({ $0 })")
  }
}

private final class ServiceBox: @unchecked Sendable {
  var service: LSPLanguageService?
}
