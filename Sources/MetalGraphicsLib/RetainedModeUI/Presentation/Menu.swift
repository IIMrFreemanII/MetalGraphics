import simd

/// A menu's sizes and type.
public enum MenuMetrics {
  public static let font = TextFont.system(size: 13)
  public static let shortcutColor: float4 = .secondaryLabel
  public static let itemInset = Inset(left: PickerMark.checkWidth + 8, top: 4, right: 12, bottom: 4)
  public static let listInset = Inset(vertical: 4, horizontal: 4)
  public static let separatorInset = Inset(vertical: 5, horizontal: 6)
  public static let minWidth: Float = 160
  /// A menu shown in place, when not given a width.
  public static let panelWidth: Float = 220
}

/// One command in a menu: its title, a check mark when `checked`, its key equivalent at the
/// trailing edge, red when destructive. The row under the pointer or the arrow keys is
/// highlighted; a click runs `action` and closes the menu. What a picker's menu rows look like.
///
///     MenuItem("Duplicate", shortcut: "⌘D") { duplicate() }
public final class MenuItem : SingleChildElement {
  /// What choosing it runs. `@Component` arms it on mount and clears it on unmount.
  public var action: (() -> Void)?
  public private(set) var isChecked: Bool
  public let isEnabled: Bool
  let mark: PickerMark
  private let title: Text
  /// Told when the item is chosen or hovered: the menu it is in.
  weak var menu: MenuList?

  public init(
    _ title: String, checked: Bool = false, shortcut: String? = nil, role: ButtonRole? = nil, disabled: Bool = false,
    action: (() -> Void)? = nil
  ) {
    self.action = action
    self.isChecked = checked
    self.isEnabled = !disabled
    let color: float4 = disabled ? .tertiaryLabel : role == .destructive ? .destructive : .label
    let title = Text(title).font(MenuMetrics.font).foregroundColor(color).lineLimit(1)
    self.title = title
    let row = HStack(spacing: 16) {
      title
      Spacer()
      if let shortcut {
        Text(shortcut).font(MenuMetrics.font).foregroundColor(disabled ? .tertiaryLabel : MenuMetrics.shortcutColor)
      }
    }
    let mark = PickerMark(.menuItem, selected: checked) { row.padding(MenuMetrics.itemInset) }
    self.mark = mark
    super.init()
    let hit = HittableView(onTap: nil) { mark }
    self.applyContent([hit])
    hit.onTap = { [unowned self] _ in self.choose() }
    hit.onHover = { [unowned self] hovering, _ in
      if hovering { self.menu?.highlight(self) }
    }
  }

  func choose() {
    guard self.isEnabled else { return }
    let action = self.action
    self.menu?.chose(self)
    action?()
  }

  public func setChecked(_ value: Bool, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    guard value != self.isChecked else { return }
    self.isChecked = value
    self.mark.setProgress(value ? 1 : 0, context, animation: nil)
  }

  public func setTitle(_ value: String, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    guard value != self.title.text else { return }
    self.title.setText(value, context, animation: animation)
  }
}

/// A hairline between groups of a menu's items.
public final class MenuSeparator : SingleChildElement {
  public override init() {
    super.init()
    self.applyContent([Rectangle(.separator).frame(height: 0.5).padding(MenuMetrics.separatorInset)])
  }
}

/// A menu's items in a column, with ↑ ↓ to move the highlight and Return or Space to choose:
/// what an open `Menu` and a `MenuPanel` hold.
final class MenuList : SingleChildElement {
  private let items: [MenuItem]
  private weak var highlighted: MenuItem?
  private weak var context: UIContext?
  /// Told after an item is chosen: closes the menu.
  var onChoose: (() -> Void)?

  init(_ elements: [UIElement]) {
    self.items = elements.compactMap { $0 as? MenuItem }
    super.init()
    let column = VStack(alignment: .leading, spacing: 0)
    column.applyContent(elements)
    let keys = KeyPressElement(keys: [.upArrow, .downArrow, .return, .space], phases: [.down, .repeat], action: nil) {
      column.padding(MenuMetrics.listInset).frame(minWidth: MenuMetrics.minWidth, alignment: .leading)
    }
    self.applyContent([TextStyleElement(defaults: TextEnvironment().font(MenuMetrics.font)) { keys }])
    keys.action = { [unowned self] press in self.key(press.key) }
    for item in self.items { item.menu = self }
  }

  override func mount(_ context: UIContext) {
    self.context = context
  }

  override func unmount(_ context: UIContext) {
    self.context = nil
  }

  func highlight(_ item: MenuItem?) {
    guard item !== self.highlighted, let context = self.context else { return }
    self.highlighted?.mark.setHighlighted(false, context)
    self.highlighted = item
    item?.mark.setHighlighted(true, context)
  }

  func chose(_ item: MenuItem) {
    self.onChoose?()
  }

  private func key(_ key: KeyEquivalent) -> KeyPress.Result {
    let enabled = self.items.filter(\.isEnabled)
    guard !enabled.isEmpty else { return .ignored }
    let index = enabled.firstIndex { $0 === self.highlighted }
    switch key {
    case .upArrow:
      self.highlight(enabled[index.map { $0 == 0 ? enabled.count - 1 : $0 - 1 } ?? enabled.count - 1])
    case .downArrow:
      self.highlight(enabled[index.map { $0 == enabled.count - 1 ? 0 : $0 + 1 } ?? 0])
    default:
      if let highlighted = self.highlighted { highlighted.choose() } else { self.onChoose?() }
    }
    return .handled
  }
}

/// An open menu in place: its items on menu glass. For a spec, or a menu an app shows itself;
/// `Menu` opens one from a button.
///
///     MenuPanel {
///       MenuItem("Cut", shortcut: "⌘X") { … }
///       MenuSeparator()
///       MenuItem("Delete", role: .destructive) { … }
///     }
public final class MenuPanel : SingleChildElement {
  public init(width: Float = MenuMetrics.panelWidth, @UIElementBuilder items: () -> [UIElement]) {
    super.init()
    self.applyContent([CardChrome.popover(MenuList(items()).frame(width: width), material: .menu, scrolls: false)])
  }
}

/// A button that opens a menu of commands, as SwiftUI's `Menu`: its title with a chevron, and
/// under it, on menu glass, the items. Choosing one runs it and closes the menu; so do a click
/// outside, Escape and a scroll.
///
///     Menu("Sort") {
///       MenuItem("Name", checked: true) { sort(.name) }
///       MenuItem("Date") { sort(.date) }
///     }
public final class Menu : SingleChildElement {
  private let makeItems: () -> [UIElement]
  private let face: HittableView
  private let title: Text
  private var menu: PopoverHandle?
  private weak var context: UIContext?

  public init(_ title: String, @UIElementBuilder items: @escaping () -> [UIElement]) {
    self.makeItems = items
    let title = Text(title).font(FormMetrics.font).foregroundColor(FormMetrics.labelColor)
    self.title = title
    let face = HittableView(onTap: nil) {
      PopupFace(chevrons: false) {
        HStack(spacing: 6) {
          title
          Image(icon: .chevronDown).foregroundColor(.secondaryLabel)
        }
      }
    }
    self.face = face
    super.init()
    self.applyContent([face])
    face.onTap = { [unowned self] _ in self.open() }
  }

  public override func mount(_ context: UIContext) {
    self.context = context
  }

  public override func unmount(_ context: UIContext) {
    if let menu = self.menu { context.dismissPopover(menu, animated: false) }
    self.context = nil
  }

  /// Opens the menu under the button: its items are made afresh each time.
  public func open() {
    guard let context = self.context, self.menu?.isPresented != true else { return }
    let list = MenuList(self.makeItems())
    list.onChoose = { [weak self] in
      guard let self, let menu = self.menu, let context = self.context else { return }
      context.dismissPopover(menu, animated: true)
    }
    self.menu = context.presentPopover(list, anchor: self.face, alignment: .leading, material: .menu) { [weak self] in
      self?.menu = nil
    }
  }

  public func setTitle(_ value: String, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    guard value != self.title.text else { return }
    self.title.setText(value, context, animation: animation)
  }
}

/// An element that opens a menu on a right click: `.contextMenu { … }`. The menu opens under
/// it, leading-aligned, on menu glass; its items are made afresh each time.
public final class ContextMenuElement : SingleChildElement {
  private let makeItems: () -> [UIElement]
  private let hit: HittableView
  private var menu: PopoverHandle?
  private weak var context: UIContext?

  init(items: @escaping () -> [UIElement], @UIElementBuilder content: () -> [UIElement]) {
    self.makeItems = items
    let hit = HittableView(onTap: nil) {}
    hit.applyContent(content())
    self.hit = hit
    super.init()
    self.applyContent([hit])
    hit.onSecondaryTap = { [unowned self] _ in self.open() }
  }

  public override func mount(_ context: UIContext) {
    self.context = context
  }

  public override func unmount(_ context: UIContext) {
    if let menu = self.menu { context.dismissPopover(menu, animated: false) }
    self.context = nil
  }

  /// Opens the menu, as a right click does.
  public func open() {
    guard let context = self.context, self.menu?.isPresented != true else { return }
    let list = MenuList(self.makeItems())
    list.onChoose = { [weak self] in
      guard let self, let menu = self.menu, let context = self.context else { return }
      context.dismissPopover(menu, animated: true)
    }
    self.menu = context.presentPopover(list, anchor: self.hit, alignment: .leading, material: .menu) { [weak self] in
      self?.menu = nil
    }
  }
}

public extension UIElement {
  /// Opens a menu of `items` on a right click on this element. See `ContextMenuElement`.
  func contextMenu(@UIElementBuilder _ items: @escaping () -> [UIElement]) -> ContextMenuElement {
    ContextMenuElement(items: items) { self }
  }
}
