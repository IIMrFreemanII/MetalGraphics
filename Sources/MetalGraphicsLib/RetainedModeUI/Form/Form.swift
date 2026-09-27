import simd

/// Sections of controls down a scrolling, grouped background, as SwiftUI's `Form` in its grouped
/// style: `Form { Section("Account") { … } Section { … } }`.
///
/// Its children are laid out one above the other and fill its width. Rows written straight in
/// the form, outside any section, are grouped as SwiftUI groups them: each run of them goes on a
/// card of its own, an implicit `Section`.
public final class Form : SingleChildElement {
  /// The sections, down the scrolling content.
  private let stack: VStack
  /// The implicit sections, by the first row of their run, so a content change that keeps a run
  /// keeps its section, and `replaceChildren` keeps it mounted.
  private var implicitSections: [ObjectIdentifier : Section] = [:]

  public init(@UIElementBuilder content: () -> [UIElement] = { [] }) {
    self.stack = VStack(alignment: .leading, spacing: FormMetrics.sectionSpacing)
    super.init()

    let stack = self.stack
    stack.applyContent(self.grouped(content(), nil, animation: nil))
    self.applyContent([
      Background(FormMetrics.groupedBackground) {
        ScrollView(.vertical) {
          stack.padding(FormMetrics.formInset)
        }
      }
    ])
  }

  /// The door `@Component` attaches the content through: it goes into the scrolling stack, not
  /// in place of the form's own tree.
  public func replaceChildren(_ elements: [UIElement], _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.stack.replaceChildren(self.grouped(elements, context, animation: animation), context, animation: animation)
  }

  /// `elements` with each run of rows that are not sections put in an implicit section.
  private func grouped(_ elements: [UIElement], _ context: UIContext?, animation: UIAnimation?) -> [UIElement] {
    var result: [UIElement] = []
    result.reserveCapacity(elements.count)
    var run: [UIElement] = []
    var kept: [ObjectIdentifier : Section] = [:]

    func flush() {
      guard let first = run.first else { return }
      let key = ObjectIdentifier(first)
      let section = self.implicitSections[key] ?? Section()
      if let context {
        section.replaceChildren(run, context, animation: animation)
      } else {
        section.applyContent(run)
      }
      kept[key] = section
      result.append(section)
      run.removeAll(keepingCapacity: true)
    }

    for element in elements {
      if Self.isSection(element) {
        flush()
        result.append(element)
      } else {
        run.append(element)
      }
    }
    flush()
    self.implicitSections = kept
    return result
  }

  /// A section, or one wrapped in modifiers: `Section { … }.transition(.opacity)`.
  private static func isSection(_ element: UIElement) -> Bool {
    var current = element
    while true {
      if current is Section { return true }
      guard let single = current as? SingleChildElement, let child = single.child else { return false }
      current = child
    }
  }
}
