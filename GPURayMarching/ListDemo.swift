import MetalGraphicsLib
import ReactiveUI

struct DemoItem : Identifiable {
  let id = UUID()
  let name: String
  let detail: String
  let color: float4
}

// One row of the main list, as its own component.
//
// Rows cannot be inlined into `onCreate`: a row owns state (`hovered`, `taps`, `expanded`) and
// state needs an owner the macro can generate against. Extracting it into a nested `@Component`
// is the sanctioned factoring — from `ListDemo`'s side `RowView(item:onRemove:)` is just a
// constructor call, and `RowView` resolves its own reactivity at compile time.
//
// All three states survive a shuffle, because the row keeps its element: tap a few names, expand
// one, shuffle, and the counts and the open row move with their items.
@Component
final class RowView : SingleChildElement {
  let item: DemoItem
  let onRemove: (DemoItem.ID) -> Void

  @State var hovered: Bool = false
  @State var taps: Int = 0
  @State var expanded: Bool = false

  init(item: DemoItem, onRemove: @escaping (DemoItem.ID) -> Void) {
    self.item = item
    self.onRemove = onRemove
    super.init()
  }

  private static let labelFont = TextFont.system(size: 12)
  private static let detailColor = float4(1, 1, 1, 0.8)
  private static let badgeColor = float4(0, 0, 0, 0.35)

  // A row is a list and a branch at once: the badge and the detail line are `if`s inside it.
  @UIElementBuilder var body: [UIElement] {
    VStack(alignment: .leading, spacing: 2) {
      HStack(spacing: 6) {
        Text(self.expanded ? "▾" : "▸")
          .font(Self.labelFont)
          .foregroundColor(.white)
          .onTap { _ in self.expanded.toggle() }
        Text(self.item.name)
          .font(Self.labelFont)
          .foregroundColor(.white)
          .onTap { _ in self.taps += 1 }
        if self.taps > 0 {
          Text("×\(self.taps)")
            .font(Self.labelFont)
            .foregroundColor(.white)
            .padding(Inset(vertical: 0, horizontal: 4))
            .background(Self.badgeColor)
        }
        Text("✕")
          .font(Self.labelFont)
          .foregroundColor(.white)
          .onTap { _ in self.onRemove(self.item.id) }
      }
      if self.expanded {
        Text(self.item.detail)
          .font(Self.labelFont)
          .foregroundColor(Self.detailColor)
      }
    }
    .padding(Inset(vertical: 4, horizontal: 8))
    .background(self.hovered ? .black : self.item.color)
    .onHover { isHovered, _ in
      self.hovered = isHovered
    }
  }
}

// A stateless chip, shared by the HList and the Todo / Done lists. It still has to be a
// component to take part in a row factory, but it owns nothing.
@Component
final class ChipView : SingleChildElement {
  let item: DemoItem
  let onTap: (DemoItem) -> Void

  init(item: DemoItem, onTap: @escaping (DemoItem) -> Void) {
    self.item = item
    self.onTap = onTap
    super.init()
  }

  private static let labelFont = TextFont.system(size: 12)

  @UIElementBuilder var body: [UIElement] {
    Text(self.item.name)
      .font(Self.labelFont)
      .foregroundColor(.white)
      .padding(Inset(vertical: 3, horizontal: 6))
      .background(self.item.color)
      .onTap { _ in self.onTap(self.item) }
  }
}

// Shows how a @State array reaches the screen.
//
// - Operations: every button calls one of the mutation methods @Component generates for
//   `items`, so an append or a remove touches one row, not all of them.
// - VList: rows with their own state, which survives a reorder.
// - HList over the same array: both lists follow every change.
// - Reactive list arguments: spacing and alignment are set in place.
// - Two arrays: moving an item is a remove from one and an append to the other.
// - An empty state: a branch reading the array.
@Component
final class ListDemo : SingleChildElement {
  private static let palette: [(name: String, color: float4)] = [
    ("red", .init(0.9, 0.25, 0.2, 1)),
    ("green", .init(0.1, 0.6, 0.2, 1)),
    ("blue", .init(0.2, 0.45, 0.95, 1)),
    ("amber", .init(0.85, 0.6, 0.1, 1)),
    ("purple", .init(0.6, 0.3, 0.9, 1)),
    ("teal", .init(0.1, 0.6, 0.6, 1)),
  ]
  private static let tasks = ["design", "build", "test", "review", "ship"]
  private static let spacings: [Float] = [0, 6, 20]
  private static let alignments: [(name: String, value: HorizontalAlignment)] = [
    ("leading", .leading), ("center", .center), ("trailing", .trailing),
  ]
  private static let captionFont = TextFont.system(size: 12)
  private static let captionColor = float4(0.45, 0.45, 0.45, 1)
  private static let buttonFont = TextFont.system(size: 13)
  private static let buttonInset = Inset(vertical: 4, horizontal: 8)
  private static let buttonColor = float4(0.25, 0.25, 0.25, 1)
  private static let grey = float4(0.9, 0.9, 0.9, 1)

  // Not state: only used to name new items, never read by `body`.
  private var nextItem = 4

  @State var spacing: Int = 1
  @State var alignment: Int = 0
  @State var items: [DemoItem] = (0..<4).map { ListDemo.makeItem($0) }
  @State var todo: [DemoItem] = ListDemo.tasks.enumerated().map { ListDemo.makeTask($0.element, $0.offset) }
  @State var done: [DemoItem] = []

  // Buttons are inlined: their colours are constant and they own no state, so there is
  // nothing for a nested component to hold.
  @UIElementBuilder var body: [UIElement] {
    HStack(alignment: .top, spacing: 40) {
      VStack(alignment: .leading, spacing: 8) {
        Text("Operations: generated mutation methods")
          .font(Self.captionFont)
          .foregroundColor(Self.captionColor)
        HStack(spacing: 6) {
          Text("Append")
            .font(Self.buttonFont)
            .foregroundColor(.white)
            .padding(Self.buttonInset)
            .background(Self.buttonColor)
            .onTap { _ in self.append() }
          Text("Insert first")
            .font(Self.buttonFont)
            .foregroundColor(.white)
            .padding(Self.buttonInset)
            .background(Self.buttonColor)
            .onTap { _ in self.insert(at: 0) }
          Text("Insert middle")
            .font(Self.buttonFont)
            .foregroundColor(.white)
            .padding(Self.buttonInset)
            .background(Self.buttonColor)
            .onTap { _ in self.insert(at: self.items.count / 2) }
          Text("Remove first")
            .font(Self.buttonFont)
            .foregroundColor(.white)
            .padding(Self.buttonInset)
            .background(Self.buttonColor)
            .onTap { _ in self.removeItems(at: 0) }
          Text("Remove last")
            .font(Self.buttonFont)
            .foregroundColor(.white)
            .padding(Self.buttonInset)
            .background(Self.buttonColor)
            .onTap { _ in self.removeItems(at: self.items.count - 1) }
        }
        HStack(spacing: 6) {
          Text("Remove reds")
            .font(Self.buttonFont)
            .foregroundColor(.white)
            .padding(Self.buttonInset)
            .background(Self.buttonColor)
            .onTap { _ in self.removeItems(where: { $0.name.hasPrefix("red") }) }
          Text("Shuffle")
            .font(Self.buttonFont)
            .foregroundColor(.white)
            .padding(Self.buttonInset)
            .background(Self.buttonColor)
            .onTap { _ in self.replaceItems(self.items.shuffled()) }
          Text("Sort")
            .font(Self.buttonFont)
            .foregroundColor(.white)
            .padding(Self.buttonInset)
            .background(Self.buttonColor)
            .onTap { _ in self.replaceItems(self.items.sorted { $0.name < $1.name }) }
          Text("Reverse")
            .font(Self.buttonFont)
            .foregroundColor(.white)
            .padding(Self.buttonInset)
            .background(Self.buttonColor)
            .onTap { _ in self.replaceItems(self.items.reversed()) }
          Text("Clear")
            .font(Self.buttonFont)
            .foregroundColor(.white)
            .padding(Self.buttonInset)
            .background(Self.buttonColor)
            .onTap { _ in self.replaceItems([]) }
        }

        // Read inside element arguments, so only this text and this frame's size update.
        Text("\(self.items.count) items")
        Rectangle(Self.palette[2].color)
          .frame(width: Float(self.items.count) * 24 + 2, height: 6)

        Text("VList: rows own state. Tap a name to count, ▸ expands, ✕ removes")
          .font(Self.captionFont)
          .foregroundColor(Self.captionColor)
        HStack(spacing: 6) {
          Text("spacing: \(Int(Self.spacings[self.spacing]))")
            .font(Self.buttonFont)
            .foregroundColor(.white)
            .padding(Self.buttonInset)
            .background(Self.buttonColor)
            .onTap { _ in self.spacing = (self.spacing + 1) % Self.spacings.count }
          Text("alignment: \(Self.alignments[self.alignment].name)")
            .font(Self.buttonFont)
            .foregroundColor(.white)
            .padding(Self.buttonInset)
            .background(Self.buttonColor)
            .onTap { _ in self.alignment = (self.alignment + 1) % Self.alignments.count }
        }
        VList(
          alignment: Self.alignments[self.alignment].value,
          spacing: Self.spacings[self.spacing],
          items: self.items
        ) { item in
          RowView(item: item, onRemove: { id in self.removeItems(where: { $0.id == id }) })
        }
        .padding(Inset(all: 6))
        .background(Self.grey)

        // Read in a condition, so emptying the array swaps this branch in.
        if self.items.isEmpty {
          Text("No items. Press Append.")
            .font(.system(size: 14))
            .foregroundColor(Self.captionColor)
        } else {
          Text("Counts and open rows follow their items through Shuffle, Sort and Reverse.")
            .font(Self.captionFont)
            .foregroundColor(Self.captionColor)
        }
      }

      VStack(alignment: .leading, spacing: 8) {
        // A second list over the same array. Each list keeps its own elements, so both follow
        // every change and neither disturbs the other.
        Text("HList over the same array. Tap a chip to move it to the front")
          .font(Self.captionFont)
          .foregroundColor(Self.captionColor)
        HList(spacing: 4, items: self.items) { item in
          ChipView(item: item, onTap: { item in self.moveToFront(item.id) })
        }
        .padding(Inset(all: 6))
        .background(Self.grey)

        // Two arrays, two lists. A move is a remove from one and an append to the other, and
        // each is incremental. The rows are new elements on the other side, which is fine for a
        // row that owns no state.
        Text("Two arrays. Tap a task to move it across")
          .font(Self.captionFont)
          .foregroundColor(Self.captionColor)
        HStack(alignment: .top, spacing: 16) {
          VStack(alignment: .leading, spacing: 6) {
            Text("Todo: \(self.todo.count)")
            VList(alignment: .leading, spacing: 4, items: self.todo) { item in
              ChipView(item: item, onTap: { item in self.complete(item) })
            }
            if self.todo.isEmpty {
              Text("All done")
                .font(Self.captionFont)
                .foregroundColor(Self.captionColor)
            }
          }
          .padding(Inset(all: 6))
          .background(Self.grey)
          VStack(alignment: .leading, spacing: 6) {
            Text("Done: \(self.done.count)")
            VList(alignment: .leading, spacing: 4, items: self.done) { item in
              ChipView(item: item, onTap: { item in self.reopen(item) })
            }
            if self.done.isEmpty {
              Text("Nothing yet")
                .font(Self.captionFont)
                .foregroundColor(Self.captionColor)
            }
          }
          .padding(Inset(all: 6))
          .background(Self.grey)
        }
      }
    }
  }

  // MARK: - Actions

  // `appendItems` / `insertItems` / `removeItems` / `replaceItems` are generated by
  // @Component from `@State var items`. They exist so the call site can name the operation:
  // an append becomes one `insertChild` in each list, where a plain `self.items = …` (or
  // `self.items.append(…)`, which assigns through the setter) would rebuild every row.
  //
  // A reorder is not an incremental operation, so Shuffle, Sort, Reverse and "move to front"
  // take the full-rebuild path through `replaceItems`. Every row still keeps its element, and
  // with it its own state, through `elementsById`. "Remove reds" takes it too when more than
  // one row matches.

  private static func makeItem(_ index: Int) -> DemoItem {
    let entry = Self.palette[Int.random(in: 0..<Self.palette.count)]
    return DemoItem(name: "\(entry.name) \(index)", detail: "item #\(index), made from \(entry.name)", color: entry.color)
  }

  private static func makeTask(_ name: String, _ index: Int) -> DemoItem {
    let entry = Self.palette[index % Self.palette.count]
    return DemoItem(name: name, detail: name, color: entry.color)
  }

  func append() {
    self.appendItems(Self.makeItem(self.nextItem))
    self.nextItem += 1
  }

  func insert(at index: Int) {
    self.insertItems(Self.makeItem(self.nextItem), at: index)
    self.nextItem += 1
  }

  func moveToFront(_ id: DemoItem.ID) {
    guard let index = self.items.firstIndex(where: { $0.id == id }), index > 0 else { return }
    var reordered = self.items
    reordered.insert(reordered.remove(at: index), at: 0)
    self.replaceItems(reordered)
  }

  func complete(_ item: DemoItem) {
    self.removeTodo(where: { $0.id == item.id })
    self.appendDone(item)
  }

  func reopen(_ item: DemoItem) {
    self.removeDone(where: { $0.id == item.id })
    self.appendTodo(item)
  }
}
