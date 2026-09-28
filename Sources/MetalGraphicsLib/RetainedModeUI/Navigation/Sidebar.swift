import simd

/// A sidebar title's type and inset.
public enum SidebarMetrics {
  public static let titleFont = TextFont.system(size: 11, weight: .semibold)
  public static let titleColor: float4 = .secondaryLabel
  public static let titleInset = Inset(left: 10, top: 4, right: 10, bottom: 6)
}

/// The small heading over a sidebar's links: "Demos", "Favourites". Not in SwiftUI, where a
/// `Section` header in a sidebar list plays its part.
///
///     SidebarTitle("Demos")
public final class SidebarTitle : SingleChildElement {
  private let text: Text

  public init(_ title: String) {
    let text = Text(title).font(SidebarMetrics.titleFont).foregroundColor(SidebarMetrics.titleColor)
    self.text = text
    super.init()
    self.applyContent([text.padding(SidebarMetrics.titleInset)])
  }

  public func setTitle(_ value: String, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    guard value != self.text.text else { return }
    self.text.setText(value, context, animation: animation)
  }
}

/// A link in a sidebar: 26 tall, an optional glyph before the title, the selection's highlight
/// with the title medium weight. What a `NavigationLink` in a `NavigationSplitView`'s sidebar
/// looks like, for a sidebar driven by hand.
///
///     SidebarLink("Form", icon: .document, selected: page == .form) { page = .form }
public final class SidebarLink : SingleChildElement {
  private let row: ListRow

  public init(_ title: String, icon: ThemeIcon? = nil, selected: Bool = false, action: (() -> Void)? = nil) {
    self.row = ListRow(title, selected: selected, height: NavigationMetrics.sidebarRowHeight, margin: 0, action: action, content: {
      if let icon { Image(icon: icon).foregroundColor(.secondaryLabel) }
    })
    super.init()
    self.applyContent([self.row])
  }

  /// What a tap runs.
  public var action: (() -> Void)? {
    get { self.row.action }
    set { self.row.action = newValue }
  }

  public func setSelected(_ value: Bool, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.row.setSelected(value, context, animation: animation)
  }

  public func setTitle(_ value: String, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.row.setLabel(value, context, animation: animation)
  }
}

/// A navigation bar in place: 38 tall on the bar tint with a hairline under it, the title
/// centred in the headline font, `leading` items (after a ‹ back button when `back` is given)
/// and `trailing` ones at the edges. A `NavigationStack` draws its own; for a page's items there,
/// use `.toolbar(leading:trailing:)`.
public final class NavigationBar : SingleChildElement {
  private let title: Text

  public init(
    _ title: String, back: String? = nil,
    @UIElementBuilder leading: () -> [UIElement] = { [] }, @UIElementBuilder trailing: () -> [UIElement] = { [] }
  ) {
    let title = Text(title).font(NavigationMetrics.titleFont).foregroundColor(NavigationMetrics.titleColor).lineLimit(1)
    self.title = title
    super.init()
    var leadingItems = leading()
    if let back { leadingItems.insert(Button("‹ " + (back.isEmpty ? "Back" : back)), at: 0) }
    let row = HStack(spacing: 8)
    row.applyContent(leadingItems + [Spacer()] + trailing())
    self.applyContent([
      ZStack {
        row.padding(Inset(horizontal: 10))
        title
      }
      .frame(maxWidth: .infinity, minHeight: NavigationMetrics.barHeight)
      .background(NavigationMetrics.barColor)
      .overlay(alignment: .bottom) {
        Rectangle(NavigationMetrics.separatorColor).frame(height: 0.5)
      }
    ])
  }

  public func setTitle(_ value: String, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    guard value != self.title.text else { return }
    self.title.setText(value, context, animation: animation)
  }
}
