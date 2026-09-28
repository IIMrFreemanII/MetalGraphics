@testable import Demo
@testable import MetalGraphicsLib
import XCTest

/// The system appearance reaches every window, on its own turn, and only redraws.
final class AppearanceE2ETests: AppTestCase {
  func testEveryWindowFollowsTheSystemAppearance() throws {
    self.app.open(id: AppScenes.sharedState.id)
    self.app.settle()
    XCTAssertTrue(self.app.windows.allSatisfy { $0.context.theme === Theme.light })

    self.app.setAppearance(.dark)
    self.app.step()
    for window in self.app.windows {
      XCTAssertTrue(window.context.theme === Theme.dark, "\(window.sceneID) is still light")
    }
    XCTAssertNotNil(self.app.settle(), "a window kept drawing after the switch")

    self.app.setAppearance(.light)
    self.app.step()
    XCTAssertTrue(self.app.windows.allSatisfy { $0.context.theme === Theme.light })
  }
}
