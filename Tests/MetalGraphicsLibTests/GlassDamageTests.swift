@testable import MetalGraphicsLib
import simd
import XCTest

/// A glass's blurred backdrop stays in the atlas from frame to frame: only a change below the
/// glass renders it again, never one drawn above it. Every frame must still come out as a full
/// redraw does.
@MainActor
final class GlassDamageTests: XCTestCase {
  /// The same tree twice, one harness shading only what changed and one shading everything.
  private struct Pair {
    let partial: UIHarness
    let full: UIHarness

    init(_ tree: () -> UIElement) {
      self.partial = UIHarness(tree)
      self.full = UIHarness(tree)
      self.full.graphics.partialRendering = false
      self.partial.settle()
      self.full.settle()
    }

    /// Changes both trees the same way, draws a frame, and checks the two agree.
    func change(file: StaticString = #filePath, line: UInt = #line, _ body: (UIHarness) -> Void) {
      body(self.partial)
      body(self.full)
      self.partial.step()
      self.full.step()
      XCTAssertEqual(self.partial.targetPixels(), self.full.targetPixels(), "differs from a full redraw", file: file, line: line)
    }
  }

  private static func backdrop() -> UIElement {
    VStack(spacing: 8) {
      Text("Behind the glass")
      Rectangle(.blue).frame(width: 220, height: 40).cornerRadius(8)
      Text("More text below it")
    }
  }

  func testTextAboveGlassKeepsItsBackdrop() {
    let labels = [Text("0"), Text("0")]
    var made = 0
    let pair = Pair {
      let label = labels[made]
      made += 1
      return ZStack {
        Self.backdrop()
        label.frame(width: 160, height: 90).glass(in: .rect(cornerRadius: 12))
      }
    }
    for n in 1 ... 5 {
      pair.change { h in
        let label = h === pair.partial ? labels[0] : labels[1]
        label.setText("\(n)", h.context)
      }
      XCTAssertEqual(pair.partial.graphics.lastGlassPasses, 0, "typing over the glass rendered its backdrop again")
      XCTAssertLessThan(pair.partial.graphics.lastDamagedCells, pair.partial.graphics.grid.cells.count)
    }
  }

  func testChangeBelowGlassRendersItsBackdrop() {
    let fills = [Rectangle(.red), Rectangle(.red)]
    var made = 0
    let pair = Pair {
      let fill = fills[made]
      made += 1
      return ZStack {
        fill.frame(width: 100, height: 60)
        Rectangle(float4(0, 0, 0, 0)).frame(width: 160, height: 90).glass(in: .rect(cornerRadius: 12))
      }
    }
    pair.change { h in
      (h === pair.partial ? fills[0] : fills[1]).setColor(.green, h.context)
    }
    XCTAssertEqual(pair.partial.graphics.lastGlassPasses, 1)
  }

  /// Two glasses, the upper one over the lower: a change beneath both renders both backdrops,
  /// a change between them only the upper one's.
  func testStackedGlassesRenderOnlyWhatShowsTheChange() {
    var bottoms: [Rectangle] = []
    var middles: [Rectangle] = []
    let pair = Pair {
      let bottom = Rectangle(.red)
      let middle = Rectangle(float4(1, 0.6, 0, 1))
      bottoms.append(bottom)
      middles.append(middle)
      return ZStack(alignment: .topLeading) {
        bottom.frame(width: 80, height: 60).padding(Inset(left: 40, top: 40))
        Rectangle(float4(0, 0, 0, 0)).frame(width: 140, height: 100).glass(in: .rect(cornerRadius: 10)).padding(Inset(left: 30, top: 30))
        middle.frame(width: 40, height: 30).padding(Inset(left: 190, top: 120))
        Rectangle(float4(0, 0, 0, 0)).frame(width: 140, height: 100).glass(in: .rect(cornerRadius: 10)).padding(Inset(left: 120, top: 90))
      }
    }
    pair.change { h in
      (h === pair.partial ? bottoms[0] : bottoms[1]).setColor(.green, h.context)
    }
    XCTAssertEqual(pair.partial.graphics.lastGlassPasses, 2, "a change beneath both glasses")
    pair.change { h in
      (h === pair.partial ? middles[0] : middles[1]).setColor(float4(0.6, 0.2, 0.9, 1), h.context)
    }
    XCTAssertEqual(pair.partial.graphics.lastGlassPasses, 1, "a change between the glasses")
  }

  func testMovingGlassRendersItsBackdrop() {
    var movers: [EffectElement] = []
    let pair = Pair {
      let mover = EffectElement {
        Rectangle(float4(0, 0, 0, 0)).frame(width: 120, height: 80).glass(in: .rect(cornerRadius: 12))
      }
      movers.append(mover)
      return ZStack {
        Self.backdrop()
        mover
      }
    }
    pair.change { h in
      (h === pair.partial ? movers[0] : movers[1]).setOffset(float2(30, 10), h.context)
    }
    XCTAssertEqual(pair.partial.graphics.lastGlassPasses, 1)
  }

  /// A glass casts its shadow beneath itself, not into its own frost.
  func testGlassDoesNotFrostItsOwnShadow() {
    func glass(shadow: Bool) -> UIHarness {
      UIHarness {
        ZStack {
          Rectangle(.white)
          if shadow {
            Rectangle(float4(0, 0, 0, 0)).frame(width: 160, height: 100).glass(in: .rect(cornerRadius: 12)).shadow(radius: 12, y: 6)
          } else {
            Rectangle(float4(0, 0, 0, 0)).frame(width: 160, height: 100).glass(in: .rect(cornerRadius: 12))
          }
        }
      }
    }
    let center = float2(160, 120)
    XCTAssertEqual(glass(shadow: true).pixel(at: center), glass(shadow: false).pixel(at: center))
  }
}
