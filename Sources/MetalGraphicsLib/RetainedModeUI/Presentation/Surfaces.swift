import simd

/// What dims a window behind a sheet or an alert: the scrim colour over all the space it is
/// offered, `content` centred on it. The modal presentations draw their own; this is for a spec
/// or a surface of an app's own. Not in SwiftUI.
public final class Scrim : SingleChildElement {
  public init(@UIElementBuilder content: () -> [UIElement] = { [] }) {
    super.init()
    let stack = ZStack(alignment: .center)
    stack.applyContent(content())
    self.applyContent([
      stack
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.scrim)
    ])
  }
}

/// The cards presentations draw on: a popover's and a sheet's, the same for the layers that
/// present them and for the display elements that show one in place.
enum CardChrome {
  static let popoverRadius: Float = 10
  static let sheetRadius: Float = 12

  /// Popover glass, radius 10, a hairline and a 12 pt shadow. In a layer the content scrolls
  /// when the card is given less height than it wants; shown in place (`scrolls: false`) the card
  /// fits it.
  static func popover(_ content: UIElement, material: ThemeMaterial = .popover, scrolls: Bool = true) -> UIElement {
    (scrolls ? ScrollView(.vertical) { content } : content)
      .clipShape(.rect(cornerRadius: Self.popoverRadius))
      .background {
        CardFill(cornerRadius: Self.popoverRadius, material: material).shadow(color: .shadow, radius: 12, y: 6)
      }
      .border(.separator, width: 0.5, in: .rect(cornerRadius: Self.popoverRadius))
  }

  /// Sheet glass, radius 12, a hairline and a 22 pt shadow: a sheet's, an alert's, a dialog's.
  static func sheet(_ content: UIElement, scrolls: Bool = true) -> UIElement {
    (scrolls ? ScrollView(.vertical) { content } : content)
      .clipShape(.rect(cornerRadius: Self.sheetRadius))
      .background {
        CardFill(cornerRadius: Self.sheetRadius, material: .sheet).shadow(color: .shadow, radius: 22, y: 10)
      }
      .border(.separator, width: 0.5, in: .rect(cornerRadius: Self.sheetRadius))
  }
}

/// A popover's card with `content` on it, in place: what `.popover` and a picker's menu show,
/// for a spec or a surface of an app's own.
///
///     Popover { Text("Pinned").padding(12) }
public final class Popover : SingleChildElement {
  public init(@UIElementBuilder content: () -> [UIElement] = { [] }) {
    super.init()
    let stack = VStack(alignment: .leading, spacing: 0)
    stack.applyContent(content())
    self.applyContent([CardChrome.popover(stack, scrolls: false)])
  }
}

/// How an `Alert` lays its buttons out.
public enum AlertLayout : Sendable {
  /// Side by side for two, cancel on the left; stacked for more, cancel last. As macOS.
  case automatic
  case row
  case stack
}

/// A sheet's layout, without its card: a title, the content, and the actions at the trailing
/// edge. For the content of a `.sheet`, so each sheet lays out alike.
///
///     .sheet(isPresented: $renaming) {
///       SheetLayout(title: "Rename") { TextField("Name", text: $name) } actions: {
///         Button("Cancel", role: .cancel) { … }
///         Button("Rename") { … }.buttonStyle(.borderedProminent)
///       }
///     }
public final class SheetLayout : SingleChildElement {
  public static let titleFont = TextFont.system(size: 13, weight: .semibold)
  public static let padding: Float = 20

  public init(
    title: String? = nil, spacing: Float = 16,
    @UIElementBuilder content: () -> [UIElement] = { [] }, @UIElementBuilder actions: () -> [UIElement] = { [] }
  ) {
    super.init()
    let body = VStack(alignment: .leading, spacing: 10)
    body.applyContent(content())
    let buttons = HStack(spacing: 8)
    let actions = actions()
    buttons.applyContent([Spacer()] + actions)
    let column = VStack(alignment: .leading, spacing: spacing)
    var parts: [UIElement] = []
    if let title, !title.isEmpty { parts.append(Text(title).font(Self.titleFont)) }
    parts.append(body)
    if !actions.isEmpty { parts.append(buttons) }
    column.applyContent(parts)
    self.applyContent([column.padding(Self.padding)])
  }
}

/// A sheet's card with a title, content and actions, in place: what `.sheet` shows, for a spec.
public final class Sheet : SingleChildElement {
  public init(
    title: String? = nil, width: Float = 420,
    @UIElementBuilder content: () -> [UIElement] = { [] }, @UIElementBuilder actions: () -> [UIElement] = { [] }
  ) {
    super.init()
    self.applyContent([CardChrome.sheet(SheetLayout(title: title, content: content, actions: actions).frame(width: width), scrolls: false)])
  }
}

/// An alert's card in place: its title, message and buttons as `.alert` lays them out (the
/// first button without a role prominent, a cancel on the left of two, more stacked with cancel
/// last), 260 wide. For a spec; to ask the user, use `.alert`.
public final class Alert : SingleChildElement {
  public static let width: Float = 260

  public init(
    _ title: String, message: String? = nil, titleVisible: Bool = true, layout: AlertLayout = .automatic,
    @UIElementBuilder actions: () -> [UIElement] = { [] }
  ) {
    super.init()
    let content = PresentationContent.make(
      .alert, title: titleVisible ? title : "", titleVisibility: titleVisible ? .visible : .hidden,
      content: actions(), message: message.map { [Text($0)] } ?? [], layout: layout
    )
    self.applyContent([CardChrome.sheet(content.root.frame(width: Self.width), scrolls: false)])
  }
}

/// A confirmation dialog's card in place: its actions always stacked, with Cancel added when
/// none is given, 280 wide. For a spec; to ask the user, use `.confirmationDialog`.
public final class ConfirmationDialog : SingleChildElement {
  public static let width: Float = 280

  public init(
    _ title: String, message: String? = nil, titleVisible: Bool = true, @UIElementBuilder actions: () -> [UIElement] = { [] }
  ) {
    super.init()
    let content = PresentationContent.make(
      .confirmationDialog, title: title, titleVisibility: titleVisible ? .visible : .hidden,
      content: actions(), message: message.map { [Text($0)] } ?? []
    )
    self.applyContent([CardChrome.sheet(content.root.frame(width: Self.width), scrolls: false)])
  }
}
