import MetalGraphicsLib
import ReactiveUI

// Grids, as SwiftUI lays them out:
//
// - `Grid` with `GridRow`s: columns as wide as their widest cell, a row outside any GridRow
//   spanning every column, `gridCellColumns`, `gridColumnAlignment` and a row's own alignment.
// - `LazyVGrid` with fixed, flexible and adaptive columns; the button changes the columns.
// - `LazyHGrid` filling rows top to bottom.
//
// Grey backgrounds show a container's own bounds.
@Component
final class GridsDemo : SingleChildElement {
  private static let captionFont = TextFont.system(size: 12)
  private static let captionColor = float4(0.45, 0.45, 0.45, 1)
  private static let buttonFont = TextFont.system(size: 13)
  private static let bodyFont = TextFont.system(size: 13)
  private static let buttonInset = Inset(vertical: 4, horizontal: 8)
  private static let buttonColor = float4(0.25, 0.25, 0.25, 1)
  private static let grey = float4(0.9, 0.9, 0.9, 1)
  private static let amber = float4(0.85, 0.6, 0.1, 1)
  private static let purple = float4(0.6, 0.3, 0.9, 1)
  private static let green = float4(0.2, 0.65, 0.35, 1)
  private static let animation = UIAnimation.easeInOut(0.35)

  private static let columnSets: [(name: String, value: [GridItem])] = [
    ("3 flexible", [GridItem(.flexible(), spacing: 6), GridItem(.flexible(), spacing: 6), GridItem(.flexible())]),
    ("fixed 60 + flexible", [GridItem(.fixed(60), spacing: 6), GridItem(.flexible())]),
    ("adaptive, at least 50", [GridItem(.adaptive(minimum: 50), spacing: 6)]),
  ]

  @State var trailingNumbers: Bool = true
  @State var spanNotes: Bool = false
  @State var columnSet: Int = 0
  @State var columns: [GridItem] = GridsDemo.columnSets[0].value

  @UIElementBuilder var body: [UIElement] {
    HStack(alignment: .top, spacing: 40) {
      VStack(alignment: .leading, spacing: 8) {
        Text("Grid: columns as wide as their widest cell")
          .font(Self.captionFont)
          .foregroundColor(Self.captionColor)
        HStack(spacing: 6) {
          Text(self.trailingNumbers ? "numbers: trailing" : "numbers: leading")
            .font(Self.buttonFont)
            .foregroundColor(.white)
            .padding(Self.buttonInset)
            .background(Self.buttonColor)
            .onTap { _ in self.trailingNumbers.toggle() }
          Text(self.spanNotes ? "notes: over Qty" : "notes: 1 column")
            .font(Self.buttonFont)
            .foregroundColor(.white)
            .padding(Self.buttonInset)
            .background(Self.buttonColor)
            .onTap { _ in self.spanNotes.toggle() }
        }
        Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 6) {
          GridRow {
            Text("Item").font(Self.captionFont).foregroundColor(Self.captionColor)
            Text("Qty").font(Self.captionFont).foregroundColor(Self.captionColor)
            Text("Notes").font(Self.captionFont).foregroundColor(Self.captionColor)
          }
          Divider()
          GridRow {
            Text("Apples").font(Self.bodyFont)
            Text("12").font(Self.bodyFont)
              .gridColumnAlignment(self.trailingNumbers ? .trailing : .leading)
            Text("green").font(Self.bodyFont)
          }
          GridRow {
            Text("Oranges").font(Self.bodyFont)
            if self.spanNotes {
              // Over the Qty and Notes columns.
              Text("from the market, washed").font(Self.bodyFont)
                .background(Self.amber)
                .gridCellColumns(2)
            } else {
              Text("1024").font(Self.bodyFont)
              Text("from the market, washed").font(Self.bodyFont)
                .background(Self.amber)
            }
          }
          GridRow(alignment: .bottom) {
            Text("Pears").font(TextFont.system(size: 20))
            Text("7").font(Self.bodyFont)
            Rectangle(Self.purple).frame(width: 30, height: 30)
          }
        }
        .animation(Self.animation, value: self.trailingNumbers)
        .animation(Self.animation, value: self.spanNotes)
        .padding(.all, 8)
        .background(Self.grey)
      }

      VStack(alignment: .leading, spacing: 8) {
        Text("LazyVGrid: columns from GridItems")
          .font(Self.captionFont)
          .foregroundColor(Self.captionColor)
        Text("columns: \(Self.columnSets[self.columnSet].name)")
          .font(Self.buttonFont)
          .foregroundColor(.white)
          .padding(Self.buttonInset)
          .background(Self.buttonColor)
          .onTap { _ in self.nextColumns() }
        LazyVGrid(columns: self.columns, spacing: 6) {
          Rectangle(Self.purple).frame(height: 30)
          Rectangle(Self.amber).frame(height: 30)
          Rectangle(Self.green).frame(height: 30)
          Rectangle(Self.purple).frame(height: 30)
          Rectangle(Self.amber).frame(height: 30)
          Rectangle(Self.green).frame(height: 30)
          Rectangle(Self.purple).frame(height: 30)
        }
        .animation(Self.animation, value: self.columnSet)
        .frame(width: 260)
        .background(Self.grey)

        Text("LazyHGrid: rows filled top to bottom")
          .font(Self.captionFont)
          .foregroundColor(Self.captionColor)
        LazyHGrid(rows: [GridItem(.fixed(24), spacing: 4), GridItem(.fixed(24), spacing: 4), GridItem(.fixed(24))], spacing: 4) {
          Text("1").font(Self.bodyFont).frame(width: 30, height: 24).background(Self.amber)
          Text("2").font(Self.bodyFont).frame(width: 30, height: 24).background(Self.amber)
          Text("3").font(Self.bodyFont).frame(width: 30, height: 24).background(Self.amber)
          Text("4").font(Self.bodyFont).frame(width: 30, height: 24).background(Self.green)
          Text("5").font(Self.bodyFont).frame(width: 30, height: 24).background(Self.green)
        }
        // As in SwiftUI, a LazyHGrid takes all the height offered and centres its rows in it.
        .fixedSize()
        .background(Self.grey)
      }
    }
  }

  func nextColumns() {
    self.columnSet = (self.columnSet + 1) % Self.columnSets.count
    self.columns = Self.columnSets[self.columnSet].value
  }
}
