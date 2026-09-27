import Foundation

/// What one build or run printed, shared by every window: output arrives from a process's pipes
/// on their own queues, and each console pulls what it has not shown yet. Lines are parsed for
/// compiler diagnostics as they complete.
///
/// Everything is behind one lock, held only to append or copy.
public final class BuildLog: @unchecked Sendable {
  public struct Chunk: Sendable, Equatable {
    public let text: String
    /// From standard error.
    public let isError: Bool

    public init(_ text: String, isError: Bool = false) {
      self.text = text
      self.isError = isError
    }
  }

  private let lock = NSLock()
  private var storedChunks: [Chunk] = []
  private var storedDiagnostics: [CompilerDiagnostic] = []
  private var seen: Set<String> = []
  /// Each stream's line so far, until its newline arrives.
  private var partial: [Bool: String] = [:]
  private var storedGeneration = 0

  public init() {}

  /// Moves on with every `reset`: a console that showed an older generation starts over.
  public var generation: Int {
    self.lock.withLock { self.storedGeneration }
  }

  /// Forgets everything, for the next build.
  public func reset() {
    self.lock.withLock {
      self.storedChunks = []
      self.storedDiagnostics = []
      self.seen = []
      self.partial = [:]
      self.storedGeneration += 1
    }
  }

  /// Adds output, from any thread. Terminal escape codes (the compiler colours its output
  /// whatever `TERM` says) are taken out.
  public func append(_ text: String, isError: Bool = false) {
    let text = Self.strippingEscapes(text)
    guard !text.isEmpty else { return }
    self.lock.withLock {
      self.storedChunks.append(Chunk(text, isError: isError))
      var pending = (self.partial[isError] ?? "") + text
      while let newline = pending.firstIndex(of: "\n") {
        self.take(line: String(pending[..<newline]))
        pending = String(pending[pending.index(after: newline)...])
      }
      self.partial[isError] = pending
    }
  }

  /// Parses the lines left unfinished, as a process ends.
  public func finish() {
    self.lock.withLock {
      for (_, line) in self.partial where !line.isEmpty {
        self.take(line: line)
      }
      self.partial = [:]
    }
  }

  /// `text` without ANSI escape sequences: `ESC [ … letter` (colours, bold), `ESC ( x`, and
  /// other `ESC x` pairs. Text without an escape is returned as it is.
  public static func strippingEscapes(_ text: String) -> String {
    guard text.utf8.contains(0x1B) else { return text }
    var out: [UInt8] = []
    out.reserveCapacity(text.utf8.count)
    var bytes = text.utf8.makeIterator()
    while let byte = bytes.next() {
      guard byte == 0x1B else {
        out.append(byte)
        continue
      }
      guard let next = bytes.next() else { break }
      // ESC ( B and ESC ) B pick a character set: three bytes.
      if next == 0x28 || next == 0x29 {
        _ = bytes.next()
        continue
      }
      guard next == 0x5B else { continue }  // ESC x: two bytes, both dropped.
      // A control sequence: parameters and intermediates, up to a final byte @ … ~.
      while let byte = bytes.next(), !(0x40 ... 0x7E).contains(byte) {}
    }
    return String(decoding: out, as: UTF8.self)
  }

  /// Under the lock.
  private func take(line: String) {
    guard let diagnostic = CompilerDiagnosticParser.parse(line), self.seen.insert(diagnostic.id).inserted else { return }
    self.storedDiagnostics.append(diagnostic)
  }

  /// The chunks from `index` on, and the index to ask from next time.
  public func chunks(from index: Int) -> (chunks: [Chunk], next: Int) {
    self.lock.withLock {
      let start = min(index, self.storedChunks.count)
      return (Array(self.storedChunks[start...]), self.storedChunks.count)
    }
  }

  /// Every diagnostic so far, each once, in the order printed.
  public var diagnostics: [CompilerDiagnostic] {
    self.lock.withLock { self.storedDiagnostics }
  }

  /// The diagnostics in the file at `path`.
  public func diagnostics(inFile path: String) -> [CompilerDiagnostic] {
    self.lock.withLock { self.storedDiagnostics.filter { $0.path == path } }
  }
}
