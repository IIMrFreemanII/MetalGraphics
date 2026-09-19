@resultBuilder
public struct UIElementBuilder {
  public static func buildBlock<T: UIElement>(_ element: T) -> T {
    return element
  }
  
  public static func buildBlock(_ elements: UIElement...) -> [UIElement] {
    return elements
  }
}
