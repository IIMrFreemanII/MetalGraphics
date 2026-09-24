import MetalGraphicsLib
import ReactiveUI

enum Demo : String, Identifiable {
  case conditional
  case list
  case text
  case layout
  case animation
  case image
  case vector
  case scroll
  case containers
  case grids
  case shapes
  case glass
  case table
  case keyboard
  case form

  var id: Self { self }

  var title: String {
    switch self {
    case .conditional: "Conditional"
    case .list: "List"
    case .text: "Text"
    case .layout: "Layout"
    case .animation: "Animation"
    case .image: "Image"
    case .vector: "Vector"
    case .scroll: "Scroll"
    case .containers: "Containers"
    case .grids: "Grids"
    case .shapes: "Shapes"
    case .glass: "Glass"
    case .table: "Table"
    case .keyboard: "Keyboard"
    case .form: "Form"
    }
  }

  @MainActor func make() -> UIElement {
    switch self {
    case .conditional: ConditionalDemo()
    case .list: ListDemo()
    case .text: TextDemo()
    case .layout: LayoutDemo()
    case .animation: AnimationDemo()
    case .image: ImageDemo()
    case .vector: VectorDemo()
    case .scroll: ScrollDemo()
    case .containers: ContainersDemo()
    case .grids: GridsDemo()
    case .shapes: ShapesDemo()
    case .glass: GlassDemo()
    case .table: TableDemo()
    case .keyboard: KeyboardDemo()
    case .form: FormDemo()
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
  private static let tabFont = TextFont.system(size: 14)
  private static let tabAnimation = UIAnimation.easeOut(0.15)

  // Restored from `UIStorage`, so a hot reload or a relaunch reopens the tab you were on.
  private static let selectedKey = "Demos.selected"

  @State var selected: Demo = UIStorage.value(Demos.selectedKey, default: Demo.text)
  // Always `[selected]`: the list needs a `@State` array of its own (F10).
  @State var shown: [Demo] = [UIStorage.value(Demos.selectedKey, default: Demo.text)]

  @UIElementBuilder var body: [UIElement] {
    VStack(alignment: .leading) {
      HStack(spacing: 4) {
        Text(Demo.conditional.title)
          .font(Self.tabFont)
          .foregroundColor(self.selected == .conditional ? .white : .black)
          .padding(Self.tabInset)
          .background(self.selected == .conditional ? Self.activeTabColor : Self.inactiveTabColor)
          .animation(Self.tabAnimation, value: self.selected)
          .onTap { _ in self.select(.conditional) }
        Text(Demo.list.title)
          .font(Self.tabFont)
          .foregroundColor(self.selected == .list ? .white : .black)
          .padding(Self.tabInset)
          .background(self.selected == .list ? Self.activeTabColor : Self.inactiveTabColor)
          .animation(Self.tabAnimation, value: self.selected)
          .onTap { _ in self.select(.list) }
        Text(Demo.text.title)
          .font(Self.tabFont)
          .foregroundColor(self.selected == .text ? .white : .black)
          .padding(Self.tabInset)
          .background(self.selected == .text ? Self.activeTabColor : Self.inactiveTabColor)
          .animation(Self.tabAnimation, value: self.selected)
          .onTap { _ in self.select(.text) }
        Text(Demo.layout.title)
          .font(Self.tabFont)
          .foregroundColor(self.selected == .layout ? .white : .black)
          .padding(Self.tabInset)
          .background(self.selected == .layout ? Self.activeTabColor : Self.inactiveTabColor)
          .animation(Self.tabAnimation, value: self.selected)
          .onTap { _ in self.select(.layout) }
        Text(Demo.animation.title)
          .font(Self.tabFont)
          .foregroundColor(self.selected == .animation ? .white : .black)
          .padding(Self.tabInset)
          .background(self.selected == .animation ? Self.activeTabColor : Self.inactiveTabColor)
          .animation(Self.tabAnimation, value: self.selected)
          .onTap { _ in self.select(.animation) }
        Text(Demo.image.title)
          .font(Self.tabFont)
          .foregroundColor(self.selected == .image ? .white : .black)
          .padding(Self.tabInset)
          .background(self.selected == .image ? Self.activeTabColor : Self.inactiveTabColor)
          .animation(Self.tabAnimation, value: self.selected)
          .onTap { _ in self.select(.image) }
        Text(Demo.vector.title)
          .font(Self.tabFont)
          .foregroundColor(self.selected == .vector ? .white : .black)
          .padding(Self.tabInset)
          .background(self.selected == .vector ? Self.activeTabColor : Self.inactiveTabColor)
          .animation(Self.tabAnimation, value: self.selected)
          .onTap { _ in self.select(.vector) }
        Text(Demo.scroll.title)
          .font(Self.tabFont)
          .foregroundColor(self.selected == .scroll ? .white : .black)
          .padding(Self.tabInset)
          .background(self.selected == .scroll ? Self.activeTabColor : Self.inactiveTabColor)
          .animation(Self.tabAnimation, value: self.selected)
          .onTap { _ in self.select(.scroll) }
        Text(Demo.containers.title)
          .font(Self.tabFont)
          .foregroundColor(self.selected == .containers ? .white : .black)
          .padding(Self.tabInset)
          .background(self.selected == .containers ? Self.activeTabColor : Self.inactiveTabColor)
          .animation(Self.tabAnimation, value: self.selected)
          .onTap { _ in self.select(.containers) }
        Text(Demo.grids.title)
          .font(Self.tabFont)
          .foregroundColor(self.selected == .grids ? .white : .black)
          .padding(Self.tabInset)
          .background(self.selected == .grids ? Self.activeTabColor : Self.inactiveTabColor)
          .animation(Self.tabAnimation, value: self.selected)
          .onTap { _ in self.select(.grids) }
        Text(Demo.shapes.title)
          .font(Self.tabFont)
          .foregroundColor(self.selected == .shapes ? .white : .black)
          .padding(Self.tabInset)
          .background(self.selected == .shapes ? Self.activeTabColor : Self.inactiveTabColor)
          .animation(Self.tabAnimation, value: self.selected)
          .onTap { _ in self.select(.shapes) }
        Text(Demo.glass.title)
          .font(Self.tabFont)
          .foregroundColor(self.selected == .glass ? .white : .black)
          .padding(Self.tabInset)
          .background(self.selected == .glass ? Self.activeTabColor : Self.inactiveTabColor)
          .animation(Self.tabAnimation, value: self.selected)
          .onTap { _ in self.select(.glass) }
        Text(Demo.table.title)
          .font(Self.tabFont)
          .foregroundColor(self.selected == .table ? .white : .black)
          .padding(Self.tabInset)
          .background(self.selected == .table ? Self.activeTabColor : Self.inactiveTabColor)
          .animation(Self.tabAnimation, value: self.selected)
          .onTap { _ in self.select(.table) }
        Text(Demo.keyboard.title)
          .font(Self.tabFont)
          .foregroundColor(self.selected == .keyboard ? .white : .black)
          .padding(Self.tabInset)
          .background(self.selected == .keyboard ? Self.activeTabColor : Self.inactiveTabColor)
          .animation(Self.tabAnimation, value: self.selected)
          .onTap { _ in self.select(.keyboard) }
        Text(Demo.form.title)
          .font(Self.tabFont)
          .foregroundColor(self.selected == .form ? .white : .black)
          .padding(Self.tabInset)
          .background(self.selected == .form ? Self.activeTabColor : Self.inactiveTabColor)
          .animation(Self.tabAnimation, value: self.selected)
          .onTap { _ in self.select(.form) }
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
    UIStorage.set(demo, for: Self.selectedKey)
  }
}
