import Foundation

public enum TextFileError: Error, Equatable, CustomStringConvertible {
  /// Not text: it has NUL bytes, as images and binaries do.
  case binary
  case unreadable(String)
  case unwritable(String)

  public var description: String {
    switch self {
    case .binary: "Not a text file"
    case .unreadable(let reason): "Could not read the file: \(reason)"
    case .unwritable(let reason): "Could not save the file: \(reason)"
    }
  }
}

/// A text file's contents, and how to write them back the way they came.
public struct TextFileContents: Sendable, Equatable {
  public var text: String
  public var encoding: String.Encoding
  /// Whether it started with a byte order mark, written back when saved.
  public var hasBOM: Bool

  public init(text: String, encoding: String.Encoding = .utf8, hasBOM: Bool = false) {
    self.text = text
    self.encoding = encoding
    self.hasBOM = hasBOM
  }
}

/// Reads and writes source files: UTF-8 unless a byte order mark says UTF-16, Latin-1 for bytes
/// that are not UTF-8, and nothing that looks binary. Line endings are left as they are; the
/// editor's `TextDocument` converts and remembers them.
public enum TextFileIO {
  /// The first bytes looked at for a NUL.
  static let sniffLength = 8000

  public static func read(_ url: URL) throws -> TextFileContents {
    let data: Data
    do {
      data = try Data(contentsOf: url)
    } catch {
      throw TextFileError.unreadable(error.localizedDescription)
    }
    return try self.decode(data)
  }

  public static func decode(_ data: Data) throws -> TextFileContents {
    let bytes = [UInt8](data.prefix(4))
    if bytes.starts(with: [0xEF, 0xBB, 0xBF]) {
      return TextFileContents(text: String(decoding: data.dropFirst(3), as: UTF8.self), encoding: .utf8, hasBOM: true)
    }
    if bytes.starts(with: [0xFF, 0xFE]) || bytes.starts(with: [0xFE, 0xFF]) {
      let encoding: String.Encoding = bytes[0] == 0xFF ? .utf16LittleEndian : .utf16BigEndian
      guard let text = String(data: data.dropFirst(2), encoding: encoding) else {
        throw TextFileError.unreadable("invalid UTF-16")
      }
      return TextFileContents(text: text, encoding: encoding, hasBOM: true)
    }
    if data.prefix(self.sniffLength).contains(0) {
      throw TextFileError.binary
    }
    if let text = String(data: data, encoding: .utf8) {
      return TextFileContents(text: text, encoding: .utf8)
    }
    // Every byte is some Latin-1 character, so this never fails.
    return TextFileContents(text: String(decoding: data.map { UInt16($0) }, as: UTF16.self), encoding: .isoLatin1)
  }

  public static func encode(_ contents: TextFileContents) throws -> Data {
    var data = Data()
    if contents.hasBOM {
      switch contents.encoding {
      case .utf16LittleEndian: data.append(contentsOf: [0xFF, 0xFE])
      case .utf16BigEndian: data.append(contentsOf: [0xFE, 0xFF])
      default: data.append(contentsOf: [0xEF, 0xBB, 0xBF])
      }
    }
    guard let body = contents.text.data(using: contents.encoding) else {
      throw TextFileError.unwritable("the text has characters \(contents.encoding) cannot hold")
    }
    data.append(body)
    return data
  }

  /// Writes `contents` to `url` atomically: a crash mid-write leaves the old file.
  public static func write(_ contents: TextFileContents, to url: URL) throws {
    let data = try self.encode(contents)
    do {
      try data.write(to: url, options: .atomic)
    } catch {
      throw TextFileError.unwritable(error.localizedDescription)
    }
  }
}
