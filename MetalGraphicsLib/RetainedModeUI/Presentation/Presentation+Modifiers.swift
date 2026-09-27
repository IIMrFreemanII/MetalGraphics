import simd

// The presentation modifiers, in two forms.
//
// With a `Binding` and a content closure, as SwiftUI writes them: for trees built by hand, and
// for type-checking a `@Component` body, which is never run.
//
// With the value alone and no content: what `@Component` generates. It lowers `$state` into the
// value, `setIsPresented`/`setItem` updates, and a write-back armed into `onIsPresentedChange`
// or `onItemChange`; and arms the content closure into `content`/`itemContent` on mount, through
// `presentationContent`, so it may capture `self`.

extension UIElementWrapping where Self: UIElement {
  // MARK: - With a binding

  /// Shows `content` on a sheet while `isPresented` is true.
  public func sheet(
    isPresented: Binding<Bool>, onDismiss: (() -> Void)? = nil,
    @UIElementBuilder content: @escaping () -> [UIElement]
  ) -> PresentationElement {
    PresentationElement.bound(.sheet, self, isPresented, onDismiss: onDismiss, content: content)
  }

  /// Shows a sheet for `item` while it is not nil.
  public func sheet<Item: Identifiable>(
    item: Binding<Item?>, onDismiss: (() -> Void)? = nil,
    @UIElementBuilder content: @escaping (Item) -> [UIElement]
  ) -> ItemPresentationElement<Item> {
    ItemPresentationElement.bound(.sheet, self, item, onDismiss: onDismiss, content: content)
  }

  /// Covers the whole window with `content` while `isPresented` is true.
  public func fullScreenCover(
    isPresented: Binding<Bool>, onDismiss: (() -> Void)? = nil,
    @UIElementBuilder content: @escaping () -> [UIElement]
  ) -> PresentationElement {
    PresentationElement.bound(.fullScreenCover, self, isPresented, onDismiss: onDismiss, content: content)
  }

  /// Covers the whole window with content for `item` while it is not nil.
  public func fullScreenCover<Item: Identifiable>(
    item: Binding<Item?>, onDismiss: (() -> Void)? = nil,
    @UIElementBuilder content: @escaping (Item) -> [UIElement]
  ) -> ItemPresentationElement<Item> {
    ItemPresentationElement.bound(.fullScreenCover, self, item, onDismiss: onDismiss, content: content)
  }

  /// Shows `content` on a card pointing at this element while `isPresented` is true: below it,
  /// or above with `arrowEdge: .bottom`, where there is room.
  public func popover(
    isPresented: Binding<Bool>, attachmentAnchor: PopoverAttachmentAnchor = .rect(.bounds),
    arrowEdge: Edge = .top, @UIElementBuilder content: @escaping () -> [UIElement]
  ) -> PresentationElement {
    let element = self.popover(isPresented: isPresented.wrappedValue, attachmentAnchor: attachmentAnchor, arrowEdge: arrowEdge)
    element.bind(isPresented)
    element.content = content
    return element
  }

  /// Shows an alert while `isPresented` is true. Every button in `actions` dismisses it once its
  /// action ran; with none, it has an OK button.
  public func alert(
    _ title: String, isPresented: Binding<Bool>, @UIElementBuilder actions: @escaping () -> [UIElement],
    @UIElementBuilder message: @escaping () -> [UIElement] = { [] }
  ) -> PresentationElement {
    let element = self.alert(title, isPresented: isPresented.wrappedValue)
    element.bind(isPresented)
    element.content = actions
    element.message = message
    return element
  }

  /// Shows a choice of actions while `isPresented` is true, with a Cancel button unless one of
  /// them is `.cancel`.
  public func confirmationDialog(
    _ title: String, isPresented: Binding<Bool>, titleVisibility: Visibility = .automatic,
    @UIElementBuilder actions: @escaping () -> [UIElement],
    @UIElementBuilder message: @escaping () -> [UIElement] = { [] }
  ) -> PresentationElement {
    let element = self.confirmationDialog(title, isPresented: isPresented.wrappedValue, titleVisibility: titleVisibility)
    element.bind(isPresented)
    element.content = actions
    element.message = message
    return element
  }

  // MARK: - With the value, for @Component

  public func sheet(isPresented: Bool, onDismiss: (() -> Void)? = nil) -> PresentationElement {
    let element = PresentationElement(kind: .sheet, isPresented: isPresented, content: self)
    element.onDismiss = onDismiss
    return element
  }

  public func sheet<Item: Identifiable>(item: Item?, onDismiss: (() -> Void)? = nil) -> ItemPresentationElement<Item> {
    let element = ItemPresentationElement(kind: .sheet, item: item, content: self)
    element.onDismiss = onDismiss
    return element
  }

  public func fullScreenCover(isPresented: Bool, onDismiss: (() -> Void)? = nil) -> PresentationElement {
    let element = PresentationElement(kind: .fullScreenCover, isPresented: isPresented, content: self)
    element.onDismiss = onDismiss
    return element
  }

  public func fullScreenCover<Item: Identifiable>(item: Item?, onDismiss: (() -> Void)? = nil) -> ItemPresentationElement<Item> {
    let element = ItemPresentationElement(kind: .fullScreenCover, item: item, content: self)
    element.onDismiss = onDismiss
    return element
  }

  public func popover(
    isPresented: Bool, attachmentAnchor: PopoverAttachmentAnchor = .rect(.bounds), arrowEdge: Edge = .top
  ) -> PresentationElement {
    PresentationElement(kind: .popover, isPresented: isPresented, prefersAbove: arrowEdge == .bottom, content: self)
  }

  public func alert(_ title: String, isPresented: Bool) -> PresentationElement {
    PresentationElement(kind: .alert, isPresented: isPresented, title: title, content: self)
  }

  public func confirmationDialog(
    _ title: String, isPresented: Bool, titleVisibility: Visibility = .automatic
  ) -> PresentationElement {
    PresentationElement(
      kind: .confirmationDialog, isPresented: isPresented, title: title, titleVisibility: titleVisibility, content: self
    )
  }
}

/// What `@Component` arms a presentation's content through, so the closure it wrote is built
/// as a `@UIElementBuilder` block.
public func presentationContent(@UIElementBuilder _ content: @escaping () -> [UIElement]) -> () -> [UIElement] {
  content
}

public func presentationItemContent<Item>(
  @UIElementBuilder _ content: @escaping (Item) -> [UIElement]
) -> (Item) -> [UIElement] {
  content
}

extension PresentationElement {
  static func bound(
    _ kind: PresentationKind, _ presenter: UIElement, _ isPresented: Binding<Bool>,
    onDismiss: (() -> Void)?, content: @escaping () -> [UIElement]
  ) -> PresentationElement {
    let element = PresentationElement(kind: kind, isPresented: isPresented.wrappedValue, content: presenter)
    element.bind(isPresented)
    element.onDismiss = onDismiss
    element.content = content
    return element
  }

  /// Writes a dismissal back to `binding`, and shows what it then holds.
  func bind(_ binding: Binding<Bool>) -> Void {
    self.onIsPresentedChange = { [unowned self] value in
      binding.wrappedValue = value
      if let context = self.context { self.setIsPresented(binding.wrappedValue, context) }
    }
  }
}

extension ItemPresentationElement {
  static func bound(
    _ kind: PresentationKind, _ presenter: UIElement, _ item: Binding<Item?>,
    onDismiss: (() -> Void)?, content: @escaping (Item) -> [UIElement]
  ) -> ItemPresentationElement<Item> {
    let element = ItemPresentationElement(kind: kind, item: item.wrappedValue, content: presenter)
    element.onItemChange = { [unowned element] value in
      item.wrappedValue = value
      if let context = element.context { element.setItem(item.wrappedValue, context) }
    }
    element.onDismiss = onDismiss
    element.itemContent = content
    return element
  }
}
