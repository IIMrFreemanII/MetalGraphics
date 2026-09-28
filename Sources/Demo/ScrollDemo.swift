import MetalGraphicsLib
import ReactiveUI
import Synchronization

struct ScrollRow : Identifiable {
  let id: Int
  let color: float4

  var name: String { "Row \(self.id)" }

  static func make(_ index: Int) -> ScrollRow {
    let hue = Float(index % 12) / 12
    return ScrollRow(id: index, color: float4(0.35 + 0.5 * hue, 0.45, 0.85 - 0.5 * hue, 1))
  }
}

// One row, hoverable and tappable: rows scrolled out of view must stop taking the pointer at
// the scroll view's edge.
@Component
final class ScrollRowView : SingleChildElement {
  let row: ScrollRow

  @State var hovered: Bool = false
  @State var taps: Int = 0

  init(row: ScrollRow) {
    self.row = row
    super.init()
  }

  private static let font = TextFont.system(size: 13)

  @UIElementBuilder var body: [UIElement] {
    HStack(spacing: 8) {
      Text(self.row.name)
        .font(Self.font)
        .foregroundColor(.white)
      Spacer()
      if self.taps > 0 {
        Text("×\(self.taps)")
          .font(Self.font)
          .foregroundColor(.white)
      }
    }
    .padding(Inset(vertical: 6, horizontal: 10))
    .background(self.hovered ? .black : self.row.color)
    .onHover { isHovered, _ in self.hovered = isHovered }
    .onTap { _ in self.taps += 1 }
  }
}

// Scrolling to a row by id. A body cannot take a closure of the reader's shape, so this part is
// built by hand and reaches the demo through a one-row list's `onCreate`.
func makeScrollToDemo(rows: [ScrollRow]) -> UIElement {
  let font = TextFont.system(size: 13)
  let button = { (title: String, action: @escaping () -> Void) -> UIElement in
    Text(title)
      .font(font)
      .foregroundColor(.label)
      .padding(Inset(vertical: 4, horizontal: 8))
      .background(.fill, in: .rect(cornerRadius: 6))
      .onTap { _ in action() }
  }

  return ScrollViewReader { proxy in
    HStack(spacing: 6) {
      button("Top") { proxy.scrollTo(0, anchor: .top, animation: .easeInOut(0.4)) }
      button("Row 50") { proxy.scrollTo(50, anchor: .center, animation: .spring()) }
      button("Row 99") { proxy.scrollTo(99, animation: .easeInOut(0.4)) }
    }
    ScrollView {
      VList(alignment: .leading, spacing: 2, items: rows) { row in
        ScrollRowView(row: row).id(row.id)
      }
    }
    .frame(width: 240, height: 260)
    .padding(Inset(top: 6))
  }
}

// Shows scroll views:
//
// - Vertical, over a list of hoverable, tappable rows, clipped drawing and hitting alike.
// - `.scrollDisabled` bound to state: the wheel then goes to the scroll views around it.
// - Horizontal, over a strip of chips.
// - Both axes, over a grid wider and taller than itself, inside the vertical one's neighbour.
// - `ScrollViewReader` scrolling to a row by id, with and without an animation.
@Component
final class ScrollDemo : SingleChildElement {
  private static let captionFont = TextFont.system(size: 12)
  private static let captionColor: float4 = .secondaryLabel
  private static let buttonFont = TextFont.system(size: 13)
  private static let buttonInset = Inset(vertical: 4, horizontal: 8)
  private static let buttonColor: float4 = .fill
  private static let buttonShape = UIShape.rect(cornerRadius: 6)
  private static let chipFont = TextFont.system(size: 12)

  @State var disabled: Bool = false
  @State var indicators: Bool = true
  @State var rows: [ScrollRow] = (0..<200).map { ScrollRow.make($0) }
  @State var chips: [ScrollRow] = (0..<40).map { ScrollRow.make($0) }
  @State var gridRows: [ScrollRow] = (0..<30).map { ScrollRow.make($0) }
  @State var manyRows: [ScrollRow] = (0..<10_000).map { ScrollRow.make($0) }
  // One item: the hand-built reader section, see `makeScrollToDemo`.
  @State var reader: [ScrollRow] = [ScrollRow.make(0)]

  @UIElementBuilder var body: [UIElement] {
    VStack(alignment: .leading, spacing: 8) {
      HStack(spacing: 6) {
        Text(self.disabled ? "Enable scrolling" : "Disable scrolling")
          .font(Self.buttonFont)
          .foregroundColor(.label)
          .padding(Self.buttonInset)
          .background(Self.buttonColor, in: Self.buttonShape)
          .onTap { _ in self.disabled.toggle() }
        Text(self.indicators ? "Hide indicators" : "Show indicators")
          .font(Self.buttonFont)
          .foregroundColor(.label)
          .padding(Self.buttonInset)
          .background(Self.buttonColor, in: Self.buttonShape)
          .onTap { _ in self.indicators.toggle() }
        Spacer()
      }
      HStack(alignment: .top, spacing: 16) {
        VStack(alignment: .leading, spacing: 4) {
          Text("Vertical, 200 rows")
            .font(Self.captionFont)
            .foregroundColor(Self.captionColor)
          ScrollView(.vertical, showsIndicators: self.indicators) {
            VList(alignment: .leading, spacing: 2, items: self.rows) { row in
              ScrollRowView(row: row)
            }
          }
          .scrollDisabled(self.disabled)
          .frame(width: 240, height: 300)
        }
        VStack(alignment: .leading, spacing: 4) {
          Text("Horizontal")
            .font(Self.captionFont)
            .foregroundColor(Self.captionColor)
          ScrollView(.horizontal, showsIndicators: self.indicators) {
            HList(spacing: 4, items: self.chips) { chip in
              Text(chip.name)
                .font(ScrollDemo.chipFont)
                .foregroundColor(.white)
                .padding(Inset(vertical: 4, horizontal: 8))
                .background(chip.color)
            }
          }
          .scrollDisabled(self.disabled)
          .frame(width: 300, height: 36)
          Text("Both axes")
            .font(Self.captionFont)
            .foregroundColor(Self.captionColor)
          ScrollView([.vertical, .horizontal], showsIndicators: self.indicators) {
            VList(alignment: .leading, spacing: 2, items: self.gridRows) { row in
              Text("\(row.name) — a line far too wide to fit, so it scrolls sideways as well")
                .font(ScrollDemo.chipFont)
                .foregroundColor(.white)
                .padding(Inset(vertical: 4, horizontal: 8))
                .background(row.color)
            }
          }
          .scrollDisabled(self.disabled)
          .frame(width: 300, height: 220)
        }
        VList(alignment: .leading, items: self.reader) { _ in
          makeScrollToDemo(rows: (0..<100).map { ScrollRow.make($0) })
        }
        // Rows are built as they scroll into view: each says how many were built before it.
        VStack(alignment: .leading, spacing: 4) {
          Text("LazyVStack, 10,000 rows")
            .font(Self.captionFont)
            .foregroundColor(Self.captionColor)
          ScrollView(.vertical, showsIndicators: self.indicators) {
            LazyVStack(alignment: .leading, spacing: 2, items: self.manyRows) { row in
              let built = LazyRowCounter.count.add(1, ordering: .relaxed).newValue
              return Text("\(row.name) · built #\(built)")
                .font(ScrollDemo.chipFont)
                .foregroundColor(.white)
                .padding(Inset(vertical: 4, horizontal: 8))
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(row.color)
            }
          }
          .scrollDisabled(self.disabled)
          .frame(width: 220, height: 300)
        }
      }
    }
  }
}

/// How many rows the lazy stacks in `ScrollDemo` have built so far, in every window.
enum LazyRowCounter {
  static let count = Atomic<Int>(0)
}
