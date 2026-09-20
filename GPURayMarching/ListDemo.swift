import MetalGraphicsLib

struct DemoItem : Identifiable {
  let id = UUID()
  let color: float4
}

// Shows how state reaches the screen: collection changes drive both lists, rows keep their own
// state across a shuffle, and values read inside element arguments update without a rebuild.
//
// Buttons, left to right: green appends, blue inserts at the front, red removes the last row,
// black shuffles (same items, new order), white clears, grey toggles the spacing.
final class ListDemo : SingleChildElement {
  private static let palette: [float4] = [
    .red, .green, .blue,
    .init(1, 0.8, 0.2, 1),    // amber
    .init(0.6, 0.3, 0.9, 1),  // purple
    .init(0.2, 0.8, 0.8, 1),  // teal
  ]

  @State private var spacing: Float = 6
  private let items = ObservableCollection<DemoItem>([
    .init(color: .red),
    .init(color: .green),
    .init(color: .blue),
  ])

  override func mount(_ context: UIContext) {
    super.mount(context)

    self.setChild(
      VStack(alignment: .leading, spacing: 12) {
        HStack(spacing: 6) {
          self.button(.green) { self.append() }
          self.button(.blue) { self.insertFirst() }
          self.button(.red) { self.removeLast() }
          self.button(.black) { self.shuffle() }
          self.button(.white) { self.clear() }
          self.button(.init(0.5, 0.5, 0.5, 1)) { self.toggleSpacing() }
        }

        // Width is read inside an element argument, so only this frame updates; the
        // surrounding builder never re-runs.
        Rectangle(.blue)
          .frame(width: Float(self.items.collection.count) * 24, height: 6)

        // Two lists over one collection; both follow every change.
        VList(spacing: self.spacing, items: self.items) { item in
          self.row(item)
        }
        HList(spacing: self.spacing, items: self.items) { item in
          self.row(item)
        }

        // Read in the builder body, so emptying the collection re-runs the builder.
        if self.items.collection.isEmpty {
          Rectangle(.green).frame(width: 60, height: 60)
        }
      },
      context
    )
  }

  // MARK: - Actions

  func append() {
    self.items.append(.init(color: Self.palette.randomElement() ?? .red))
  }

  func insertFirst() {
    self.items.insert(.init(color: Self.palette.randomElement() ?? .red), at: 0)
  }

  func removeLast() {
    self.items.remove(at: self.items.items.count - 1)
  }

  // Same items in a new order: every row keeps its element, and with it its hover state.
  func shuffle() {
    self.items.replaceAll(self.items.items.shuffled())
  }

  func clear() {
    self.items.replaceAll([])
  }

  func toggleSpacing() {
    self.spacing = self.spacing == 6 ? 20 : 6
  }

  // MARK: - Pieces

  private func button(_ color: float4, _ action: @escaping () -> Void) -> UIElement {
    Rectangle(color)
      .frame(width: 24, height: 24)
      .onTap { _ in action() }
  }

  private func row(_ item: DemoItem) -> UIElement {
    // State per row, owned by the row's element; it survives shuffles and remounts.
    let hovered = State(false)

    return Rectangle(hovered.wrappedValue ? .black : item.color)
      .frame(width: 60, height: 24)
      .onHover { isHovered, _ in hovered.value = isHovered }
      .onTap { _ in self.items.remove(with: item.id) }
  }
}
