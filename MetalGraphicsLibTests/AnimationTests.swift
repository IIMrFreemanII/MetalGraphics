@testable import MetalGraphicsLib
import simd
import XCTest

@MainActor
final class AnimationTests: XCTestCase {
  func testLinearOpacityStepsThenSettles() {
    let effect = EffectElement(opacity: 1) { Rectangle(.red).frame(width: 100, height: 100) }
    let h = UIHarness { effect }
    var completions = 0

    withAnimation(.linear(0.5)) {
      effect.setOpacity(0, h.context, animation: UITransaction.animation)
    } completion: {
      completions += 1
    }

    h.advance(0.25)
    XCTAssertEqual(effect.opacity, 0.5, accuracy: 0.05)
    XCTAssertEqual(completions, 0)

    XCTAssertNotNil(h.settle())
    XCTAssertEqual(effect.opacity, 0)
    XCTAssertEqual(completions, 1)
  }

  func testIdleTreeStopsDrawing() {
    let h = UIHarness { Button("Idle") }
    XCTAssertNotNil(h.settle())
    let renders = h.renders
    h.step(frames: 30)
    XCTAssertEqual(h.renders, renders, "an idle tree must not redraw")
  }

  func testFrameSizeSpringArrives() {
    let frame = Rectangle(.blue).frame(width: 40, height: 40)
    let h = UIHarness { frame }
    frame.setWidth(120, h.context, animation: .spring())
    h.step()
    XCTAssertGreaterThan(frame.getSize().x, 40)
    XCTAssertNotNil(h.settle())
    XCTAssertEqual(frame.getSize().x, 120, accuracy: 0.01)
  }
}
