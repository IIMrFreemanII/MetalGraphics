import MetalGraphicsLib
import ReactiveUI

struct DragChip : Identifiable, Equatable {
  let id: Int
  let name: String
  let color: float4
}

// Drag and drop inside the app, as in SwiftUI.
//
// - The palette's chips are `.draggable(chip)`: past a few points of movement a copy of the chip
//   follows the pointer. A shorter press is still a click.
// - The basket is a `.dropDestination(for: DragChip.self)`. Its border lights up through
//   `isTargeted` while a chip is over it, and a drop adds a copy of the chip. A basket chip
//   dropped back on the basket stays as it is.
// - A chip in the basket drags with a custom preview; dropped on the bin, it is removed. The
//   bin takes only chips, so the task rows below never light it up.
// - The tasks reorder with `.onMove`, whose action calls the generated
//   `moveTasks(fromOffsets:toOffset:)` under `withAnimation`: rows keep their elements and slide.
// - Escape cancels a drag.
@Component
final class DragDropDemo : SingleChildElement {
  private static let captionFont = TextFont.system(size: 12)
  private static let captionColor = float4(0.45, 0.45, 0.45, 1)
  private static let chipFont = TextFont.system(size: 13)
  private static let chipInset = Inset(vertical: 6, horizontal: 10)
  private static let chipShape = UIShape.rect(cornerRadius: 6)
  private static let zoneInset = Inset(all: 10)
  private static let zoneColor = float4(0.93, 0.93, 0.94, 1)
  private static let idleBorder = float4(0, 0, 0, 0.12)
  private static let basketBorder = float4(0.0, 0.48, 1.0, 1)
  private static let binBorder = float4(0.92, 0.23, 0.2, 1)
  private static let taskColor = float4(1, 1, 1, 1)
  private static let reorder = UIAnimation.easeOut(0.2)
  private static let colors: [(name: String, color: float4)] = [
    ("Red", float4(0.92, 0.3, 0.26, 1)), ("Orange", float4(0.96, 0.58, 0.18, 1)),
    ("Green", float4(0.25, 0.7, 0.35, 1)), ("Blue", float4(0.2, 0.47, 0.95, 1)),
    ("Purple", float4(0.6, 0.35, 0.85, 1)),
  ]

  @State var palette: [DragChip] = DragDropDemo.makePalette()
  @State var basket: [DragChip] = []
  @State var basketTargeted: Bool = false
  @State var binTargeted: Bool = false
  @State var tasks: [DragChip] = DragDropDemo.makeTasks()
  @State var status: String = "Nothing dropped yet"

  private var nextID = 1000

  @UIElementBuilder var body: [UIElement] {
    VStack(alignment: .leading, spacing: 12) {
      Text("Drag a chip into the basket, and a basket chip onto the bin. Escape cancels a drag.")
        .font(Self.captionFont)
        .foregroundColor(Self.captionColor)
      HList(spacing: 8, items: self.palette) { chip in
        Text(chip.name)
          .font(DragDropDemo.chipFont)
          .foregroundColor(.white)
          .padding(DragDropDemo.chipInset)
          .background(chip.color, in: DragDropDemo.chipShape)
          .draggable(chip)
      }
      HStack(alignment: .top, spacing: 16) {
        HList(spacing: 6, items: self.basket) { chip in
          // Opaque to the macro: the custom preview is built with the chip it shows.
          Text(chip.name)
            .font(DragDropDemo.chipFont)
            .foregroundColor(.white)
            .padding(DragDropDemo.chipInset)
            .background(chip.color, in: DragDropDemo.chipShape)
            .draggable(chip) {
              Text("Remove \(chip.name)?")
                .font(DragDropDemo.captionFont)
                .foregroundColor(.white)
                .padding(DragDropDemo.chipInset)
                .background(float4(0.2, 0.2, 0.2, 0.9), in: DragDropDemo.chipShape)
            }
        }
        .padding(Self.zoneInset)
        .frame(width: 360, height: 60)
        .background(Self.zoneColor)
        .border(self.basketTargeted ? Self.basketBorder : Self.idleBorder, width: 2)
        .dropDestination(for: DragChip.self) { items, _ in
          self.add(items)
        } isTargeted: { over in
          self.basketTargeted = over
        }
        Text("Bin")
          .font(Self.chipFont)
          .padding(Self.zoneInset)
          .frame(width: 80, height: 60)
          .background(Self.zoneColor)
          .border(self.binTargeted ? Self.binBorder : Self.idleBorder, width: 2)
          .dropDestination(for: DragChip.self) { items, _ in
            self.discard(items)
            return true
          } isTargeted: { over in
            self.binTargeted = over
          }
      }
      Text(self.status)
        .font(Self.captionFont)
        .foregroundColor(Self.captionColor)
      Text("Drag a task to reorder the list.")
        .font(Self.captionFont)
        .foregroundColor(Self.captionColor)
      VList(alignment: .leading, spacing: 4, items: self.tasks) { task in
        HStack(spacing: 8) {
          Rectangle(task.color)
            .frame(width: 10, height: 10)
          Text(task.name)
            .font(DragDropDemo.chipFont)
          Spacer()
        }
        .padding(DragDropDemo.chipInset)
        .frame(width: 260)
        .background(DragDropDemo.taskColor, in: DragDropDemo.chipShape)
      }
      .onMove { from, to in
        withAnimation(Self.reorder) {
          self.moveTasks(fromOffsets: from, toOffset: to)
        }
      }
      .padding(Inset(all: 6))
      .background(Self.zoneColor)
    }
  }

  // MARK: - Actions

  /// Adds palette chips to the basket. A basket chip dropped back on the basket is already
  /// there: it is not added again, and the drop is refused.
  func add(_ items: [DragChip]) -> Bool {
    let added = items.filter { item in !self.basket.contains(where: { $0.id == item.id }) }
    guard !added.isEmpty else { return false }
    for item in added {
      // A copy with an id of its own: the same colour can sit in the basket twice.
      self.appendBasket(DragChip(id: self.nextID, name: item.name, color: item.color))
      self.nextID += 1
    }
    self.status = "Dropped \(added.map(\.name).joined(separator: ", ")) in the basket"
    return true
  }

  func discard(_ items: [DragChip]) {
    let binned = items.filter { item in self.basket.contains(where: { $0.id == item.id }) }
    guard !binned.isEmpty else {
      self.status = "Only chips in the basket can be binned"
      return
    }
    for item in binned {
      self.removeBasket(where: { $0.id == item.id })
    }
    self.status = "Binned \(binned.map(\.name).joined(separator: ", "))"
  }

  private static func makePalette() -> [DragChip] {
    Self.colors.enumerated().map { index, entry in DragChip(id: index, name: entry.name, color: entry.color) }
  }

  private static func makeTasks() -> [DragChip] {
    ["Sketch the layout", "Pick the colours", "Write the copy", "Review", "Ship it"]
      .enumerated()
      .map { index, name in DragChip(id: 100 + index, name: name, color: Self.colors[index % Self.colors.count].color) }
  }
}
