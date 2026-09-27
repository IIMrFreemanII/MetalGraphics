import Carbon.HIToolbox
import GameController

extension GCKeyCode {
  /// The key an `NSEvent.keyCode` (a macOS virtual key code, `kVK_*`) names, as the HID usage
  /// `Input` keeps its key state in. Nil for keys outside the table (keypad, media, JIS/ISO).
  ///
  /// Virtual key codes follow the physical ANSI layout, so `kVK_ANSI_Q` is the key in that
  /// position whatever the keyboard layout prints on it — the same meaning a HID usage has.
  public init?(macKeyCode: UInt16) {
    switch Int(macKeyCode) {
    case kVK_ANSI_A: self = .keyA
    case kVK_ANSI_B: self = .keyB
    case kVK_ANSI_C: self = .keyC
    case kVK_ANSI_D: self = .keyD
    case kVK_ANSI_E: self = .keyE
    case kVK_ANSI_F: self = .keyF
    case kVK_ANSI_G: self = .keyG
    case kVK_ANSI_H: self = .keyH
    case kVK_ANSI_I: self = .keyI
    case kVK_ANSI_J: self = .keyJ
    case kVK_ANSI_K: self = .keyK
    case kVK_ANSI_L: self = .keyL
    case kVK_ANSI_M: self = .keyM
    case kVK_ANSI_N: self = .keyN
    case kVK_ANSI_O: self = .keyO
    case kVK_ANSI_P: self = .keyP
    case kVK_ANSI_Q: self = .keyQ
    case kVK_ANSI_R: self = .keyR
    case kVK_ANSI_S: self = .keyS
    case kVK_ANSI_T: self = .keyT
    case kVK_ANSI_U: self = .keyU
    case kVK_ANSI_V: self = .keyV
    case kVK_ANSI_W: self = .keyW
    case kVK_ANSI_X: self = .keyX
    case kVK_ANSI_Y: self = .keyY
    case kVK_ANSI_Z: self = .keyZ

    case kVK_ANSI_1: self = .one
    case kVK_ANSI_2: self = .two
    case kVK_ANSI_3: self = .three
    case kVK_ANSI_4: self = .four
    case kVK_ANSI_5: self = .five
    case kVK_ANSI_6: self = .six
    case kVK_ANSI_7: self = .seven
    case kVK_ANSI_8: self = .eight
    case kVK_ANSI_9: self = .nine
    case kVK_ANSI_0: self = .zero

    case kVK_Return: self = .returnOrEnter
    case kVK_Escape: self = .escape
    case kVK_Delete: self = .deleteOrBackspace
    case kVK_ForwardDelete: self = .deleteForward
    case kVK_Tab: self = .tab
    case kVK_Space: self = .spacebar
    case kVK_CapsLock: self = .capsLock

    case kVK_ANSI_Minus: self = .hyphen
    case kVK_ANSI_Equal: self = .equalSign
    case kVK_ANSI_LeftBracket: self = .openBracket
    case kVK_ANSI_RightBracket: self = .closeBracket
    case kVK_ANSI_Backslash: self = .backslash
    case kVK_ANSI_Semicolon: self = .semicolon
    case kVK_ANSI_Quote: self = .quote
    case kVK_ANSI_Grave: self = .graveAccentAndTilde
    case kVK_ANSI_Comma: self = .comma
    case kVK_ANSI_Period: self = .period
    case kVK_ANSI_Slash: self = .slash

    case kVK_LeftArrow: self = .leftArrow
    case kVK_RightArrow: self = .rightArrow
    case kVK_UpArrow: self = .upArrow
    case kVK_DownArrow: self = .downArrow
    case kVK_Home: self = .home
    case kVK_End: self = .end
    case kVK_PageUp: self = .pageUp
    case kVK_PageDown: self = .pageDown

    case kVK_F1: self = .F1
    case kVK_F2: self = .F2
    case kVK_F3: self = .F3
    case kVK_F4: self = .F4
    case kVK_F5: self = .F5
    case kVK_F6: self = .F6
    case kVK_F7: self = .F7
    case kVK_F8: self = .F8
    case kVK_F9: self = .F9
    case kVK_F10: self = .F10
    case kVK_F11: self = .F11
    case kVK_F12: self = .F12

    case kVK_Command: self = .leftGUI
    case kVK_RightCommand: self = .rightGUI
    case kVK_Shift: self = .leftShift
    case kVK_RightShift: self = .rightShift
    case kVK_Option: self = .leftAlt
    case kVK_RightOption: self = .rightAlt
    case kVK_Control: self = .leftControl
    case kVK_RightControl: self = .rightControl

    default: return nil
    }
  }
}
