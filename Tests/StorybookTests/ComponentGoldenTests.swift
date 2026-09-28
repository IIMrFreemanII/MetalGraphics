@testable import MetalGraphicsLib
@testable import Storybook
import XCTest

/// Every component's first story, light and dark, cropped to the story with room for its
/// shadow: the gallery's goldens. A component that changes how it looks fails here.
final class ComponentGoldenTests: StorybookTestCase {
  static let margin: Float = 16

  func testEveryComponentLooksAsRecorded() throws {
    let catalog = StoryRegistry.catalog()
    for component in catalog.components {
      let id = component.id(of: component.stories[0])
      for appearance in [CanvasAppearance.light, .dark] {
        self.model.appearance = appearance
        self.show(id)
        let story = try XCTUnwrap(self.window.all(IDElement.self).first { $0.mounted && $0.id == AnyHashable(StoryFrame.storyID) })
        let image = self.window.snapshot(of: story, margin: Self.margin)
        let name = "\(component.group.rawValue)-\(component.name)-\(appearance == .light ? "light" : "dark")"
        assertSnapshot(image, named: name, testCase: self)
      }
    }
  }
}
