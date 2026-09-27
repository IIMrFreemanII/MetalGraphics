import simd

/// What a `HeadlessWindow` query could not find, with what the window does show.
public struct HeadlessError: Error, CustomStringConvertible {
  public let query: String
  public let window: String
  /// Every text shown in the window, in tree order.
  public let shown: [String]

  public var description: String {
    "\(self.query): not found in \(self.window). It shows: \(self.shown.map { "\"\($0)\"" }.joined(separator: ", ")). " +
      "window.describeTree() prints the whole tree."
  }
}

/// An element found in a `HeadlessWindow`, and what a user can do to it. Actions are real input
/// at the element's centre, stepped as `HeadlessWindow`'s are: a tap that something covers
/// lands on what covers it, as it would in the app.
@MainActor public struct ElementRef {
  public let element: UIElement
  public let window: HeadlessWindow

  /// Where it is in its window: its own rect, or its first descendant's that has one.
  public var frame: HeadlessRect? { HeadlessQuery.geometry(of: self.element) }

  /// Where a pointer hits it: its hit rect, or its first hittable descendant's; else `frame`.
  public var hitFrame: HeadlessRect? { HeadlessQuery.hitGeometry(of: self.element) ?? self.frame }

  /// Mounted, not hidden, and inside the window and every scroll view around it.
  public var isShown: Bool { HeadlessQuery.isShown(self.element, in: self.window) }

  /// The text it shows, when it is a `Text`, or a text field's value.
  public var text: String? {
    if let text = self.element as? Text { return text.text }
    if let field = self.element as? TextField { return field.text }
    return nil
  }

  public func tap() throws { self.window.click(at: try self.center()) }
  public func doubleTap() throws { self.window.doubleClick(at: try self.center()) }
  public func rightClick() throws { self.window.rightClick(at: try self.center()) }
  public func hover() throws { self.window.move(to: try self.center()) }

  /// A press here, a drag to `point` (the window's), and a release there.
  public func drag(to point: float2, steps: Int = 4) throws {
    self.window.drag(from: try self.center(), to: point, steps: steps)
  }

  /// A press here, a drag to `point` on the app's screen, and a release there: out of the window.
  public func drag(toScreen point: float2, steps: Int = 8) throws {
    self.window.drag(from: try self.center(), toScreen: point, steps: steps)
  }

  private func center() throws -> float2 {
    guard let frame = self.hitFrame else {
      throw HeadlessError(query: "A place to press \(Swift.type(of: self.element))", window: self.window.sceneID, shown: self.window.shownTexts)
    }
    return frame.center
  }
}

public extension HeadlessWindow {
  // MARK: - Finding

  /// Every mounted `Text` showing exactly `text`, in tree order, shown or not.
  func find(text: String) -> [ElementRef] {
    self.all(Text.self).filter { $0.mounted && $0.text == text }.map { ElementRef(element: $0, window: self) }
  }

  /// Every mounted element tagged `.id(id)`.
  func find(id: AnyHashable) -> [ElementRef] {
    self.all(IDElement.self).filter { $0.mounted && $0.id == id }.map { ElementRef(element: $0, window: self) }
  }

  /// Every mounted `T` that `predicate` accepts.
  func find<T: UIElement>(_ type: T.Type, where predicate: (T) -> Bool = { _ in true }) -> [ElementRef] {
    self.all(type).filter { $0.mounted && predicate($0) }.map { ElementRef(element: $0, window: self) }
  }

  /// The first shown `Text` showing exactly `text`, preferring one in something pressable — the
  /// sidebar's "Form" link over a "Form" title.
  func element(text: String) throws -> ElementRef {
    let shown = self.find(text: text).filter(\.isShown)
    guard let found = shown.first(where: { HeadlessQuery.isInsideHittable($0.element) }) ?? shown.first else {
      throw HeadlessError(query: "Text \"\(text)\"", window: self.sceneID, shown: self.shownTexts)
    }
    return found
  }

  /// The first shown element tagged `.id(id)`.
  func element(id: AnyHashable) throws -> ElementRef {
    guard let found = self.find(id: id).first(where: \.isShown) else {
      throw HeadlessError(query: "Element with id \(id)", window: self.sceneID, shown: self.shownTexts)
    }
    return found
  }

  /// The shown form control — button, link, toggle, field, stepper, slider, picker — whose label
  /// is `label`, or the text field whose prompt is.
  func control(labelled label: String) throws -> ElementRef {
    if let field = self.all(TextField.self).first(where: { $0.mounted && $0.prompt == label }) {
      let ref = ElementRef(element: field, window: self)
      if ref.isShown { return ref }
    }
    for text in self.find(text: label) where text.isShown {
      var current = text.element.parent
      while let element = current {
        if element is FormControl { return ElementRef(element: element, window: self) }
        current = element.parent
      }
    }
    throw HeadlessError(query: "Control labelled \"\(label)\"", window: self.sceneID, shown: self.shownTexts)
  }

  /// The tab of dock panel `id`.
  func panel(_ id: String) throws -> ElementRef {
    guard let tab = self.all(DockTabItem.self).first(where: { $0.mounted && $0.panel == id }) else {
      throw HeadlessError(query: "Dock panel \"\(id)\"", window: self.sceneID, shown: self.shownTexts)
    }
    return ElementRef(element: tab, window: self)
  }

  /// Whether a `Text` showing exactly `text` is shown.
  func shows(_ text: String) -> Bool {
    self.find(text: text).contains(where: \.isShown)
  }

  /// Every text shown, in tree order.
  var shownTexts: [String] {
    self.all(Text.self).filter { HeadlessQuery.isShown($0, in: self) }.map(\.text)
  }

  // MARK: - Acting

  /// Taps the shown text `label`: a button's, a link's, a list row's.
  func tap(_ label: String) throws {
    try self.element(text: label).tap()
  }

  /// Focuses the text field labelled or prompted `label` by clicking it, and types `text`.
  func type(_ text: String, into label: String) throws {
    let control = try self.control(labelled: label)
    guard let field = HeadlessQuery.first(FocusableElement.self, in: control.element) else {
      throw HeadlessError(query: "A text field labelled \"\(label)\"", window: self.sceneID, shown: self.shownTexts)
    }
    self.click(at: field.position + field.size * 0.5)
    self.type(text)
  }

  /// Flips the toggle labelled `label`.
  func toggle(_ label: String) throws {
    let control = try self.control(labelled: label)
    guard control.element is Toggle else {
      throw HeadlessError(query: "A toggle labelled \"\(label)\"", window: self.sceneID, shown: self.shownTexts)
    }
    try control.tap()
  }

  // MARK: - Describing

  /// The tree, one element a line, indented by depth: its type, then what tells it apart — its
  /// text, id, value, frame — and whether it is hidden. For a failing test's message.
  func describeTree() -> String {
    var lines: [String] = []
    func visit(_ element: UIElement, _ depth: Int) {
      var line = String(repeating: "  ", count: depth) + String(describing: Swift.type(of: element))
      switch element {
      case let text as Text: line += " \"\(text.text)\""
      case let id as IDElement: line += " id=\(id.id)"
      case let field as TextField: line += " text=\"\(field.text)\""
      case let toggle as Toggle: line += " isOn=\(toggle.isOn)"
      case let tab as DockTabItem: line += " panel=\(tab.panel)"
      default: break
      }
      if let frame = HeadlessQuery.ownGeometry(of: element) { line += " \(frame)" }
      if element.isHidden { line += " hidden" }
      if !element.mounted { line += " unmounted" }
      lines.append(line)
      element.forEachChild { visit($0, depth + 1) }
    }
    visit(self.root, 0)
    return lines.joined(separator: "\n")
  }
}

/// The geometry and visibility rules the queries share.
@MainActor enum HeadlessQuery {
  /// The element's own rect, for the kinds that keep one.
  static func ownGeometry(of element: UIElement) -> HeadlessRect? {
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

  static func geometry(of element: UIElement) -> HeadlessRect? {
    if let own = self.ownGeometry(of: element) { return own }
    var found: HeadlessRect?
    self.visitDescendants(of: element) { child in
      found = self.ownGeometry(of: child)
      return found == nil
    }
    return found
  }

  static func hitGeometry(of element: UIElement) -> HeadlessRect? {
    if let hittable = element as? any Hittable {
      return HeadlessRect(origin: hittable.hitPosition, size: hittable.hitSize)
    }
    if element is Text { return nil }
    var found: HeadlessRect?
    self.visitDescendants(of: element) { child in
      if let hittable = child as? any Hittable, hittable.hitSize.x > 0, hittable.hitSize.y > 0 {
        found = HeadlessRect(origin: hittable.hitPosition, size: hittable.hitSize)
      }
      return found == nil
    }
    return found
  }

  static func first<T: UIElement>(_ type: T.Type, in element: UIElement) -> T? {
    if let match = element as? T { return match }
    var found: T?
    self.visitDescendants(of: element) { child in
      found = child as? T
      return found == nil
    }
    return found
  }

  /// Pre-order, until `body` returns false.
  private static func visitDescendants(of element: UIElement, _ body: (UIElement) -> Bool) {
    var going = true
    func visit(_ e: UIElement) {
      guard going else { return }
      e.forEachChild { child in
        guard going else { return }
        if !body(child) { going = false; return }
        visit(child)
      }
    }
    visit(element)
  }

  static func isInsideHittable(_ element: UIElement) -> Bool {
    var current = element.parent
    while let e = current {
      if e is any Hittable || e is FormControl { return true }
      current = e.parent
    }
    return false
  }

  /// Mounted, not hidden, of some size, and inside the window and every scroll view around it.
  static func isShown(_ element: UIElement, in window: HeadlessWindow) -> Bool {
    guard element.mounted, let frame = self.geometry(of: element), frame.size.x > 0, frame.size.y > 0 else { return false }
    guard self.overlaps(frame, HeadlessRect(origin: .zero, size: window.size)) else { return false }
    var current: UIElement? = element
    while let e = current {
      if e.isHidden { return false }
      if e !== element, let scroll = e as? ScrollView,
         !self.overlaps(frame, HeadlessRect(origin: scroll.position, size: scroll.size)) {
        return false
      }
      current = e.parent
    }
    return true
  }

  private static func overlaps(_ a: HeadlessRect, _ b: HeadlessRect) -> Bool {
    all(a.origin .< b.max) && all(b.origin .< a.max)
  }
}
