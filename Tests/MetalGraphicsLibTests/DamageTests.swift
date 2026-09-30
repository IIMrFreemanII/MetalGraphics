@testable import MetalGraphicsLib
import simd
import XCTest

/// Partial re-rendering: each frame shades only the grid cells whose shapes changed, and every
/// other pixel keeps the last frame's. The result must be exactly what shading everything gives.
@MainActor
final class DamageTests: XCTestCase {
  /// A tree, and what to do to it once it is up.
  private typealias Scene = () -> (tree: UIElement, start: (UIHarness) -> Void)

  /// Runs `scene` in two harnesses, one shading only what changed and one shading every pixel,
  /// and checks every frame comes out byte for byte the same.
  private func assertMatchesFullRedraw(
    frames: Int = 40, file: StaticString = #filePath, line: UInt = #line,
    _ scene: Scene, step: ((UIHarness, Int) -> Void)? = nil
  ) {
    let (partialTree, startPartial) = scene()
    let partial = UIHarness { partialTree }
    let (fullTree, startFull) = scene()
    let full = UIHarness { fullTree }
    full.graphics.partialRendering = false

    startPartial(partial)
    startFull(full)
    var partialFrames = 0
    for frame in 0 ..< frames {
      step?(partial, frame)
      step?(full, frame)
      partial.step()
      full.step()
      if partial.graphics.lastDamagedCells < partial.graphics.grid.cells.count {
        partialFrames += 1
      }
      guard partial.targetPixels() == full.targetPixels() else {
        XCTFail("frame \(frame) differs from a full redraw", file: file, line: line)
        return
      }
    }
    XCTAssertGreaterThan(partialFrames, 0, "no frame was drawn partially", file: file, line: line)
  }

  /// Text and shapes that stay where they are, around whatever moves.
  private static func backdrop() -> UIElement {
    VStack(spacing: 8) {
      Text("Static title")
      Rectangle(.blue).frame(width: 200, height: 30).cornerRadius(8)
      Text("More static text below")
    }
  }

  func testMovingElementMatchesFullRedraw() {
    self.assertMatchesFullRedraw {
      let mover = EffectElement { Rectangle(.red).frame(width: 30, height: 30) }
      let tree = ZStack(alignment: .topLeading) {
        Self.backdrop()
        mover
      }
      return (tree, { h in
        withAnimation(.linear(0.5)) { mover.setOffset(float2(200, 120), h.context, animation: UITransaction.animation) }
      })
    }
  }

  func testFadingShadowedGroupMatchesFullRedraw() {
    self.assertMatchesFullRedraw {
      let group = EffectElement(opacity: 1) {
        Rectangle(.red).frame(width: 60, height: 40).shadow(radius: 6, y: 3)
      }
      let tree = ZStack {
        Self.backdrop()
        group.position(x: 60, y: 60)
      }
      return (tree, { h in
        withAnimation(.linear(0.5)) { group.setOpacity(0.2, h.context, animation: UITransaction.animation) }
      })
    }
  }

  func testGlassOverMovingContentMatchesFullRedraw() {
    self.assertMatchesFullRedraw {
      let mover = EffectElement { Rectangle(.red).frame(width: 40, height: 40) }
      let tree = ZStack {
        Self.backdrop()
        mover.position(x: 40, y: 120)
        Rectangle(float4(0, 0, 0, 0)).frame(width: 120, height: 80).glass(in: .rect(cornerRadius: 12))
      }
      return (tree, { h in
        withAnimation(.linear(0.5)) { mover.setOffset(float2(200, 0), h.context, animation: UITransaction.animation) }
      })
    }
  }

  func testBlurredMovingElementMatchesFullRedraw() {
    self.assertMatchesFullRedraw {
      let mover = EffectElement { Rectangle(.red).frame(width: 30, height: 30) }
      let tree = ZStack(alignment: .topLeading) {
        Self.backdrop()
        mover.blur(radius: 4)
      }
      return (tree, { h in
        withAnimation(.linear(0.5)) { mover.setOffset(float2(150, 100), h.context, animation: UITransaction.animation) }
      })
    }
  }

  func testScrollingMatchesFullRedraw() {
    self.assertMatchesFullRedraw(frames: 12, {
      let tree = VStack {
        Text("Header stays put")
        ScrollView {
          // An explicit return skips the builder, which has no loops.
          VStack(spacing: 4) { return (0 ..< 30).map { Text("Row \($0)") as UIElement } }
        }
        .frame(width: 200, height: 120)
        .cornerRadius(10)
      }
      return (tree, { _ in })
    }, step: { h, _ in
      h.input.mousePosition = float2(160, 140)
      h.input.scrollDelta = float2(0, -9)
    })
  }

  func testTextChangeMatchesFullRedraw() {
    self.assertMatchesFullRedraw(frames: 8, {
      let label = Text("Count 0")
      let tree = VStack(spacing: 8) {
        Self.backdrop()
        label
      }
      return (tree, { _ in })
    }, step: { h, frame in
      h.all(Text.self).last?.setText("Count \(frame)", h.context)
    })
  }

  // MARK: - What gets shaded

  func testSmallAnimationShadesOnlyItsCells() {
    let mover = EffectElement { Rectangle(.red).frame(width: 10, height: 10) }
    let h = UIHarness(size: float2(320, 240)) {
      ZStack(alignment: .topLeading) {
        Self.backdrop()
        mover.position(x: 300, y: 225)
      }
    }
    withAnimation(.linear(1)) { mover.setOffset(float2(4, 4), h.context, animation: UITransaction.animation) }
    var shaded = 0
    for _ in 0 ..< 10 {
      h.step()
      // It stays inside a corner: at most the four cells around it.
      XCTAssertLessThanOrEqual(h.graphics.lastDamagedCells, 4)
      shaded += h.graphics.lastDamagedCells
    }
    XCTAssertGreaterThan(shaded, 0, "the animation shaded nothing")
  }

  func testRedrawWithoutVisibleChangeSkipsTheGPU() {
    let h = UIHarness { Self.backdrop() }
    XCTAssertNotNil(h.settle())
    let frames = h.graphics.gpuFrames
    let before = h.targetPixels()
    h.context.invalidate(.render)
    h.step()
    XCTAssertEqual(h.graphics.lastDamagedCells, 0)
    XCTAssertEqual(h.graphics.gpuFrames, frames, "an unchanged frame must not reach the GPU")
    XCTAssertEqual(h.targetPixels(), before)
  }

  func testFirstFrameShadesEverything() {
    let h = UIHarness { Self.backdrop() }
    XCTAssertEqual(h.graphics.lastDamagedCells, h.graphics.grid.cells.count)
  }

  func testContextExposesGraphics() {
    let h = UIHarness { Self.backdrop() }
    XCTAssertTrue(h.context.graphics === h.graphics)
  }

  /// A toggle bound to `showDamage`, as the Redraw demo's: the tint goes over the presented
  /// frame, so turning it on shades nothing again but the toggle, and leaves the pixels alone.
  func testShowDamageLeavesTheFrameAsItIs() {
    var graphics: Graphics2D?
    let toggle = Toggle("Show redrawn areas", isOn: Binding(
      get: { graphics?.sceneData.debug.showDamage ?? false },
      set: { graphics?.sceneData.debug.showDamage = $0 }
    ))
    let h = UIHarness {
      VStack(alignment: .leading, spacing: 40) {
        toggle.frame(width: 200, height: 30)
        Rectangle(.init(0.2, 0.45, 0.85, 1)).frame(width: 120, height: 80)
      }
    }
    graphics = h.graphics
    h.settle()
    let rect = h.first(Rectangle.self)!
    let spot = rect.position + rect.size * 0.5
    let before = h.pixel(at: spot)

    let row = h.first(HittableView.self)!
    let point = row.position + row.size * 0.5
    h.mouseDown(at: point)
    XCTAssertLessThan(h.graphics.lastDamagedCells, h.graphics.grid.cells.count)
    h.mouseUp(at: point)
    h.settle()

    XCTAssertTrue(h.graphics.sceneData.debug.showDamage)
    XCTAssertEqual(h.pixel(at: spot), before)
  }

  // MARK: - Window size

  /// The render grid covers the whole target, however big: a harness past 500 points once drew
  /// only the default grid's 500 in its middle, and left the edges background.
  func testAWindowPast500PointsDrawsToItsEdges() {
    let left = Rectangle(.destructive).frame(width: 200, height: 100)
    let middle = Rectangle(.success).frame(width: 460, height: 100)
    let right = Rectangle(.accent)
    let h = UIHarness(size: float2(860, 620)) {
      VStack(spacing: 0) {
        HStack(spacing: 0) {
          left
          middle
          right.frame(width: 200, height: 100)
        }
        Spacer()
        Rectangle(.warning).frame(width: 860, height: 40)
      }
    }
    h.settle()
    XCTAssertEqual(h.graphics.grid.size, int2(18, 13))
    let red = h.pixel(at: float2(10, 50))
    let green = h.pixel(at: float2(430, 50))
    let blue = h.pixel(at: float2(850, 50))
    let orange = h.pixel(at: float2(430, 610))
    XCTAssertEqual(h.pixel(at: float2(190, 50)), red)
    XCTAssertNotEqual(red, green)
    XCTAssertNotEqual(blue, green)
    XCTAssertNotEqual(blue, red)
    XCTAssertNotEqual(orange, green)
    // The far corners, outside the old 500 point grid, draw as its middle does.
    XCTAssertEqual(h.pixel(at: float2(5, 615)), orange)
    XCTAssertEqual(h.pixel(at: float2(855, 615)), orange)

    // A change at the edge shades only its cells again, and they reach the target.
    let before = h.pixel(at: float2(850, 50))
    let cells = h.graphics.grid.cells.count
    right.setColor(.destructive, h.context)
    h.step()
    XCTAssertLessThan(h.graphics.lastDamagedCells, cells)
    XCTAssertNotEqual(h.pixel(at: float2(850, 50)), before)
    XCTAssertEqual(h.pixel(at: float2(850, 50)), red)
  }

  /// And hits to its edges: the harness sizes its hit grid as the app's resize does.
  func testAWindowPast500PointsHitsToItsEdges() {
    var taps = 0
    let h = UIHarness(size: float2(860, 620)) {
      VStack(spacing: 0) {
        HStack(spacing: 0) {
          Spacer()
          Button("Far") { taps += 1 }.buttonStyle(.plain).frame(width: 60, height: 30)
        }
        Spacer()
      }
    }
    h.settle()
    let button = try! XCTUnwrap(h.first(HittableView.self))
    XCTAssertGreaterThan(button.hitPosition.x, 780)
    h.click(at: button.hitPosition + button.hitSize * 0.5)
    XCTAssertEqual(taps, 1)
  }

  /// A shape reaching the grid's far edge is filed in the last cell, once: its index one past
  /// the row once wrapped into the next row's first cell, and a shadow drew twice at the left.
  func testAShapeAtTheGridsFarEdgeIsFiledOnce() {
    let h = UIHarness(size: float2(320, 240)) {
      ZStack {
        Rectangle(float4(0.85, 0.87, 0.9, 1)).frame(width: 320, height: 240)
        Rectangle(.card).frame(width: 260, height: 110).shadow(color: .shadow, radius: 22, y: 10)
      }
    }
    h.settle()
    let grid = h.graphics.grid
    for cell in grid.shapesPerCell.prefix(grid.cells.count) {
      let shapes = cell.map { [Int($0.shape.shapeType), Int($0.shape.index)] }
      XCTAssertEqual(Set(shapes).count, shapes.count, "a shape filed twice in one cell")
    }
    // The shadow is as dark on the left as on the right.
    XCTAssertEqual(h.pixel(at: float2(25, 120)), h.pixel(at: float2(295, 120)))
  }
}
