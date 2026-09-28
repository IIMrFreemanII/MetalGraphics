@testable import MetalGraphicsLib
import simd
import XCTest

@MainActor
final class NavigationTests: XCTestCase {
  // MARK: - Helpers

  /// What the pointer hits on a button or link: the `HittableView` under its dimmer.
  private func hit(_ button: Button) -> HittableView {
    var current: UIElement? = button
    while let element = current {
      if let hit = element as? HittableView { return hit }
      current = (element as? SingleChildElement)?.child
    }
    fatalError("no hittable in \(button)")
  }

  private func tap(_ button: Button, _ h: UIHarness) {
    h.click(on: self.hit(button))
  }

  /// Mounted, on a page that is not covered.
  private func isShown(_ element: UIElement) -> Bool {
    guard element.mounted else { return false }
    var current: UIElement? = element
    while let e = current {
      if e.isHidden { return false }
      current = e.parent
    }
    return true
  }

  private func bar(_ h: UIHarness) -> StackNavigationBar {
    h.first(StackNavigationBar.self)!
  }

  // MARK: - Parent pointers

  func testParentIsSetOnMountAndClearedOnUnmount() {
    let leaf = Rectangle(.red)
    let stack = VStack { leaf }
    let frame = Frame(float2(100, 100)) { stack }
    let h = UIHarness { frame }
    XCTAssertTrue(leaf.parent === stack)
    XCTAssertTrue(stack.parent === frame)
    XCTAssertTrue(leaf.nearestAncestor(Frame.self) === frame)

    let other = Rectangle(.blue)
    stack.replaceChildren([other], h.context)
    XCTAssertNil(leaf.parent)
    XCTAssertTrue(other.parent === stack)
  }

  // MARK: - Pushing and popping

  func testViewLinkPushesAndBackButtonPops() {
    let detail = Text("Detail")
    let rootText = Text("Root")
    let link = NavigationLink("Open", destination: { detail })
    let h = UIHarness { NavigationStack { rootText; link } }
    let stack = h.first(NavigationStack.self)!
    XCTAssertEqual(stack.depth, 0)
    XCTAssertTrue(self.bar(h).back.isHidden)

    self.tap(link, h)
    XCTAssertEqual(stack.depth, 1)
    XCTAssertTrue(detail.mounted)
    XCTAssertNotNil(h.settle())
    XCTAssertTrue(self.isShown(detail))
    XCTAssertTrue(rootText.mounted, "a covered page stays mounted")
    XCTAssertFalse(self.isShown(rootText))
    XCTAssertFalse(self.bar(h).back.isHidden)

    self.tap(self.bar(h).back, h)
    XCTAssertEqual(stack.depth, 0)
    XCTAssertNotNil(h.settle())
    XCTAssertFalse(detail.mounted)
    XCTAssertTrue(self.isShown(rootText))
    XCTAssertTrue(self.bar(h).back.isHidden)
  }

  func testValueLinkPushesWhatItsDestinationBuilds() {
    var built: [Int] = []
    let link = NavigationLink("Seven", value: 7)
    let h = UIHarness {
      NavigationStack {
        link.navigationDestination(for: Int.self) { value in
          built.append(value)
          return Text("Number \(value)")
        }
      }
    }
    self.tap(link, h)
    XCTAssertEqual(built, [7])
    XCTAssertNotNil(h.settle())
    let page = h.all(Text.self).first { $0.text == "Number 7" }
    XCTAssertNotNil(page)
    XCTAssertTrue(self.isShown(page!))
  }

  func testDestinationOnTheStackItselfServesItsLinks() {
    let link = NavigationLink("Go", value: "a")
    let h = UIHarness {
      NavigationStack { link }
        .navigationDestination(for: String.self) { value in Text("Page \(value)") }
    }
    self.tap(link, h)
    XCTAssertEqual(h.first(NavigationStack.self)!.depth, 1)
    XCTAssertNotNil(h.all(Text.self).first { $0.text == "Page a" })
  }

  func testCoveredPageKeepsItsElementsAcrossAPushAndPop() {
    let field = Rectangle(.green).frame(width: 20, height: 20)
    let link = NavigationLink("Open", destination: { Text("Detail") })
    let h = UIHarness { NavigationStack { field; link } }
    self.tap(link, h)
    h.settle()
    self.tap(self.bar(h).back, h)
    h.settle()
    XCTAssertTrue(self.isShown(field))
    XCTAssertTrue(h.all(Frame.self).contains { $0 === field }, "the same element, not a rebuilt one")
  }

  // MARK: - Path

  func testInitialPathResolvesOnceDestinationsRegister() {
    let h = UIHarness {
      NavigationStack(path: [1, 2]) {
        Text("Root").navigationDestination(for: Int.self) { value in Text("Page \(value)") }
      }
    }
    let stack = h.first(NavigationStack.self)!
    XCTAssertEqual(stack.depth, 2)
    let one = h.all(Text.self).first { $0.text == "Page 1" }!
    let two = h.all(Text.self).first { $0.text == "Page 2" }!
    XCTAssertFalse(self.isShown(one))
    XCTAssertTrue(self.isShown(two))
    XCTAssertFalse(self.bar(h).back.isHidden)
  }

  func testDestinationArmedAfterMountResolvesPendingPages() {
    let destination = Text("Root").navigationDestination(for: Int.self) { value in Text("Page \(value)") }
    let armed = destination.destination
    destination.destination = nil
    let h = UIHarness { NavigationStack(path: [3]) { destination } }
    XCTAssertNil(h.all(Text.self).first { $0.text == "Page 3" })
    destination.destination = armed
    h.step()
    XCTAssertTrue(self.isShown(h.all(Text.self).first { $0.text == "Page 3" }!))
  }

  func testBoundPathRoundTrip() {
    var path: [Int] = []
    let binding = Binding(get: { path }, set: { path = $0 })
    let link = NavigationLink("One", value: 1)
    let h = UIHarness {
      NavigationStack(path: binding) {
        link.navigationDestination(for: Int.self) { value in Text("Page \(value)") }
      }
    }
    let stack = h.first(NavigationStack.self)!
    self.tap(link, h)
    XCTAssertEqual(path, [1], "the link reports to the binding")
    XCTAssertEqual(stack.depth, 1, "and the value comes back through setPath")
    h.settle()

    h.press(.escape)
    XCTAssertEqual(path, [])
    XCTAssertEqual(stack.depth, 0)
  }

  func testExternalPathChangePopsSeveralAndPushes() {
    let h = UIHarness {
      NavigationStack(path: [Int]()) {
        Text("Root").navigationDestination(for: Int.self) { value in Text("Page \(value)") }
      }
    }
    let stack = h.first(NavigationStack.self)!
    stack.setPath([1, 2, 3], h.context)
    XCTAssertEqual(stack.depth, 3)
    h.settle()
    let two = h.all(Text.self).first { $0.text == "Page 2" }!
    let three = h.all(Text.self).first { $0.text == "Page 3" }!

    stack.setPath([1], h.context)
    XCTAssertEqual(stack.depth, 1)
    XCTAssertFalse(two.mounted, "a page under the top one goes at once")
    XCTAssertTrue(three.mounted, "the top one slides away first")
    XCTAssertNotNil(h.settle())
    XCTAssertFalse(three.mounted)

    // A different value at the same depth replaces the page.
    stack.setPath([5], h.context)
    XCTAssertEqual(stack.depth, 1)
    XCTAssertNotNil(h.settle())
    XCTAssertTrue(self.isShown(h.all(Text.self).first { $0.text == "Page 5" }!))
    XCTAssertNil(h.all(Text.self).first { $0.text == "Page 1" })
  }

  func testUnchangedPathIsANoOp() {
    let h = UIHarness { NavigationStack(path: [1]) { Text("Root") } }
    h.settle()
    let renders = h.renders
    h.first(NavigationStack.self)!.setPath([1], h.context)
    h.step(frames: 5)
    XCTAssertEqual(h.renders, renders)
  }

  func testValueOfAnotherTypeIsDroppedByATypedPath() {
    var path: [Int] = []
    let binding = Binding(get: { path }, set: { path = $0 })
    let link = NavigationLink("Text", value: "not an Int")
    let h = UIHarness { NavigationStack(path: binding) { link } }
    self.tap(link, h)
    XCTAssertEqual(path, [])
    XCTAssertEqual(h.first(NavigationStack.self)!.depth, 0)
  }

  func testNavigationPathHoldsSeveralTypes() {
    var path = NavigationPath()
    let binding = Binding(get: { path }, set: { path = $0 })
    let number = NavigationLink("Number", value: 1)
    let word = NavigationLink("Word", value: "w")
    let h = UIHarness {
      NavigationStack(path: binding) {
        number
          .navigationDestination(for: Int.self) { _ in word }
          .navigationDestination(for: String.self) { value in Text("Word \(value)") }
      }
    }
    self.tap(number, h)
    h.settle()
    self.tap(word, h)
    XCTAssertEqual(path.count, 2)
    XCTAssertEqual(h.first(NavigationStack.self)!.depth, 2)
  }

  // MARK: - Keys

  func testEscapeAndCommandBracketPop() {
    var path = [1, 2]
    let binding = Binding(get: { path }, set: { path = $0 })
    let h = UIHarness { NavigationStack(path: binding) { Text("Root") } }
    let stack = h.first(NavigationStack.self)!
    h.press(.escape)
    XCTAssertEqual(stack.depth, 1)
    h.press("[", modifiers: .command)
    XCTAssertEqual(stack.depth, 0)
    XCTAssertEqual(path, [])
  }

  func testConstantPathIgnoresLinksAndBackKeys() {
    let link = NavigationLink("One", value: 1)
    let h = UIHarness { NavigationStack(path: [2]) { link } }
    let stack = h.first(NavigationStack.self)!
    h.press(.escape)
    XCTAssertEqual(stack.depth, 1)
  }

  func testBackKeysPassThroughAtTheRoot() {
    var outer = 0
    let h = UIHarness {
      NavigationStack { Text("Root") }
        .onKeyPress(.escape) { outer += 1; return .handled }
    }
    h.press(.escape)
    XCTAssertEqual(outer, 1)
  }

  func testEscapeWithModifiersDoesNotPop() {
    let h = UIHarness { NavigationStack(path: [1]) { Text("Root") } }
    h.press(.escape, modifiers: .option)
    XCTAssertEqual(h.first(NavigationStack.self)!.depth, 1)
  }

  // MARK: - Transition

  func testPushSlidesInWithoutRelayoutPerFrame() {
    let link = NavigationLink("Open", destination: { Rectangle(.blue).frame(width: 100, height: 100) })
    let h = UIHarness { NavigationStack { link } }
    h.settle()
    self.tap(link, h)
    h.step()
    let pages = h.first(NavigationPages.self)!
    XCTAssertNotNil(pages.clipRect, "clipped while sliding")
    let generation = LayoutPass.generation
    h.step(frames: 5)
    XCTAssertEqual(LayoutPass.generation, generation, "sliding only redraws")
    XCTAssertNotNil(h.settle())
    XCTAssertNil(pages.clipRect)

    let renders = h.renders
    h.step(frames: 30)
    XCTAssertEqual(h.renders, renders, "idle after the push")
  }

  func testPushMidpointSnapshot() {
    let link = NavigationLink("Open", destination: {
      Rectangle(float4(0.2, 0.5, 0.9, 1)).frame(width: 120, height: 80).navigationTitle("Detail")
    })
    let h = UIHarness(size: float2(320, 240)) {
      NavigationStack {
        VStack(spacing: 12) {
          Rectangle(float4(0.9, 0.4, 0.2, 1)).frame(width: 120, height: 80)
          link
        }
        .navigationTitle("Home")
      }
    }
    h.settle()
    assertSnapshot(h.snapshot(), named: "root", testCase: self)
    self.tap(link, h)
    h.advance(0.15)
    assertSnapshot(h.snapshot(), named: "push-midpoint", testCase: self)
    h.settle()
    assertSnapshot(h.snapshot(), named: "pushed", testCase: self)
  }

  func testInterruptedPushThenPopEndsConsistent() {
    let detail = Text("Detail")
    let rootText = Text("Root")
    let link = NavigationLink("Open", destination: { detail })
    let h = UIHarness { NavigationStack { rootText; link } }
    self.tap(link, h)
    h.step(frames: 3)
    h.press(.escape)
    XCTAssertNotNil(h.settle())
    XCTAssertFalse(detail.mounted)
    XCTAssertTrue(self.isShown(rootText))
    XCTAssertEqual(h.first(NavigationStack.self)!.depth, 0)
    for entry in h.all(NavigationEntry.self) {
      XCTAssertEqual(entry.slide, 0)
      XCTAssertFalse(entry.inTransition)
    }
  }

  func testUnmountMidTransitionCleansUp() {
    let detail = Text("Detail")
    let link = NavigationLink("Open", destination: { detail })
    let stack = NavigationStack { link }
    let frame = Frame(float2(320, 240)) { stack }
    let h = UIHarness { frame }
    self.tap(link, h)
    h.step(frames: 2)
    frame.setChild(EmptyElement(), h.context)
    XCTAssertFalse(stack.mounted)
    XCTAssertFalse(detail.mounted)
    XCTAssertNotNil(h.settle())
  }

  // MARK: - Titles

  func testTitlesShowInTheBarAndOnTheBackButton() {
    let title = Text("Root").navigationTitle("Home")
    let link = NavigationLink("Open", destination: { Text("Detail").navigationTitle("Detail") })
    let h = UIHarness { NavigationStack { title; link } }
    XCTAssertEqual(self.bar(h).title.text, "Home")

    self.tap(link, h)
    XCTAssertEqual(self.bar(h).title.text, "Detail")
    XCTAssertEqual(self.bar(h).back.title?.text, "‹ Home")

    title.setTitle("Start", h.context)
    XCTAssertEqual(self.bar(h).back.title?.text, "‹ Start")
  }

  // MARK: - Split view

  func testSidebarSelectionShowsDetailAndMovesTheHighlight() {
    let inbox = NavigationLink("Inbox", value: "inbox")
    let sent = NavigationLink("Sent", value: "sent")
    let placeholder = Text("Select")
    let h = UIHarness(size: float2(480, 240)) {
      NavigationSplitView {
        inbox
        sent.navigationDestination(for: String.self) { value in Text("Box \(value)") }
      } detail: {
        placeholder
      }
    }
    XCTAssertTrue(self.isShown(placeholder))

    self.tap(inbox, h)
    XCTAssertTrue(self.isShown(h.all(Text.self).first { $0.text == "Box inbox" }!))
    XCTAssertFalse(placeholder.mounted)
    XCTAssertTrue(inbox.face.isSelected)
    XCTAssertFalse(sent.face.isSelected)

    self.tap(sent, h)
    XCTAssertNil(h.all(Text.self).first { $0.text == "Box inbox" })
    XCTAssertNotNil(h.all(Text.self).first { $0.text == "Box sent" })
    XCTAssertFalse(inbox.face.isSelected)
    XCTAssertTrue(sent.face.isSelected)
  }

  func testDetailLinksPushInTheDetailColumnThroughSidebarDestinations() {
    let inner = NavigationLink("Deeper", value: 2)
    let item = NavigationLink("Item", value: 1)
    let h = UIHarness(size: float2(480, 240)) {
      NavigationSplitView {
        item.navigationDestination(for: Int.self) { value in
          value == 1 ? inner as UIElement : Text("Page \(value)")
        }
      } detail: {
        Text("Select")
      }
    }
    self.tap(item, h)
    h.settle()
    self.tap(inner, h)
    let detailStack = h.all(NavigationStack.self).first!
    XCTAssertEqual(detailStack.depth, 1)
    XCTAssertNotNil(h.settle())
    XCTAssertTrue(self.isShown(h.all(Text.self).first { $0.text == "Page 2" }!))
    XCTAssertTrue(item.face.isSelected, "the sidebar selection stays")
  }

  // MARK: - Split view selection

  private func boxes(_ selection: String?, _ reported: @escaping (AnyHashable) -> Void) -> (NavigationSplitView, NavigationLink, NavigationLink, Text) {
    let inbox = NavigationLink("Inbox", value: "inbox")
    let sent = NavigationLink("Sent", value: "sent")
    let placeholder = Text("Select")
    let split = NavigationSplitView(selection: selection) {
      inbox
      sent.navigationDestination(for: String.self) { value in Text("Box \(value)") }
    } detail: {
      placeholder
    }
    split.onSelectionChange = reported
    return (split, inbox, sent, placeholder)
  }

  func testInitialSelectionResolvesAtMount() {
    let (split, inbox, sent, placeholder) = self.boxes("sent") { _ in }
    let h = UIHarness(size: float2(480, 240)) { split }
    XCTAssertTrue(self.isShown(h.all(Text.self).first { $0.text == "Box sent" }!))
    XCTAssertFalse(placeholder.mounted)
    XCTAssertTrue(sent.face.isSelected)
    XCTAssertFalse(inbox.face.isSelected)
  }

  func testBoundSelectionReportsAndWaitsForTheValue() {
    var reported: [AnyHashable] = []
    let (split, inbox, sent, _) = self.boxes("sent") { reported.append($0) }
    let h = UIHarness(size: float2(480, 240)) { split }
    self.tap(inbox, h)
    XCTAssertEqual(reported, ["inbox"])
    XCTAssertTrue(sent.face.isSelected, "nothing changes until the value comes back")

    split.setSelection("inbox", h.context)
    XCTAssertTrue(inbox.face.isSelected)
    XCTAssertFalse(sent.face.isSelected)
    XCTAssertNotNil(h.all(Text.self).first { $0.text == "Box inbox" })
    XCTAssertNil(h.all(Text.self).first { $0.text == "Box sent" })
  }

  func testNilSelectionShowsThePlaceholder() {
    let (split, _, sent, placeholder) = self.boxes("sent") { _ in }
    let h = UIHarness(size: float2(480, 240)) { split }
    split.setSelection(String?.none, h.context)
    XCTAssertTrue(self.isShown(placeholder))
    XCTAssertFalse(sent.face.isSelected)
  }

  func testSelectionBindingRoundTrip() {
    var selected = "inbox"
    let binding = Binding(get: { selected }, set: { selected = $0 })
    let inbox = NavigationLink("Inbox", value: "inbox")
    let sent = NavigationLink("Sent", value: "sent")
    let h = UIHarness(size: float2(480, 240)) {
      NavigationSplitView(selection: binding) {
        inbox
        sent.navigationDestination(for: String.self) { value in Text("Box \(value)") }
      }
    }
    self.tap(sent, h)
    XCTAssertEqual(selected, "sent")
    XCTAssertTrue(sent.face.isSelected)
    XCTAssertNotNil(h.all(Text.self).first { $0.text == "Box sent" })
  }

  func testRestoredSelectionWaitsForItsDestinationToBeArmed() {
    // What `@Component` builds: the destination unarmed, its closure assigned after mount.
    let destination = NavigationLink("Sent", value: "sent").navigationDestination(for: String.self)
    let split = NavigationSplitView(selection: "sent") { destination } detail: { Text("Select") }
    let h = UIHarness(size: float2(480, 240)) { split }
    XCTAssertNil(h.all(Text.self).first { $0.text == "Box sent" })
    destination.destination = { value in Text("Box \(value)") }
    h.step()
    XCTAssertTrue(self.isShown(h.all(Text.self).first { $0.text == "Box sent" }!))
  }

  func testSelectionAdaptDropsOtherTypes() {
    var written: [Int] = []
    let adapted = NavigationSplitView.adapt { (value: Int) in written.append(value) }
    adapted(AnyHashable("no"))
    adapted(AnyHashable(3))
    XCTAssertEqual(written, [3])
  }

  func testSplitViewSnapshot() {
    let first = NavigationLink("First", value: 1)
    let h = UIHarness(size: float2(480, 240)) {
      NavigationSplitView {
        first
        NavigationLink("Second", value: 2)
          .navigationDestination(for: Int.self) { value in
            Rectangle(float4(0.3, 0.6, 0.3, 1)).frame(width: 80, height: 60).navigationTitle("Item \(value)")
          }
      } detail: {
        Text("Select an item")
      }
    }
    self.tap(first, h)
    h.settle()
    assertSnapshot(h.snapshot(), named: "split-selected", testCase: self)
  }
}
