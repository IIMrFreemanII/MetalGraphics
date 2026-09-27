import AppKit
import simd
import MetalGraphicsLib
import ReactiveUI

// Focus and key presses, as in SwiftUI.
//
// - A click on a box focuses it; a click anywhere else takes focus away. Tab and Shift-Tab move
//   focus between the boxes, in tree order.
// - Each box shows its focus from `onFocusChange`, through state: focus draws nothing itself.
// - The pad moves its dot with the arrow keys; the field collects what is typed, and Delete
//   takes it back. Each handles only its own keys.
// - A press nothing inside handles goes on out: Escape reaches the handler around both boxes,
//   which clears focus through `.focused(false)`, and the last one logs every press that got
//   that far — Tab included, which then moves focus because nothing handled it.
// - "Focus the field" focuses it from a tap, through `.focused(true)`.
@Component
final class KeyboardDemo : SingleChildElement {
  private static let captionFont = TextFont.system(size: 12)
  private static let captionColor = float4(0.45, 0.45, 0.45, 1)
  private static let labelFont = TextFont.system(size: 14)
  private static let buttonInset = Inset(vertical: 4, horizontal: 8)
  private static let buttonColor = float4(0.25, 0.25, 0.25, 1)
  private static let idleColor = float4(0.9, 0.9, 0.9, 1)
  private static let focusedColor = float4(0.78, 0.86, 1, 1)
  private static let dotColor = float4(0.2, 0.45, 0.95, 1)
  private static let arrows: Set<KeyEquivalent> = [.upArrow, .downArrow, .leftArrow, .rightArrow]
  private static let typeable = CharacterSet.alphanumerics.union(.punctuationCharacters)
    .union(.symbols).union(.whitespaces)
  private static let padSize: Float = 200
  private static let dotSize: Float = 16
  private static let step: Float = 10

  @State var dot: float2 = .zero
  @State var padFocused: Bool = false
  @State var typed: String = ""
  @State var fieldFocused: Bool = false
  @State var unhandled: String = "none yet"

  @UIElementBuilder var body: [UIElement] {
    VStack(alignment: .leading, spacing: 12) {
      Text("Click a box or press Tab to focus it. Escape clears focus.")
        .font(Self.captionFont)
        .foregroundColor(Self.captionColor)
      HStack(alignment: .top, spacing: 24) {
        Rectangle(Self.dotColor)
          .frame(width: Self.dotSize, height: Self.dotSize)
          .offset(self.dot)
          .frame(width: Self.padSize, height: Self.padSize)
          .background(self.padFocused ? Self.focusedColor : Self.idleColor)
          .focusable()
          .focused(self.padFocused)
          .onFocusChange { self.padFocused = $0 }
          .onKeyPress(keys: Self.arrows) { press in
            self.move(press.key)
            return .handled
          }
        Text(self.typed.isEmpty ? "Type here" : self.typed)
          .font(Self.labelFont)
          .padding(12)
          .frame(width: 240, height: Self.padSize, alignment: .topLeading)
          .background(self.fieldFocused ? Self.focusedColor : Self.idleColor)
          .focusable()
          .focused(self.fieldFocused)
          .onFocusChange { self.fieldFocused = $0 }
          .onKeyPress(.delete) {
            if !self.typed.isEmpty {
              self.typed.removeLast()
            }
            return .handled
          }
          .onKeyPress(characters: Self.typeable) { press in
            self.typed += press.characters
            return .handled
          }
      }
      Text("Focus the field")
        .font(Self.captionFont)
        .foregroundColor(.white)
        .padding(Self.buttonInset)
        .background(Self.buttonColor)
        .onTap { _ in self.fieldFocused = true }
      Text("Last press nothing inside handled: \(self.unhandled)")
        .font(Self.captionFont)
        .foregroundColor(Self.captionColor)
    }
    .onKeyPress(.escape) {
      self.padFocused = false
      self.fieldFocused = false
      return .handled
    }
    .onKeyPress(phases: .down) { press in
      self.unhandled = Self.name(press)
      return .ignored
    }
  }

  // MARK: - Actions

  func move(_ key: KeyEquivalent) {
    var dot = self.dot
    switch key {
    case .upArrow: dot.y -= Self.step
    case .downArrow: dot.y += Self.step
    case .leftArrow: dot.x -= Self.step
    default: dot.x += Self.step
    }
    let limit = (Self.padSize - Self.dotSize) * 0.5
    self.dot = simd_clamp(dot, float2(repeating: -limit), float2(repeating: limit))
  }

  private static func name(_ press: KeyPress) -> String {
    let name = switch press.key {
    case .tab: "Tab"
    case .return: "Return"
    case .escape: "Escape"
    case .space: "Space"
    case .delete: "Delete"
    case .upArrow: "↑"
    case .downArrow: "↓"
    case .leftArrow: "←"
    case .rightArrow: "→"
    default: press.characters
    }
    return press.modifiers.contains(.shift) ? "Shift-\(name)" : name
  }
}
