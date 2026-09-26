@testable import MetalGraphicsLib
import simd
import XCTest

@MainActor
final class PointerTests: XCTestCase {
  /// `content` pinned to the window's top left, so points read straight off its frames.
  private func harness(_ content: @escaping () -> UIElement) -> UIHarness {
    let h = UIHarness(size: float2(320, 240)) {
      VStack(alignment: .leading, spacing: 0) { content() }
        .frame(width: 320, height: 240, alignment: .topLeading)
    }
    h.settle()
    return h
  }

  // MARK: - Hover rule

  func testHoverOnlyTopmostOfOverlappingSiblings() {
    var events: [String] = []
    let h = self.harness {
      ZStack(alignment: .topLeading) {
        Rectangle(.red).frame(width: 100, height: 100).onHover { hovering, _ in events.append("under \(hovering)") }
        Rectangle(.blue).frame(width: 50, height: 50).onHover { hovering, _ in events.append("over \(hovering)") }
      }
    }
    h.move(to: float2(20, 20))
    XCTAssertEqual(events, ["over true"])
    // Off the one on top, onto the one underneath.
    h.move(to: float2(80, 80))
    XCTAssertEqual(events, ["over true", "over false", "under true"])
  }

  func testAncestorsStayHoveredWithoutReentering() {
    var outer: [Bool] = []
    var inner: [Bool] = []
    let h = self.harness {
      VStack {
        Rectangle(.red).frame(width: 40, height: 40).onHover { hovering, _ in inner.append(hovering) }
      }
      .padding(30)
      .onHover { hovering, _ in outer.append(hovering) }
    }
    h.move(to: float2(50, 50))
    XCTAssertEqual(inner, [true])
    XCTAssertEqual(outer, [true])
    h.move(to: float2(10, 10))
    XCTAssertEqual(inner, [true, false])
    XCTAssertEqual(outer, [true])
    h.move(to: float2(50, 50))
    XCTAssertEqual(outer, [true])
    h.mouseExit()
    XCTAssertEqual(outer, [true, false])
  }

  func testPopoverScrimBlocksHoverBeneath() {
    var hovered: [Bool] = []
    let anchor = HittableView(onTap: { _ in }) { Rectangle(.green).frame(width: 20, height: 20) }
    let h = self.harness {
      ZStack(alignment: .topLeading) {
        Rectangle(.red).frame(width: 320, height: 240).onHover { hovering, _ in hovered.append(hovering) }
        anchor
      }
    }
    h.move(to: float2(200, 200))
    XCTAssertEqual(hovered, [true])
    h.context.presentPopover(Rectangle(.white).frame(width: 40, height: 40), anchor: anchor)
    h.settle()
    h.move(to: float2(250, 200))
    XCTAssertEqual(hovered, [true, false])
  }

  func testOverlappingShapesHoverOnlyTheTopmost() {
    var a: [Bool] = []
    var b: [Bool] = []
    let h = self.harness {
      VectorCanvas(width: 100, height: 60) {
        Circle(center: float2(30, 30), radius: 25).fill(.red).onHover { hovering, _ in a.append(hovering) }
        Circle(center: float2(60, 30), radius: 25).fill(.blue).onHover { hovering, _ in b.append(hovering) }
      }
    }
    h.move(to: float2(45, 30))
    XCTAssertEqual(b, [true])
    XCTAssertEqual(a, [])
    h.move(to: float2(15, 30))
    XCTAssertEqual(b, [true, false])
    XCTAssertEqual(a, [true])
  }

  // MARK: - Continuous hover

  func testContinuousHoverReportsLocationsAndEnds() {
    var local: [HoverPhase] = []
    var global: [HoverPhase] = []
    let h = self.harness {
      Rectangle(.red).frame(width: 100, height: 100)
        .onContinuousHover { local.append($0) }
        .padding(20)
        .onContinuousHover(coordinateSpace: .global) { global.append($0) }
    }
    h.move(to: float2(30, 40))
    h.move(to: float2(50, 60))
    XCTAssertEqual(local, [.active(float2(10, 20)), .active(float2(30, 40))])
    XCTAssertEqual(global, [.active(float2(30, 40)), .active(float2(50, 60))])
    h.move(to: float2(5, 5))
    XCTAssertEqual(local.last, .ended)
    XCTAssertEqual(global.last, .active(float2(5, 5)))
    h.mouseExit()
    XCTAssertEqual(global.last, .ended)
  }

  // MARK: - Re-hover

  private func growingTarget(_ hovered: @escaping (Bool) -> Void) -> (Frame, () -> UIElement) {
    let frame = Frame(float2(50, 50)) { Rectangle(.red) }
    return (frame, { frame.onHover { hovering, _ in hovered(hovering) } })
  }

  func testRehoverAfterLayoutUnderStillPointer() {
    var hovered: [Bool] = []
    let (frame, content) = self.growingTarget { hovered.append($0) }
    let h = self.harness(content)
    h.move(to: float2(80, 20))
    XCTAssertEqual(hovered, [])
    frame.setSize(float2(100, 50), h.context)
    h.step()
    XCTAssertEqual(hovered, [true])
  }

  func testRehoverWaitsForAnAnimationToEnd() {
    var hovered: [Bool] = []
    let (frame, content) = self.growingTarget { hovered.append($0) }
    let h = self.harness(content)
    h.move(to: float2(60, 20))
    frame.setSize(float2(100, 50), h.context, animation: .linear(0.3))
    h.advance(0.25)
    // Already under the pointer, but still moving: no hit test yet.
    XCTAssertEqual(hovered, [])
    XCTAssertNotNil(h.settle())
    XCTAssertEqual(hovered, [true])
  }

  func testRehoverAfterScroll() {
    var hovered: [Int: Bool] = [:]
    let h = self.harness {
      ScrollView(.vertical) {
        VStack(spacing: 0) {
          return (0..<10).map { index in
            Rectangle(.red).frame(width: 200, height: 50).onHover { hovering, _ in hovered[index] = hovering }
          }
        }
      }
      .frame(width: 200, height: 200)
    }
    h.move(to: float2(100, 25))
    XCTAssertEqual(hovered[0], true)
    h.scroll(by: float2(0, -100), at: float2(100, 25))
    h.step()
    XCTAssertEqual(hovered[0], false)
    XCTAssertEqual(hovered[2], true)
  }

  func testNoRehoverWhenPointerIsOutside() {
    let (frame, content) = self.growingTarget { _ in }
    let h = self.harness(content)
    let rebuilds = h.context.hitGridRebuilds
    frame.setSize(float2(100, 50), h.context)
    h.step(frames: 5)
    XCTAssertEqual(h.context.hitGridRebuilds, rebuilds)
  }

  func testIdleWithPointerInsideStaysIdle() {
    let h = self.harness {
      Rectangle(.red).frame(width: 100, height: 100).onHover { _, _ in }.pointerStyle(.link)
    }
    h.move(to: float2(50, 50))
    XCTAssertNotNil(h.settle())
    let renders = h.renders
    let rebuilds = h.context.hitGridRebuilds
    h.step(frames: 30)
    XCTAssertEqual(h.renders, renders)
    XCTAssertEqual(h.context.hitGridRebuilds, rebuilds)
  }

  // MARK: - Pointer style

  func testPointerStyleNearestWins() {
    let h = self.harness {
      VStack {
        Rectangle(.red).frame(width: 40, height: 40).pointerStyle(.link)
      }
      .padding(30)
      .pointerStyle(.grabIdle)
    }
    h.move(to: float2(50, 50))
    XCTAssertEqual(h.pointerStyle, .link)
    h.move(to: float2(10, 10))
    XCTAssertEqual(h.pointerStyle, .grabIdle)
    h.move(to: float2(200, 200))
    XCTAssertEqual(h.pointerStyle, .default)
  }

  func testPointerStyleIsKeptWhilePressed() {
    let h = self.harness {
      Rectangle(.red).frame(width: 60, height: 60).draggable("payload")
    }
    h.move(to: float2(30, 30))
    XCTAssertEqual(h.pointerStyle, .grabIdle)
    h.mouseDown(at: float2(30, 30))
    XCTAssertEqual(h.pointerStyle, .grabActive)
    h.mouseDrag(to: float2(200, 200))
    XCTAssertEqual(h.pointerStyle, .grabActive)
    h.mouseUp(at: float2(200, 200))
    XCTAssertEqual(h.pointerStyle, .default)
  }

  func testChangedPointerStyleShowsWithoutAMove() {
    let target = HittableView { Rectangle(.red).frame(width: 60, height: 60) }.pointerStyle(.link)
    let h = self.harness { target }
    h.move(to: float2(30, 30))
    XCTAssertEqual(h.pointerStyle, .link)
    target.setPointerStyle(.zoomIn, h.context)
    h.step()
    XCTAssertEqual(h.pointerStyle, .zoomIn)
  }

  func testControlsShowTheirCursors() {
    var name = ""
    let field = TextField("Name", text: Binding(get: { name }, set: { name = $0 }))
    let h = self.harness {
      VStack(alignment: .leading, spacing: 20) {
        field.frame(width: 200)
        Button("Save")
      }
    }
    let fieldHit = h.all(HittableView.self).first { $0.pointerStyle == .horizontalText }!
    h.move(to: fieldHit.hitPosition + fieldHit.hitSize * 0.5)
    XCTAssertEqual(h.pointerStyle, .horizontalText)
    let buttonHit = h.all(HittableView.self).first { $0.pointerStyle == .link }!
    h.move(to: buttonHit.hitPosition + buttonHit.hitSize * 0.5)
    XCTAssertEqual(h.pointerStyle, .link)
  }

  // MARK: - Tap gesture

  func testTapGestureFiresOnReleaseAtItsLocation() {
    var taps: [float2] = []
    let h = self.harness {
      Rectangle(.red).frame(width: 100, height: 100).padding(10).onTapGesture { taps.append($0) }
    }
    h.mouseDown(at: float2(40, 30))
    XCTAssertEqual(taps, [])
    h.mouseUp(at: float2(40, 30))
    XCTAssertEqual(taps, [float2(40, 30)])
  }

  func testTapGestureCountsClicks() {
    var singles = 0
    var doubles = 0
    let h = self.harness {
      Rectangle(.red).frame(width: 100, height: 100)
        .onTapGesture(count: 2) { doubles += 1 }
        .padding(10)
        .onTapGesture { singles += 1 }
    }
    // A single click in the inner view falls back to the outer one, which takes one click.
    h.click(at: float2(50, 50))
    XCTAssertEqual(singles, 1)
    XCTAssertEqual(doubles, 0)
    h.click(at: float2(50, 50), count: 2)
    XCTAssertEqual(doubles, 1)
    XCTAssertEqual(singles, 1)
  }

  func testTapReleasedOutsideDoesNotFire() {
    var taps = 0
    let h = self.harness {
      Rectangle(.red).frame(width: 100, height: 100).onTapGesture { taps += 1 }
    }
    h.mouseDown(at: float2(50, 50))
    h.mouseUp(at: float2(200, 200))
    XCTAssertEqual(taps, 0)
    h.clickWithinOneFrame(at: float2(50, 50))
    XCTAssertEqual(taps, 1)
  }

  func testTapGestureAsAGesture() {
    var taps = 0
    let h = self.harness {
      Rectangle(.red).frame(width: 100, height: 100).gesture(TapGesture(count: 2).onEnded { taps += 1 })
    }
    h.doubleClick(at: float2(50, 50))
    XCTAssertEqual(taps, 1)
  }

  // MARK: - Drag gesture

  func testDragGestureStartsPastItsMinimumDistance() {
    var changes: [DragGesture.Value] = []
    var ended: DragGesture.Value? = nil
    var taps = 0
    let h = self.harness {
      Rectangle(.red).frame(width: 100, height: 100).padding(20)
        .gesture(DragGesture().onChanged { changes.append($0) }.onEnded { ended = $0 })
        .onTapGesture { taps += 1 }
    }
    h.mouseDown(at: float2(50, 50))
    h.mouseDrag(to: float2(55, 50))
    XCTAssertEqual(changes.count, 0)
    h.advance(0.1)
    h.mouseDrag(to: float2(80, 70))
    XCTAssertEqual(changes.count, 1)
    XCTAssertEqual(changes.last?.startLocation, float2(50, 50))
    XCTAssertEqual(changes.last?.location, float2(80, 70))
    XCTAssertEqual(changes.last?.translation, float2(30, 20))
    XCTAssertGreaterThan(changes.last?.velocity.x ?? 0, 0)
    h.mouseUp(at: float2(90, 70))
    XCTAssertEqual(ended?.translation, float2(40, 20))
    // A drag is not also a tap.
    XCTAssertEqual(taps, 0)
  }

  func testDragGestureWithNoMinimumChangesOnPress() {
    var changes: [DragGesture.Value] = []
    let h = self.harness {
      Rectangle(.red).frame(width: 100, height: 100)
        .gesture(DragGesture(minimumDistance: 0, coordinateSpace: .global).onChanged { changes.append($0) })
    }
    h.mouseDown(at: float2(30, 30))
    XCTAssertEqual(changes.map(\.location), [float2(30, 30)])
    h.mouseUp(at: float2(30, 30))
  }

  // MARK: - Hit-test control

  func testAllowsHitTestingPassesThrough() {
    var under = 0
    var over = 0
    let top = Rectangle(.blue).frame(width: 100, height: 100).onTap { _ in over += 1 }.allowsHitTesting(false)
    let h = self.harness {
      ZStack {
        Rectangle(.red).frame(width: 100, height: 100).onTap { _ in under += 1 }
        top
      }
    }
    h.click(at: float2(50, 50))
    XCTAssertEqual(under, 1)
    XCTAssertEqual(over, 0)
    top.setAllowsHitTesting(true, h.context)
    h.click(at: float2(50, 50))
    XCTAssertEqual(over, 1)
    XCTAssertEqual(under, 1)
  }

  func testContentShapeLimitsWhereItIsHit() {
    var taps = 0
    let h = self.harness {
      Rectangle(.red).frame(width: 100, height: 100).contentShape(.circle).onTapGesture { taps += 1 }
    }
    h.click(at: float2(5, 5))
    XCTAssertEqual(taps, 0)
    h.click(at: float2(50, 50))
    XCTAssertEqual(taps, 1)
    XCTAssertEqual(h.all(HittableView.self).count, 1)
  }

  // MARK: - One view per chain

  func testHandlerModifiersShareOneHittableView() {
    let h = self.harness {
      Rectangle(.red).frame(width: 50, height: 50).onTap { _ in }.onHover { _, _ in }.pointerStyle(.link)
    }
    XCTAssertEqual(h.all(HittableView.self).count, 1)
    let wrapped = self.harness {
      Rectangle(.red).frame(width: 50, height: 50).onTap { _ in }.onTap { _ in }
    }
    XCTAssertEqual(wrapped.all(HittableView.self).count, 2)
  }
}
