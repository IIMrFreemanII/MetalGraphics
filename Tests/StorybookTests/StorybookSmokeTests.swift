@testable import MetalGraphicsLib
@testable import Storybook
import XCTest

/// Every story builds and lays out in light and in dark, with a size, inside the canvas.
final class StorybookSmokeTests: StorybookTestCase {
  func testTheWindowOpensOnAStory() throws {
    XCTAssertNotNil(self.app.settle())
    XCTAssertTrue(self.window.shows("Storybook"))
    XCTAssertTrue(self.window.shows("Controls"))
    XCTAssertNotNil(self.canvas)
    let image = self.window.snapshot()
    writePNG(image, to: FileManager.default.temporaryDirectory.appendingPathComponent("storybook-window.png"))
  }

  func testEveryStoryBuildsInLightAndDark() throws {
    let catalog = StoryRegistry.catalog()
    XCTAssertGreaterThan(catalog.allStories.count, 40)
    for appearance in [CanvasAppearance.light, .dark] {
      self.model.appearance = appearance
      for id in catalog.allStories {
        self.show(id)
        let story = try XCTUnwrap(self.window.all(IDElement.self).first { $0.mounted && $0.id == AnyHashable(StoryFrame.storyID) }, "\(id)")
        let frame = try XCTUnwrap(HeadlessQuery.geometry(of: story), "\(id)")
        XCTAssertGreaterThan(frame.size.x, 0, "\(id)")
        XCTAssertGreaterThan(frame.size.y, 0, "\(id)")
        XCTAssertTrue(frame.size.x.isFinite && frame.size.y.isFinite, "\(id)")
      }
    }
  }
}
