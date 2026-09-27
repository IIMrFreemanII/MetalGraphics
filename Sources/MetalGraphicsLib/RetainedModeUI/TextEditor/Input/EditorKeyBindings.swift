/// The keys an editor understands by itself, as macOS's standard key bindings map them: what a
/// key does when no input method interpreted it first — in a window with no input context, in
/// tests, and for keys typed before the input method knows the editor has focus.
enum EditorKeyBindings {
  static func command(for press: KeyPress) -> EditorCommand? {
    let modifiers = press.modifiers
    let command = modifiers.contains(.command)
    let option = modifiers.contains(.option)
    let control = modifiers.contains(.control)
    let shift = modifiers.contains(.shift)

    switch press.key {
    case .leftArrow, .rightArrow:
      let forward = press.key == .rightArrow
      let motion: TextMotion = command ? .lineBoundary : option ? (control ? .subword : .word) : .character
      return .move(motion, forward: forward, extend: shift)
    case .upArrow, .downArrow:
      let forward = press.key == .downArrow
      let motion: TextMotion = command ? .document : option ? .paragraph : .visualLine
      return .move(motion, forward: forward, extend: shift)
    case .home, .end:
      let forward = press.key == .end
      return shift ? .move(.document, forward: forward, extend: true) : .scrollToDocumentEdge(forward: forward)
    case .pageUp, .pageDown:
      let forward = press.key == .pageDown
      return shift || option ? .move(.page, forward: forward, extend: shift) : .scrollPage(forward: forward)
    case .delete:
      if command { return .delete(.lineBoundary, forward: false) }
      return .delete(option ? .word : .character, forward: false)
    case .deleteForward:
      if command { return .delete(.lineBoundary, forward: true) }
      return .delete(option ? .word : .character, forward: true)
    case .return:
      return control ? .insertLineBreak : .insertNewline
    case .tab:
      if control || command { return nil }
      return shift ? .insertBacktab : .insertTab
    case .escape:
      return .cancel
    default:
      break
    }

    let key = press.key.character.lowercased()
    if command {
      switch key {
      case "a": return .selectAll
      case "c": return .copy
      case "x": return .cut
      case "v": return press.pasteboard.map { .paste($0) }
      case "z": return shift ? .redo : .undo
      case "]": return .indent
      case "[": return .outdent
      case "/": return .toggleComment
      default: return nil
      }
    }
    if control {
      // The Emacs keys every Cocoa text view has.
      switch key {
      case "a": return .move(.paragraphBoundary, forward: false, extend: shift)
      case "e": return .move(.paragraphBoundary, forward: true, extend: shift)
      case "f": return .move(.character, forward: true, extend: shift)
      case "b": return .move(.character, forward: false, extend: shift)
      case "n": return .move(.visualLine, forward: true, extend: shift)
      case "p": return .move(.visualLine, forward: false, extend: shift)
      case "d": return .delete(.character, forward: true)
      case "h": return .delete(.character, forward: false)
      case "k": return .delete(.paragraphBoundary, forward: true)
      case "y": return .yank
      case "t": return .transpose
      case "l": return .centerSelection
      case "v": return .move(.page, forward: true, extend: shift)
      default: return nil
      }
    }
    let typed = Self.typeable(press.characters)
    return typed.isEmpty ? nil : .insertText(typed)
  }

  /// What of `characters` is text: no control characters, no function-key characters.
  static func typeable(_ characters: String) -> String {
    let scalars = characters.unicodeScalars.filter { scalar in
      scalar.value >= 0x20 && scalar.value != 0x7F && !(0xF700 ... 0xF8FF).contains(scalar.value)
    }
    return scalars.count == characters.unicodeScalars.count ? characters : String(String.UnicodeScalarView(scalars))
  }
}
