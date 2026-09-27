import Foundation
import MetalGraphicsLib
import ReactiveUI

struct Person : Identifiable {
  let id = UUID()
  let name: String
  let age: Int
  let email: String
  let color: float4
}

// A `Table` over a thousand people, as SwiftUI's.
//
// - Columns: text from a key path (sortable), custom cells sorting by a key path, a column that
//   does not sort, fixed and bounded widths, trailing alignment.
// - Selection: click, cmd-click toggles, shift-click selects a range. The table reports it
//   through `onSelectionChange`, and this component keeps it in `@State`.
// - Sorting: click a title; again reverses. The component sorts its own array in
//   `onSortOrderChange`, and every row keeps its element through the reorder.
// - Resizing: drag a divider in the header.
// - Rows are built only near what shows, so a thousand of them cost what a screenful does.
@Component
final class TableDemo : SingleChildElement {
  private static let firstNames = ["Ada", "Alan", "Grace", "Linus", "Ken", "Barbara", "Edsger", "Margaret", "Donald", "Frances"]
  private static let lastNames = ["Lovelace", "Turing", "Hopper", "Torvalds", "Thompson", "Liskov", "Dijkstra", "Hamilton", "Knuth", "Allen"]
  private static let colors: [float4] = [
    .init(0.9, 0.25, 0.2, 1), .init(0.1, 0.6, 0.2, 1), .init(0.2, 0.45, 0.95, 1),
    .init(0.85, 0.6, 0.1, 1), .init(0.6, 0.3, 0.9, 1), .init(0.1, 0.6, 0.6, 1),
  ]
  private static let captionFont = TextFont.system(size: 12)
  private static let captionColor = float4(0.45, 0.45, 0.45, 1)
  private static let cellFont = TextFont.system(size: 13)
  private static let buttonFont = TextFont.system(size: 13)
  private static let buttonInset = Inset(vertical: 4, horizontal: 8)
  private static let buttonColor = float4(0.25, 0.25, 0.25, 1)
  private static let border = float4(0, 0, 0, 0.2)

  // Not state: only used to name new people, never read by `body`.
  private var nextPerson = 1000

  @State var people: [Person] = (0..<1000).map { TableDemo.makePerson($0) }
  @State var selection: Set<Person.ID> = []
  @State var sortOrder: [KeyPathComparator<Person>] = []

  @UIElementBuilder var body: [UIElement] {
    VStack(alignment: .leading, spacing: 8) {
      Text("Click a row, cmd-click to toggle, shift-click for a range. Click a title to sort; drag a divider to resize.")
        .font(Self.captionFont)
        .foregroundColor(Self.captionColor)
      HStack(spacing: 6) {
        Text("Append")
          .font(Self.buttonFont)
          .foregroundColor(.white)
          .padding(Self.buttonInset)
          .background(Self.buttonColor)
          .onTap { _ in self.append() }
        Text("Remove selected")
          .font(Self.buttonFont)
          .foregroundColor(.white)
          .padding(Self.buttonInset)
          .background(Self.buttonColor)
          .onTap { _ in self.removeSelected() }
        Text("\(self.people.count) people, \(self.selection.count) selected")
          .font(Self.captionFont)
          .foregroundColor(Self.captionColor)
      }
      Table(
        items: self.people, selection: self.selection, sortOrder: self.sortOrder,
        onSelectionChange: { selection in self.selection = selection },
        onSortOrderChange: { order in self.sort(order) }
      ) {
        TableColumn("Name", value: \.name)
        TableColumn("Age", value: \.age) { person in
          Text("\(person.age)").font(Self.cellFont)
        }
        .width(60)
        .alignment(.trailing)
        TableColumn("Email") { person in
          Text(person.email).font(Self.cellFont)
        }
        .width(min: 120, ideal: 240, max: 400)
        TableColumn("Color") { person in
          Rectangle(person.color).frame(width: 14, height: 14)
        }
        .width(50)
        .alignment(.center)
      }
      .frame(width: 640, height: 420)
      .border(Self.border)
    }
  }

  // MARK: - Actions

  private static func makePerson(_ index: Int) -> Person {
    let first = Self.firstNames[index % Self.firstNames.count]
    let last = Self.lastNames[(index / Self.firstNames.count) % Self.lastNames.count]
    return Person(
      name: "\(first) \(last) \(index)", age: 18 + (index * 37) % 60,
      email: "\(first.lowercased()).\(last.lowercased())\(index)@example.com",
      color: Self.colors[index % Self.colors.count]
    )
  }

  func append() {
    self.appendPeople(Self.makePerson(self.nextPerson))
    self.nextPerson += 1
  }

  func removeSelected() {
    let selected = self.selection
    self.removePeople(where: { selected.contains($0.id) })
    self.selection = []
  }

  func sort(_ order: [KeyPathComparator<Person>]) {
    self.sortOrder = order
    self.replacePeople(self.people.sorted(using: order))
  }
}
