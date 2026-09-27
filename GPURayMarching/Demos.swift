import MetalGraphicsLib
import ReactiveUI

enum Demo : String, Identifiable, CaseIterable {
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
  case dragDrop
  case pointer
  case navigation
  case modals
  case redraw
  case windows
  case docking
  case codeEditor
  case markdown
  case console

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
    case .dragDrop: "Drag & Drop"
    case .pointer: "Pointer"
    case .navigation: "Navigation"
    case .modals: "Modals"
    case .redraw: "Redraw"
    case .windows: "Windows"
    case .docking: "Docking"
    case .codeEditor: "Code Editor"
    case .markdown: "Markdown"
    case .console: "Console"
    }
  }

  func make() -> UIElement {
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
    case .dragDrop: DragDropDemo()
    case .pointer: PointerDemo()
    case .navigation: NavigationDemo()
    case .modals: ModalDemo()
    case .redraw: RedrawDemo()
    case .windows: WindowsDemo()
    case .docking: DockingDemo()
    case .codeEditor: CodeEditorDemo()
    case .markdown: MarkdownEditorDemo()
    case .console: ConsoleDemo()
    }
  }
}

// Every demo in a sidebar, the selected one in the detail column under its title. The demos
// are components, which a body cannot hold (F4); a navigation destination can, since its closure
// is armed like a handler rather than parsed.
@Component
final class Demos : SingleChildElement {
  // Restored from the window's storage, so a hot reload or a relaunch reopens the demo each
  // window was on, and a new window opens on the one last picked in any.
  static let selectedKey = "Demos.selected"

  let scene: WindowScene

  @State var selected: Demo
  @State var demos: [Demo] = Demo.allCases

  init(scene: WindowScene) {
    self.scene = scene
    self.selected = scene.storage.value(Demos.selectedKey, default: Demo.text)
    super.init()
  }

  @UIElementBuilder var body: [UIElement] {
    NavigationSplitView(selection: $selected) {
      VList(alignment: .leading, spacing: 2, items: self.demos) { demo in
        NavigationLink(demo.title, value: demo)
      }
      .navigationDestination(for: Demo.self) { demo in
        // Built each time a demo is selected, the restored one included: the one place every
        // selection passes through, so it is saved here.
        self.scene.storage.set(demo, for: Demos.selectedKey)
        return demo.make()
          .padding(12)
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
          .navigationTitle(demo.title)
      }
    } detail: {
      Text("Select a demo")
    }
  }
}
