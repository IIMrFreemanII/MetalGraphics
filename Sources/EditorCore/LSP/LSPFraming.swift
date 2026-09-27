import Foundation

/// The language server protocol's framing: each message is a `Content-Length: n` header, a blank
/// line, and `n` bytes of JSON.
public enum LSPFraming {
  public static func encode(_ message: JSON) -> Data {
    let body = message.data
    var data = Data("Content-Length: \(body.count)\r\n\r\n".utf8)
    data.append(body)
    return data
  }
}

/// Collects bytes as they arrive from a server, split anywhere, and hands back whole messages.
public struct LSPFrameParser: Sendable {
  private var buffer = Data()

  public init() {}

  /// Adds `data`, and returns the messages it completes, in order. A message that is not JSON is
  /// skipped.
  public mutating func append(_ data: Data) -> [JSON] {
    self.buffer.append(data)
    var messages: [JSON] = []
    while let message = self.next() {
      if let json = message { messages.append(json) }
    }
    return messages
  }

  /// The next whole message (nil inside when it is not JSON), or nil when none is complete yet.
  private mutating func next() -> JSON?? {
    let separator = Data("\r\n\r\n".utf8)
    guard let headerEnd = self.buffer.range(of: separator) else { return nil }
    let header = String(decoding: self.buffer[self.buffer.startIndex ..< headerEnd.lowerBound], as: UTF8.self)
    var length: Int? = nil
    for line in header.split(separator: "\r\n") {
      let parts = line.split(separator: ":", maxSplits: 1)
      if parts.count == 2, parts[0].lowercased() == "content-length" {
        length = Int(parts[1].trimmingCharacters(in: .whitespaces))
      }
    }
    guard let length else {
      // No length: the header is broken. Drop it, and look for the next.
      self.buffer.removeSubrange(self.buffer.startIndex ..< headerEnd.upperBound)
      return .some(nil)
    }
    let bodyStart = headerEnd.upperBound
    guard self.buffer.distance(from: bodyStart, to: self.buffer.endIndex) >= length else { return nil }
    let bodyEnd = self.buffer.index(bodyStart, offsetBy: length)
    let body = self.buffer[bodyStart ..< bodyEnd]
    let json = JSON(data: Data(body))
    self.buffer.removeSubrange(self.buffer.startIndex ..< bodyEnd)
    // Keeps indices from zero, so the buffer does not grow its start forever.
    self.buffer = Data(self.buffer)
    return .some(json)
  }
}
