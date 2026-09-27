@testable import EditorCore
import Foundation
import XCTest

final class CompilerDiagnosticParserTests: XCTestCase {
  func testErrorsWarningsAndNotes() {
    let error = CompilerDiagnosticParser.parse("/pkg/Sources/App/main.swift:12:5: error: cannot find 'x' in scope")
    XCTAssertEqual(error, CompilerDiagnostic(path: "/pkg/Sources/App/main.swift", line: 12, column: 5,
                                             severity: .error, message: "cannot find 'x' in scope"))
    XCTAssertEqual(CompilerDiagnosticParser.parse("/a/b.swift:1:2: warning: unused")?.severity, .warning)
    XCTAssertEqual(CompilerDiagnosticParser.parse("/a/b.swift:1:2: note: here")?.severity, .note)
  }

  func testNoColumnSpacesInPathsAndCarriageReturns() {
    let linker = CompilerDiagnosticParser.parse("/a/My Project/x.swift:7: error: undefined symbol\r")
    XCTAssertEqual(linker?.path, "/a/My Project/x.swift")
    XCTAssertEqual(linker?.line, 7)
    XCTAssertEqual(linker?.column, 1)
    XCTAssertEqual(linker?.message, "undefined symbol")
  }

  func testOtherLinesAreNotDiagnostics() {
    for line in ["Building for debugging...", "[3/10] Compiling App main.swift", "error: fatalError",
                 "relative/x.swift:1:1: error: no", "/a/b.swift: error: no line", ""] {
      XCTAssertNil(CompilerDiagnosticParser.parse(line), line)
    }
  }

  func testSeveritiesOrder() {
    XCTAssertLessThan(CompilerDiagnostic.Severity.warning, .error)
    XCTAssertLessThan(CompilerDiagnostic.Severity.note, .warning)
  }
}

final class BuildLogTests: XCTestCase {
  func testLinesSplitAcrossChunksAreParsedWhole() {
    let log = BuildLog()
    log.append("/a/x.swift:3:1: err")
    XCTAssertEqual(log.diagnostics, [])
    log.append("or: broken\n/a/x.swift:4:1: warning: meh\n")
    XCTAssertEqual(log.diagnostics.map(\.line), [3, 4])
    // Each stream keeps its own partial line.
    log.append("/a/y.swift:1:1: error: ", isError: true)
    log.append("Compiling…\n")
    log.append("half\n", isError: true)
    XCTAssertEqual(log.diagnostics.last?.message, "half")
  }

  func testColourCodesAreTakenOut() {
    let log = BuildLog()
    log.append("/a/x.swift:3:7: \u{1B}[1;31merror: \u{1B}[1;39mcannot find 'x'\u{1B}[0m\n\u{1B}[0;36m1 |\u{1B}[0m let\n")
    XCTAssertEqual(log.diagnostics.first?.message, "cannot find 'x'")
    XCTAssertEqual(log.chunks(from: 0).chunks.first?.text, "/a/x.swift:3:7: error: cannot find 'x'\n1 | let\n")
    XCTAssertEqual(BuildLog.strippingEscapes("plain ✓"), "plain ✓")
    XCTAssertEqual(BuildLog.strippingEscapes("\u{1B}(Bx\u{1B}"), "x")
  }

  func testTheSameDiagnosticIsKeptOnce() {
    let log = BuildLog()
    log.append("/a/x.swift:3:1: error: broken\n/a/x.swift:3:1: error: broken\n")
    XCTAssertEqual(log.diagnostics.count, 1)
    XCTAssertEqual(log.diagnostics(inFile: "/a/x.swift").count, 1)
    XCTAssertEqual(log.diagnostics(inFile: "/a/other.swift").count, 0)
  }

  func testFinishParsesTheLastLineAndChunksAreReadFromACursor() {
    let log = BuildLog()
    log.append("a\n")
    log.append("/a/x.swift:1:1: error: last", isError: true)
    log.finish()
    XCTAssertEqual(log.diagnostics.count, 1)
    let first = log.chunks(from: 0)
    XCTAssertEqual(first.chunks, [BuildLog.Chunk("a\n"), BuildLog.Chunk("/a/x.swift:1:1: error: last", isError: true)])
    XCTAssertEqual(log.chunks(from: first.next).chunks, [])

    let generation = log.generation
    log.reset()
    XCTAssertEqual(log.generation, generation + 1)
    XCTAssertEqual(log.chunks(from: 0).chunks, [])
    XCTAssertEqual(log.diagnostics, [])
  }
}

final class ProcessRunnerTests: XCTestCase {
  private final class Collected: @unchecked Sendable {
    let lock = NSLock()
    var out = ""
    var err = ""
    var status: Int32?
  }

  func testOutputOfBothStreamsThenTheStatus() {
    let runner = ProcessRunner()
    let collected = Collected()
    let done = self.expectation(description: "finished")
    runner.start("/bin/sh", ["-c", "echo one; echo two >&2; echo three; exit 3"], in: "/tmp", output: { text, isError in
      collected.lock.withLock { if isError { collected.err += text } else { collected.out += text } }
    }, finished: { status in
      collected.lock.withLock { collected.status = status }
      done.fulfill()
    })
    self.wait(for: [done], timeout: 10)
    collected.lock.withLock {
      XCTAssertEqual(collected.out, "one\nthree\n")
      XCTAssertEqual(collected.err, "two\n")
      XCTAssertEqual(collected.status, 3)
    }
    XCTAssertFalse(runner.isRunning)
  }

  func testStopEndsALongRun() {
    let runner = ProcessRunner()
    let done = self.expectation(description: "finished")
    let collected = Collected()
    runner.start("/bin/sleep", ["30"], in: "/tmp", output: { _, _ in }, finished: { status in
      collected.lock.withLock { collected.status = status }
      done.fulfill()
    })
    XCTAssertTrue(runner.isRunning)
    runner.stop()
    self.wait(for: [done], timeout: 5)
    XCTAssertEqual(collected.lock.withLock { collected.status }, SIGTERM)
  }

  func testAMissingExecutableFailsAtOnce() {
    let runner = ProcessRunner()
    let collected = Collected()
    runner.start("/no/such/tool", [], in: "/tmp", output: { text, _ in
      collected.lock.withLock { collected.err += text }
    }, finished: { status in collected.lock.withLock { collected.status = status } })
    collected.lock.withLock {
      XCTAssertEqual(collected.status, -1)
      XCTAssertTrue(collected.err.hasPrefix("Could not start /no/such/tool"))
    }
  }

  func testSwiftPMArguments() {
    XCTAssertEqual(SwiftPMBuildService.arguments(for: .build), ["swift", "build"])
    XCTAssertEqual(SwiftPMBuildService.arguments(for: .run(product: "App")), ["swift", "run", "App"])
    XCTAssertEqual(SwiftPMBuildService.arguments(for: .run(product: nil)), ["swift", "run"])
    XCTAssertEqual(SwiftPMBuildService.arguments(for: .test), ["swift", "test"])
  }
}

final class PackageInfoTests: XCTestCase {
  func testExecutablesAreThePackagesExecutableProducts() {
    let json = """
    {"name": "Pkg", "products": [
      {"name": "Tool", "type": {"executable": null}, "targets": ["Tool"]},
      {"name": "Lib", "type": {"library": ["automatic"]}, "targets": ["Lib"]},
      {"name": "App", "type": {"executable": null}, "targets": ["App"]}
    ]}
    """
    XCTAssertEqual(PackageInfo.parse(Data(json.utf8)), PackageInfo(name: "Pkg", executables: ["App", "Tool"]))
    XCTAssertNil(PackageInfo.parse(Data("not json".utf8)))
  }

  func testAFolderWithoutAManifestIsNoPackage() throws {
    let root = try makeFolder(["main.swift": ""], in: self)
    XCTAssertNil(PackageInfo.describe(root.path))
  }
}

final class DirectoryWatcherTests: XCTestCase {
  private final class Paths: @unchecked Sendable {
    let lock = NSLock()
    var all: [String] = []
  }

  func testChangesAreReportedOutsideIgnoredFolders() throws {
    let root = try makeFolder(["Sources/a.swift": "", ".build/x": ""], in: self)
    // A temporary folder is under /var, a link to /private/var, which is what FSEvents reports:
    // paths come back as the watcher was given them.
    let real = root.path
    let paths = Paths()
    let changed = self.expectation(description: "changed")
    changed.assertForOverFulfill = false
    let watcher = try XCTUnwrap(DirectoryWatcher(real, latency: 0.05) { changedPaths in
      paths.lock.withLock { paths.all += changedPaths }
      if changedPaths.contains(real + "/Sources/b.swift") { changed.fulfill() }
    })
    XCTAssertFalse(watcher.isWatched(real + "/.build/debug/x.o"))
    XCTAssertFalse(watcher.isWatched("/elsewhere/a.swift"))
    XCTAssertTrue(watcher.isWatched(real + "/Sources/a.swift"))

    // FSEvents may take a moment to start delivering.
    Thread.sleep(forTimeInterval: 0.3)
    try Data("x".utf8).write(to: root.appendingPathComponent(".build/y"))
    try Data("let b = 1".utf8).write(to: root.appendingPathComponent("Sources/b.swift"))
    self.wait(for: [changed], timeout: 10)
    paths.lock.withLock {
      XCTAssertFalse(paths.all.contains { $0.contains("/.build/") })
    }
    withExtendedLifetime(watcher) {}
  }
}
