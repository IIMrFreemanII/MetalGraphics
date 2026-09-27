import simd

/// The root of what one presentation shows: a layer over the app's tree, or a window of its
/// own. What `DismissAction` finds from inside the content, and what nested presentations take
/// their window style from.
public class PresentationRoot : MultiChildElement {
  /// The `.sheet`, `.alert` or other modifier that shows it; nil for a popover a control opened.
  weak var presenter: PresentationElement?
  /// The window style presentations made from inside the content default to: this one's own.
  var inheritedWindowStyle = PresentationWindowStyle.inline
  /// The buttons Return and Escape run, in an alert or a confirmation dialog.
  weak var defaultButton: Button?
  weak var cancelButton: Button?
  /// Set once it has started going away: asking again does nothing.
  var isDismissing = false

  /// What the user asks for with Escape, a click outside, a dismiss action or a button: writes
  /// the presenter's binding back, which dismisses it, or else dismisses it itself.
  func requestDismiss() -> Void {
    guard !self.isDismissing else { return }
    if let presenter = self.presenter {
      presenter.userDismissed(self)
    } else {
      self.dismissItself()
    }
  }

  /// Runs the cancel button, which dismisses as any button in an alert does; with none, dismisses.
  func cancel() -> Void {
    guard !self.isDismissing else { return }
    if let button = self.cancelButton, button.mounted {
      button.performTap()
    } else {
      self.requestDismiss()
    }
  }

  /// Runs the default button, if there is one that is enabled. Whether there was.
  func activateDefault() -> Bool {
    guard !self.isDismissing, let button = self.defaultButton, button.mounted, !button.isDisabled else {
      return false
    }
    button.performTap()
    return true
  }

  /// Goes away without a presenter to ask: a popover a control opened.
  func dismissItself() -> Void {}

  /// The context what it shows is in: the layer's own, or its window's.
  var presentedContext: UIContext? { nil }

  /// Goes, animated or not. The presenter has already let go of it.
  func dismissAnimated(_ animated: Bool) -> Void {}

  /// Goes at once, without writing any binding back or running `onDismiss`: its presenter went
  /// away.
  func dismissImmediately() -> Void {}

  /// Asks every presentation shown from inside this one to go away, writing their bindings back:
  /// what is shown over something that goes goes with it.
  func dismissNested(_ context: UIContext) -> Void {
    for presentation in context.presentations where presentation.isShowing {
      if presentation.nearestAncestor(PresentationRoot.self) === self {
        presentation.userDismissed(nil)
      }
    }
  }

  // MARK: - Alert buttons

  /// Wires the buttons of an alert or a dialog: each one dismisses it once its action ran, the
  /// first without a role is the default, and the cancel one runs on Escape.
  func adopt(buttons: [Button]) -> Void {
    for button in buttons {
      button.presentationAction = { [weak self] in self?.requestDismiss() }
    }
    self.defaultButton = buttons.first { $0.role == nil }
    self.cancelButton = buttons.first { $0.role == .cancel }
  }
}
