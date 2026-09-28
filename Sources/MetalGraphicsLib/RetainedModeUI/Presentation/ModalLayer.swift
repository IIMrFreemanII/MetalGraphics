import simd

/// A sheet, a full-screen cover, an alert or a confirmation dialog over the app's tree: a
/// backdrop over the whole window that takes every click, and the card on it. Everything under
/// it gets no input until it goes (see `UIContext.modalFocusStart`).
///
/// A click on the backdrop dismisses, or runs an alert's or a dialog's cancel button; Escape does
/// the same.
/// Return runs an alert's or a dialog's default button.
final class ModalLayer : OverlayLayer {
  static let sheetAnimation = UIAnimation.easeOut(0.22)
  static let coverAnimation = UIAnimation.easeInOut(0.3)
  static let alertAnimation = UIAnimation.easeOut(0.18)
  static let cornerRadius: Float = 12
  static let sheetTopMargin: Float = 16
  static let margin: Float = 16

  let kind: PresentationKind
  private let scrim: HittableView
  private let backdrop: TransitionElement?
  private let cardTransition: TransitionElement
  private let card: UIElement
  private var cardSize: float2 = .zero
  private var cardOrigin: float2 = .zero

  /// `content` goes on the card; `style` is what styles its texts, around it.
  init(_ kind: PresentationKind, content: UIElement) {
    self.kind = kind
    let radius = Self.cornerRadius
    let chrome: UIElement
    switch kind {
    case .fullScreenCover:
      chrome = content
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(FormMetrics.groupedBackground)
      self.backdrop = nil
    default:
      chrome = ScrollView(.vertical) { content }
        .clipShape(.rect(cornerRadius: radius))
        .background {
          CardFill(cornerRadius: radius, material: .sheet).shadow(color: .shadow, radius: 22, y: 10)
        }
        .border(.separator, width: 0.5, in: .rect(cornerRadius: radius))
      self.backdrop = TransitionElement(.opacity) { ModalBackdrop() }
    }
    let backdrop = self.backdrop
    self.scrim = HittableView(onTap: nil, onPress: { _, _ in }) {
      if let backdrop { backdrop }
    }
    // A click anywhere on the card never reaches the backdrop, as on a popover's.
    let backstop = HittableView(onTap: { _ in }, onPress: { _, _ in }) { chrome }
    let transition = TransitionElement(Self.transition(kind, height: 0)) { backstop }
    self.cardTransition = transition
    let keys = KeyPressElement(keys: [.escape, .return], phases: [.down], action: nil) { transition }
    self.card = keys
    super.init(isModal: true, dismissesOnOutsideScroll: false)
    self.applyContent([self.scrim, keys])
    self.scrim.onTap = { [unowned self] _ in self.backdropTapped() }
    keys.action = { [unowned self] press in self.handleKey(press) }
  }

  private static func transition(_ kind: PresentationKind, height: Float) -> UITransition {
    switch kind {
    case .fullScreenCover:
      return .move(float2(0, height))
    case .alert, .confirmationDialog:
      return .asymmetric(insertion: .opacity.combined(with: .scale(1.06)), removal: .opacity)
    default:
      return .move(float2(0, -24)).combined(with: .opacity)
    }
  }

  private var animation: UIAnimation {
    switch self.kind {
    case .fullScreenCover: return Self.coverAnimation
    case .alert, .confirmationDialog: return Self.alertAnimation
    default: return Self.sheetAnimation
    }
  }

  private func backdropTapped() -> Void {
    switch self.kind {
    case .fullScreenCover: return
    case .alert, .confirmationDialog: self.cancel()
    default: self.requestDismiss()
    }
  }

  private func handleKey(_ press: KeyPress) -> KeyPress.Result {
    guard press.modifiers.intersection([.command, .option, .control, .shift]).isEmpty else { return .ignored }
    if press.key == .escape {
      self.cancel()
      return .handled
    }
    if press.key == .return, self.kind == .alert || self.kind == .confirmationDialog {
      return self.activateDefault() ? .handled : .ignored
    }
    return .ignored
  }

  override func contains(_ point: float2) -> Bool {
    ClipRect(position: self.cardOrigin, size: self.cardSize).contains(point)
  }

  override func animateIn(_ context: UIContext) {
    if self.kind == .fullScreenCover {
      // From below the window, however tall it is now.
      self.cardTransition.transition = Self.transition(self.kind, height: context.windowSize.y)
    }
    self.backdrop?.animateIn(self.animation, context)
    self.cardTransition.animateIn(self.animation, context)
  }

  override func animateOut(_ context: UIContext, completion: @escaping () -> Void) {
    if self.kind == .fullScreenCover {
      self.cardTransition.transition = Self.transition(self.kind, height: context.windowSize.y)
    }
    let animation = self.kind == .sheet ? UIAnimation.easeIn(0.18) : self.animation
    self.backdrop?.animateOut(animation, context) {}
    self.cardTransition.animateOut(animation, context, completion: completion)
  }

  // MARK: - Layout

  override func layout(in windowSize: float2) {
    _ = self.scrim.calcSize(ProposedSize(windowSize))
    let maxWidth = max(windowSize.x - Self.margin * 2, 0)
    let maxHeight = max(windowSize.y - Self.margin * 2, 0)
    let proposal: ProposedSize
    switch self.kind {
    case .fullScreenCover:
      proposal = ProposedSize(windowSize)
    case .alert, .confirmationDialog:
      let width = min(self.kind == .alert ? 260 : 280, maxWidth)
      let ideal = self.card.measure(ProposedSize(width: width, height: nil))
      proposal = ProposedSize(width: width, height: min(ideal.y, maxHeight))
    default:
      let ideal = self.card.measure(.unspecified)
      let width = min(max(ideal.x, min(200, maxWidth)), maxWidth)
      let height = min(ideal.y, max(windowSize.y - Self.sheetTopMargin * 2, 0))
      proposal = ProposedSize(width: width, height: height)
    }
    self.cardSize = self.card.calcSize(proposal)
  }

  override func calcPosition(_ position: float2) {
    self.scrim.calcPosition(position)
    let x = ((self.windowSize.x - self.cardSize.x) * 0.5).rounded()
    let y: Float
    switch self.kind {
    case .fullScreenCover: y = 0
    case .sheet, .popover: y = Self.sheetTopMargin
    case .alert, .confirmationDialog: y = ((self.windowSize.y - self.cardSize.y) * 0.4).rounded()
    }
    self.cardOrigin = position + float2(self.kind == .fullScreenCover ? 0 : x, y)
    self.card.calcPosition(self.cardOrigin)
  }
}
