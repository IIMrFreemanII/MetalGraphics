@testable import MetalGraphicsLib
import simd
import XCTest

/// Layout through the whole frame (`UIContext.update`), not a bare `calcSize`.
/// Expected values are SwiftUI's, as in `Tools/layoutchecks`.
@MainActor
final class LayoutTests: XCTestCase {
  func testTwoRectsShareAnHStack() {
    let a = Rectangle(.red), b = Rectangle(.blue)
    _ = UIHarness(size: float2(200, 50)) { HStack { a; b } }
    XCTAssertEqual(a.size, float2(100, 50))
    XCTAssertEqual(b.position, float2(100, 0))
  }

  func testSpacingComesOffTheShare() {
    let a = Rectangle(.red), b = Rectangle(.blue)
    _ = UIHarness(size: float2(210, 50)) { HStack(spacing: 10) { a; b } }
    XCTAssertEqual(a.size, float2(100, 50))
    XCTAssertEqual(b.position, float2(110, 0))
  }

  func testSpacerPushesApart() {
    let c = Rectangle(.blue)
    _ = UIHarness(size: float2(300, 24)) {
      HStack { Rectangle(.red).frame(width: 24, height: 24); Spacer(); c.frame(width: 24, height: 24) }
    }
    XCTAssertEqual(c.position, float2(276, 0))
  }

  func testNestedStacksShareHeight() {
    let left = Rectangle(.green), bottom = Rectangle(.blue)
    _ = UIHarness(size: float2(200, 100)) {
      VStack { HStack { left; Rectangle(.white) }; bottom; Rectangle(.red).frame(height: 20) }
    }
    XCTAssertEqual(left.size, float2(100, 40))
    XCTAssertEqual(bottom.size, float2(200, 40))
  }

  func testResizeRelaysOut() {
    let a = Rectangle(.red), b = Rectangle(.blue)
    let h = UIHarness(size: float2(200, 50)) { HStack { a; b } }
    XCTAssertEqual(a.size.x, 100)
    // What a window resize does: the next frame's update sees the new size.
    h.renderer.windowSize = float2(400, 50)
    h.context.update(root: h.root, size: float2(400, 50), input: h.input, graphics: h.graphics)
    XCTAssertEqual(a.size.x, 200)
  }
}
