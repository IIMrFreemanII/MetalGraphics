@testable import MetalGraphicsLib
import simd
import XCTest

@MainActor
final class SnapshotTests: XCTestCase {
  private func card(_ swatch: Rectangle) -> UIElement {
    VStack(spacing: 12) {
      swatch.frame(width: 120, height: 48).cornerRadius(10)
        .onHover { hovered, _ in }
      Text("Headless")
      Button("Save")
    }
    .padding(16)
    .background(float4(1, 1, 1, 1))
  }

  func testCard() {
    let swatch = Rectangle(.blue)
    let h = UIHarness(size: float2(320, 240)) { self.card(swatch) }
    h.settle()
    assertSnapshot(h.snapshot(), named: "card", testCase: self)
  }

  func testCardHovered() {
    let swatch = Rectangle(.blue)
    let h = UIHarness(size: float2(320, 240)) { self.card(swatch) }
    let hit = h.first(HittableView.self)!
    hit.onHover = { hovered, _ in swatch.setColor(hovered ? .red : .blue, h.context, animation: .linear(0.2)) }

    h.move(to: hit.hitPosition + hit.hitSize * 0.5)
    h.settle()
    assertSnapshot(h.snapshot(), named: "card-hovered", testCase: self)
    // Pixels read back directly, not only through the golden.
    let p = h.pixel(at: hit.hitPosition + hit.hitSize * 0.5)
    XCTAssertGreaterThan(p.x, 200, "swatch should be red once hovered, got \(p)")
    XCTAssertLessThan(p.z, 120)
  }
}
