@testable import MetalGraphicsLib
import simd
import XCTest

@MainActor
final class DragAndDropTests: XCTestCase {
  struct Chip: Equatable {
    let name: String
  }

  struct Row: Identifiable {
    let id: Int
  }

  /// Everything a drop destination was told, in order.
  final class Log {
    var drops: [(items: [Chip], location: float2)] = []
    var targeted: [Bool] = []
  }

  /// A 40 x 40 red chip carrying `chip`, left of a 100 x 100 gray destination for chips.
  private func board(_ log: Log, chip: Chip = Chip(name: "a")) -> UIElement {
    HStack(spacing: 40) {
      Rectangle(.red).frame(width: 40, height: 40).draggable(chip)
      Rectangle(float4(0.8, 0.8, 0.8, 1)).frame(width: 100, height: 100)
        .dropDestination(for: Chip.self) { items, location in
          log.drops.append((items, location))
          return true
        } isTargeted: { log.targeted.append($0) }
    }
  }

  private func center(_ element: DraggableElement) -> float2 {
    element.hitPosition + element.hitSize * 0.5
  }

  private func center(_ element: DropDestinationBase) -> float2 {
    element.position + element.size * 0.5
  }

  func testDropDeliversThePayloadAndWhereItLanded() {
    let log = Log()
    let h = UIHarness { self.board(log, chip: Chip(name: "b")) }
    let source = h.first(DraggableElement.self)!
    let target = h.first(DropDestinationBase.self)!

    h.drag(from: self.center(source), to: target.position + float2(30, 40))

    XCTAssertEqual(log.drops.count, 1)
    XCTAssertEqual(log.drops.first?.items, [Chip(name: "b")])
    XCTAssertEqual(log.drops.first?.location, float2(30, 40))
    XCTAssertEqual(log.targeted, [true, false])
    XCTAssertFalse(h.context.isDragging)
  }

  func testTargetingFollowsThePointer() {
    let log = Log()
    let h = UIHarness { self.board(log) }
    let source = h.first(DraggableElement.self)!
    let target = h.first(DropDestinationBase.self)!

    h.mouseDown(at: self.center(source))
    h.mouseDrag(to: self.center(source) + float2(10, 0))
    XCTAssertTrue(h.context.isDragging)
    XCTAssertEqual(log.targeted, [])

    h.mouseDrag(to: self.center(target))
    XCTAssertEqual(log.targeted, [true])
    XCTAssertTrue(target.isTargetedNow)

    h.mouseDrag(to: float2(5, 5))
    XCTAssertEqual(log.targeted, [true, false])

    // Released over nothing: no drop.
    h.mouseUp(at: float2(5, 5))
    XCTAssertTrue(log.drops.isEmpty)
    XCTAssertFalse(h.context.isDragging)
  }

  func testDestinationForAnotherTypeIsNeverTargeted() {
    var dropped = 0
    var targeted: [Bool] = []
    let h = UIHarness {
      HStack(spacing: 40) {
        Rectangle(.red).frame(width: 40, height: 40).draggable(Chip(name: "a"))
        Rectangle(.blue).frame(width: 100, height: 100)
          .dropDestination(for: Int.self) { _, _ in
            dropped += 1
            return true
          } isTargeted: { targeted.append($0) }
      }
    }
    let source = h.first(DraggableElement.self)!
    let target = h.first(DropDestinationBase.self)!

    h.drag(from: self.center(source), to: self.center(target))
    XCTAssertEqual(dropped, 0)
    XCTAssertEqual(targeted, [])
  }

  func testShortPressIsAClickNotADrag() {
    let log = Log()
    var taps = 0
    let h = UIHarness {
      HStack(spacing: 40) {
        Rectangle(.red).frame(width: 40, height: 40).draggable(Chip(name: "a")).onTap { _ in taps += 1 }
        Rectangle(.blue).frame(width: 100, height: 100)
          .dropDestination(for: Chip.self) { items, location in
            log.drops.append((items, location))
            return true
          }
      }
    }
    let source = h.first(DraggableElement.self)!

    h.mouseDown(at: self.center(source))
    h.mouseDrag(to: self.center(source) + float2(1, 1))
    XCTAssertFalse(h.context.isDragging)
    h.mouseUp(at: self.center(source) + float2(1, 1))

    XCTAssertEqual(taps, 1)
    XCTAssertTrue(log.drops.isEmpty)
  }

  func testEscapeCancelsTheDrag() {
    let log = Log()
    let h = UIHarness { self.board(log) }
    let source = h.first(DraggableElement.self)!
    let target = h.first(DropDestinationBase.self)!

    h.mouseDown(at: self.center(source))
    h.mouseDrag(to: self.center(target))
    XCTAssertEqual(log.targeted, [true])

    h.press(.escape)
    XCTAssertFalse(h.context.isDragging)
    XCTAssertEqual(log.targeted, [true, false])

    // The rest of the press moves nothing and drops nothing.
    h.mouseDrag(to: self.center(target) + float2(5, 5))
    XCTAssertFalse(h.context.isDragging)
    h.mouseUp(at: self.center(target))
    XCTAssertTrue(log.drops.isEmpty)
  }

  func testInnermostDestinationWins() {
    var drops: [String] = []
    let h = UIHarness {
      HStack(spacing: 40) {
        Rectangle(.red).frame(width: 40, height: 40).draggable(Chip(name: "a"))
        Rectangle(.blue).frame(width: 60, height: 60)
          .dropDestination(for: Chip.self) { _, _ in
            drops.append("inner")
            return true
          }
          .padding(20)
          .dropDestination(for: Chip.self) { _, _ in
            drops.append("outer")
            return true
          }
      }
    }
    let source = h.first(DraggableElement.self)!
    let outer = h.all(DropDestinationBase.self)[0]

    h.drag(from: self.center(source), to: self.center(outer))
    h.drag(from: self.center(source), to: outer.position + float2(5, 5))
    XCTAssertEqual(drops, ["inner", "outer"])
  }

  func testDestinationClippedAwayIsNotTargeted() {
    var targeted: [Bool] = []
    let h = UIHarness {
      HStack(spacing: 20) {
        Rectangle(.red).frame(width: 40, height: 40).draggable(Chip(name: "a"))
        // 100 high, centred: the destination is laid out just below what it shows.
        ScrollView {
          VStack {
            Rectangle(float4(0.8, 0.8, 0.8, 1)).frame(width: 100, height: 100)
            Rectangle(.blue).frame(width: 100, height: 100)
              .dropDestination(for: Chip.self) { _, _ in true } isTargeted: { targeted.append($0) }
          }
        }
        .frame(width: 100, height: 100)
      }
    }
    let source = h.first(DraggableElement.self)!
    let target = h.first(DropDestinationBase.self)!
    XCTAssertGreaterThan(target.position.y + 10, 170)

    h.mouseDown(at: self.center(source))
    h.mouseDrag(to: target.position + float2(50, 10))
    XCTAssertEqual(targeted, [])
    h.mouseUp(at: target.position + float2(50, 10))
  }

  func testSourceRemovedMidDragCancels() {
    let log = Log()
    let chip = Rectangle(.red).frame(width: 40, height: 40).draggable(Chip(name: "a"))
    let column = VStack { chip }
    let h = UIHarness {
      HStack(spacing: 40) {
        column
        Rectangle(.blue).frame(width: 100, height: 100)
          .dropDestination(for: Chip.self) { items, location in
            log.drops.append((items, location))
            return true
          } isTargeted: { log.targeted.append($0) }
      }
    }
    let target = h.first(DropDestinationBase.self)!

    h.mouseDown(at: self.center(chip))
    h.mouseDrag(to: self.center(target))
    XCTAssertTrue(h.context.isDragging)

    column.replaceChildren([], h.context)
    h.step()
    XCTAssertFalse(h.context.isDragging)
    XCTAssertEqual(log.targeted, [true, false])

    h.mouseUp(at: self.center(target))
    XCTAssertTrue(log.drops.isEmpty)
  }

  func testCustomPreviewIsMountedOnlyWhileDragging() {
    let preview = Rectangle(.green).frame(width: 20, height: 20)
    let h = UIHarness {
      Rectangle(.red).frame(width: 40, height: 40).draggable(Chip(name: "a")) { preview }
    }
    let source = h.first(DraggableElement.self)!
    XCTAssertFalse(preview.mounted)

    h.mouseDown(at: self.center(source))
    h.mouseDrag(to: float2(40, 40))
    XCTAssertTrue(preview.mounted)
    // Centred on the pointer.
    let p = h.pixel(at: float2(40, 40))
    XCTAssertGreaterThan(p.y, 200, "preview should be green under the pointer, got \(p)")

    h.mouseUp(at: float2(40, 40))
    XCTAssertFalse(preview.mounted)
  }

  // MARK: - Reordering

  func testMoveElementsMatchesSwiftUI() {
    var a = ["a", "b", "c", "d"]
    a.moveElements(fromOffsets: [0], toOffset: 3)
    XCTAssertEqual(a, ["b", "c", "a", "d"])

    a = ["a", "b", "c", "d"]
    a.moveElements(fromOffsets: [3], toOffset: 0)
    XCTAssertEqual(a, ["d", "a", "b", "c"])

    a = ["a", "b", "c", "d"]
    a.moveElements(fromOffsets: [1, 3], toOffset: 0)
    XCTAssertEqual(a, ["b", "d", "a", "c"])

    a = ["a", "b", "c", "d"]
    a.moveElements(fromOffsets: [0], toOffset: 4)
    XCTAssertEqual(a, ["b", "c", "d", "a"])
  }

  /// Four 100 x 30 rows, reorderable.
  private func list(_ moves: @escaping (IndexSet, Int) -> Void) -> UIElement {
    let colors: [float4] = [.red, .green, float4(0.8, 0.8, 0.8, 1), float4(1, 0.8, 0, 1)]
    return VList(items: (0 ..< 4).map { Row(id: $0) }) { row in
      Rectangle(colors[row.id]).frame(width: 100, height: 30)
    }
    .onMove(perform: moves)
  }

  func testDraggingARowReportsSwiftUIOffsets() {
    var moves: [(IndexSet, Int)] = []
    let h = UIHarness { self.list { moves.append(($0, $1)) } }
    let reorder = h.first(ReorderElement.self)!
    let top = reorder.position
    let x = top.x + 50

    // Row 0 dropped past row 2's middle: before row 3.
    h.drag(from: float2(x, top.y + 15), to: float2(x, top.y + 80))
    XCTAssertEqual(moves.count, 1)
    XCTAssertEqual(moves.first?.0, IndexSet(integer: 0))
    XCTAssertEqual(moves.first?.1, 3)

    // Row 3 dropped above everything.
    h.drag(from: float2(x, top.y + 105), to: float2(x, top.y + 2))
    XCTAssertEqual(moves.last?.0, IndexSet(integer: 3))
    XCTAssertEqual(moves.last?.1, 0)

    // Back where it started: no move.
    h.drag(from: float2(x, top.y + 45), to: float2(x, top.y + 50))
    XCTAssertEqual(moves.count, 2)
  }

  // MARK: - Drawing

  func testGhostFollowsThePointer() {
    let log = Log()
    let h = UIHarness { self.board(log) }
    let source = h.first(DraggableElement.self)!
    let target = h.first(DropDestinationBase.self)!

    h.mouseDown(at: self.center(source))
    h.mouseDrag(to: self.center(target))
    let p = h.pixel(at: self.center(target))
    XCTAssertGreaterThan(p.x, 200, "the lifted chip should be over the destination, got \(p)")
    assertSnapshot(h.snapshot(), named: "drag-ghost", testCase: self)

    h.mouseUp(at: self.center(target))
    let after = h.pixel(at: self.center(target))
    XCTAssertLessThan(after.x, 230, "the chip should be gone once dropped, got \(after)")
  }

  func testReorderShowsWhereTheRowGoes() {
    let h = UIHarness { self.list { _, _ in } }
    let reorder = h.first(ReorderElement.self)!
    let top = reorder.position
    let x = top.x + 50

    // Grabbed by its top edge, so the lifted row hangs below the line between rows 1 and 2.
    h.mouseDown(at: float2(x, top.y + 2))
    h.mouseDrag(to: float2(x, top.y + 66))
    assertSnapshot(h.snapshot(), named: "reorder-indicator", testCase: self)
    h.mouseUp(at: float2(x, top.y + 66))
  }

  // MARK: - Idle

  func testNothingRedrawsWhileHeldStillOrAfterTheDrop() {
    let log = Log()
    let h = UIHarness { self.board(log) }
    let source = h.first(DraggableElement.self)!
    let target = h.first(DropDestinationBase.self)!

    h.mouseDown(at: self.center(source))
    h.mouseDrag(to: self.center(target))
    h.step()
    var renders = h.renders
    h.step(frames: 30)
    XCTAssertEqual(h.renders, renders, "a drag held still should not redraw")

    h.mouseUp(at: self.center(target))
    XCTAssertNotNil(h.settle())
    renders = h.renders
    h.step(frames: 30)
    XCTAssertEqual(h.renders, renders, "nothing should redraw once dropped")
  }
}
