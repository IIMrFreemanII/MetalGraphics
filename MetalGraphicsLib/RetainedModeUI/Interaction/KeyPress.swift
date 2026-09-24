import AppKit
// For `GCKeyCode`, the key vocabulary `Input` already uses. No GameController input is read.
import GameController

/// A key, by the character it types with no modifiers held, as SwiftUI's `KeyEquivalent`.
///
/// Keys that type nothing — the arrows, home, end, page up and down, forward delete — are
/// AppKit's function-key characters (`NSUpArrowFunctionKey` and the rest), which is what
/// `NSEvent.charactersIgnoringModifiers` reports for them.
public struct KeyEquivalent: Hashable, Sendable, ExpressibleByExtendedGraphemeClusterLiteral {
  public let character: Character

  public init(_ character: Character) {
    self.character = character
  }

  public init(extendedGraphemeClusterLiteral character: Character) {
    self.character = character
  }

  public static let upArrow = KeyEquivalent("\u{F700}")
  public static let downArrow = KeyEquivalent("\u{F701}")
  public static let leftArrow = KeyEquivalent("\u{F702}")
  public static let rightArrow = KeyEquivalent("\u{F703}")
  public static let home = KeyEquivalent("\u{F729}")
  public static let end = KeyEquivalent("\u{F72B}")
  public static let pageUp = KeyEquivalent("\u{F72C}")
  public static let pageDown = KeyEquivalent("\u{F72D}")
  public static let clear = KeyEquivalent("\u{F739}")
  public static let deleteForward = KeyEquivalent("\u{F728}")
  public static let delete = KeyEquivalent("\u{7F}")
  public static let escape = KeyEquivalent("\u{1B}")
  public static let tab = KeyEquivalent("\t")
  public static let space = KeyEquivalent(" ")
  public static let `return` = KeyEquivalent("\r")
}

/// One key event, as `.onKeyPress` handlers receive it. Queued by `MyMTKView` in
/// `Input.keyPresses` and routed by `UIContext` to the focused element and the ones around it.
public struct KeyPress: Sendable {
  public struct Phases: OptionSet, Sendable {
    public let rawValue: UInt8
    public init(rawValue: UInt8) { self.rawValue = rawValue }

    public static let down = Phases(rawValue: 1 << 0)
    /// The key is held and the system auto-repeats it.
    public static let `repeat` = Phases(rawValue: 1 << 1)
    public static let up = Phases(rawValue: 1 << 2)

    public static let all: Phases = [.down, .repeat, .up]
  }

  public enum Result: Sendable {
    /// Stops the press here.
    case handled
    /// Offers the press to the next handler out.
    case ignored
  }

  public let key: KeyEquivalent
  /// What the key types with the modifiers held, e.g. "A" for shift-a. Empty for a key that
  /// types nothing.
  public let characters: String
  public let modifiers: NSEvent.ModifierFlags
  /// A single phase.
  public let phase: Phases
  /// The physical key, whatever the keyboard layout prints on it: WASD stays where it is on
  /// AZERTY. Nil for keys outside `GCKeyCode(macKeyCode:)`'s table.
  public let keyCode: GCKeyCode?

  public init(
    key: KeyEquivalent, characters: String, modifiers: NSEvent.ModifierFlags = [], phase: Phases,
    keyCode: GCKeyCode? = nil
  ) {
    self.key = key
    self.characters = characters
    self.modifiers = modifiers
    self.phase = phase
    self.keyCode = keyCode
  }
}

/// Offers key presses that reach it to `action`. Made by `.onKeyPress`.
///
/// A press reaches it when the focused element is inside it, or, with nothing focused, when no
/// focusable element is around it. See `UIContext.dispatchKeys(_:)`.
public final class KeyPressElement : SingleChildElement {
  private let keys: Set<KeyEquivalent>?
  private let characters: CharacterSet?
  private let phases: KeyPress.Phases

  /// Settable, and cleared while unmounted, like a `HittableView`'s handlers.
  public var action: ((KeyPress) -> KeyPress.Result)?

  public init(
    keys: Set<KeyEquivalent>? = nil, characters: CharacterSet? = nil, phases: KeyPress.Phases,
    action: ((KeyPress) -> KeyPress.Result)?, @UIElementBuilder content: () -> [UIElement]
  ) {
    self.keys = keys
    self.characters = characters
    self.phases = phases
    self.action = action
    super.init()
    self.applyContent(content())
  }

  /// `@Component` assigns `action` through these, so a handler written with no parameter fits
  /// it as well as one that takes the press.
  public static func adapt(_ action: @escaping () -> KeyPress.Result) -> (KeyPress) -> KeyPress.Result {
    { _ in action() }
  }

  public static func adapt(_ action: @escaping (KeyPress) -> KeyPress.Result) -> (KeyPress) -> KeyPress.Result {
    action
  }

  public override func mount(_ context: UIContext) {
    context.registerKeyHandler(self)
  }

  public override func unmount(_ context: UIContext) {
    context.unregisterKeyHandler(self)
  }

  func handle(_ press: KeyPress) -> KeyPress.Result {
    guard let action = self.action, self.phases.contains(press.phase) else { return .ignored }
    if let keys = self.keys, !keys.contains(press.key) { return .ignored }
    if let characters = self.characters {
      // A key that types nothing matches no character set.
      guard !press.characters.isEmpty,
            press.characters.unicodeScalars.allSatisfy({ characters.contains($0) })
      else { return .ignored }
    }
    return action(press)
  }
}

extension UIElementWrapping where Self: UIElement {
  /// Calls `action` when `key` goes down or repeats while this element, or something in it, is
  /// focused. `.handled` stops the press; `.ignored` passes it on to the handlers around this one.
  public func onKeyPress(_ key: KeyEquivalent, action: @escaping () -> KeyPress.Result) -> KeyPressElement {
    KeyPressElement(keys: [key], phases: [.down, .repeat], action: KeyPressElement.adapt(action)) {
      self
    }
  }

  public func onKeyPress(
    _ key: KeyEquivalent, phases: KeyPress.Phases = [.down, .repeat],
    action: @escaping (KeyPress) -> KeyPress.Result
  ) -> KeyPressElement {
    KeyPressElement(keys: [key], phases: phases, action: action) {
      self
    }
  }

  public func onKeyPress(
    keys: Set<KeyEquivalent>, phases: KeyPress.Phases = [.down, .repeat],
    action: @escaping (KeyPress) -> KeyPress.Result
  ) -> KeyPressElement {
    KeyPressElement(keys: keys, phases: phases, action: action) {
      self
    }
  }

  /// Only presses whose every typed character is in `characters`.
  public func onKeyPress(
    characters: CharacterSet, phases: KeyPress.Phases = [.down, .repeat],
    action: @escaping (KeyPress) -> KeyPress.Result
  ) -> KeyPressElement {
    KeyPressElement(characters: characters, phases: phases, action: action) {
      self
    }
  }

  /// Every key.
  public func onKeyPress(
    phases: KeyPress.Phases = [.down, .repeat], action: @escaping (KeyPress) -> KeyPress.Result
  ) -> KeyPressElement {
    KeyPressElement(phases: phases, action: action) {
      self
    }
  }
}
