import Foundation
@testable import Storybook
import XCTest

/// The Swift gallery and the web mirror describe one design system: every component the web
/// mirror (`DesignSystemWeb/meta.mjs`) has, a story shows in Swift, and every story names a Swift
/// file that exists.
final class ParityTests: XCTestCase {
  private static let root = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()

  /// Web components shown in Swift under another story: web name → the Swift story.
  private static let aliases = [
    "Icon": "AnimatedIcon",
    "Section": "Form",
    "MenuItem": "MenuPanel",
    "MenuSeparator": "MenuPanel",
  ]

  private func webComponents() throws -> [String] {
    let meta = try String(contentsOf: Self.root.appendingPathComponent("DesignSystemWeb/meta.mjs"), encoding: .utf8)
    let pattern = try NSRegularExpression(pattern: #"^ *"?name"?: "([^"]+)""#, options: .anchorsMatchLines)
    return pattern.matches(in: meta, range: NSRange(meta.startIndex..., in: meta)).compactMap {
      Range($0.range(at: 1), in: meta).map { String(meta[$0]) }
    }
  }

  func testEveryWebComponentHasAStory() throws {
    let web = try self.webComponents()
    XCTAssertGreaterThan(web.count, 40)
    let catalog = StoryRegistry.catalog()
    let covered = Set(catalog.components.flatMap { [$0.name] + ($0.webName.map { [$0] } ?? []) })
    let missing = web.filter { !covered.contains($0) && !covered.contains(Self.aliases[$0] ?? "") }
    XCTAssertEqual(missing, [], "web components with no Swift story")
  }

  func testEveryStoryNamesASwiftFileThatExists() {
    for component in StoryRegistry.catalog().components {
      let path = Self.root.appendingPathComponent(component.source).path
      XCTAssertTrue(FileManager.default.fileExists(atPath: path), "\(component.name): \(component.source)")
    }
  }

  func testStoriesHaveUniqueNames() {
    let catalog = StoryRegistry.catalog()
    let names = catalog.components.map(\.name)
    XCTAssertEqual(names.count, Set(names).count)
    for component in catalog.components {
      let stories = component.stories.map(\.name)
      XCTAssertEqual(stories.count, Set(stories).count, component.name)
      // Every story's args are the component's.
      for story in component.stories {
        let unknown = Set(story.args.keys).subtracting(component.argTypes.map(\.name))
        XCTAssertEqual(unknown, [], "\(component.name) / \(story.name)")
      }
    }
  }
}
