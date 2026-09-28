import simd

/// What a presentation shows, the same in a layer over the app's tree or in a window of its
/// own: the content of a sheet, a cover or a popover as it is, or an alert's and a dialog's
/// title, message and buttons laid out as macOS lays them out.
struct PresentationContent {
  /// Where the content goes: a sheet's, a cover's or a popover's. A stack even for one element,
  /// so it ends the key handler's spine and the handler around it never belongs to a text field
  /// inside (see `UIContext.collect`).
  let root: UIElement
  /// An alert's or a dialog's buttons, in the order they show.
  let buttons: [Button]
  /// An alert's or a dialog's title, which `setTitle` updates.
  let title: Text?

  static func make(
    _ kind: PresentationKind, title: String, titleVisibility: Visibility,
    content: [UIElement], message: [UIElement], layout: AlertLayout = .automatic
  ) -> PresentationContent {
    switch kind {
    case .sheet, .fullScreenCover, .popover:
      return PresentationContent(root: Self.stack(VStack(spacing: 0), content), buttons: [], title: nil)
    case .alert, .confirmationDialog:
      return self.alert(kind, title: title, titleVisibility: titleVisibility, actions: content, message: message, layout: layout)
    }
  }

  private static func alert(
    _ kind: PresentationKind, title: String, titleVisibility: Visibility,
    actions: [UIElement], message: [UIElement], layout: AlertLayout
  ) -> PresentationContent {
    // Each action with the button it is, found through the wrappers around it.
    var entries = actions.map { ($0, Self.button(in: $0)) }
    if kind == .alert, !entries.contains(where: { $0.1 != nil }) {
      let ok = Button("OK")
      entries.append((ok, ok))
    }
    if kind == .confirmationDialog, !entries.contains(where: { $0.1?.role == .cancel }) {
      let cancel = Button("Cancel", role: .cancel)
      entries.append((cancel, cancel))
    }
    let cancels = entries.filter { $0.1?.role == .cancel }
    let others = entries.filter { $0.1?.role != .cancel }
    // Side by side with the default on the right, as a two-button alert; else stacked, cancel
    // last.
    let sideBySide = switch layout {
    case .automatic: kind == .alert && entries.count <= 2
    case .row: true
    case .stack: false
    }
    let ordered = sideBySide ? cancels + others : others + cancels
    let buttons = ordered.compactMap { $0.1 }
    let defaultButton = buttons.first { $0.role == nil }
    for button in buttons {
      _ = button.buttonStyle(button === defaultButton ? .borderedProminent : .bordered)
      button.face.fillsWidth = true
      button.face.centersContent = true
    }
    let rowElements = ordered.map { $0.0 }
    let row: UIElement = sideBySide
      ? Self.stack(HStack(spacing: 8), rowElements)
      : Self.stack(VStack(spacing: 6), rowElements)

    let showsTitle = kind == .alert || titleVisibility != .hidden
    let titleText = showsTitle && !title.isEmpty ? Text(title).bold().multilineTextAlignment(.center) : nil
    let root = VStack(spacing: 12) {
      if let titleText { titleText }
      if !message.isEmpty {
        Self.stack(VStack(spacing: 4), message)
          .font(FormMetrics.captionFont)
          .foregroundColor(FormMetrics.secondaryColor)
          .multilineTextAlignment(.center)
      }
      row
    }
    .padding(Inset(vertical: 18, horizontal: 16))
    return PresentationContent(root: root, buttons: buttons, title: titleText)
  }

  private static func stack<S: MultiChildElement>(_ stack: S, _ elements: [UIElement]) -> S {
    stack.applyContent(elements)
    return stack
  }

  /// The button `element` is, or wraps with nothing but single-child elements in between.
  static func button(in element: UIElement) -> Button? {
    var current: UIElement = element
    while true {
      if let button = current as? Button { return button }
      guard let single = current as? SingleChildElement, let child = single.child else { return nil }
      current = child
    }
  }
}

/// A presentation's dimmed backdrop: one rect over the whole window.
final class ModalBackdrop : FormGraphic {
  static let color: float4 = .scrim

  override func sizeThatFits(_ proposal: ProposedSize) -> float2 {
    proposal.replacingUnspecified(with: .zero)
  }

  override func draw(_ renderer: Graphics2D, origin: float2, size: float2, scale: Float, opacity: Float) {
    var color = Self.color
    color.w *= opacity
    renderer.draw(roundedRect: origin, size: size, radii: .zero, color: color)
  }
}
