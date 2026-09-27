@testable import MetalGraphicsLib
import simd
import XCTest

/// Sheets, covers, popovers, alerts and dialogs shown over the app's window.
@MainActor
final class ModalTests: XCTestCase {
  // MARK: - Helpers

  /// State for a binding in a tree built by hand.
  final class Flag {
    var value: Bool
    init(_ value: Bool = false) { self.value = value }
    var binding: Binding<Bool> { Binding(get: { self.value }, set: { self.value = $0 }) }
  }

  struct Item: Identifiable, Equatable {
    let id: Int
  }

  /// What the pointer hits on a button: the `HittableView` under its dimmer.
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

  /// The button on a presentation with `title`.
  private func button(_ title: String, _ h: UIHarness) -> Button {
    guard let button = h.overlayAll(Button.self).first(where: { $0.title?.text == title }) else {
      fatalError("no button \(title)")
    }
    return button
  }

  /// Presents what `element` shows as if its binding just went true.
  private func present(_ element: PresentationElement, _ flag: Flag, _ h: UIHarness) {
    flag.value = true
    element.setIsPresented(true, h.context)
    XCTAssertNotNil(h.settle())
  }

  private let window = float2(320, 240)

  private func background() -> Frame {
    Rectangle(float4(0.85, 0.87, 0.9, 1)).frame(width: 320, height: 240)
  }

  // MARK: - Presenting and dismissing

  func testSheetPresentsOnTheBindingAndEscapeDismissesIt() {
    let flag = Flag()
    var dismissed = 0
    let text = Text("On the sheet")
    let presenter = self.background().sheet(isPresented: flag.binding, onDismiss: { dismissed += 1 }) { text }
    let h = UIHarness { presenter }
    XCTAssertTrue(h.context.overlays.isEmpty)

    self.present(presenter, flag, h)
    XCTAssertEqual(h.context.overlays.count, 1)
    XCTAssertTrue(text.mounted)

    h.press(.escape)
    XCTAssertFalse(flag.value, "Escape writes the binding back")
    XCTAssertFalse(presenter.isPresented)
    XCTAssertEqual(dismissed, 0, "onDismiss waits until it has gone")
    XCTAssertNotNil(h.settle())
    XCTAssertTrue(h.context.overlays.isEmpty)
    XCTAssertFalse(text.mounted)
    XCTAssertEqual(dismissed, 1)
  }

  func testPresentedAtMountWhenTheBindingIsAlreadyTrue() {
    let flag = Flag(true)
    let text = Text("Already")
    let h = UIHarness { self.background().sheet(isPresented: flag.binding) { text } }
    XCTAssertNotNil(h.settle())
    XCTAssertTrue(text.mounted)
    XCTAssertEqual(h.context.overlays.count, 1)
  }

  func testContentIsBuiltAfreshEachTime() {
    let flag = Flag()
    var builds = 0
    let presenter = self.background().sheet(isPresented: flag.binding) {
      builds += 1
      return [Text("Sheet \(builds)")]
    }
    let h = UIHarness { presenter }
    self.present(presenter, flag, h)
    h.press(.escape)
    h.settle()
    self.present(presenter, flag, h)
    XCTAssertEqual(builds, 2)
  }

  func testBackdropClickDismissesAndCardClickDoesNot() {
    let flag = Flag()
    let presenter = self.background().sheet(isPresented: flag.binding) {
      Rectangle(.white).frame(width: 100, height: 60)
    }
    let h = UIHarness { presenter }
    self.present(presenter, flag, h)
    // The sheet is at least 200 wide, centred, 16 below the top.
    h.click(at: float2(160, 40))
    XCTAssertTrue(flag.value, "a click on the card stays")
    h.click(at: float2(160, 200))
    XCTAssertFalse(flag.value, "a click on the backdrop dismisses")
  }

  func testConstantBindingIsNeverDismissedByTheUser() {
    let presenter = self.background().sheet(isPresented: .constant(true)) { Text("Stuck") }
    let h = UIHarness { presenter }
    XCTAssertNotNil(h.settle())
    h.press(.escape)
    h.click(at: float2(160, 200))
    XCTAssertNotNil(h.settle())
    XCTAssertEqual(h.context.overlays.count, 1)
  }

  func testRepresentingWhileLeavingShowsANewOne() {
    let flag = Flag()
    let presenter = self.background().sheet(isPresented: flag.binding) { Text("Again") }
    let h = UIHarness { presenter }
    self.present(presenter, flag, h)
    h.press(.escape)
    flag.value = true
    presenter.setIsPresented(true, h.context)
    XCTAssertEqual(h.context.overlays.count, 2, "the old one still leaving")
    XCTAssertNotNil(h.settle())
    XCTAssertEqual(h.context.overlays.count, 1)
    XCTAssertTrue(presenter.isShowing)
  }

  func testUnmountingThePresenterRemovesItWithoutWritingBack() {
    let flag = Flag()
    var dismissed = 0
    let presenter = self.background().sheet(isPresented: flag.binding, onDismiss: { dismissed += 1 }) { Text("Gone") }
    let stack = VStack { presenter }
    let h = UIHarness { stack }
    self.present(presenter, flag, h)
    stack.replaceChildren([], h.context)
    XCTAssertTrue(h.context.overlays.isEmpty, "at once")
    XCTAssertTrue(flag.value)
    XCTAssertEqual(dismissed, 0)
    XCTAssertNotNil(h.settle())
  }

  // MARK: - Modality

  func testNothingUnderASheetGetsInput() {
    var taps = 0
    var hovers: [Bool] = []
    var presses = 0
    var keys = 0
    var name = ""
    let button = Button("Under") { taps += 1 }
    let hoverSpot = Rectangle(.green).frame(width: 40, height: 20).onHover { hovering, _ in hovers.append(hovering) }
    let pressSpot = Rectangle(.blue).frame(width: 40, height: 20).onPress { down, _ in if down { presses += 1 } }
    let field = TextField("Name", text: Binding(get: { name }, set: { name = $0 }))
    let scroll = ScrollView { Rectangle(.red).frame(width: 40, height: 400) }
    let tree = VStack(alignment: .leading, spacing: 4) {
      button
      hoverSpot
      pressSpot
      field.frame(width: 140)
      scroll.frame(width: 40, height: 40)
    }
    .padding(Inset(left: 8, top: 90, right: 0, bottom: 0))
    .frame(width: 320, height: 240, alignment: .topLeading)
    .onKeyPress(.space) { keys += 1; return .handled }
    // Ignoring writes, so the clicks on the backdrop below do not dismiss it.
    var shown = false
    let presenter = tree.sheet(isPresented: Binding(get: { shown }, set: { _ in })) { Text("Modal") }
    let h = UIHarness { presenter }
    h.settle()
    let focusable = h.first(FocusableElement.self)!

    shown = true
    presenter.setIsPresented(true, h.context)
    XCTAssertNotNil(h.settle())
    self.tap(button, h)
    XCTAssertEqual(taps, 0, "tap")
    h.move(to: float2(20, 125))
    XCTAssertEqual(hovers, [], "hover")
    h.mouseDown(at: float2(20, 150))
    h.mouseUp(at: float2(20, 150))
    XCTAssertEqual(presses, 0, "press")
    h.click(on: focusable)
    XCTAssertNil(h.context.focused, "focus click")
    h.press(.tab)
    XCTAssertNil(h.context.focused, "Tab")
    h.press(.space)
    XCTAssertEqual(keys, 0, "key")
    h.scroll(by: float2(0, -30), at: scroll.position + float2(10, 10))
    XCTAssertEqual(scroll.offset, .zero, "scroll")

    shown = false
    presenter.setIsPresented(false, h.context)
    XCTAssertNotNil(h.settle())
    self.tap(button, h)
    XCTAssertEqual(taps, 1, "live again once it has gone")
  }

  func testEscapeDoesNotPopTheStackUnderASheet() {
    let flag = Flag()
    let link = NavigationLink("Open", destination: { Text("Detail") })
    let stack = NavigationStack { link }
    let presenter = stack.sheet(isPresented: flag.binding) { Text("Sheet") }
    let h = UIHarness { presenter }
    h.settle()
    self.tap(link, h)
    XCTAssertNotNil(h.settle())
    XCTAssertEqual(stack.depth, 1)

    self.present(presenter, flag, h)
    h.press(.escape)
    XCTAssertFalse(flag.value)
    XCTAssertEqual(stack.depth, 1, "the sheet took it")
    XCTAssertNotNil(h.settle())
    h.press(.escape)
    XCTAssertEqual(stack.depth, 0)
  }

  func testTabStaysInTheSheetAndFocusComesBack() {
    var a = "", b = "", c = ""
    let fieldA = TextField("A", text: Binding(get: { a }, set: { a = $0 }))
    let flag = Flag()
    let presenter = VStack { fieldA.frame(width: 200) }
      .padding(Inset(left: 0, top: 150, right: 0, bottom: 0))
      .frame(width: 320, height: 240, alignment: .top)
      .sheet(isPresented: flag.binding) {
        VStack(spacing: 8) {
          TextField("B", text: Binding(get: { b }, set: { b = $0 })).frame(width: 180)
          TextField("C", text: Binding(get: { c }, set: { c = $0 })).frame(width: 180)
        }
      }
    let h = UIHarness { presenter }
    h.settle()
    let underField = h.first(FocusableElement.self)!
    h.click(on: underField)
    XCTAssertTrue(h.context.focused === underField)

    self.present(presenter, flag, h)
    XCTAssertNil(h.context.focused, "presenting takes focus away")
    let fields = h.overlayAll(FocusableElement.self)
    XCTAssertEqual(fields.count, 2)
    h.press(.tab)
    XCTAssertTrue(h.context.focused === fields[0])
    h.press(.tab)
    XCTAssertTrue(h.context.focused === fields[1])
    h.press(.tab)
    XCTAssertTrue(h.context.focused === fields[0], "wraps round inside the sheet")

    flag.value = false
    presenter.setIsPresented(false, h.context)
    XCTAssertNotNil(h.settle())
    XCTAssertTrue(h.context.focused === underField, "focus comes back")
  }

  // MARK: - Stacking

  func testAnAlertOnASheetGoesFirst() {
    let sheetFlag = Flag()
    let alertFlag = Flag()
    let inner = Text("Sheet body").alert("Sure?", isPresented: alertFlag.binding) { Button("Yes") {} }
    let presenter = self.background().sheet(isPresented: sheetFlag.binding) { inner }
    let h = UIHarness { presenter }
    self.present(presenter, sheetFlag, h)
    self.present(inner, alertFlag, h)
    XCTAssertEqual(h.context.overlays.count, 2)

    h.press(.escape)
    XCTAssertFalse(alertFlag.value)
    XCTAssertTrue(sheetFlag.value, "only the alert")
    XCTAssertNotNil(h.settle())
    h.press(.escape)
    XCTAssertFalse(sheetFlag.value)
  }

  func testDismissingTheSheetDismissesTheAlertOnIt() {
    let sheetFlag = Flag()
    let alertFlag = Flag()
    let inner = Text("Sheet body").alert("Sure?", isPresented: alertFlag.binding) { Button("Yes") {} }
    let presenter = self.background().sheet(isPresented: sheetFlag.binding) { inner }
    let h = UIHarness { presenter }
    self.present(presenter, sheetFlag, h)
    self.present(inner, alertFlag, h)

    sheetFlag.value = false
    presenter.setIsPresented(false, h.context)
    XCTAssertFalse(alertFlag.value, "its binding written back too")
    XCTAssertNotNil(h.settle())
    XCTAssertTrue(h.context.overlays.isEmpty)
  }

  // MARK: - Alerts and dialogs

  func testAlertButtonsReturnAndEscape() {
    let flag = Flag()
    var log: [String] = []
    let presenter = self.background().alert("Delete?", isPresented: flag.binding) {
      Button("Cancel", role: .cancel) { log.append("cancel") }
      Button("Delete", role: .destructive) { log.append("delete") }
      Button("Keep") { log.append("keep") }
    } message: {
      Text("Gone for good.")
    }
    let h = UIHarness { presenter }

    self.present(presenter, flag, h)
    XCTAssertEqual(h.overlayAll(Button.self).map { $0.title?.text }, ["Delete", "Keep", "Cancel"], "stacked, cancel last")
    h.press(.return)
    XCTAssertEqual(log, ["keep"], "Return runs the first without a role")
    XCTAssertFalse(flag.value)
    h.settle()

    self.present(presenter, flag, h)
    h.press(.escape)
    XCTAssertEqual(log, ["keep", "cancel"])
    XCTAssertFalse(flag.value)
    h.settle()

    self.present(presenter, flag, h)
    self.tap(self.button("Delete", h), h)
    XCTAssertEqual(log, ["keep", "cancel", "delete"])
    XCTAssertFalse(flag.value, "any button dismisses")
  }

  func testTwoButtonAlertPutsCancelFirst() {
    let flag = Flag()
    let presenter = self.background().alert("Quit?", isPresented: flag.binding) {
      Button("Quit") {}
      Button("Cancel", role: .cancel) {}
    }
    let h = UIHarness { presenter }
    self.present(presenter, flag, h)
    let buttons = h.overlayAll(Button.self)
    XCTAssertEqual(buttons.map { $0.title?.text }, ["Cancel", "Quit"])
    XCTAssertEqual(buttons[1].style, .borderedProminent)
    XCTAssertLessThan(buttons[0].face.position.x, buttons[1].face.position.x, "side by side")
  }

  func testAlertWithNoButtonsHasOK() {
    let flag = Flag()
    let presenter = self.background().alert("Saved", isPresented: flag.binding) {}
    let h = UIHarness { presenter }
    self.present(presenter, flag, h)
    XCTAssertEqual(h.overlayAll(Button.self).map { $0.title?.text }, ["OK"])
    h.press(.return)
    XCTAssertFalse(flag.value)
  }

  func testDisabledDefaultButtonDoesNothingOnReturn() {
    let flag = Flag()
    var ran = false
    let presenter = self.background().alert("Send?", isPresented: flag.binding) {
      Button("Send") { ran = true }.disabled(true)
      Button("Cancel", role: .cancel) {}
    }
    let h = UIHarness { presenter }
    self.present(presenter, flag, h)
    h.press(.return)
    XCTAssertFalse(ran)
    XCTAssertTrue(flag.value)
  }

  func testDialogGetsCancelAndItsBackdropCancels() {
    let flag = Flag()
    var saved = 0
    let presenter = self.background().confirmationDialog("Save changes?", isPresented: flag.binding) {
      Button("Save") { saved += 1 }
    }
    let h = UIHarness { presenter }
    self.present(presenter, flag, h)
    XCTAssertEqual(h.overlayAll(Button.self).map { $0.title?.text }, ["Save", "Cancel"])
    h.click(at: float2(10, 230))
    XCTAssertFalse(flag.value)
    XCTAssertEqual(saved, 0)
  }

  func testAlertTitleFollowsItsSetter() {
    let flag = Flag()
    let presenter = self.background().alert("One", isPresented: flag.binding) {}
    let h = UIHarness { presenter }
    self.present(presenter, flag, h)
    presenter.setTitle("Two", h.context)
    h.settle()
    XCTAssertTrue(h.overlayAll(Text.self).contains { $0.text == "Two" })
  }

  // MARK: - Items

  func testItemSheetFollowsItsItem() {
    var current: Item? = Item(id: 1)
    var built: [Int] = []
    let presenter = self.background().sheet(item: Binding(get: { current }, set: { current = $0 })) { item in
      built.append(item.id)
      return [Text("Item \(item.id)")]
    }
    let h = UIHarness { presenter }
    XCTAssertNotNil(h.settle())
    XCTAssertEqual(built, [1])

    current = Item(id: 2)
    presenter.setItem(current, h.context)
    XCTAssertEqual(built, [1, 2], "a new item is presented afresh")
    XCTAssertEqual(h.context.overlays.count, 2)
    XCTAssertNotNil(h.settle())
    XCTAssertEqual(h.context.overlays.count, 1)

    presenter.setItem(Item(id: 2), h.context)
    XCTAssertEqual(built, [1, 2], "the same one changes nothing")

    h.press(.escape)
    XCTAssertNil(current, "Escape writes nil back")
    XCTAssertNotNil(h.settle())
    XCTAssertTrue(h.context.overlays.isEmpty)
  }

  // MARK: - Dismiss from inside

  final class Dismisser : SingleChildElement {
    @Environment(\.dismiss) var dismiss
    @Environment(\.isPresented) var isInPresentation

    override init() {
      super.init()
      self.applyContent([Text("Inside")])
    }
  }

  func testDismissActionFromTheContent() {
    let flag = Flag()
    let dismisser = Dismisser()
    let presenter = self.background().sheet(isPresented: flag.binding) { dismisser }
    let h = UIHarness { presenter }
    self.present(presenter, flag, h)
    XCTAssertTrue(dismisser.isInPresentation)
    dismisser.dismiss()
    XCTAssertFalse(flag.value)

    let outside = Dismisser()
    let h2 = UIHarness { outside }
    XCTAssertFalse(outside.isInPresentation)
    outside.dismiss()
    XCTAssertNotNil(h2.settle())
  }

  func testDismissPresentationFromAButton() {
    let flag = Flag()
    var done: Button!
    done = Button("Done") { done.dismissPresentation() }
    let presenter = self.background().sheet(isPresented: flag.binding) { done }
    let h = UIHarness { presenter }
    self.present(presenter, flag, h)
    self.tap(done, h)
    XCTAssertFalse(flag.value)
  }

  // MARK: - Popover and cover

  func testPopoverModifierPointsAtItsElementAndIsModal() {
    let flag = Flag()
    var presses = 0
    let source = Rectangle(.blue).frame(width: 60, height: 24)
    let presenter = source.popover(isPresented: flag.binding) { Rectangle(.white).frame(width: 80, height: 40) }
    let h = UIHarness {
      ZStack(alignment: .topLeading) {
        Rectangle(.green).frame(width: 320, height: 240).onPress { down, _ in if down { presses += 1 } }
        presenter.padding(Inset(left: 100, top: 40, right: 0, bottom: 0))
      }
    }
    h.settle()
    self.present(presenter, flag, h)
    let layer = h.context.overlays.first as? PopoverLayer
    XCTAssertNotNil(layer)
    XCTAssertTrue(layer!.contains(float2(130, 64 + 4 + 20)), "below its element, centred on it")

    h.mouseDown(at: float2(20, 200))
    h.mouseUp(at: float2(20, 200))
    XCTAssertEqual(presses, 0, "a press under it is taken")
    XCTAssertFalse(flag.value, "a click outside dismisses it")
  }

  func testCoverFillsTheWindowAndOnlyEscapeDismissesIt() {
    let flag = Flag()
    let presenter = self.background().fullScreenCover(isPresented: flag.binding) { Text("Cover") }
    let h = UIHarness { presenter }
    self.present(presenter, flag, h)
    let layer = h.context.overlays.first!
    XCTAssertTrue(layer.contains(float2(1, 1)))
    XCTAssertTrue(layer.contains(float2(319, 239)))
    h.click(at: float2(10, 10))
    XCTAssertTrue(flag.value, "no backdrop to click")
    h.press(.escape)
    XCTAssertFalse(flag.value)
  }

  func testScrollOutsideAMenuInASheetClosesOnlyTheMenu() {
    let flag = Flag()
    let anchor = HittableView(onTap: { _ in }) { Rectangle(.blue).frame(width: 60, height: 20) }
    let presenter = self.background().sheet(isPresented: flag.binding) { anchor }
    let h = UIHarness { presenter }
    self.present(presenter, flag, h)
    let menu = h.context.presentPopover(Rectangle(.white).frame(width: 60, height: 60), anchor: anchor)
    XCTAssertNotNil(h.settle())
    h.scroll(by: float2(0, -10), at: float2(300, 230))
    XCTAssertNotNil(h.settle())
    XCTAssertFalse(menu.isPresented)
    XCTAssertTrue(flag.value)
    XCTAssertEqual(h.context.overlays.count, 1)
  }

  // MARK: - Windows of their own

  func testABlockedTreeTakesNoInputAndLeavesItsHover() {
    var taps = 0
    var hovers: [Bool] = []
    var keys = 0
    let button = Button("Tap") { taps += 1 }
    let spot = Rectangle(.green).frame(width: 60, height: 30).onHover { hovering, _ in hovers.append(hovering) }
    let scroll = ScrollView { Rectangle(.red).frame(width: 40, height: 400) }
    let h = UIHarness {
      VStack(spacing: 8) {
        button
        spot
        scroll.frame(width: 40, height: 40)
      }
      .onKeyPress(.space) { keys += 1; return .handled }
    }
    h.settle()
    h.move(to: spot.position + float2(30, 15))
    XCTAssertEqual(hovers, [true])

    h.context.blockInput()
    h.step()
    XCTAssertEqual(hovers, [true, false], "what was hovered is left")
    self.tap(button, h)
    h.press(.space)
    h.scroll(by: float2(0, -20), at: scroll.position + float2(10, 10))
    h.move(to: spot.position + float2(20, 10))
    XCTAssertEqual(taps, 0)
    XCTAssertEqual(keys, 0)
    XCTAssertEqual(scroll.offset, .zero)
    XCTAssertEqual(hovers, [true, false])

    h.context.unblockInput()
    self.tap(button, h)
    XCTAssertEqual(taps, 1)
  }

  func testAWindowStyleShowsOverTheTreeWhenThereIsNoWindow() {
    let flag = Flag()
    let presenter = self.background().sheet(isPresented: flag.binding) { Text("Inline") }
    let h = UIHarness { presenter.presentationWindow(.floating) }
    self.present(presenter, flag, h)
    XCTAssertEqual(h.context.overlays.count, 1, "a harness has no window to open one beside")
  }

  func testTheWindowStyleIsFoundAroundOnAndInside() {
    let a = Text("A").sheet(isPresented: false)
    let wrapped = a.presentationWindow(.attached)
    let b = Text("B").presentationWindow(.floating).sheet(isPresented: false)
    let c = Text("C").sheet(isPresented: false)
    let h = UIHarness { VStack { wrapped; b; c } }
    XCTAssertNotNil(h.settle())
    XCTAssertEqual(a.windowStyle, .attached, "around it")
    XCTAssertEqual(b.windowStyle, .floating, "on the element it modifies")
    XCTAssertEqual(c.windowStyle, .inline)
  }

  // MARK: - Cost

  func testPresentingOnlyRedrawsWhileItAnimatesAndThenIdles() {
    let flag = Flag()
    let presenter = self.background().sheet(isPresented: flag.binding) {
      Rectangle(.white).frame(width: 160, height: 80)
    }
    let h = UIHarness { presenter }
    h.settle()
    flag.value = true
    presenter.setIsPresented(true, h.context)
    h.step(frames: 2)
    let generation = LayoutPass.generation
    h.step(frames: 5)
    XCTAssertEqual(LayoutPass.generation, generation, "animating only redraws")
    XCTAssertNotNil(h.settle())

    let renders = h.renders
    h.step(frames: 30)
    XCTAssertEqual(h.renders, renders, "idle once shown")
  }

  // MARK: - Snapshots

  func testSnapshots() {
    let flag = Flag()
    let sheet = self.background().sheet(isPresented: flag.binding) {
      VStack(spacing: 10) {
        Text("Edit name")
        Rectangle(float4(0.2, 0.5, 0.9, 1)).frame(width: 160, height: 40)
      }
      .padding(16)
    }
    var h = UIHarness { sheet }
    self.present(sheet, flag, h)
    assertSnapshot(h.snapshot(), named: "sheet", testCase: self)

    let alert = self.background().alert("Delete “Notes”?", isPresented: flag.binding) {
      Button("Delete", role: .destructive) {}
      Button("Cancel", role: .cancel) {}
    } message: {
      Text("This cannot be undone.")
    }
    h = UIHarness { alert }
    self.present(alert, flag, h)
    assertSnapshot(h.snapshot(), named: "alert", testCase: self)

    let dialog = self.background().confirmationDialog("Save changes?", isPresented: flag.binding) {
      Button("Save") {}
      Button("Don’t Save", role: .destructive) {}
    }
    h = UIHarness { dialog }
    self.present(dialog, flag, h)
    assertSnapshot(h.snapshot(), named: "confirmation-dialog", testCase: self)

    let cover = self.background().fullScreenCover(isPresented: flag.binding) { Text("Covering everything") }
    h = UIHarness { cover }
    self.present(cover, flag, h)
    assertSnapshot(h.snapshot(), named: "full-screen-cover", testCase: self)

    let popover = Rectangle(.blue).frame(width: 60, height: 24)
      .popover(isPresented: flag.binding) { Text("Details").padding(12) }
    h = UIHarness { ZStack { self.background(); popover } }
    self.present(popover, flag, h)
    assertSnapshot(h.snapshot(), named: "popover-modifier", testCase: self)

    let styled = self.background().sheet(isPresented: flag.binding) { Text("Large").padding(16) }
    h = UIHarness { styled.font(.system(size: 28)) }
    self.present(styled, flag, h)
    assertSnapshot(h.snapshot(), named: "sheet-font", testCase: self)
  }
}
