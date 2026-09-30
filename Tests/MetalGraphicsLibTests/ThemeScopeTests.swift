@testable import MetalGraphicsLib
import simd
import XCTest

/// `.colorScheme(_:)` and `.theme(_:)`: one subtree drawn with another theme than its window's.
@MainActor
final class ThemeScopeTests: XCTestCase {
  private let lightCard = SIMD4<UInt8>(255, 255, 255, 255)
  private let darkCard = SIMD4<UInt8>(0x23, 0x23, 0x26, 255)

  override func tearDown() {
    ThemeStore.shared.setSystemAppearance(.light)
    super.tearDown()
  }

  /// Two cards side by side: the right one in a dark scope, in a light window.
  private func sideBySide() -> (UIHarness, ThemeScopeElement) {
    let scope = Rectangle(.card).frame(width: 100, height: 100).colorScheme(.dark)
    let h = UIHarness {
      HStack(spacing: 20) {
        Rectangle(.card).frame(width: 100, height: 100)
        scope
      }
    }
    return (h, scope)
  }

  func testAScopeDrawsItsSubtreeWithItsTheme() {
    let (h, _) = self.sideBySide()
    XCTAssertEqual(h.pixel(at: float2(100, 120)), self.lightCard)
    XCTAssertEqual(h.pixel(at: float2(220, 120)), self.darkCard)
    // The window going dark leaves the dark scope dark, and the rest follows.
    h.context.setTheme(.dark)
    XCTAssertEqual(h.pixel(at: float2(100, 120)), self.darkCard)
    XCTAssertEqual(h.pixel(at: float2(220, 120)), self.darkCard)
    h.context.setTheme(.light)
  }

  func testChangingTheScopeOnlyRenders() {
    let (h, scope) = self.sideBySide()
    XCTAssertNotNil(h.settle())
    scope.setAppearance(.light, h.context)
    XCTAssertTrue(h.context.needsRender)
    XCTAssertFalse(h.context.pending.contains(.layout))
    XCTAssertEqual(h.pixel(at: float2(220, 120)), self.lightCard)
    scope.setTheme(.dark, h.context)
    XCTAssertEqual(h.pixel(at: float2(220, 120)), self.darkCard)
    // The same again changes nothing.
    XCTAssertNotNil(h.settle())
    scope.setTheme(.dark, h.context)
    XCTAssertFalse(h.context.needsRender)
  }

  /// Text takes its role colour from the scope: light text on the dark card.
  func testTextInAScopeTakesItsLabelColour() {
    let h = UIHarness {
      Rectangle(.label).frame(width: 60, height: 60).colorScheme(.dark)
    }
    let dark = Theme.dark[.label]
    let pixel = h.pixel(at: float2(160, 120))
    XCTAssertEqual(Float(pixel.x) / 255, dark.x, accuracy: 0.02)
  }

  func testAPopoverShownFromAScopeTakesItsTheme() {
    let anchor = HittableView(onTap: { _ in }) { Rectangle(.card).frame(width: 60, height: 20) }
    let h = UIHarness { anchor.colorScheme(.dark) }
    XCTAssertNotNil(h.settle())
    h.context.presentPopover(Rectangle(.card).frame(width: 60, height: 60), anchor: anchor)
    XCTAssertNotNil(h.settle())
    let content = try! XCTUnwrap(h.overlayAll(Rectangle.self).first)
    let center = content.position + float2(30, 30)
    XCTAssertEqual(h.pixel(at: center), self.darkCard)
  }

  func testATextEditorInAScopeTakesItsEditorTheme() {
    let editor = TextEditor(document: TextDocument("let x = 1"))
    let scope = editor.frame(width: 200, height: 60).colorScheme(.dark)
    let h = UIHarness { scope }
    h.settle()
    XCTAssertEqual(editor.theme, Theme.dark.editor)
    // The window changing leaves it in the scope's.
    h.context.setTheme(.dark)
    h.context.setTheme(.light)
    h.settle()
    XCTAssertEqual(editor.theme, Theme.dark.editor)
    scope.setAppearance(.light, h.context)
    h.settle()
    XCTAssertEqual(editor.theme, Theme.light.editor)
  }

  /// A shadow's role colour is resolved in the scope of what casts it.
  func testAShadowInAScopeUsesItsTheme() {
    let h = UIHarness {
      HStack(spacing: 40) {
        Rectangle(.card).frame(width: 60, height: 60).shadow(color: .label, radius: 0, x: 8, y: 8)
        Rectangle(.card).frame(width: 60, height: 60).shadow(color: .label, radius: 0, x: 8, y: 8).colorScheme(.dark)
      }
    }
    XCTAssertNotNil(h.settle())
    let left = try! XCTUnwrap(h.all(Rectangle.self).first)
    let right = try! XCTUnwrap(h.all(Rectangle.self).last)
    // Just past each card's bottom-right corner, inside its shadow.
    let lightShadow = h.pixel(at: left.position + float2(64, 64))
    let darkShadow = h.pixel(at: right.position + float2(64, 64))
    XCTAssertLessThan(lightShadow.x, 60, "light label is near black")
    XCTAssertGreaterThan(darkShadow.x, 200, "dark label is near white")
  }

  func testTheStoreFollowsForAColorScheme() {
    let custom = Theme.dark.with { $0.colors[.card] = float4(1, 0, 0, 1) }  // design: a test theme
    let (h, _) = self.sideBySide()
    XCTAssertEqual(h.pixel(at: float2(220, 120)), self.darkCard)
    ThemeStore.shared.setThemes(light: .light, dark: custom)
    defer { ThemeStore.shared.setThemes(light: .light, dark: .dark) }
    // Told as a window is: the window's theme set anew.
    h.context.setTheme(.dark)
    h.context.setTheme(.light)
    XCTAssertEqual(h.pixel(at: float2(220, 120)), SIMD4(255, 0, 0, 255))
  }
}
