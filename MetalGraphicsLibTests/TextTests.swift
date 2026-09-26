@testable import MetalGraphicsLib
import CoreText
import Foundation
import simd
import XCTest

@MainActor
final class TextTests: XCTestCase {
  private static let paragraph = "The quick brown fox jumps over the lazy dog, again and again, until it tires."

  private func layout(
    _ text: String, font: TextFont = .body, paragraph: TextParagraph = TextParagraph(), width: Float = .infinity,
    height: Float = .infinity, style: (inout TextRunStyle) -> Void = { _ in }
  ) -> TextLayout {
    var runStyle = TextRunStyle(font: font)
    style(&runStyle)
    return layoutText(
      runs: [TextRunInput(string: text, style: runStyle)], paragraph: paragraph, maxSize: float2(width, height),
      keepsFirstLine: true
    )
  }

  private func postScriptName(_ font: TextFont) -> String {
    CTFontCopyPostScriptName(FontManager.shared.face(for: font).font) as String
  }

  private func faceKey(_ font: TextFont) -> Int32 {
    let face = FontManager.shared.face(for: font)
    return FontManager.shared.faceKey(for: face.font, oblique: face.oblique)
  }

  // MARK: - Fonts

  func testSystemFacesAreDistinctPerWeightAndOpticalSize() {
    let regular = self.faceKey(.system(size: 13))
    XCTAssertNotEqual(regular, self.faceKey(.system(size: 13).bold()))
    XCTAssertNotEqual(regular, self.faceKey(.system(size: 13).italic()))
    // Same weight, other side of the optical size split: other outlines.
    XCTAssertNotEqual(regular, self.faceKey(.system(size: 30)))
    // Same side of it: the same glyphs, whatever the size.
    XCTAssertEqual(regular, self.faceKey(.system(size: 15)))
    XCTAssertEqual(self.faceKey(.system(size: 22)), self.faceKey(.system(size: 34)))
  }

  func testTextStylesUseTheirSizesAndWeights() {
    XCTAssertEqual(TextFont.title.size, 22)
    XCTAssertEqual(TextFont.headline.weight, .bold)
    XCTAssertTrue(self.postScriptName(.headline).contains("Bold"))
    XCTAssertTrue(self.postScriptName(.body).contains("Regular"))
  }

  func testDesignsAndCustomWeights() {
    XCTAssertTrue(self.postScriptName(.system(size: 14, design: .serif)).contains("NewYork"))
    XCTAssertTrue(self.postScriptName(.system(size: 14, design: .rounded)).contains("Rounded"))
    XCTAssertTrue(self.postScriptName(.system(size: 14).monospaced()).contains("Monospaced"))
    XCTAssertEqual(self.postScriptName(.custom("Helvetica Neue", size: 14).weight(.bold)), "HelveticaNeue-Bold")
    XCTAssertEqual(self.postScriptName(.custom("Menlo", size: 14).italic()), "Menlo-Italic")
  }

  func testItalicOfAFaceWithoutOneIsSlanted() throws {
    let font = TextFont.custom("Papyrus", size: 14)
    guard self.postScriptName(font).hasPrefix("Papyrus") else { throw XCTSkip("Papyrus is not installed") }
    XCTAssertFalse(FontManager.shared.face(for: font).oblique)
    XCTAssertTrue(FontManager.shared.face(for: font.italic()).oblique)
    XCTAssertNotEqual(self.faceKey(font), self.faceKey(font.italic()))
  }

  // MARK: - Layout

  func testLineLimitTruncatesTheLastLine() {
    let one = self.layout(Self.paragraph, paragraph: TextParagraph(lineLimit: 1), width: 120)
    XCTAssertEqual(one.lines.count, 1)
    XCTAssertTrue(one.isTruncated)
    XCTAssertLessThanOrEqual(one.size.x, 120)

    let two = self.layout(Self.paragraph, paragraph: TextParagraph(lineLimit: 2), width: 120)
    XCTAssertEqual(two.lines.count, 2)
    XCTAssertTrue(two.isTruncated)

    let all = self.layout(Self.paragraph, width: 120)
    XCTAssertGreaterThan(all.lines.count, 2)
    XCTAssertFalse(all.isTruncated)
  }

  func testTooShortATextTruncatesWhatFits() {
    let lineHeight = self.layout("A").size.y
    let cut = self.layout(Self.paragraph, width: 120, height: lineHeight * 2.5)
    XCTAssertEqual(cut.lines.count, 2)
    XCTAssertTrue(cut.isTruncated)
  }

  func testMoreParagraphsThanLinesEndsInAnEllipsis() {
    let cut = self.layout("First\nSecond", paragraph: TextParagraph(lineLimit: 1))
    XCTAssertTrue(cut.isTruncated)
    XCTAssertGreaterThan(cut.size.x, self.layout("First").size.x)
  }

  func testLineSpacingGoesBetweenLines() {
    let plain = self.layout(Self.paragraph, width: 120)
    let spaced = self.layout(Self.paragraph, paragraph: TextParagraph(lineSpacing: 5), width: 120)
    XCTAssertEqual(spaced.size.y, plain.size.y + Float(plain.lines.count - 1) * 5, accuracy: 0.01)
  }

  func testAlignmentIndentsShorterLines() {
    let text = "A long first line\nshort"
    let leading = self.layout(text)
    let centred = self.layout(text, paragraph: TextParagraph(alignment: .center))
    let trailing = self.layout(text, paragraph: TextParagraph(alignment: .trailing))
    let slack = leading.size.x - leading.lines[1].width
    XCTAssertEqual(leading.lines[1].x, 0)
    XCTAssertEqual(centred.lines[1].x, slack * 0.5, accuracy: 0.01)
    XCTAssertEqual(trailing.lines[1].x, slack, accuracy: 0.01)
    XCTAssertEqual(trailing.lines[0].x, 0, accuracy: 0.01)
  }

  func testMinimumScaleFactorShrinksToFit() {
    let natural = self.layout(Self.paragraph).size.x
    let width = natural * 0.7
    let shrunk = self.layout(Self.paragraph, paragraph: TextParagraph(lineLimit: 1, minimumScaleFactor: 0.5), width: width)
    XCTAssertFalse(shrunk.isTruncated)
    XCTAssertLessThan(shrunk.fontScale, 1)
    XCTAssertGreaterThanOrEqual(shrunk.fontScale, 0.5)
    XCTAssertLessThanOrEqual(shrunk.size.x, width)

    // Not allowed to shrink far enough: as small as allowed, and still cut.
    let tooNarrow = self.layout(Self.paragraph, paragraph: TextParagraph(lineLimit: 1, minimumScaleFactor: 0.8), width: natural * 0.3)
    XCTAssertTrue(tooNarrow.isTruncated)
    XCTAssertEqual(tooNarrow.fontScale, 0.8)
  }

  func testKerningAndTrackingWiden() {
    let plain = self.layout("Kerning").size.x
    XCTAssertEqual(self.layout("Kerning") { $0.kerning = 2 }.size.x, plain + 2 * 7, accuracy: 1)
    XCTAssertGreaterThan(self.layout("Tracking") { $0.tracking = 2 }.size.x, self.layout("Tracking").size.x + 10)
  }

  func testBaselineOffsetMakesRoom() {
    let plain = self.layout("Raised")
    let raised = self.layout("Raised") { $0.baselineOffset = 6 }
    XCTAssertEqual(raised.size.y, plain.size.y + 6, accuracy: 0.01)
    XCTAssertEqual(raised.lines[0].glyphs[0].origin.y, plain.lines[0].glyphs[0].origin.y + 6, accuracy: 0.01)
  }

  func testDecorationsSitUnderAndThroughTheText() {
    let layout = self.layout("Decorated text  ") {
      $0.underline = true
      $0.strikethrough = true
    }
    let line = layout.lines[0]
    let underline = line.decorations.first { !$0.isStrikethrough }!
    let strike = line.decorations.first { $0.isStrikethrough }!
    XCTAssertEqual(line.decorations.count, 2)
    XCTAssertGreaterThan(underline.origin.y, line.baseline)
    XCTAssertLessThan(strike.origin.y + strike.size.y, line.baseline)
    // Across the text, not its trailing spaces.
    XCTAssertEqual(underline.origin.x, 0, accuracy: 0.5)
    XCTAssertEqual(underline.size.x, line.width, accuracy: 0.5)
  }

  func testEmptyTextHasALine() {
    XCTAssertGreaterThan(self.layout("").size.y, 0)
    XCTAssertEqual(self.layout("A\n").size.y, self.layout("A\nB").size.y, accuracy: 0.01)
  }

  // MARK: - Text

  func testTextCaseChangesWhatIsShaped() {
    let lower = Text("abc")
    let upper = Text("abc").textCase(.uppercase)
    let reference = Text("ABC")
    _ = UIHarness { HStack { lower; upper; reference } }
    XCTAssertEqual(upper.getSize(), reference.getSize())
    XCTAssertNotEqual(upper.getSize(), lower.getSize())
  }

  func testConcatenationKeepsEachOperandsRunStyle() {
    let joined = Text("Bold ").bold() + Text("red").foregroundColor(.red) + Text(" plain").lineLimit(1)
    XCTAssertEqual(joined.runs.count, 3)
    XCTAssertEqual(joined.text, "Bold red plain")
    XCTAssertEqual(joined.runs[0].style.weight, .bold)
    XCTAssertEqual(joined.runs[1].style.foreground, .red)
    XCTAssertNil(joined.runs[1].style.weight)
    // Paragraph modifiers on an operand are dropped, as in SwiftUI.
    XCTAssertNil(joined.style.lineLimit)
    XCTAssertNil(joined.runs[2].style.lineLimit)
  }

  func testRunsMayMixFontSizes() {
    let small = Text("small").font(.caption)
    let mixed = Text("small").font(.caption) + Text("BIG").font(.largeTitle)
    _ = UIHarness { VStack { small; mixed } }
    XCTAssertGreaterThan(mixed.getSize().y, small.getSize().y * 2)
  }

  func testFormattedText() {
    let context = UIContext()
    let number = Text(1234.5, format: .number)
    XCTAssertEqual(number.text, 1234.5.formatted(.number))
    number.setText(42.0, context)
    XCTAssertEqual(number.text, 42.0.formatted(.number))
    // A value of another type is described, not force-cast.
    number.setText("n/a", context)
    XCTAssertEqual(number.text, "n/a")

    let date = Date(timeIntervalSince1970: 1_000_000)
    let time = Text(date, style: .time)
    XCTAssertEqual(time.text, date.formatted(date: .omitted, time: .shortened))
    XCTAssertEqual(Text(date, style: .date).text, date.formatted(date: .long, time: .omitted))
    XCTAssertEqual(Text(verbatim: "as is").text, "as is")
  }

  func testSettersRelayoutOnlyOnChange() {
    let text = Text(Self.paragraph)
    let h = UIHarness { text.frame(width: 120) }
    h.settle()
    let height = text.getSize().y
    text.setLineLimit(1, h.context)
    h.settle()
    XCTAssertLessThan(text.getSize().y, height)

    let generation = LayoutPass.generation
    text.setLineLimit(1, h.context)
    h.settle()
    XCTAssertEqual(LayoutPass.generation, generation)
  }

  // MARK: - Inheritance

  func testContainerStyleReachesEveryText() {
    let a = Text(Self.paragraph)
    let b = Text(Self.paragraph)
    let h = UIHarness {
      VStack { a; b }
        .font(.title)
        .lineLimit(2)
        .foregroundStyle(.red)
        .frame(width: 200)
    }
    h.settle()
    XCTAssertEqual(a.font, .title)
    XCTAssertEqual(b.font, .title)
    XCTAssertEqual(a.displayedColor, .red)
    let reference = Text(Self.paragraph).font(.title).lineLimit(2)
    _ = UIHarness { reference.frame(width: 200) }
    XCTAssertEqual(a.getSize(), reference.getSize())
  }

  func testNearestStyleWins() {
    let own = Text("own").font(.body)
    let inner = Text("inner")
    let outer = Text("outer")
    let h = UIHarness {
      VStack {
        own
        VStack { inner }.font(.caption)
        outer
      }
      .font(.title)
      .font(.largeTitle)
    }
    h.settle()
    XCTAssertEqual(own.font, .body)
    XCTAssertEqual(inner.font, .caption)
    // A later modifier on a container sits farther out: the first one wins.
    XCTAssertEqual(outer.font, .title)
  }

  func testDefaultsYieldToAnOuterStyle() {
    let fallback = Text("fallback")
    let overridden = Text("overridden")
    let h = UIHarness {
      VStack {
        TextStyleElement(defaults: TextEnvironment().font(.caption)) { fallback }
        VStack {
          TextStyleElement(defaults: TextEnvironment().font(.caption)) { overridden }
        }
        .font(.title)
      }
    }
    h.settle()
    XCTAssertEqual(fallback.font, .caption)
    XCTAssertEqual(overridden.font, .title)
  }

  func testChangingAContainerFontReshapes() {
    let text = Text("Grows")
    let style = TextStyleElement(overrides: TextEnvironment().font(.body)) { text }
    let h = UIHarness { style }
    h.settle()
    let small = text.getSize()
    style.setFont(.largeTitle, h.context)
    h.settle()
    XCTAssertGreaterThan(text.getSize().y, small.y)
    XCTAssertEqual(text.font, .largeTitle)
  }

  func testAnimatedContainerColourOnlyRedraws() {
    let text = Text("Fading")
    let style = TextStyleElement(overrides: TextEnvironment().foregroundColor(.red)) { text }
    let h = UIHarness { style }
    h.settle()
    XCTAssertEqual(text.displayedColor, .red)

    let generation = LayoutPass.generation
    let renders = h.renders
    style.setForegroundColor(.blue, h.context, animation: .linear(0.5))
    h.advance(0.25)
    XCTAssertNotEqual(text.displayedColor, .red)
    XCTAssertNotEqual(text.displayedColor, .blue)
    XCTAssertNotNil(h.settle())
    XCTAssertEqual(text.displayedColor, .blue)
    XCTAssertGreaterThan(h.renders, renders + 10)
    XCTAssertEqual(LayoutPass.generation, generation)

    // Idle again: nothing drawn.
    let idle = h.renders
    h.step(frames: 30)
    XCTAssertEqual(h.renders, idle)
  }

  func testRowsBuiltWhileScrollingInheritTheStyle() {
    struct Row: Identifiable { let id: Int }
    var built: [Int: Text] = [:]
    let h = UIHarness(size: float2(200, 200)) {
      ScrollView(.vertical) {
        LazyVStack(items: (0..<200).map(Row.init)) { row in
          let text = Text("Row \(row.id)")
          built[row.id] = text
          return text
        }
      }
      .font(.title)
    }
    h.settle()
    XCTAssertNil(built[150])
    for _ in 0..<40 {
      h.scroll(by: float2(0, -400), at: float2(100, 100))
    }
    let late = built.keys.max()!
    XCTAssertGreaterThan(late, 100)
    XCTAssertEqual(built[late]!.font, .title)
  }

  func testPickerMenuOptionsTakeTheFormFont() {
    let one = Text("One")
    let two = Text("Two")
    let picker = Picker("Pick", selection: 1, content: {
      one.tag(1)
      two.tag(2)
    })
    let h = UIHarness { picker }
    h.settle()
    let button = h.all(HittableView.self).first { $0.hitSize.x > 0 }!
    h.click(on: button)
    XCTAssertNotNil(h.settle())
    XCTAssertEqual(two.font, FormMetrics.font)
  }

  /// What `@Component` folds at compile time draws exactly what the runtime wrapper does.
  func testFoldedStylesMatchTheRuntimeOnes() {
    let size = float2(200, 120)
    func pixels(_ tree: () -> UIElement) -> Data {
      let h = UIHarness(size: size, tree)
      h.settle()
      return h.snapshot().dataProvider!.data! as Data
    }

    let runtime = pixels {
      VStack(alignment: .leading) {
        Text(Self.paragraph)
        VStack { Text("Inner").bold() }.font(.caption)
      }
      .font(.title)
      .foregroundStyle(.red)
      .lineLimit(1)
    }
    // As the macro emits it: each container's style hoisted, nearest modifier applied last, and
    // written into the texts innermost container first.
    let inner = TextEnvironment().font(.caption)
    let outer = TextEnvironment().lineLimit(1).foregroundStyle(.red).font(.title)
    let folded = pixels {
      VStack(alignment: .leading) {
        Text(Self.paragraph).inheritStyle(outer)
        VStack { Text("Inner").bold().inheritStyle(inner).inheritStyle(outer) }
      }
    }
    XCTAssertEqual(runtime, folded)
    // And the style did something.
    let plain = pixels {
      VStack(alignment: .leading) {
        Text(Self.paragraph)
        VStack { Text("Inner").bold() }
      }
    }
    XCTAssertNotEqual(runtime, plain)
  }

  // MARK: - Snapshots

  private func page(height: Float = 240, @UIElementBuilder _ content: () -> [UIElement]) -> UIElement {
    VStack(alignment: .leading, spacing: 6, content: content)
      .padding(12)
      .frame(width: 320, height: height, alignment: .topLeading)
      .background(float4(1, 1, 1, 1))
  }

  func testStylesSnapshot() {
    let h = UIHarness(size: float2(320, 240)) {
      self.page {
        Text("Large Title").font(.largeTitle)
        Text("Title").font(.title)
        Text("Headline").font(.headline)
        Text("Body").font(.body)
        Text("Caption").font(.caption)
        Text("Light · Regular · Bold · Black")
        (Text("Light ").fontWeight(.light) + Text("Regular ") + Text("Bold ").bold() + Text("Black").fontWeight(.black))
        Text("Serif italic").font(.system(size: 16, design: .serif)).italic()
        Text("Rounded 12:34").font(.system(size: 16, design: .rounded)).monospacedDigit()
      }
    }
    h.settle()
    assertSnapshot(h.snapshot(), named: "text-styles", testCase: self)
  }

  func testDecorationsSnapshot() {
    let h = UIHarness(size: float2(320, 240)) {
      self.page {
        Text("Underlined").underline()
        Text("Struck through").strikethrough(color: .red)
        Text("Kerning 3").kerning(3)
        Text("Tracking 3").tracking(3)
        Text("x") + Text("2").baselineOffset(8).font(.caption) + Text(" raised")
        VStack(alignment: .leading) {
          Text("Inherited underline")
          Text("and colour")
        }
        .underline()
        .foregroundStyle(float4(0.1, 0.5, 0.2, 1))
        Text("Shadowed").font(.title).shadow(color: float4(0, 0, 0, 0.4), radius: 2, y: 2)
      }
    }
    h.settle()
    assertSnapshot(h.snapshot(), named: "text-decorations", testCase: self)
  }

  func testTruncationAndAlignmentSnapshot() {
    let h = UIHarness(size: float2(320, 300)) {
      self.page(height: 300) {
        Text(Self.paragraph).lineLimit(1)
        Text(Self.paragraph).lineLimit(1).truncationMode(.head)
        Text(Self.paragraph).lineLimit(1).truncationMode(.middle)
        Text("The quick brown fox jumps over the lazy dog, twice").lineLimit(1).minimumScaleFactor(0.5)
        Text(Self.paragraph).lineLimit(2).lineSpacing(4)
        Text("Centred lines\nshort").multilineTextAlignment(.center)
        Text("Trailing lines\nshort").multilineTextAlignment(.trailing)
      }
    }
    h.settle()
    assertSnapshot(h.snapshot(), named: "text-truncation-alignment", testCase: self)
  }

  func testRunsSnapshot() {
    let h = UIHarness(size: float2(320, 240)) {
      self.page {
        Text("Red ").foregroundColor(.red) + Text("green ").foregroundColor(float4(0.1, 0.6, 0.2, 1))
          + Text("blue").foregroundColor(.blue).bold()
        (Text("Mixed ").font(.caption) + Text("sizes").font(.title) + Text(" on one line").italic())
        (Text("Inherits the colour, ") + Text("keeps its own").foregroundColor(.red))
          .foregroundStyle(.blue)
        (Text("Wraps across lines with ") + Text("a bold run in the middle").bold() + Text(" of the paragraph."))
          .frame(width: 200, alignment: .leading)
      }
    }
    h.settle()
    assertSnapshot(h.snapshot(), named: "text-runs", testCase: self)
  }
}
