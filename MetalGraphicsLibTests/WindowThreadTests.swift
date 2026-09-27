import Foundation
@testable import MetalGraphicsLib
import ReactiveUI
import simd
import XCTest

// Windows on threads of their own, as the app runs them: each `UIHarness` here is made and
// stepped on its own `WindowThread`, and a shared `@Model` is written from one while the other
// is on its own thread.

/// Holds what one thread hands another in a test.
private final class Box<T>: @unchecked Sendable {
  var value: T
  init(_ value: T) { self.value = value }
}

/// Runs `body` on `thread` and waits for it. Tests only: a window never waits for another thread.
private func on<T>(_ thread: WindowThread, _ body: @escaping () -> T) -> T {
  nonisolated(unsafe) let body = body
  let result = Box<T?>(nil)
  let done = DispatchSemaphore(value: 0)
  thread.executor.post {
    result.value = body()
    done.signal()
  }
  done.wait()
  return result.value!
}

final class WindowThreadTests: XCTestCase {
  private var threads: [WindowThread] = []

  private func makeThread(_ name: String) -> WindowThread {
    let thread = WindowThread(name: name)
    thread.start()
    self.threads.append(thread)
    return thread
  }

  override func tearDown() {
    for thread in self.threads {
      thread.stop()
      XCTAssertTrue(thread.waitUntilFinished(timeout: 5))
    }
    self.threads.removeAll()
    super.tearDown()
  }

  // MARK: - Threads

  func testPostedWorkRunsOnTheThreadInOrder() {
    let thread = self.makeThread("A")
    let log = Box<[Int]>([])
    let lock = NSLock()
    for i in 0 ..< 20 {
      thread.executor.post {
        precondition(Thread.current === thread)
        lock.withLock { log.value.append(i) }
      }
    }
    _ = on(thread) { 0 }
    XCTAssertEqual(lock.withLock { log.value }, Array(0 ..< 20))
  }

  func testNothingRunsAfterStop() {
    let thread = WindowThread(name: "stopping")
    thread.start()
    let ran = Box(false)
    thread.stop()
    XCTAssertTrue(thread.waitUntilFinished(timeout: 5))
    thread.executor.post { ran.value = true }
    Thread.sleep(forTimeInterval: 0.05)
    XCTAssertFalse(ran.value)
  }

  func testPassStateIsPerThread() {
    let a = self.makeThread("A")
    let b = self.makeThread("B")
    let inside = DispatchSemaphore(value: 0)
    let release = DispatchSemaphore(value: 0)
    // A holds an animation and a text scope while B looks.
    a.executor.post {
      withAnimation(.linear(2)) {
        TextScope.with(TextEnvironment().font(.system(size: 40))) {
          inside.signal()
          release.wait()
        }
      }
    }
    inside.wait()
    let seen = on(b) { (UITransaction.animation == nil, TextScope.current.font == nil, TextScope.depth) }
    release.signal()
    XCTAssertTrue(seen.0)
    XCTAssertTrue(seen.1)
    XCTAssertEqual(seen.2, 0)
  }

  // MARK: - A shared model across window threads

  private func window(on thread: WindowThread, _ model: SyncModel) -> Box<UIHarness> {
    on(thread) { Box(UIHarness { SyncReader(model: model) }) }
  }

  private func countText(_ h: UIHarness) -> String? {
    h.all(Text.self).first?.text
  }

  func testWriteReachesAnotherWindowOnItsNextTurn() {
    let model = SyncModel()
    let a = self.makeThread("A"), b = self.makeThread("B")
    let ha = self.window(on: a, model), hb = self.window(on: b, model)

    // The writer's own window is updated right away, before it steps.
    let own = on(a) { () -> String? in
      model.count = 7
      ha.value.step()
      return self.countText(ha.value)
    }
    XCTAssertEqual(own, "7")

    // The other's delivery was posted before this, so it ran first.
    let other = on(b) { () -> String? in
      hb.value.step()
      return self.countText(hb.value)
    }
    XCTAssertEqual(other, "7")
  }

  func testWritesBeforeADeliveryRunAreOneDelivery() {
    let b = self.makeThread("B")
    let list = ModelObservers()
    let probe = on(b) { () -> Box<Probe> in
      let probe = Probe()
      list.add(probe, token: 5)
      return Box(probe)
    }

    // B is busy while the main thread writes fifty times.
    let busy = DispatchSemaphore(value: 0)
    let release = DispatchSemaphore(value: 0)
    b.executor.post {
      busy.signal()
      release.wait()
    }
    busy.wait()
    for _ in 0 ..< 50 {
      list.notify(also: ModelObservers())
    }
    release.signal()

    let calls = on(b) { probe.value.calls }
    XCTAssertEqual(calls.map(\.token), [5])
  }

  func testDeliveryCarriesTheLastWritersAnimation() {
    let b = self.makeThread("B")
    let list = ModelObservers()
    let probe = on(b) { () -> Box<Probe> in
      let probe = Probe()
      list.add(probe, token: 0)
      return Box(probe)
    }

    let busy = DispatchSemaphore(value: 0)
    let release = DispatchSemaphore(value: 0)
    b.executor.post {
      busy.signal()
      release.wait()
    }
    busy.wait()
    withAnimation(.linear(1)) { list.notify(also: ModelObservers()) }
    withAnimation(.linear(3)) { list.notify(also: ModelObservers()) }
    release.signal()

    let calls = on(b) { probe.value.calls }
    XCTAssertEqual(calls.count, 1)
    XCTAssertEqual(calls.first?.animation?.duration, 3)
  }

  func testAnimatedWriteAnimatesInTheOtherWindow() {
    let model = SyncModel()
    let a = self.makeThread("A"), b = self.makeThread("B")
    let ha = self.window(on: a, model)
    let hb = self.window(on: b, model)
    _ = on(b) { hb.value.settle() }
    defer { withExtendedLifetime(ha) {} }

    on(a) { withAnimation(.linear(0.5)) { model.count = 4 } }

    let animating = on(b) { () -> Bool in
      hb.value.step()
      return !hb.value.context.animator.isIdle
    }
    XCTAssertTrue(animating)
    let settled = on(b) { hb.value.settle() }
    XCTAssertNotNil(settled)
  }

  func testUnmountWhileADeliveryIsPostedIsHarmless() {
    let model = SyncModel()
    let a = self.makeThread("A"), b = self.makeThread("B")
    let ha = self.window(on: a, model)
    let hb = self.window(on: b, model)
    defer { withExtendedLifetime(ha) {} }

    let busy = DispatchSemaphore(value: 0)
    let release = DispatchSemaphore(value: 0)
    b.executor.post {
      busy.signal()
      release.wait()
      // Runs before the delivery the write below posts.
      hb.value.root.setChild(EmptyElement(), hb.value.context)
    }
    busy.wait()
    on(a) { model.count = 2 }
    release.signal()

    let observers = on(b) { () -> Int in
      hb.value.step()
      return model.__observers(named: "count").count
    }
    // A's reader is still subscribed; B's is gone.
    XCTAssertEqual(observers, 1)
  }

  // MARK: - Shared GPU work

  /// A glyph first laid out in one window is baked by that window's flush; another window
  /// drawing it from its own queue waits for the bake before sampling it.
  func testGlyphsBakedByOneWindowDrawInAnother() {
    let a = self.makeThread("A"), b = self.makeThread("B")
    // Characters no other test draws, so their bakes are new.
    let text = "ʬ ʭ ʮ ʯ ǂ ǁ ƺ"
    let pixelsA = on(a) { () -> [UInt8] in
      let h = UIHarness(size: float2(200, 60)) { Text(text).font(.system(size: 24)) }
      return h.targetPixels()
    }
    let pixelsB = on(b) { () -> [UInt8] in
      let h = UIHarness(size: float2(200, 60)) { Text(text).font(.system(size: 24)) }
      return h.targetPixels()
    }
    XCTAssertEqual(pixelsA, pixelsB)
    XCTAssertTrue(pixelsA.contains { $0 < 128 }, "the text drew nothing")
  }
}

/// Stands in for a component: records each update, and the animation it ran under.
private final class Probe: UIElement {
  struct Call {
    let token: Int
    let animation: UIAnimation?
  }

  var calls: [Call] = []

  override func __modelDidChange(_ token: Int, _ animated: Bool) {
    self.calls.append(Call(token: token, animation: UITransaction.animation))
  }
}
