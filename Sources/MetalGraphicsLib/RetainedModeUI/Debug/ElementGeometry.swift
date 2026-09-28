import simd

/// Where an element was laid out, for the kinds that keep their rect: hittable views, focusable
/// elements, texts, identified elements, scroll views, dock tabs. What headless queries and
/// debug overlays read; on the element's own thread, after a layout.
enum ElementGeometry {
  static func ownRect(of element: UIElement) -> HeadlessRect? {
    switch element {
    case let hittable as any Hittable: HeadlessRect(origin: hittable.hitPosition, size: hittable.hitSize)
    case let focusable as FocusableElement: HeadlessRect(origin: focusable.position, size: focusable.size)
    case let text as Text: HeadlessRect(origin: text.position, size: text.size)
    case let id as IDElement: HeadlessRect(origin: id.position, size: id.size)
    case let scroll as ScrollView: HeadlessRect(origin: scroll.position, size: scroll.size)
    case let tab as DockTabItem: HeadlessRect(origin: tab.position, size: tab.size)
    default: nil
    }
  }
}
