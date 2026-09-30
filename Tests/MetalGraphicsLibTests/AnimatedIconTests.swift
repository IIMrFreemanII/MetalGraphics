@testable import MetalGraphicsLib
import simd
import XCTest

@MainActor
final class AnimatedIconTests: XCTestCase {
  /// Every glyph at rest (but the spinner, which never rests), then the stateful ones held
  /// active, on the content background.
  private func sheet() -> UIElement {
    func row(_ glyphs: [AnimatedGlyph], active: Bool?) -> UIElement {
      let icons: [UIElement] = glyphs.map { AnimatedIcon($0, active: active).foregroundColor(.label) }
      return HStack(spacing: 8) { () -> [UIElement] in return icons }
    }
    let resting = AnimatedGlyph.allCases.filter { $0 != .spinner }
    let stateful = AnimatedGlyph.allCases.filter(\.isStateful)
    return ZStack {
      Rectangle(.contentBackground)
      VStack(alignment: .leading, spacing: 8) {
        row(Array(resting[0..<16]), active: nil)
        row(Array(resting[16..<32]), active: nil)
        row(Array(resting[32..<48]), active: nil)
        row(Array(resting[48...]), active: nil)
        row(Array(stateful.prefix(16)), active: true)
        row(Array(stateful.dropFirst(16)), active: true)
      }
    }
  }

  func testGlyphsAtRestAndHeld() {
    let h = UIHarness(size: float2(400, 150)) { self.sheet() }
    XCTAssertNotNil(h.settle(), "icons at rest and made active do not animate")
    assertSnapshot(h.snapshot(), named: "animated-icons-light", testCase: self)
    h.context.setTheme(.dark)
    h.settle()
    assertSnapshot(h.snapshot(), named: "animated-icons-dark", testCase: self)
    h.context.setTheme(.light)
  }

  func testEveryGlyphReadsItsTemplate() {
    XCTAssertEqual(AnimatedGlyph.allCases.count, 63, "the template's 56 and our 7")
    for glyph in AnimatedGlyph.allCases {
      let style = glyph.style
      XCTAssertGreaterThan(style.nodes.count, 3, "\(glyph): the three groups and its parts")
      XCTAssertFalse(style.rules.isEmpty, "\(glyph)")
      for rule in style.rules {
        for decl in rule.declarations {
          if case .animation(let a?) = decl { XCTAssertGreaterThan(a.duration, 0, "\(glyph): \(a.keyframes.name)") }
        }
      }
    }
    // The template's own numbers: the spring settles in 1.338 s, and a chevron is 10 × 10.
    XCTAssertEqual(GlyphEasing.springDuration, 1.338, accuracy: 0.0005)
    XCTAssertEqual(AnimatedGlyph.chevronRight.box, [10, 10])
    XCTAssertEqual(AnimatedGlyph(ThemeIcon.folder), .folder)
  }

  func testTheSpringMatchesTheTemplatesCurve() {
    // The template samples the spring into CSS linear(); these are four of its 45 points
    // (at 8/44, 10/44, 20/44 and 30/44 of 1.338 s): the overshoot's peak, then settling.
    let e = GlyphEasing.spring
    XCTAssertEqual(e(8 / 44), 1.272, accuracy: 0.01)
    XCTAssertEqual(e(10 / 44), 1.171, accuracy: 0.01)
    XCTAssertEqual(e(20 / 44), 0.997, accuracy: 0.01)
    XCTAssertEqual(e(30 / 44), 0.995, accuracy: 0.01)
    XCTAssertEqual(e(1), 1)
  }

  func testHoveringItsRowPlaysAndHoldsItsPose() throws {
    let folder = AnimatedIcon(.folder)
    let row = ListRow("Sources", content: { folder })
    let h = UIHarness(size: float2(200, 40)) { row.frame(width: 200) }
    XCTAssertNotNil(h.settle())
    let rest = pixels(h.snapshot())

    let hit = try XCTUnwrap(h.first(HittableView.self))
    h.move(to: hit.position + hit.size * 0.5)
    XCTAssertTrue(folder.isHovering, "the row's hover reaches the icon")
    h.advance(0.1)
    XCTAssertFalse(h.isIdle, "mid-spring")
    XCTAssertNotNil(h.settle(), "a finished motion stops drawing")
    let rendersAfter = h.renders
    h.step(frames: 30)
    XCTAssertEqual(h.renders, rendersAfter, "an open folder at rest does not redraw")
    XCTAssertNotEqual(pixels(h.snapshot()), rest, "held open while hovered")

    h.mouseExit()
    XCTAssertFalse(folder.isHovering)
    XCTAssertNotNil(h.settle())
    XCTAssertEqual(pixels(h.snapshot()), rest, "closed again")
  }

  func testPressSquashesAndSpringsBack() throws {
    let icon = AnimatedIcon(.gear)
    let button = Button(action: nil) { icon }
    let h = UIHarness(size: float2(80, 60)) { button }
    h.settle()
    let hit = try XCTUnwrap(h.first(HittableView.self))
    let center = hit.position + hit.size * 0.5
    h.move(to: center)
    h.settle()
    let hovered = pixels(h.snapshot())
    h.mouseDown(at: center)
    XCTAssertTrue(icon.isPressedDown)
    h.settle()
    XCTAssertNotEqual(pixels(h.snapshot()), hovered, "squashed while held")
    h.mouseUp(at: center)
    XCTAssertFalse(icon.isPressedDown)
    XCTAssertNotNil(h.settle())
    XCTAssertEqual(pixels(h.snapshot()), hovered, "sprung back")
  }

  func testAPressOnARowReachesItsIconAndAClickTogglesIt() throws {
    // A row with no action takes no press of its own; its icon still squashes, and a click
    // changes a `.click` icon's state, as a pointerdown on the template's host does.
    let folder = AnimatedIcon(.folder, trigger: .click, active: false)
    let row = ListRow("Sources", content: { folder })
    let h = UIHarness(size: float2(200, 40)) { row.frame(width: 200) }
    h.settle()
    let hit = try XCTUnwrap(h.first(HittableView.self))
    let center = hit.position + hit.size * 0.5
    h.move(to: center)
    h.mouseDown(at: center)
    XCTAssertTrue(folder.isPressedDown, "the row's press reaches the icon")
    h.mouseUp(at: center)
    XCTAssertFalse(folder.isPressedDown)
    XCTAssertEqual(folder.active, true, "and the click opened it")
    XCTAssertNotNil(h.settle())
  }

  func testActiveSnapsAtFirstAndMovesAfter() {
    let chevron = AnimatedIcon(.chevronRight, active: true)
    let h = UIHarness(size: float2(40, 40)) { chevron }
    XCTAssertEqual(h.settle(), 0, "made active, it shows its end state without moving")

    chevron.setActive(false, h.context)
    XCTAssertFalse(h.isIdle, "a change afterwards springs")
    XCTAssertNotNil(h.settle())
  }

  func testThreeStates() {
    // sort: unset shows both arrows, true only the down one, false only the up one
    let sort = AnimatedIcon(.sort).scale(3)
    let h = UIHarness(size: float2(40, 40)) { sort }
    h.settle()
    let unset = pixels(h.snapshot())
    sort.setActive(true, h.context); h.settle()
    let descending = pixels(h.snapshot())
    sort.setActive(false, h.context); h.settle()
    let ascending = pixels(h.snapshot())
    XCTAssertNotEqual(unset, descending)
    XCTAssertNotEqual(descending, ascending)
    XCTAssertNotEqual(unset, ascending)
    sort.setActive(nil, h.context); h.settle()
    XCTAssertEqual(pixels(h.snapshot()), unset)
  }

  func testTheCheckmarkDrawsOnAndOff() {
    let check = AnimatedIcon(.checkmark, active: false).scale(3)
    let h = UIHarness(size: float2(40, 40)) { check }
    h.settle()
    let empty = pixels(h.snapshot())
    check.setActive(true, h.context)
    h.advance(0.1)
    let partway = pixels(h.snapshot())
    XCTAssertNotNil(h.settle())
    let drawn = pixels(h.snapshot())
    XCTAssertNotEqual(empty, partway)
    XCTAssertNotEqual(partway, drawn)
    check.setActive(false, h.context)
    XCTAssertNotNil(h.settle())
    XCTAssertEqual(pixels(h.snapshot()), empty, "drawn off again")
  }

  func testMountPlaysItsEntranceOnce() {
    let icon = AnimatedIcon(.warning, mount: true)
    let h = UIHarness(size: float2(40, 40)) { icon }
    XCTAssertFalse(h.isIdle, "the entrance plays")
    XCTAssertNotNil(h.settle())
    icon.replay(h.context)
    XCTAssertFalse(h.isIdle, "and plays again on replay")
    XCTAssertNotNil(h.settle())
  }

  func testALoopRunsUntilItStops() {
    let gear = AnimatedIcon(.gear, loop: true)
    let h = UIHarness(size: float2(40, 40)) { gear }
    var renders = h.renders
    h.step(frames: 30)
    XCTAssertGreaterThan(h.renders - renders, 10, "a looping gear turns")
    gear.setLoop(false, h.context)
    XCTAssertNotNil(h.settle(), "and stops")
    renders = h.renders
    h.step(frames: 30)
    XCTAssertEqual(h.renders, renders, "a stopped loop does not redraw")
  }

  func testTheSpinnerAlwaysTurnsOnWakes() {
    let spinner = AnimatedIcon(.spinner)
    let h = UIHarness(size: float2(40, 40)) { spinner }
    XCTAssertNotNil(h.settle(), "no display link: it steps on wakes")
    XCTAssertTrue(spinner.isMoving)
    let renders = h.renders
    h.step(frames: 60)
    // 30 frames a second, not 60
    XCTAssertGreaterThanOrEqual(h.renders - renders, 28)
    XCTAssertLessThanOrEqual(h.renders - renders, 32)
  }

  func testTheEyeFollowsThePointer() throws {
    let eye = AnimatedIcon(.eye).scale(3)
    let button = Button(action: nil) { eye }.frame(width: 120, height: 60)
    let h = UIHarness(size: float2(140, 80)) { button }
    h.settle()
    let hit = try XCTUnwrap(h.first(HittableView.self))
    h.move(to: hit.position + float2(10, hit.size.y * 0.5))
    h.settle()
    let left = pixels(h.snapshot())
    h.move(to: hit.position + float2(hit.size.x - 10, hit.size.y * 0.5))
    XCTAssertFalse(h.isIdle, "the pupil moves")
    h.settle()
    XCTAssertNotEqual(pixels(h.snapshot()), left, "looking the other way")
  }

  func testPlayPauseMorphsAndSettles() {
    let icon = AnimatedIcon(.playPause, active: false).scale(3)
    let h = UIHarness(size: float2(60, 60)) { icon }
    h.settle()
    let play = pixels(h.snapshot())
    icon.setActive(true, h.context)
    h.advance(0.05)
    XCTAssertFalse(h.isIdle)
    XCTAssertNotNil(h.settle())
    XCTAssertNotEqual(pixels(h.snapshot()), play, "paused")
    icon.setActive(false, h.context)
    XCTAssertNotNil(h.settle())
    XCTAssertEqual(pixels(h.snapshot()), play, "playing again")
  }

  // MARK: - In the components

  func testDisclosureGroupTurnsItsChevron() throws {
    let group = DisclosureGroup("Advanced", isExpanded: false, content: { Text("Inside") })
    let h = UIHarness(size: float2(300, 120)) { group.frame(width: 280) }
    let chevron = try XCTUnwrap(h.first(AnimatedIcon.self))
    XCTAssertEqual(chevron.glyph, .chevronRight)
    XCTAssertEqual(chevron.active, false)
    group.setIsExpanded(true, h.context)
    XCTAssertEqual(chevron.active, true, "expanded, the chevron turns down")
    XCTAssertNotNil(h.settle())
  }

  func testAStepperKeyPlaysOnlyItsGlyph() throws {
    let stepper = Stepper("Lives", value: 9, in: 1 ... 9)
    let h = UIHarness(size: float2(300, 60)) { stepper.frame(width: 280) }
    let icons = h.all(AnimatedIcon.self)
    XCTAssertEqual(icons.map(\.glyph), [.stepperMinus, .stepperPlus])
    XCTAssertEqual(icons.map(\.active), [false, true], "at the top of its range, + is blocked")
    let plus = icons[1]
    h.move(to: plus.position + plus.size * 0.5)
    XCTAssertTrue(plus.isHovering, "the + key's hover plays its glyph")
    XCTAssertFalse(icons[0].isHovering, "and not the other key's")
    XCTAssertNotNil(h.settle())
  }

  func testABlockedStepperKeyShakesNo() throws {
    let stepper = Stepper("Lives", value: 9, in: 1 ... 9)
    let h = UIHarness(size: float2(300, 60)) { stepper.frame(width: 280) }
    let plus = h.all(AnimatedIcon.self)[1]
    let center = plus.position + plus.size * 0.5
    h.move(to: center)
    h.settle()
    let rest = pixels(h.snapshot())
    h.mouseDown(at: center)
    XCTAssertTrue(plus.isPressedDown, "the key's press reaches its glyph")
    h.advance(0.08)
    XCTAssertNotEqual(pixels(h.snapshot()), rest, "shaking no mid-press")
    h.mouseUp(at: center)
    XCTAssertNotNil(h.settle())
    XCTAssertEqual(stepper.value, 9, "and the value stays at the top")
  }

  func testAFieldsLeadingIconFollowsTheField() throws {
    let field = TextField("Search", text: "").leadingIcon(.magnifier)
    let h = UIHarness(size: float2(300, 60)) { field.frame(width: 240) }
    XCTAssertNotNil(h.settle())
    let rest = pixels(h.snapshot())
    let hit = try XCTUnwrap(h.all(HittableView.self).first)
    h.move(to: hit.position + hit.size * 0.5)
    h.advance(0.15)
    XCTAssertNotEqual(pixels(h.snapshot()), rest, "the magnifier, drawn by the field's box, orbits as the field is hovered")
    XCTAssertNotNil(h.settle(), "and settles")
    XCTAssertEqual(pixels(h.snapshot()), rest, "back at rest")
  }

  // MARK: - Pieces

  func testTransformPivotsAboutTheOrigin() {
    let turn = AnimatedIcon.affine(.rotate(90), origin: float2(8, 8))!
    let p = turn.linear * float2(12, 8) + turn.translation
    XCTAssertEqual(p.x, 8, accuracy: 1e-4)
    XCTAssertEqual(p.y, 12, accuracy: 1e-4, "clockwise on screen, y down")
    XCTAssertNil(AnimatedIcon.affine(.identity, origin: float2(8, 8)))
  }

  func testEasingsMatchTheirCurves() {
    for easing in [GlyphEasing.ease, .easeIn, .easeOut, .easeInOut, .linear, .spring] {
      XCTAssertEqual(easing(0), 0, accuracy: 1e-4)
      XCTAssertEqual(easing(1), 1, accuracy: 1e-4)
    }
    XCTAssertEqual(GlyphEasing.easeInOut(0.5), 0.5, accuracy: 1e-3, "symmetric")
    XCTAssertGreaterThan(GlyphEasing.cubic(0.3, 1.5, 0.5, 1)(0.6), 1, "an overshoot passes its end")
  }

  func testTheCSSReaderReadsWhatTheGlyphsWrite() {
    XCTAssertEqual(GlyphCSS.time("calc(560ms*var(--mgi-t,1))"), 0.56)
    XCTAssertEqual(GlyphCSS.time(AnimatedGlyphSource.SP.split(separator: " ").map(String.init)[0]), GlyphEasing.springDuration)
    XCTAssertEqual(GlyphCSS.easing("cubic-bezier(.3,.7,.4,1)"), .cubic(0.3, 0.7, 0.4, 1))
    XCTAssertEqual(GlyphCSS.transform("translate(.4px,-1.7px) rotate(-18deg)"), GlyphTransform(tx: 0.4, ty: -1.7, rotation: -18))
    XCTAssertEqual(GlyphCSS.color("var(--mgi-ft,var(--mg-hue-teal))"), .tint(.fileType, fallback: .hue(.teal)))
    XCTAssertEqual(GlyphCSS.color("var(--mg-color-content-background,#fff)"), .role(.contentBackground))
  }

  private func pixels(_ image: CGImage) -> [UInt8] {
    let data = image.dataProvider!.data! as Data
    return [UInt8](data)
  }
}
