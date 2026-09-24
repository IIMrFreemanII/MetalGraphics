import Foundation

/// The Swift 6.4 compiler ends a plugin session with a zero-length message. swift-syntax 602's
/// message loop decodes it as JSON, prints `Internal Error: … Underlying error: unexpected end of
/// file` and exits 1 after every compile. The build does not care, but InjectionNext counts any
/// `error: ` in compiler output as a failed compile, so no file using the macros could be injected.
///
/// This forwards stdin to the loop through a pipe and turns the zero-length message into a clean
/// end of input. Remove it once swift-syntax is bumped past 602 (see Package.swift).
enum StdinFilter {
  static func install() {
    let source = dup(STDIN_FILENO)
    var fds: [Int32] = [0, 0]
    // On any failure the loop keeps reading the real stdin: noisy, but correct.
    guard source >= 0, pipe(&fds) == 0, dup2(fds[0], STDIN_FILENO) >= 0 else { return }
    close(fds[0])
    let sink = fds[1]

    Thread.detachNewThread {
      defer { close(sink) }
      // Each message is an 8-byte little-endian length, then that many bytes of JSON.
      while let header = readExactly(source, count: 8) {
        let size = header.withUnsafeBytes { UInt64(littleEndian: $0.loadUnaligned(as: UInt64.self)) }
        guard size > 0, let body = readExactly(source, count: Int(size)),
              writeAll(sink, header), writeAll(sink, body)
        else { return }
      }
    }
  }

  /// `nil` at end of input, including input that ends partway through.
  private static func readExactly(_ fd: Int32, count: Int) -> [UInt8]? {
    var buffer = [UInt8](repeating: 0, count: count)
    var filled = 0
    while filled < count {
      let n = buffer.withUnsafeMutableBytes { read(fd, $0.baseAddress! + filled, count - filled) }
      if n < 0 && errno == EINTR { continue }
      guard n > 0 else { return nil }
      filled += n
    }
    return buffer
  }

  private static func writeAll(_ fd: Int32, _ bytes: [UInt8]) -> Bool {
    var written = 0
    while written < bytes.count {
      let n = bytes.withUnsafeBytes { write(fd, $0.baseAddress! + written, bytes.count - written) }
      if n < 0 && errno == EINTR { continue }
      guard n > 0 else { return false }
      written += n
    }
    return true
  }
}
