import MetalGraphicsLib
import ReactiveUI

enum Demo : Identifiable {
  case conditional
  case list
  case toggle
  case text
  case layout

  var id: Self { self }

  var title: String {
    switch self {
    case .conditional: "Conditional"
    case .list: "List"
    case .toggle: "Toggle"
    case .text: "Text"
    case .layout: "Layout"
    }
  }

  @MainActor func make() -> UIElement {
    switch self {
    case .conditional: ConditionalDemo()
    case .list: ListDemo()
    case .toggle: ToggleDemo()
    case .text: TextDemo()
    case .layout: LayoutDemo()
    }
  }
}

// A tab bar over the demos. A body cannot hold a component (F4), but a list's `onCreate` can,
// so the selected demo lives in a one-row VList and switching tabs replaces that row.
@Component
final class Demos : SingleChildElement {
  private static let tabInset = Inset(vertical: 5, horizontal: 12)
  private static let activeTabColor = float4(0.2, 0.2, 0.2, 1)
  private static let inactiveTabColor = float4(0.88, 0.88, 0.88, 1)
  private static let activeTabStyle = TextStyle(color: .white, fontSize: 14)
  private static let inactiveTabStyle = TextStyle(fontSize: 14)

  @State var selected: Demo = .text
  // Always `[selected]`: the list needs a `@State` array of its own (F10).
  @State var shown: [Demo] = [.text]

  @UIElementBuilder var body: [UIElement] {
    VStack(alignment: .leading) {
      HStack(spacing: 4) {
        Text(Demo.conditional.title, style: self.selected == .conditional ? Self.activeTabStyle : Self.inactiveTabStyle)
          .padding(Self.tabInset)
          .background(self.selected == .conditional ? Self.activeTabColor : Self.inactiveTabColor)
          .onTap { _ in self.select(.conditional) }
        Text(Demo.list.title, style: self.selected == .list ? Self.activeTabStyle : Self.inactiveTabStyle)
          .padding(Self.tabInset)
          .background(self.selected == .list ? Self.activeTabColor : Self.inactiveTabColor)
          .onTap { _ in self.select(.list) }
        Text(Demo.toggle.title, style: self.selected == .toggle ? Self.activeTabStyle : Self.inactiveTabStyle)
          .padding(Self.tabInset)
          .background(self.selected == .toggle ? Self.activeTabColor : Self.inactiveTabColor)
          .onTap { _ in self.select(.toggle) }
        Text(Demo.text.title, style: self.selected == .text ? Self.activeTabStyle : Self.inactiveTabStyle)
          .padding(Self.tabInset)
          .background(self.selected == .text ? Self.activeTabColor : Self.inactiveTabColor)
          .onTap { _ in self.select(.text) }
        Text(Demo.layout.title, style: self.selected == .layout ? Self.activeTabStyle : Self.inactiveTabStyle)
          .padding(Self.tabInset)
          .background(self.selected == .layout ? Self.activeTabColor : Self.inactiveTabColor)
          .onTap { _ in self.select(.layout) }
        Spacer()
      }
      VList(alignment: .leading, items: self.shown) { demo in
        demo.make()
      }
      .padding(Inset(top: 12))
      Spacer()
    }
  }

  // MARK: - Actions

  func select(_ demo: Demo) {
    // re-selecting would rebuild the demo and lose its state
    guard demo != self.selected else { return }
    self.selected = demo
    self.shown = [demo]
  }
}
