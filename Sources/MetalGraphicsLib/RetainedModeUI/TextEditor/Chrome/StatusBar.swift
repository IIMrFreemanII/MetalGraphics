import simd

/// A `StatusBar`'s sizes, type and colours.
public enum StatusBarMetrics {
  public static let height: Float = 24
  public static let font = TextFont.system(size: 11)
  public static let color: float4 = .secondaryLabel
  public static let problemColor: float4 = .destructive
  public static let background: float4 = .barOverContent
  public static let spacing: Float = 12
  public static let inset = Inset(horizontal: 12)
}

/// The line under an editor: where the caret is, what went wrong in the accent of a problem, and
/// the file's name at the trailing edge, on a bar over the content with a hairline above. Content
/// given goes after the problem. Not in SwiftUI.
///
///     StatusBar(position: "Ln 12, Col 4", problem: loadError, file: "Greeter.swift")
public final class StatusBar : SingleChildElement {
  private let position: Text
  private let problem: Text
  private let file: Text
  private let extras: HStack

  public init(position: String, problem: String = "", file: String = "", @UIElementBuilder content: () -> [UIElement] = { [] }) {
    let position = Text(position).font(StatusBarMetrics.font).foregroundColor(StatusBarMetrics.color)
    let problem = Text(problem).font(StatusBarMetrics.font).foregroundColor(StatusBarMetrics.problemColor).lineLimit(1)
    let file = Text(file).font(StatusBarMetrics.font).foregroundColor(StatusBarMetrics.color)
    let extras = HStack(spacing: StatusBarMetrics.spacing)
    self.position = position
    self.problem = problem
    self.file = file
    self.extras = extras
    super.init()
    let extra = content()
    var row: [UIElement] = [position, problem]
    if !extra.isEmpty {
      extras.applyContent(extra)
      row.append(extras)
    }
    let stack = HStack(spacing: StatusBarMetrics.spacing)
    stack.applyContent(row + [Spacer(), file])
    self.applyContent([
      stack
        .padding(StatusBarMetrics.inset)
        .frame(maxWidth: .infinity, minHeight: StatusBarMetrics.height, alignment: .leading)
        .background(StatusBarMetrics.background)
        .overlay(alignment: .top) {
          Rectangle(.separator)
            .frame(height: 0.5)
        }
    ])
  }

  public func setPosition(_ value: String, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    guard value != self.position.text else { return }
    self.position.setText(value, context, animation: animation)
  }

  public func setProblem(_ value: String, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    guard value != self.problem.text else { return }
    self.problem.setText(value, context, animation: animation)
  }

  public func setFile(_ value: String, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    guard value != self.file.text else { return }
    self.file.setText(value, context, animation: animation)
  }
}
