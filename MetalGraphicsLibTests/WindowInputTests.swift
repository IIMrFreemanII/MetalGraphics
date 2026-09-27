import AppKit
import GameController
@testable import MetalGraphicsLib
import simd
import XCTest

@MainActor
final class WindowInputTests: XCTestCase {
  private func key(_ type: NSEvent.EventType, _ characters: String, code: UInt16) -> NSEvent {
    NSEvent.keyEvent(
      with: type, location: .zero, modifierFlags: [], timestamp: 0, windowNumber: 0, context: nil,
      characters: characters, charactersIgnoringModifiers: characters, isARepeat: false, keyCode: code
    )!
  }

  /// A view whose handle's thread is never started: events queue up for `apply(_:to:)`.
  private func view() -> RetainedLayerView {
    RetainedLayerView(handle: WindowHandle(name: "test"))
  }

  /// What the window's next frame does first.
  private func apply(_ view: RetainedLayerView, to input: Input) {
    var events: [InputEvent] = []
    view.handle.takeEvents(into: &events)
    events.forEach(input.apply)
  }

  // Keys and buttons held when another window takes key get their ups there, never here.
  func testResigningKeyReleasesEverythingHeld() {
    let view = self.view()
    let input = Input()
    input.windowSize = float2(200, 100)
    view.keyDown(with: self.key(.keyDown, "a", code: 0))
    self.apply(view, to: input)
    input.endFrame()
    input.leftMousePressed = true
    input.isPointerInView = true
    input.mousePosition = float2(50, 50)
    input.prevMousePosition = float2(50, 50)

    view.windowDidResignKey()
    self.apply(view, to: input)

    XCTAssertFalse(input.isWindowKey)
    XCTAssertTrue(input.keysPressed.isEmpty)
    XCTAssertTrue(input.keysUp.contains(.keyA))
    XCTAssertEqual(input.keyPresses.last?.phase, .up)
    XCTAssertFalse(input.leftMousePressed)
    XCTAssertTrue(input.leftMouseUp)
    XCTAssertFalse(input.isPointerInView)
    XCTAssertEqual(input.mousePosition, float2(repeating: -1_000_000))
  }

  /// Events reach the window's thread in the order the view saw them, and only when it takes them.
  func testEventsQueueInOrderUntilTaken() {
    let view = self.view()
    view.keyDown(with: self.key(.keyDown, "a", code: 0))
    view.keyUp(with: self.key(.keyUp, "a", code: 0))
    let input = Input()
    XCTAssertTrue(input.keyPresses.isEmpty)

    self.apply(view, to: input)
    XCTAssertEqual(input.keyPresses.map(\.phase), [.down, .up])
    self.apply(view, to: input)
    XCTAssertEqual(input.keyPresses.count, 2)
  }

  /// ⌘V pastes what the view read from the pasteboard with the key, on the main thread.
  func testPasteInsertsWhatTheKeyCarried() {
    var text = "ab"
    let field = TextField("Name", text: Binding(get: { text }, set: { text = $0 }))
    let h = UIHarness { field }
    h.click(on: h.first(FocusableElement.self)!)
    h.input.apply(.keyDown(InputEvent.Key(
      keyCode: 9, characters: "v", charactersIgnoringModifiers: "v", modifiers: .command, pasteboard: "cd"
    )))
    h.step()
    XCTAssertEqual(text, "abcd")
  }

  func testRegistryHoldsWindowsWeakly() {
    var handle: WindowHandle? = WindowHandle(name: "test")
    WindowRegistry.add(handle!)
    XCTAssertTrue(WindowRegistry.live.contains { $0 === handle })

    let before = WindowRegistry.live.count
    handle = nil
    XCTAssertEqual(WindowRegistry.live.count, before - 1)
  }
}
