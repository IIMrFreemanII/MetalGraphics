@testable import MetalGraphicsLib
@testable import Storybook
import XCTest

/// The Storybook driven as a user would: picking stories in the sidebar, editing controls,
/// using the story, the toolbar, and a relaunch.
final class StorybookE2ETests: StorybookTestCase {
  private var story: IDElement? {
    self.window.all(IDElement.self).first { $0.mounted && $0.id == AnyHashable(StoryFrame.storyID) }
  }

  /// The texts the story shows.
  private var storyTexts: [String] {
    guard let story = self.story else { return [] }
    return ElementInspector.snapshot(of: story).compactMap(\.text)
  }

  func testTheSidebarOpensAComponentAndPicksAStory() throws {
    XCTAssertNotNil(self.app.settle())
    try self.window.tap("Toggle")
    XCTAssertNotNil(self.app.settle())
    try self.window.tap("Off")
    XCTAssertNotNil(self.app.settle())
    XCTAssertEqual(self.model.selection, StoryID(component: "Toggle", story: "Off"))
    XCTAssertTrue(self.window.shows("Toggle — Off"), "the bar's title")
    let toggle = try XCTUnwrap(self.window.all(Toggle.self).first { $0.mounted && $0.isInside(self.story!) })
    XCTAssertFalse(toggle.isOn)
  }

  func testSearchFiltersTheSidebar() throws {
    self.model.search = "chip"
    XCTAssertNotNil(self.app.settle())
    XCTAssertTrue(self.window.shows("ToggleChip"))
    XCTAssertFalse(self.window.shows("Button"))
    self.model.search = "zzz"
    XCTAssertNotNil(self.app.settle())
    XCTAssertTrue(self.window.shows("No stories match “zzz”"))
  }

  func testEditingAControlRedrawsTheStoryAndItsSource() throws {
    self.show(StoryID(component: "Button", story: "Bordered"))
    XCTAssertTrue(self.storyTexts.contains("Save"))
    // Typed after what the field holds, as in any field.
    try self.window.type(" All", into: "title")
    XCTAssertNotNil(self.app.settle())
    XCTAssertTrue(self.storyTexts.contains("Save All"), "\(self.storyTexts)")
    XCTAssertEqual(StoryArgs(values: self.model.args).string("title"), "Save All")
    // The Source tab shows the Swift for it.
    let source = try XCTUnwrap(IDESpace.panel(self.window, kind: "source"))
    try self.window.panel(source).tap()
    XCTAssertNotNil(self.app.settle())
    let editor = try XCTUnwrap(self.window.all(SourcePanel.self).first { $0.mounted })
    XCTAssertTrue(ElementInspector.snapshot(of: editor).isEmpty == false)
    XCTAssertTrue(StoryRegistry.catalog().component("Button")!.snippet(StoryArgs(values: self.model.args)).contains("Button(\"Save All\")"))
    // Kept for the story: back to it after another, the edit is still there.
    self.show(StoryID(component: "Toggle", story: "On"))
    self.show(StoryID(component: "Button", story: "Bordered"))
    XCTAssertEqual(StoryArgs(values: self.model.args).string("title"), "Save All")
    self.model.resetArgs(in: StoryRegistry.catalog())
    XCTAssertNotNil(self.app.settle())
    XCTAssertEqual(StoryArgs(values: self.model.args).string("title"), "Save")
  }

  func testUsingTheStoryLogsActionsAndWritesItsArgsBack() throws {
    self.show(StoryID(component: "Toggle", story: "On"))
    let toggle = try XCTUnwrap(self.window.all(Toggle.self).first { $0.mounted && $0.isInside(self.story!) })
    try ElementRef(element: toggle, window: self.window).tap()
    XCTAssertNotNil(self.app.settle())
    XCTAssertFalse(toggle.isOn)
    XCTAssertEqual(StoryArgs(values: self.model.args).bool("isOn"), false, "written back to the args")
    XCTAssertEqual(self.model.actions.first?.name, "isOn changed")
    // The control in the Controls panel follows.
    let control = try XCTUnwrap(self.window.all(Toggle.self).first { $0.mounted && !$0.isInside(self.story!) && $0 !== toggle })
    XCTAssertFalse(control.isOn)

    self.show(StoryID(component: "Button", story: "Bordered"))
    try self.window.tap("Save")
    XCTAssertEqual(self.model.actions.first?.name, "tapped Save")
  }

  func testSideBySideDrawsTheStoryLightAndDark() throws {
    self.model.appearance = .sideBySide
    self.show(StoryID(component: "Button", story: "Bordered"))
    let scopes = self.window.all(ThemeScopeElement.self).filter(\.mounted)
    XCTAssertEqual(scopes.map(\.appearance), [.light, .dark])
    XCTAssertEqual(self.window.all(IDElement.self).filter { $0.mounted && $0.id == AnyHashable(StoryFrame.storyID) }.count, 2)
  }

  func testDocsShowTheComponentsPropsAndEveryStory() throws {
    self.model.mode = .docs
    self.show(StoryID(component: "ListRow", story: "Problem"))
    XCTAssertTrue(self.window.shows("Props"))
    XCTAssertTrue(self.window.shows("subtitle"))
    XCTAssertFalse(self.window.find(text: "Completion").isEmpty, "each story's name, further down")
  }

  func testTheInspectorListsTheStorysTree() throws {
    self.show(StoryID(component: "ListRow", story: "Problem"))
    let panel = try XCTUnwrap(IDESpace.panel(self.window, kind: "inspector"))
    try self.window.panel(panel).tap()
    XCTAssertNotNil(self.app.settle())
    XCTAssertTrue(self.window.shownTexts.contains { $0.hasPrefix("Text  “cannot find 'nam' in scope”") })
  }

  func testTheStoryAndTheCanvasSettingsSurviveARelaunch() throws {
    self.show(StoryID(component: "Toggle", story: "Off"))
    self.model.appearance = .dark
    XCTAssertNotNil(self.app.settle())
    self.relaunch()
    XCTAssertNotNil(self.app.settle())
    XCTAssertEqual(self.model.selection, StoryID(component: "Toggle", story: "Off"))
    XCTAssertEqual(self.model.appearance, .dark)
  }

  func testNextStoryAndCycleAppearance() {
    self.show(StoryID(component: "Button", story: "Styles"))
    self.model.selectNeighbour(1, in: StoryRegistry.catalog())
    XCTAssertEqual(self.model.selection, StoryID(component: "Button", story: "Bordered"))
    self.model.selectNeighbour(-2, in: StoryRegistry.catalog())
    XCTAssertEqual(self.model.selection.component, "ColorScheme")
    self.model.appearance = .window
    self.model.cycleAppearance()
    XCTAssertEqual(self.model.appearance, .light)
    self.model.stepZoom(1)
    XCTAssertEqual(self.model.zoom, 1.25)
  }
}

/// The id of the dock panel of `kind` in the Storybook's layout.
enum IDESpace {
  @MainActor static func panel(_ window: HeadlessWindow, kind: String) -> String? {
    StorybookDock.space.layout.panels.first { $0.value.kind == kind }?.key
  }
}
