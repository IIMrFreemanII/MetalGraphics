@testable import MetalGraphicsLib
import ReactiveUI
import simd
import XCTest

// One `@Model` read by trees in several windows. Each `UIHarness` stands in for a window: its
// own renderer, context and input, as `RootViewRenderer` gives each real one.

@Model
final class SyncModel {
  var count: Int = 0
  var flag: Bool = false
  var label: String = "a"
}

@Component
final class SyncReader : SingleChildElement {
  @Bindable let model: SyncModel

  init(model: SyncModel) {
    self.model = model
    super.init()
  }

  @UIElementBuilder var body: [UIElement] {
    VStack(alignment: .leading, spacing: 4) {
      Text("\(self.model.count)")
      Rectangle(.red).frame(width: 10 + Float(self.model.count) * 10, height: 10)
      if self.model.flag {
        Text("On")
      }
      TextField("Label", text: $model.label)
      Toggle("Flag", isOn: $model.flag)
    }
  }
}

@MainActor
final class ModelSyncTests: XCTestCase {
  private func window(_ model: SyncModel) -> (UIHarness, SyncReader) {
    let reader = SyncReader(model: model)
    return (UIHarness { reader }, reader)
  }

  private func countText(_ h: UIHarness) -> String? {
    h.all(Text.self).first?.text
  }

  private func shows(_ text: String, _ h: UIHarness) -> Bool {
    h.all(Text.self).contains { $0.text == text && $0.mounted }
  }

  func testWriteUpdatesEveryWindow() {
    let model = SyncModel()
    let (h1, _) = self.window(model)
    let (h2, _) = self.window(model)
    _ = h1.settle(); _ = h2.settle()
    let renders = (h1.renders, h2.renders)

    model.count = 5
    h1.step(); h2.step()

    XCTAssertEqual(self.countText(h1), "5")
    XCTAssertEqual(self.countText(h2), "5")
    XCTAssertGreaterThan(h1.renders, renders.0)
    XCTAssertGreaterThan(h2.renders, renders.1)
  }

  func testBranchOnModelSwapsInEveryWindow() {
    let model = SyncModel()
    let (h1, _) = self.window(model)
    let (h2, _) = self.window(model)
    XCTAssertFalse(self.shows("On", h1))

    model.flag = true
    h1.step(); h2.step()

    XCTAssertTrue(self.shows("On", h1))
    XCTAssertTrue(self.shows("On", h2))
  }

  func testEqualWriteLeavesEveryWindowIdle() {
    let model = SyncModel()
    let (h1, _) = self.window(model)
    let (h2, _) = self.window(model)
    _ = h1.settle(); _ = h2.settle()
    let renders = (h1.renders, h2.renders)

    model.count = model.count
    model.label = "a"
    h1.step(frames: 10); h2.step(frames: 10)

    XCTAssertEqual(h1.renders, renders.0)
    XCTAssertEqual(h2.renders, renders.1)
  }

  func testBindingInOneWindowWritesTheModel() {
    let model = SyncModel()
    let (h1, _) = self.window(model)
    let (h2, _) = self.window(model)

    // What a click on the toggle calls: the write-back armed from `$model.flag`.
    h1.first(Toggle.self)!.onIsOnChange?(true)
    h1.step(); h2.step()

    XCTAssertTrue(model.flag)
    XCTAssertTrue(h2.first(Toggle.self)!.isOn)
    XCTAssertTrue(self.shows("On", h2))
  }

  func testTypingInOneWindowShowsInTheOther() {
    let model = SyncModel()
    let (h1, _) = self.window(model)
    let (h2, _) = self.window(model)

    // The field comes first in the tree, so its focusable is the first one.
    h1.click(on: h1.first(FocusableElement.self)!)
    h1.type("bc")
    h2.step()

    XCTAssertEqual(model.label, "abc")
    XCTAssertEqual(h2.first(TextField.self)!.text, "abc")
  }

  func testUnmountedWindowStopsListening() {
    let model = SyncModel()
    let (h1, _) = self.window(model)
    let (h2, _) = self.window(model)
    let observers = model.__observers(named: "count")
    XCTAssertEqual(observers.count, 2)

    h1.root.setChild(EmptyElement(), h1.context)
    XCTAssertEqual(observers.count, 1)

    model.count = 3
    h2.step()
    XCTAssertEqual(self.countText(h2), "3")
  }

  func testRemountReplaysWritesMadeWhileUnmounted() {
    let model = SyncModel()
    let (h1, reader) = self.window(model)
    h1.root.setChild(EmptyElement(), h1.context)

    model.count = 9
    model.flag = true
    h1.root.setChild(reader, h1.context)
    h1.step()

    XCTAssertEqual(self.countText(h1), "9")
    XCTAssertTrue(self.shows("On", h1))
    XCTAssertEqual(model.__observers(named: "count").count, 1)
  }

  func testAnimatedWriteAnimatesInEveryWindowAndSettles() {
    let model = SyncModel()
    let (h1, _) = self.window(model)
    let (h2, _) = self.window(model)
    _ = h1.settle(); _ = h2.settle()

    withAnimation(.linear(0.5)) { model.count = 4 }
    h1.step(); h2.step()
    XCTAssertFalse(h1.context.animator.isIdle)
    XCTAssertFalse(h2.context.animator.isIdle)

    XCTAssertNotNil(h1.settle())
    XCTAssertNotNil(h2.settle())
  }
}

/// `ModelObservers` on its own, with elements standing in for components.
@MainActor
final class ModelObserversTests: XCTestCase {
  private final class Probe: UIElement {
    var calls: [Int] = []
    var onChange: ((Probe) -> Void)?
    override func __modelDidChange(_ token: Int, _ animated: Bool) {
      self.calls.append(token)
      self.onChange?(self)
    }
  }

  func testNotifiesOwnListThenTheAnyList() {
    let own = ModelObservers()
    let any = ModelObservers()
    let a = Probe()
    let b = Probe()
    own.add(a, token: 3)
    any.add(b, token: 7)

    own.notify(also: any)

    XCTAssertEqual(a.calls, [3])
    XCTAssertEqual(b.calls, [7])
  }

  func testFreedSubscriberIsSkippedAndDropped() {
    let list = ModelObservers()
    var probe: Probe? = Probe()
    list.add(probe!, token: 0)
    probe = nil

    list.notify(also: ModelObservers())
    XCTAssertEqual(list.count, 0)
  }

  func testSubscribersChangedDuringANotifyAreSafe() {
    let list = ModelObservers()
    let first = Probe()
    let second = Probe()
    let late = Probe()
    // The first reader unmounts the second and mounts a new one, as a branch swap would.
    first.onChange = { _ in
      list.remove(second)
      list.add(late, token: 2)
    }
    list.add(first, token: 0)
    list.add(second, token: 1)

    list.notify(also: ModelObservers())

    XCTAssertEqual(first.calls, [0])
    // Still called from the snapshot; a real component finds no context and does nothing.
    XCTAssertEqual(second.calls, [1])
    // Built from the current value already.
    XCTAssertEqual(late.calls, [])
    XCTAssertEqual(list.count, 2)
  }
}
