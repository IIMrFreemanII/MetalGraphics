@testable import MetalGraphicsLib
import simd
import XCTest

@MainActor
final class ThemeTests: XCTestCase {
  func testHexColor() {
    XCTAssertEqual(float4(hex: 0xFF8000), float4(1, 128.0 / 255, 0, 1))
    XCTAssertEqual(float4(hex: 0x000000, alpha: 0.5), float4(0, 0, 0, 0.5))
    XCTAssertEqual(float4(1, 1, 1, 0.5).withAlpha(0.5), float4(1, 1, 1, 0.25))
  }

  /// Switching appearance never lays anything out again: only colours differ.
  func testLightAndDarkShareTheirType() {
    XCTAssertEqual(Theme.light.typography, Theme.dark.typography)
    XCTAssertEqual(Theme.light.spacing, Theme.dark.spacing)
    XCTAssertEqual(Theme.light.radii, Theme.dark.radii)
  }

  func testWithChangesACopy() {
    let brand = Theme.light.with { $0.colors[.accent] = float4(hex: 0xD97757) }
    XCTAssertEqual(brand[.accent], float4(hex: 0xD97757))
    XCTAssertEqual(Theme.light[.accent], float4(hex: 0x007AFF))
    XCTAssertEqual(brand[.label], Theme.light[.label])
  }

  /// Swift's and Metal's layouts of what the shaders read must match: Metal asserts its sizes.
  func testShaderStructLayouts() {
    XCTAssertEqual(MemoryLayout<GlassItem>.stride, 160)
    XCTAssertEqual(MemoryLayout<SceneData>.stride, 32)
    XCTAssertEqual(MemoryLayout<SceneData>.offset(of: \SceneData.background), 16)
  }

  func testSetThemeOnlyRenders() {
    let h = UIHarness { Text("Hello").padding() }
    h.settle()
    h.context.setTheme(.dark)
    XCTAssertTrue(h.context.needsRender)
    XCTAssertFalse(h.context.pending.contains(.layout), "an appearance change lays the tree out")
    h.step()
    XCTAssertTrue(h.graphics.theme === Theme.dark)
    XCTAssertNotNil(h.settle())
    // Setting the same theme again changes nothing.
    h.context.setTheme(.dark)
    XCTAssertFalse(h.context.needsRender)
    h.context.setTheme(.light)
  }

  /// A text editor that was not given a theme shows the window theme's, in light and dark.
  func testTextEditorFollowsTheThemeUnlessGivenOne() {
    let follows = TextEditor(document: TextDocument("let x = 1"))
    let fixed = TextEditor(document: TextDocument("let y = 2")).editorTheme(.light)
    let h = UIHarness {
      VStack {
        follows.frame(width: 200, height: 60)
        fixed.frame(width: 200, height: 60)
      }
    }
    h.settle()
    XCTAssertEqual(follows.theme, Theme.light.editor)
    h.context.setTheme(.dark)
    h.settle()
    XCTAssertEqual(follows.theme, Theme.dark.editor)
    XCTAssertEqual(fixed.theme, EditorTheme.light)
    h.context.setTheme(.light)
  }

  /// A role colour follows the theme when drawn, with nothing rebuilt.
  func testRoleColoursFollowTheTheme() {
    let h = UIHarness { Rectangle(.card).frame(width: 100, height: 100) }
    let light = h.pixel(at: float2(160, 120))
    XCTAssertEqual(light, SIMD4(255, 255, 255, 255))
    h.context.setTheme(.dark)
    let dark = h.pixel(at: float2(160, 120))
    XCTAssertEqual(dark, SIMD4(0x23, 0x23, 0x26, 255))
    h.context.setTheme(.light)
  }

  /// Between two roles a colour animates through what they are in the theme, and lands on the
  /// role itself.
  func testRoleToRoleAnimatesAndLandsOnTheRole() {
    let rectangle = Rectangle(.label)
    let h = UIHarness { rectangle.frame(width: 100, height: 100) }
    h.settle()
    rectangle.setColor(.accent, h.context, animation: .linear(1))
    h.advance(0.5)
    XCTAssertGreaterThanOrEqual(rectangle.color.w, 0, "mid-animation the colour is a plain one")
    h.settle()
    XCTAssertEqual(rectangle.color, .accent)
  }

  func testStoreNotifiesOnlyWhenTheThemeShowingChanges() {
    let store = ThemeStore()
    XCTAssertTrue(store.theme === Theme.light)
    store.setSystemAppearance(.dark)
    XCTAssertTrue(store.theme === Theme.dark)
    store.appearanceOverride = .light
    XCTAssertEqual(store.appearance, .light)
    store.setSystemAppearance(.light)
    XCTAssertTrue(store.theme === Theme.light)
    store.appearanceOverride = nil
    XCTAssertTrue(store.theme === Theme.light)
  }
}

/// A window that lets the desktop through: nothing drawn is clear, and glass there shows its
/// material's fallback.
@MainActor
final class TranslucencyTests: XCTestCase {
  private func bgra(_ h: UIHarness, _ point: float2) -> SIMD4<UInt8> {
    let pixels = h.targetPixels()
    let width = Int(h.size.x * h.pixelsPerPoint)
    let i = (Int(point.y * h.pixelsPerPoint) * width + Int(point.x * h.pixelsPerPoint)) * 4
    return SIMD4(pixels[i + 2], pixels[i + 1], pixels[i], pixels[i + 3])
  }

  func testClearBackgroundLeavesEmptyPixelsClear() {
    let h = UIHarness {
      Rectangle(float4(1, 0, 0, 0.5)).frame(width: 100, height: 100)
    }
    h.graphics.background = .clear
    h.context.invalidate(.render)
    h.step()
    XCTAssertEqual(self.bgra(h, float2(5, 5)), SIMD4(0, 0, 0, 0))
    // Premultiplied: half red is (128, 0, 0, 128).
    let center = self.bgra(h, float2(160, 120))
    XCTAssertEqual(center.w, 128, accuracy: 1)
    XCTAssertEqual(center.x, 128, accuracy: 1)
  }

  func testGlassFallbackFillsWhatTheWindowLetsThrough() {
    func glass(_ fallback: float4) -> UIHarness {
      let h = UIHarness {
        Rectangle(.clear).frame(width: 160, height: 100)
          .glass(GlassMaterial(blurRadius: 10, tint: .clear, saturation: 1, noise: 0, fallback: fallback))
      }
      h.graphics.background = .clear
      h.context.invalidate(.render)
      h.step()
      return h
    }
    XCTAssertEqual(self.bgra(glass(float4(0, 0, 1, 1)), float2(160, 120)), SIMD4(0, 0, 255, 255))
    XCTAssertEqual(self.bgra(glass(.clear), float2(160, 120)).w, 0)
  }

  /// The rim is a light edge along the top, fading toward the bottom.
  func testGlassRimIsBrightestAtTheTop() {
    let h = UIHarness {
      ZStack {
        Rectangle(.black)
        Rectangle(.clear).frame(width: 160, height: 100)
          .glass(GlassMaterial(blurRadius: 4, tint: .clear, saturation: 1, noise: 0, rim: .white, rimWidth: 2, rimBottom: 0.25))
      }
    }
    let top = h.pixel(at: float2(160, 70.5))
    let bottom = h.pixel(at: float2(160, 169.5))
    let middle = h.pixel(at: float2(160, 120))
    XCTAssertGreaterThan(top.x, 200)
    XCTAssertGreaterThan(bottom.x, 30)
    XCTAssertLessThan(bottom.x, top.x)
    XCTAssertLessThan(middle.x, 5)
  }
}

private func XCTAssertEqual(_ a: UInt8, _ b: UInt8, accuracy: UInt8, file: StaticString = #filePath, line: UInt = #line) {
  XCTAssertLessThanOrEqual(a > b ? a - b : b - a, accuracy, file: file, line: line)
}
