@testable import MetalGraphicsLib
import simd
import XCTest

@MainActor
final class ButtonTests: XCTestCase {
  private func center(_ hit: any Hittable) -> float2 {
    hit.hitPosition + hit.hitSize * 0.5
  }

  // MARK: - Labels

  func testLabelButtonRunsItsAction() {
    var taps = 0
    let h = UIHarness {
      Button(action: { taps += 1 }) {
        Rectangle(.red).frame(width: 12, height: 12)
        Text("Close")
      }
    }
    h.click(on: h.first(HittableView.self)!)
    XCTAssertEqual(taps, 1)
  }

  func testDisabledLabelButtonDoesNothing() {
    var taps = 0
    let h = UIHarness { Button(action: { taps += 1 }) { Text("Close") }.disabled(true) }
    h.click(on: h.first(HittableView.self)!)
    XCTAssertEqual(taps, 0)
  }

  func testLabelTextTakesTheStyleUnlessColoredOnPurpose() {
    let plain = Text("Plain")
    let red = Text("Red").foregroundColor(.red)
    let nested = Text("Nested")
    let button = Button(action: {}) { plain; red; VStack { nested } }
    let h = UIHarness { button }
    h.settle()
    XCTAssertEqual(plain.displayedColor, FormMetrics.accentColor)
    XCTAssertEqual(plain.font.size, FormMetrics.font.size)
    XCTAssertEqual(red.displayedColor, .red)
    // A text deeper in the label is styled too.
    XCTAssertEqual(nested.displayedColor, FormMetrics.accentColor)
    XCTAssertEqual(nested.font, FormMetrics.font)

    button.setButtonStyle(.borderedProminent, h.context)
    h.settle()
    XCTAssertEqual(plain.displayedColor, float4(1, 1, 1, 1))
    XCTAssertEqual(red.displayedColor, .red)
  }

  func testAnimatedStyleChangeFadesTheLabelWithoutRelayout() {
    let text = Text("Go")
    let button = Button(action: {}) { text }
    let h = UIHarness { button }
    h.settle()
    button.setButtonStyle(.plain, h.context, animation: .linear(1))
    // The face relayouts once for the new style; the colour then only redraws.
    h.step()
    let generation = LayoutPass.generation
    h.advance(0.5)
    let midway = text.displayedColor
    XCTAssertNotEqual(midway, FormMetrics.accentColor)
    XCTAssertNotEqual(midway, FormMetrics.labelColor)
    XCTAssertNotNil(h.settle())
    XCTAssertEqual(text.displayedColor, FormMetrics.labelColor)
    // Only the colour changed: redrawn every frame, never laid out again.
    XCTAssertEqual(LayoutPass.generation, generation)
  }

  func testFontAroundTheButtonReachesItsLabel() {
    let text = Text("Big")
    let h = UIHarness { Button(action: {}) { text }.font(.title) }
    h.settle()
    XCTAssertEqual(text.font, .title)
  }

  func testReplacedLabelIsStyled() {
    let button = Button().buttonStyle(.plain)
    let h = UIHarness { button }
    let text = Text("Later")
    button.replaceChildren([text], h.context)
    h.settle()
    XCTAssertEqual(text.displayedColor, FormMetrics.labelColor)
    XCTAssertGreaterThan(h.first(HittableView.self)!.hitSize.x, 0)
  }

  // MARK: - Styles

  func testBorderedPressDarkensTheFaceNotTheLabel() {
    let h = UIHarness { Button("Go").buttonStyle(.bordered) }
    let face = h.first(ButtonFace.self)!
    let press = h.all(EffectElement.self).last!
    let point = self.center(h.first(HittableView.self)!)
    h.mouseDown(at: point)
    XCTAssertTrue(face.isPressed)
    XCTAssertEqual(press.opacity, 1)
    h.mouseUp(at: point)
    XCTAssertFalse(face.isPressed)
  }

  func testTextStylePressDimsTheLabel() {
    let h = UIHarness { Button("Go") }
    let face = h.first(ButtonFace.self)!
    let press = h.all(EffectElement.self).last!
    let point = self.center(h.first(HittableView.self)!)
    h.mouseDown(at: point)
    XCTAssertFalse(face.isPressed)
    XCTAssertLessThan(press.opacity, 1)
    h.mouseUp(at: point)
    XCTAssertEqual(press.opacity, 1)
  }

  func testBorderedStyleInsetsTheLabel() {
    let text = Text("Go")
    let button = Button { text }
    let h = UIHarness { button }
    h.settle()
    let plainSize = h.first(HittableView.self)!.hitSize
    button.setButtonStyle(.bordered, h.context)
    h.settle()
    let borderedSize = h.first(HittableView.self)!.hitSize
    XCTAssertEqual(borderedSize.x, plainSize.x + 20, accuracy: 0.01)
    XCTAssertEqual(borderedSize.y, plainSize.y + 6, accuracy: 0.01)
  }

  // MARK: - Snapshots

  func testStyles() {
    let h = UIHarness(size: float2(320, 240)) {
      VStack(alignment: .leading, spacing: 10) {
        Button("Automatic")
        Button("Plain").buttonStyle(.plain)
        Button("Bordered").buttonStyle(.bordered)
        Button("Prominent").buttonStyle(.borderedProminent)
        Button("Delete", role: .destructive).buttonStyle(.borderedProminent)
        Button(action: {}) {
          Rectangle(.red).frame(width: 10, height: 10).cornerRadius(5)
          Text("Label")
        }
        .buttonStyle(.bordered)
      }
      .padding(16)
      .frame(width: 320, height: 240, alignment: .topLeading)
      .background(float4(1, 1, 1, 1))
    }
    h.settle()
    assertSnapshot(h.snapshot(), named: "button-styles", testCase: self)
  }
}
