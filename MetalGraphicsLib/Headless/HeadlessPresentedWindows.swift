import CoreGraphics
import simd

/// `PresentedWindows` for a `HeadlessApp`: a presentation's window, opened on the app's screen
/// where AppKit would put it — a sheet hanging from its window's top, a floating one centred over
/// it, a popover by its source, a cover over its window or the whole screen — and closed when it
/// goes. Its tree runs on its window's thread, which here is the test's, and steps with it.
///
/// Its screen is the app's: points, top left origin, y down.
@MainActor final class HeadlessPresentedWindows : PresentedWindowHost {
  private unowned let app: HeadlessApp
  private var windows: [ObjectIdentifier: HeadlessWindow] = [:]

  init(app: HeadlessApp) {
    self.app = app
  }

  func open(_ request: PresentedWindowRequest) {
    guard let parent = self.app.windows.first(where: { $0.handle === request.parent && $0.isOpen }) else {
      PresentedWindows.send(.parentClosed, to: request.handle)
      return
    }
    let presentation = HeadlessPresentation(
      kind: request.kind, style: request.style, parent: parent, anchor: request.anchor
    )
    let size = self.size(for: request.idealSize, presentation)
    let window = HeadlessWindow(
      app: self.app, adopting: request.handle, sceneID: WindowPresentation.sceneID, title: request.title,
      size: size, origin: self.origin(for: size, presentation)
    )
    window.presentation = presentation
    let handle = request.handle
    window.onUserClose = { PresentedWindows.send(.userClosed, to: handle) }
    self.windows[ObjectIdentifier(handle)] = window
    self.app.addPresented(window)
  }

  func resize(_ handle: WindowHandle, to idealSize: float2) {
    guard let window = self.windows[ObjectIdentifier(handle)], let presentation = window.presentation else { return }
    let size = self.size(for: idealSize, presentation)
    window.setContentSize(size)
    window.origin = self.origin(for: size, presentation)
  }

  func move(_ handle: WindowHandle, anchor: ClipRect) {
    guard let window = self.windows[ObjectIdentifier(handle)], var presentation = window.presentation else { return }
    presentation.anchor = anchor
    window.presentation = presentation
    window.origin = self.origin(for: window.size, presentation)
  }

  func close(_ handle: WindowHandle) {
    guard let window = self.windows.removeValue(forKey: ObjectIdentifier(handle)) else { return }
    window.close(quitting: false)
  }

  func showPointerStyle(_ handle: WindowHandle, _ style: PointerStyle) {
    self.windows[ObjectIdentifier(handle)]?.setPointerStyle(style)
  }

  /// `window` was resized: a cover over it follows.
  func parentResized(_ parent: HeadlessWindow) {
    for window in self.windows.values {
      guard let presentation = window.presentation, presentation.parent === parent else { continue }
      if presentation.kind == .fullScreenCover, presentation.style.placement == .attached {
        window.setContentSize(parent.size)
        window.origin = parent.origin
      } else {
        window.origin = self.origin(for: window.size, presentation)
      }
    }
  }

  // MARK: - Geometry

  private var screen: CGRect {
    CGRect(x: 0, y: 0, width: CGFloat(self.app.screenSize.x), height: CGFloat(self.app.screenSize.y))
  }

  private func size(for ideal: float2, _ presentation: HeadlessPresentation) -> float2 {
    switch (presentation.kind, presentation.style.placement) {
    case (.fullScreenCover, .attached): return presentation.parent?.size ?? self.app.screenSize
    case (.fullScreenCover, _): return self.app.screenSize
    default:
      let size = PresentedWindows.clamp(ideal, presentation.kind, in: self.screen)
      return float2(Float(size.width), Float(size.height))
    }
  }

  private func origin(for size: float2, _ presentation: HeadlessPresentation) -> float2 {
    guard let parent = presentation.parent else { return .zero }
    let screen = self.app.screenSize
    switch (presentation.kind, presentation.style.placement) {
    case (.fullScreenCover, .attached):
      return parent.origin
    case (.fullScreenCover, _):
      return .zero
    case (.popover, _):
      let anchor = presentation.anchor ?? ClipRect(position: .zero, size: parent.size)
      let source = ClipRect(min: parent.origin + anchor.min, max: parent.origin + anchor.max)
      // Below the source, or above when there is more room there; y down.
      let below = source.max.y + 4
      let above = source.min.y - 4 - size.y
      let y = below + size.y <= screen.y || screen.y - source.max.y >= source.min.y ? below : above
      let x = (source.min.x + source.max.x - size.x) * 0.5
      return simd_clamp(float2(x, y).rounded(.down), .zero, simd_max(screen - size, .zero))
    case (_, .attached):
      // Hanging from the top of its window's content, as a sheet does.
      return float2(parent.origin.x + ((parent.size.x - size.x) * 0.5).rounded(.down), parent.origin.y)
    default:
      let center = parent.origin + parent.size * 0.5 - float2(0, parent.size.y * 0.1)
      return simd_clamp((center - size * 0.5).rounded(.down), .zero, simd_max(screen - size, .zero))
    }
  }
}

/// What a headless window shows, when it is a presentation's.
struct HeadlessPresentation {
  let kind: PresentationKind
  let style: PresentationWindowStyle
  /// The window it was presented from. Weak: it may close first, and its presentation's window
  /// closes after it.
  weak var parent: HeadlessWindow?
  /// Where a popover points from, in the parent's content.
  var anchor: ClipRect?

  /// Whether the window it was presented from takes no input while it shows.
  var isModal: Bool { self.kind != .popover }
}
