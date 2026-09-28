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
