@testable import EditorCore
import Foundation
import XCTest

/// Against the real sourcekit-lsp: slow (it indexes), so only with `EDITOR_SLOW_TESTS=1`.
final class SourceKitLSPTests: XCTestCase {
  private final class Collected: @unchecked Sendable {
    let lock = NSLock()
    var diagnostics: [LSPDiagnostic]?
  }

  func testDiagnosticsCompletionHoverAndDefinition() throws {
    try XCTSkipUnless(ProcessInfo.processInfo.environment["EDITOR_SLOW_TESTS"] == "1", "set EDITOR_SLOW_TESTS=1")
    let main = "let greeting = \"Hello\"\nprint(greting)\nlet n = greeting.count\n"
    let root = try makeFolder([
      "Package.swift": "// swift-tools-version: 6.0\nimport PackageDescription\nlet package = Package(name: \"P\", targets: [.executableTarget(name: \"P\")])\n",
      "Sources/P/main.swift": main,
    ], in: self)
    // sourcekit-lsp reports real paths: /private/var for a temporary folder.
    let real = root.resolvingSymlinksInPath().path.replacingOccurrences(of: "/var/", with: "/private/var/")
    let path = real + "/Sources/P/main.swift"
    let service = try XCTUnwrap(SourceKitLSP.start(root: real))
    // Paths come back standardized, as the editor's are: /var, not /private/var.
    let reported = URL(fileURLWithPath: path).standardizedFileURL.path
    defer { service.shutdown() }
    let collected = Collected()
    let published = self.expectation(description: "diagnostics")
    published.assertForOverFulfill = false
    service.onDiagnostics = { file, _, diagnostics in
      guard file == reported, !diagnostics.isEmpty else { return }
      collected.lock.withLock { collected.diagnostics = diagnostics }
      published.fulfill()
    }
    service.open(path: path, text: main, version: 1)
    self.wait(for: [published], timeout: 120)
    let diagnostics = try XCTUnwrap(collected.lock.withLock { collected.diagnostics })
    XCTAssertTrue(diagnostics.contains { $0.message.contains("greting") && $0.range.start.line == 1 })
    XCTAssertEqual(diagnostics.first?.range.start.character, 6)

    let completed = self.expectation(description: "completion")
    // After "greeting." on line 2.
    service.completion(path: path, at: LSPPosition(line: 2, character: 17)) { items in
      XCTAssertTrue(items.contains { $0.label.hasPrefix("count") }, "\(items.prefix(5).map(\.label))")
      completed.fulfill()
    }
    let hovered = self.expectation(description: "hover")
    service.hover(path: path, at: LSPPosition(line: 0, character: 6)) { text in
      XCTAssertTrue(text?.contains("greeting") == true, text ?? "nil")
      hovered.fulfill()
    }
    let defined = self.expectation(description: "definition")
    service.definition(path: path, at: LSPPosition(line: 2, character: 10)) { locations in
      XCTAssertEqual(locations.first?.range.start.line, 0)
      defined.fulfill()
    }
    self.wait(for: [completed, hovered, defined], timeout: 60)
  }
}
