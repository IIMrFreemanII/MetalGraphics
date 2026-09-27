import Foundation

/// A JSON value: what language server messages are made of. Built and read by hand, so the
/// client needs no Codable type for each of the protocol's many shapes, and stays `Sendable`.
public enum JSON: Sendable, Hashable {
  case null
  case bool(Bool)
  case number(Double)
  case string(String)
  case array([JSON])
  case object([String: JSON])

  // MARK: - Reading

  public subscript(key: String) -> JSON? {
    if case .object(let object) = self { return object[key] }
    return nil
  }

  public subscript(index: Int) -> JSON? {
    if case .array(let array) = self, array.indices.contains(index) { return array[index] }
    return nil
  }

  public var string: String? {
    if case .string(let value) = self { return value }
    return nil
  }

  public var int: Int? {
    if case .number(let value) = self { return Int(exactly: value.rounded()) }
    return nil
  }

  public var bool: Bool? {
    if case .bool(let value) = self { return value }
    return nil
  }

  public var array: [JSON]? {
    if case .array(let value) = self { return value }
    return nil
  }

  public var object: [String: JSON]? {
    if case .object(let value) = self { return value }
    return nil
  }

  public var isNull: Bool {
    if case .null = self { return true }
    return false
  }

  // MARK: - Data

  /// Parses `data`; nil when it is not JSON.
  public init?(data: Data) {
    guard let object = try? JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed]) else { return nil }
    self.init(any: object)
  }

  private init(any: Any) {
    switch any {
    case let number as NSNumber:
      // Booleans come as NSNumber too; CFBoolean tells them apart.
      if CFGetTypeID(number) == CFBooleanGetTypeID() {
        self = .bool(number.boolValue)
      } else {
        self = .number(number.doubleValue)
      }
    case let string as String:
      self = .string(string)
    case let array as [Any]:
      self = .array(array.map(JSON.init(any:)))
    case let object as [String: Any]:
      self = .object(object.mapValues(JSON.init(any:)))
    default:
      self = .null
    }
  }

  /// Compact JSON, keys sorted so the same value always encodes the same.
  public var data: Data {
    var out = ""
    self.write(to: &out)
    return Data(out.utf8)
  }

  private func write(to out: inout String) {
    switch self {
    case .null:
      out += "null"
    case .bool(let value):
      out += value ? "true" : "false"
    case .number(let value):
      if value == value.rounded(), abs(value) < 1e15 {
        out += String(Int64(value))
      } else {
        out += "\(value)"
      }
    case .string(let value):
      Self.writeString(value, to: &out)
    case .array(let values):
      out += "["
      for (index, value) in values.enumerated() {
        if index > 0 { out += "," }
        value.write(to: &out)
      }
      out += "]"
    case .object(let values):
      out += "{"
      for (index, key) in values.keys.sorted().enumerated() {
        if index > 0 { out += "," }
        Self.writeString(key, to: &out)
        out += ":"
        values[key]!.write(to: &out)
      }
      out += "}"
    }
  }

  private static func writeString(_ value: String, to out: inout String) {
    out += "\""
    for scalar in value.unicodeScalars {
      switch scalar {
      case "\"": out += "\\\""
      case "\\": out += "\\\\"
      case "\n": out += "\\n"
      case "\r": out += "\\r"
      case "\t": out += "\\t"
      case let control where control.value < 0x20:
        out += String(format: "\\u%04x", control.value)
      default:
        out.unicodeScalars.append(scalar)
      }
    }
    out += "\""
  }
}

extension JSON: ExpressibleByStringLiteral, ExpressibleByIntegerLiteral, ExpressibleByBooleanLiteral,
  ExpressibleByArrayLiteral, ExpressibleByDictionaryLiteral, ExpressibleByNilLiteral {
  public init(stringLiteral value: String) { self = .string(value) }
  public init(integerLiteral value: Int) { self = .number(Double(value)) }
  public init(booleanLiteral value: Bool) { self = .bool(value) }
  public init(arrayLiteral elements: JSON...) { self = .array(elements) }
  public init(dictionaryLiteral elements: (String, JSON)...) {
    self = .object(Dictionary(elements, uniquingKeysWith: { _, last in last }))
  }
  public init(nilLiteral: ()) { self = .null }
}
