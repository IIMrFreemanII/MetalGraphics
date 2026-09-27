import simd

/// How a `Picker` shows its options.
public enum PickerStyle : Sendable {
  /// A button showing the selected option, which opens a menu of them all. The default, as in
  /// SwiftUI on macOS.
  case menu
  /// Side by side in a segmented bar at the row's trailing edge.
  case segmented
  /// One row each under the label, the selected one checked.
  case inline
}

/// One option out of several: `Picker("Level", selection: $level) { Text("Easy").tag(0) … }`.
///
/// Each option selects the value its `.tag(_:)` gave it; an option with no tag, or a tag of
/// another type than the selection's, selects nothing. The selection is held type-erased, so a
/// picker's node has one type whatever it selects.
///
/// In the menu style the options are in no tree until the menu opens: they move into its popover
/// while it is open, so an option element only ever has one parent.
public final class Picker : FormControl {
  public private(set) var selection: AnyHashable
  public private(set) var style: PickerStyle = .menu
  /// Where a click reports the option's tag. `@Component` arms it with the binding's write-back,
  /// through `adapt`.
  public var onSelectionChange: ((AnyHashable) -> Void)?

  private let label: Text
  private var options: [UIElement] = []
  /// Each option's highlight or check mark, in option order: the control's own, or the open
  /// menu's.
  private var marks: [PickerMark] = []

  /// The menu style's button and the title it shows.
  private let menuTitle = Text("").font(FormMetrics.font).foregroundColor(FormMetrics.labelColor)
  private var menuButton: HittableView?
  private var menu: PopoverHandle?
  /// The menu row the arrow keys are on.
  private var highlighted = -1
  /// The text style the picker was last laid out under, which its menu's options take too.
  private var textScope = TextEnvironment()

  public init<T: Hashable>(
    _ label: String, selection: T, onSelectionChange: ((AnyHashable) -> Void)? = nil,
    @UIElementBuilder content: () -> [UIElement] = { [] }
  ) {
    self.selection = AnyHashable(selection)
    self.onSelectionChange = onSelectionChange
    self.label = Text(label).font(FormMetrics.font).foregroundColor(FormMetrics.labelColor)
    super.init(content: EmptyElement())
    self.options = content()
    self.rebuild(nil)
  }

  /// A hand-built picker over a binding. In a `@Component` body `$state` is lowered instead.
  public convenience init<T: Hashable>(
    _ label: String, selection: Binding<T>, @UIElementBuilder content: () -> [UIElement] = { [] }
  ) {
    self.init(label, selection: selection.wrappedValue, content: content)
    self.onSelectionChange = { [unowned self] tag in
      guard let value = tag.base as? T else { return }
      selection.wrappedValue = value
      if let context = self.context { self.setSelection(selection.wrappedValue, context) }
    }
  }

  /// Fits a write-back to the selection's own type: what `@Component` arms `onSelectionChange`
  /// through. A tag of another type is dropped.
  public static func adapt<T: Hashable>(_ write: @escaping (T) -> Void) -> (AnyHashable) -> Void {
    { tag in
      if let value = tag.base as? T { write(value) }
    }
  }

  /// The door `@Component` attaches the options through.
  public func replaceChildren(_ elements: [UIElement], _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.closeMenu(animated: false)
    self.options = elements
    self.rebuild(animation)
  }

  public override func unmount(_ context: UIContext) {
    self.closeMenu(animated: false)
    super.unmount(context)
  }

  // MARK: - Building

  /// Builds the tree for the current style around the options. Runs when the options or the
  /// style change, never for a new selection.
  private func rebuild(_ animation: UIAnimation?) {
    self.marks.removeAll(keepingCapacity: true)

    let label = self.label
    let tree: UIElement
    switch self.style {
    case .menu:
      self.menuTitle.text = self.selectedTitle
      let title = self.menuTitle
      let button = HittableView(onTap: nil) {
        PopupFace(chevrons: true) { title }
      }
      button.onTap = { [unowned self] _ in self.openMenu() }
      self.menuButton = button
      tree = HStack(spacing: FormMetrics.labelSpacing) {
        if !label.text.isEmpty {
          label
          Spacer()
        }
        button
      }
    case .segmented:
      let bar = HStack(spacing: 2)
      bar.applyContent(self.rows(.segment))
      tree = HStack(spacing: FormMetrics.labelSpacing) {
        if !label.text.isEmpty {
          label
          Spacer()
        }
        Background(FormMetrics.fillColor, in: .rect(cornerRadius: 7)) {
          bar.padding(2)
        }
      }
    case .inline:
      let list = VStack(alignment: .leading, spacing: 0)
      list.applyContent(self.rows(.check))
      tree = VStack(alignment: .leading, spacing: 4) {
        if !label.text.isEmpty { label }
        list
      }
    }
    if self.style != .menu {
      self.menuButton = nil
    }
    // Options are drawn in the form's font unless they, or something around the picker, set one.
    self.setContent(TextStyleElement(defaults: Self.optionStyle) { tree }, animation: animation)
  }

  private static let optionStyle = TextEnvironment().font(FormMetrics.font)

  public override func calcSize(_ proposal: ProposedSize) -> float2 {
    self.textScope = TextScope.current
    return super.calcSize(proposal)
  }

  /// Each option wrapped in its mark and a tap target, in option order.
  private func rows(_ kind: PickerMark.Kind) -> [UIElement] {
    self.options.enumerated().map { index, option in
      let mark = PickerMark(kind, selected: option.tagValue == self.selection) {
        switch kind {
        case .segment:
          option.padding(Inset(vertical: 3, horizontal: 12))
        case .check:
          HStack(spacing: 8) {
            option
            Spacer(minLength: PickerMark.checkWidth)
          }
          .padding(Inset(vertical: 5, horizontal: 0))
        case .menuItem:
          option.padding(Inset(left: PickerMark.checkWidth + 8, top: 4, right: 16, bottom: 4))
        }
      }
      self.marks.append(mark)
      let hit = HittableView(onTap: { [unowned self] _ in self.choose(index) }) { mark }
      if kind == .menuItem {
        hit.onHover = { [unowned self] hovering, _ in
          if hovering { self.highlight(index) }
        }
      }
      return hit
    }
  }

  /// The selected option's text, when it is one; else the tag itself.
  private var selectedTitle: String {
    guard let option = self.options.first(where: { $0.tagValue == self.selection }) else { return "" }
    var current: UIElement = option
    while true {
      if let text = current as? Text { return text.text }
      guard let single = current as? SingleChildElement, let child = single.child else { break }
      current = child
    }
    return "\(self.selection.base)"
  }

  // MARK: - Menu

  private func openMenu() {
    guard !self.isDisabled, let context = self.context, let button = self.menuButton,
          self.menu?.isPresented != true
    else { return }
    let list = VStack(alignment: .leading, spacing: 0)
    list.applyContent(self.rows(.menuItem))
    let keys = KeyPressElement(keys: [.upArrow, .downArrow, .return, .space], phases: [.down, .repeat], action: nil) {
      list.padding(Inset(vertical: 4, horizontal: 4))
    }
    keys.action = { [unowned self] press in self.menuKey(press.key) }
    // On the selected option, as a macOS menu opens.
    self.highlighted = -1
    self.highlight(self.options.firstIndex { $0.tagValue == self.selection } ?? -1)
    self.menu = context.presentPopover(
      keys, anchor: button, alignment: .trailing, textStyle: self.textScope, textDefaults: Self.optionStyle
    ) { [weak self] in
      guard let self else { return }
      self.menu = nil
      self.marks.removeAll(keepingCapacity: true)
    }
  }

  private func closeMenu(animated: Bool) {
    guard let menu = self.menu, let context = self.context else { return }
    context.dismissPopover(menu, animated: animated)
  }

  private func highlight(_ index: Int) {
    guard index != self.highlighted, let context = self.context else { return }
    if self.marks.indices.contains(self.highlighted) {
      self.marks[self.highlighted].setHighlighted(false, context)
    }
    self.highlighted = index
    if self.marks.indices.contains(index) {
      self.marks[index].setHighlighted(true, context)
    }
  }

  private func menuKey(_ key: KeyEquivalent) -> KeyPress.Result {
    let count = self.options.count
    guard count > 0 else { return .ignored }
    switch key {
    case .upArrow:
      self.highlight(self.highlighted <= 0 ? count - 1 : self.highlighted - 1)
    case .downArrow:
      self.highlight(self.highlighted >= count - 1 ? 0 : self.highlighted + 1)
    default:
      if self.options.indices.contains(self.highlighted) {
        self.choose(self.highlighted)
      } else {
        self.closeMenu(animated: true)
      }
    }
    return .handled
  }

  private func choose(_ index: Int) {
    defer { self.closeMenu(animated: true) }
    guard !self.isDisabled, let report = self.onSelectionChange,
          let tag = self.options[index].tagValue, tag != self.selection
    else { return }
    self.commit { report(tag) }
  }

  // MARK: - Setters

  public func setSelection<T: Hashable>(_ value: T, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    let selection = AnyHashable(value)
    guard selection != self.selection else { return }
    self.selection = selection
    let animation = self.animation(animation)
    for (option, mark) in zip(self.options, self.marks) {
      mark.setProgress(option.tagValue == selection ? 1 : 0, context, animation: animation)
    }
    if self.style == .menu {
      self.menuTitle.setText(self.selectedTitle, context, animation: animation)
    }
  }

  public func setPickerStyle(_ value: PickerStyle, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    guard value != self.style else { return }
    self.closeMenu(animated: false)
    self.style = value
    self.rebuild(animation)
  }

  /// Built in `style`: `.pickerStyle(.inline)`. Sets this picker's own style and returns it.
  public func pickerStyle(_ style: PickerStyle) -> Self {
    if style != self.style {
      self.style = style
      self.rebuild(nil)
    }
    return self
  }

  public func setLabel(_ value: String, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    guard value != self.label.text else { return }
    self.label.setText(value, context, animation: animation)
  }
}

/// What marks a picker option selected, behind or beside the option it wraps: a raised white
/// segment, a check mark at the trailing edge, or — in a menu — a check mark at the leading edge
/// and a highlight under the row the pointer or the arrow keys are on. `progress` is how
/// selected, for the fade.
final class PickerMark : UIRenderableElement {
  enum Kind {
    case segment
    case check
    case menuItem
  }

  static let checkWidth: Float = 18

  let kind: Kind
  private(set) var position: float2 = .zero
  private(set) var size: float2 = .zero
  private(set) var progress: Float
  private var highlighted = false

  init(_ kind: Kind, selected: Bool, @UIElementBuilder content: () -> [UIElement]) {
    self.kind = kind
    self.progress = selected ? 1 : 0
    super.init()
    self.applyContent(content())
  }

  override func mount(_ context: UIContext) {
    context.registerRenderableView(self)
  }

  override func unmount(_ context: UIContext) {
    context.unregisterRenderableView(self)
  }

  func setProgress(_ value: Float, _ context: UIContext, animation: UIAnimation?) {
    context.animator.set(self, .progress, from: self.progress, to: value, animation, context) { element, value, context in
      unsafeDowncast(element, to: PickerMark.self).progress = value.x
      context.invalidate()
    }
  }

  func setHighlighted(_ value: Bool, _ context: UIContext) {
    guard value != self.highlighted else { return }
    self.highlighted = value
    context.invalidate()
  }

  override func getSize() -> float2 {
    self.size
  }

  override func calcSize(_ proposal: ProposedSize) -> float2 {
    self.size = self.child?.calcSize(proposal) ?? .zero
    return self.size
  }

  override func calcPosition(_ position: float2) {
    self.position = position
    self.child?.calcPosition(position)
  }

  override func render(_ renderer: Graphics2D, _ effect: EffectState) {
    guard effect.opacity > 0 else { return }
    let origin = effect.apply(to: self.position) - renderer.size * 0.5
    let size = self.size * effect.scale
    let s = effect.scale

    if self.kind == .menuItem, self.highlighted {
      var fill = FormMetrics.accentColor
      fill.w *= 0.16 * effect.opacity
      renderer.draw(roundedRect: origin, size: size, radii: float4(repeating: 5 * s), color: fill)
    }

    let alpha = effect.opacity * self.progress
    guard alpha > 0 else { return }
    switch self.kind {
    case .segment:
      let radii = float4(repeating: 5 * s)
      renderer.draw(roundedRect: origin - 0.5 * s, size: size + s, radii: radii, color: float4(0, 0, 0, 0.1 * alpha))
      renderer.draw(roundedRect: origin, size: size, radii: radii, color: float4(1, 1, 1, alpha))
    case .check:
      let center = float2(origin.x + size.x - Self.checkWidth * 0.5 * s, origin.y + size.y * 0.5)
      Self.drawCheck(renderer, at: center, scale: s, color: FormMetrics.accentColor, alpha: alpha)
    case .menuItem:
      let center = float2(origin.x + (Self.checkWidth * 0.5 + 4) * s, origin.y + size.y * 0.5)
      Self.drawCheck(renderer, at: center, scale: s, color: FormMetrics.labelColor, alpha: alpha)
    }
  }

  static func drawCheck(_ renderer: Graphics2D, at center: float2, scale s: Float, color: float4, alpha: Float) {
    var ink = color
    ink.w *= alpha
    let corner = center + float2(-1.5, 3.5) * s
    renderer.draw(stroke: center + float2(-5, 0) * s, to: corner, width: 2 * s, color: ink)
    renderer.draw(stroke: corner, to: center + float2(5, -5) * s, width: 2 * s, color: ink)
  }
}

/// A bordered button face around a title, as a pop-up button or a date pill: white, rounded,
/// with ⌃⌄ at the trailing edge when `chevrons` is set.
final class PopupFace : UIRenderableElement {
  static let inset = Inset(left: 8, top: 3, right: 8, bottom: 3)
  static let chevronWidth: Float = 16

  let chevrons: Bool
  private(set) var position: float2 = .zero
  private(set) var size: float2 = .zero
  private var inset: Inset {
    self.chevrons ? Inset(left: 8, top: 3, right: 8 + Self.chevronWidth, bottom: 3) : Self.inset
  }

  init(chevrons: Bool, @UIElementBuilder content: () -> [UIElement]) {
    self.chevrons = chevrons
    super.init()
    self.applyContent(content())
  }

  override func mount(_ context: UIContext) {
    context.registerRenderableView(self)
  }

  override func unmount(_ context: UIContext) {
    context.unregisterRenderableView(self)
  }

  override func getSize() -> float2 {
    self.size
  }

  private var padding: float2 {
    float2(self.inset.left + self.inset.right, self.inset.top + self.inset.bottom)
  }

  override func sizeThatFits(_ proposal: ProposedSize) -> float2 {
    (self.child?.measure(.unspecified) ?? .zero) + self.padding
  }

  override func calcSize(_ proposal: ProposedSize) -> float2 {
    self.size = (self.child?.calcSize(.unspecified) ?? .zero) + self.padding
    return self.size
  }

  override func calcPosition(_ position: float2) {
    self.position = position
    self.child?.calcPosition(position + float2(self.inset.left, self.inset.top))
  }

  override func render(_ renderer: Graphics2D, _ effect: EffectState) {
    guard effect.opacity > 0 else { return }
    let s = effect.scale
    let origin = effect.apply(to: self.position) - renderer.size * 0.5
    let size = self.size * s
    let radii = float4(repeating: 6 * s)
    renderer.draw(roundedRect: origin, size: size, radii: radii, color: float4(1, 1, 1, effect.opacity))
    var border = FormMetrics.strokeColor
    border.w *= effect.opacity
    renderer.draw(roundedRect: origin, size: size, radii: radii, color: border, strokeWidth: s)
    guard self.chevrons else { return }
    var ink = FormMetrics.labelColor
    ink.w *= 0.7 * effect.opacity
    let center = float2(origin.x + size.x - (8 + Self.chevronWidth * 0.5) * s + 2 * s, origin.y + size.y * 0.5)
    let w = 1.4 * s
    // ⌃ above ⌄
    renderer.draw(stroke: center + float2(-3, -2) * s, to: center + float2(0, -5) * s, width: w, color: ink)
    renderer.draw(stroke: center + float2(0, -5) * s, to: center + float2(3, -2) * s, width: w, color: ink)
    renderer.draw(stroke: center + float2(-3, 2) * s, to: center + float2(0, 5) * s, width: w, color: ink)
    renderer.draw(stroke: center + float2(0, 5) * s, to: center + float2(3, 2) * s, width: w, color: ink)
  }
}
