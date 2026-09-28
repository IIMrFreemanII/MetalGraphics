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
