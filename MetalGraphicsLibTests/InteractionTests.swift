@testable import MetalGraphicsLib
import simd
import XCTest

@MainActor
final class InteractionTests: XCTestCase {
  /// A 100 x 100 square in the middle of the default 320 x 240 window.
  let center = float2(160, 120)
  let outside = float2(5, 5)

  func testHoverEntersAndLeaves() {
    var events: [Bool] = []
    let h = UIHarness { Rectangle(.red).frame(width: 100, height: 100).onHover { hovered, _ in events.append(hovered) } }
    let hit = h.first(HittableView.self)!

    h.move(to: self.center)
    XCTAssertTrue(hit.isHovered)
    h.move(to: self.outside)
    XCTAssertFalse(hit.isHovered)
    XCTAssertEqual(events, [true, false])
  }

  func testClickOutsideDoesNotTap() {
    var taps = 0
    let h = UIHarness { Rectangle(.red).frame(width: 100, height: 100).onTap { _ in taps += 1 } }
    h.click(at: self.outside)
    XCTAssertEqual(taps, 0)
    h.click(at: self.center)
    XCTAssertEqual(taps, 1)
  }

  func testButtonRunsItsAction() {
    var saved = 0
    let h = UIHarness { Button("Save") { saved += 1 } }
    h.click(on: h.first(HittableView.self)!)
    XCTAssertEqual(saved, 1)
  }

  func testClickWithinOneFrameStillTaps() {
    var taps = 0
    let h = UIHarness { Rectangle(.red).frame(width: 100, height: 100).onTap { _ in taps += 1 } }
    h.clickWithinOneFrame(at: self.center)
    XCTAssertEqual(taps, 1)
  }

  func testClickFocusesTextFieldAndTypingEditsIt() {
    // A field only edits through its binding, as in SwiftUI.
    var name = ""
    let field = TextField("Name", text: Binding(get: { name }, set: { name = $0 }))
    let h = UIHarness { field }
    XCTAssertNil(h.context.focused)

    h.click(on: h.first(FocusableElement.self)!)
    XCTAssertNotNil(h.context.focused)

    h.type("Hi there")
    XCTAssertEqual(name, "Hi there")
    XCTAssertEqual(field.text, "Hi there")
    h.press(.delete)
    XCTAssertEqual(name, "Hi ther")
  }

  func testTabMovesFocusInTreeOrder() {
    var textA = "", textB = ""
    let a = TextField("A", text: Binding(get: { textA }, set: { textA = $0 }))
    let b = TextField("B", text: Binding(get: { textB }, set: { textB = $0 }))
    let h = UIHarness { VStack { a; b } }
    let focusables = h.all(FocusableElement.self)
    XCTAssertEqual(focusables.count, 2)

    h.press(.tab)
    XCTAssertTrue(h.context.focused === focusables[0])
    h.press(.tab)
    XCTAssertTrue(h.context.focused === focusables[1])

    h.type("x")
    XCTAssertEqual(textA, "")
    XCTAssertEqual(textB, "x")
  }

  func testWheelScrollsContent() {
    // An explicit `return` skips the builder, which has no `for`.
    let scroll = ScrollView { VStack { return (0 ..< 20).map { _ in Rectangle(.blue).frame(height: 50) } } }
    let h = UIHarness { scroll }
    XCTAssertEqual(scroll.offset, float2.zero)

    h.scroll(by: float2(0, -120), at: self.center)
    XCTAssertNotEqual(scroll.offset.y, 0)
  }
}
