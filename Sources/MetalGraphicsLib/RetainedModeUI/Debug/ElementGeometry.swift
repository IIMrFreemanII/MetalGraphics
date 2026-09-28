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

/// One element of a tree, as an inspector lists it.
public struct ElementInfo : Sendable, Equatable {
  /// How deep it is under the element inspected, from 0.
  public let depth: Int
  /// Its type's name, without its module: `ListRow`, `Text`, `Frame`.
  public let type: String
  /// Its text, when it shows one.
  public let text: String?
  /// Where it was laid out, when its kind keeps a rect.
  public let frame: HeadlessRect?
}

/// What is laid out under an element, for a design tool's inspector: each element's type, text
/// and frame, in tree order. On the element's own thread, after a layout; for a panel that shows
/// it, never per frame.
public enum ElementInspector {
  /// The tree under `element`, `maxCount` elements at most.
  public static func snapshot(of element: UIElement, maxCount: Int = 400) -> [ElementInfo] {
    var infos: [ElementInfo] = []
    func visit(_ element: UIElement, _ depth: Int) {
      guard infos.count < maxCount, !element.isHidden else { return }
      let name = String(describing: type(of: element)).split(separator: "<").first.map(String.init) ?? "UIElement"
      let text = (element as? Text)?.text ?? (element as? TextField)?.text
      infos.append(ElementInfo(depth: depth, type: name, text: text, frame: ElementGeometry.ownRect(of: element)))
      element.forEachChild { visit($0, depth + 1) }
    }
    visit(element, 0)
    return infos
  }
}
