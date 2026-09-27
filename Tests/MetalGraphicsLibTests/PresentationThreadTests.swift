import Foundation
@testable import MetalGraphicsLib
import XCTest

// A presentation's window runs on the thread of the window it was presented from: a child
// handle, sharing the parent's thread and mailbox, with a renderer of its own. On real threads.

private final class Box<T>: @unchecked Sendable {
  var value: T
  init(_ value: T) { self.value = value }
}

/// Runs `body` on `handle`'s thread and waits for it. Tests only.
private func on<T>(_ handle: WindowHandle, _ body: @escaping () -> T) -> T {
  nonisolated(unsafe) let body = body
  let result = Box<T?>(nil)
  let done = DispatchSemaphore(value: 0)
  handle.executor.post {
    result.value = body()
    done.signal()
  }
  XCTAssertEqual(done.wait(timeout: .now() + 5), .success)
  return result.value!
}

final class PresentationThreadTests: XCTestCase {
  private func makeParent() -> WindowHandle {
    let parent = WindowHandle(name: "Parent")
    parent.start(
      sceneID: "parent", root: { _ in Text("Parent") }, restoring: "", persist: nil, layer: nil,
      showPointerStyle: { _ in }
    )
    return parent
  }

  /// A child of `parent` with a text of its own, made on `parent`'s thread.
  private func makeChild(of parent: WindowHandle) -> (WindowHandle, Text) {
    let made = on(parent) { () -> (WindowHandle, Text) in
      let child = WindowHandle(childOf: parent, name: "Child")
      let text = Text("Child")
      nonisolated(unsafe) let root = text
      child.start(
        sceneID: "child", root: { _ in root }, restoring: "", persist: nil, layer: nil, showPointerStyle: { _ in }
      )
      return (child, text)
    }
    nonisolated(unsafe) let result = made
    return result
  }

  func testAChildRunsOnItsParentsThreadBesideIt() {
    let parent = self.makeParent()
    let (child, text) = self.makeChild(of: parent)
    XCTAssertTrue(child.thread == nil)
    XCTAssertTrue(child.executor === parent.executor)
    XCTAssertTrue(child.root === parent)
    XCTAssertEqual(on(parent) { parent.surfaces.count }, 2)
    XCTAssertTrue(on(parent) { text.mounted })
    XCTAssertTrue(on(parent) { child.currentRenderer?.uiContext !== parent.currentRenderer?.uiContext })
    parent.close()
    XCTAssertTrue(parent.thread!.waitUntilFinished(timeout: 5))
  }

  func testClosingAChildKeepsTheThread() {
    let parent = self.makeParent()
    let (child, text) = self.makeChild(of: parent)
    child.close()
    // After the teardown it posted.
    XCTAssertFalse(on(parent) { text.mounted })
    XCTAssertEqual(on(parent) { parent.children.count }, 0)
    XCTAssertEqual(on(parent) { parent.surfaces.count }, 1)
    XCTAssertTrue(on(parent) { parent.currentRenderer != nil }, "the parent goes on")
    child.send(.pointerExited)
    XCTAssertFalse(child.hasEvents, "a closed child takes nothing")
    parent.close()
    XCTAssertTrue(parent.thread!.waitUntilFinished(timeout: 5))
  }

  func testStoppingTheParentTearsItsChildrenDown() {
    let parent = self.makeParent()
    let (child, text) = self.makeChild(of: parent)
    let (grandchild, nested) = on(parent) { () -> (WindowHandle, Text) in
      let grandchild = WindowHandle(childOf: child, name: "Grandchild")
      let text = Text("Nested")
      nonisolated(unsafe) let root = text
      grandchild.start(
        sceneID: "nested", root: { _ in root }, restoring: "", persist: nil, layer: nil, showPointerStyle: { _ in }
      )
      return (grandchild, text)
    }
    XCTAssertTrue(grandchild.root === parent)
    XCTAssertEqual(on(parent) { parent.surfaces.count }, 3)
    parent.close()
    XCTAssertTrue(parent.thread!.waitUntilFinished(timeout: 5))
    XCTAssertFalse(text.mounted)
    XCTAssertFalse(nested.mounted)
    XCTAssertNil(child.currentRenderer)
    XCTAssertNil(grandchild.currentRenderer)
  }
}
