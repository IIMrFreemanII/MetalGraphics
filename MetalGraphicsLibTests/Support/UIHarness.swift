import AppKit
import Metal
@testable import MetalGraphicsLib
import simd

/// A retained-mode UI tree running headlessly: no window, no view, no display link.
///
/// It runs the app's frame (`TestViewRenderer.draw(in:)`) by hand: `step()` feeds whatever
/// input the helpers set into `UIContext.update`, and renders into an offscreen texture when
/// the context needs it. Time is a fake clock that only moves when a step moves it, so
/// animations land on exact values.
///
///     let h = UIHarness(size: float2(320, 240)) { Button("Save") { saved += 1 } }
///     h.click(at: float2(160, 120))
///     XCTAssertEqual(saved, 1)
@MainActor
final class UIHarness {
  let renderer: ViewRenderer
  let graphics: Graphics2D
  let root = Frame(float2())
  var context: UIContext { self.renderer.uiContext }
  var input: Input { self.renderer.input }

  /// Seconds on the fake clock; starts at 0.
  private(set) var now: Double = 0
  let size: float2
  let pixelsPerPoint: Float
  private let target: MTLTexture
  /// Frames stepped, and those of them that were drawn.
  private(set) var frames = 0
  private(set) var renders = 0

  init(size: float2 = float2(320, 240), pixelsPerPoint: Float = 2, _ tree: () -> UIElement) {
    self.size = size
    self.pixelsPerPoint = pixelsPerPoint

    let renderer = ViewRenderer()
    renderer.input = Input()
    renderer.windowSize = size
    renderer.input.windowSize = size
    self.renderer = renderer
    self.graphics = Graphics2D(renderer: renderer)
    renderer.graphics2D = self.graphics
    self.target = Graphics2D.makeOffscreenTarget(size: size, pixelsPerPoint: pixelsPerPoint)

    // Parked far away, as `MyMTKView.mouseExited` does, so nothing starts hovered.
    let outside = float2(repeating: -1_000_000)
    renderer.input.mousePosition = outside
    renderer.input.prevMousePosition = outside

    self.renderer.uiContext.clock = { [unowned self] in self.now }
    self.root.mounted = true
    self.root.setChild(tree(), self.renderer.uiContext)
    self.step()
  }

  // MARK: - Frames

  /// One frame: advance the clock by `dt`, update, and draw if anything changed.
  func step(_ dt: Double = 1.0 / 60) {
    self.now += dt
    self.frames += 1
    self.context.update(root: self.root, size: self.size, input: self.input, graphics: self.graphics)
    guard self.context.needsRender else {
      self.input.endFrame()
      return
    }
    self.draw()
  }

  func step(frames count: Int, _ dt: Double = 1.0 / 60) {
    for _ in 0 ..< count { self.step(dt) }
  }

  /// Steps `seconds` of fake time at 60 frames per second.
  func advance(_ seconds: Double) {
    self.step(frames: max(1, Int((seconds * 60).rounded(.up))))
  }

  /// Steps until nothing animates and nothing needs drawing. Returns the frames it took, or
  /// nil if it was still busy after `maxFrames`.
  @discardableResult
  func settle(maxFrames: Int = 600) -> Int? {
    for i in 0 ..< maxFrames {
      if self.isIdle { return i }
      self.step()
    }
    return self.isIdle ? maxFrames : nil
  }

  var isIdle: Bool { self.context.animator.isIdle && !self.context.needsRender }

  private func draw() {
    self.renders += 1
    // `Graphics2D.endFrame` ends the input frame too, as in the app.
    self.graphics.render(into: self.target, pixelsPerPoint: self.pixelsPerPoint) { _ in
      self.context.render(root: self.root, self.graphics)
    }
  }

  // MARK: - Mouse

  /// Moves the pointer to `point` (points, window top left origin, y down) and steps.
  func move(to point: float2) {
    self.setMouse(point)
    self.step()
  }

  /// A press and a release at `point`, a frame each, as a real click arrives. `count` is the
  /// click's number in a run of them: 2 for the second click of a double click.
  func click(at point: float2, count: Int = 1) {
    self.setMouse(point)
    self.input.leftMousePressed = true
    self.input.leftMouseDown = true
    self.input.clickCount = count
    self.step()
    self.input.leftMousePressed = false
    self.input.leftMouseUp = true
    self.step()
  }

  /// A press and a release that both land before the next frame, as a fast click can.
  func clickWithinOneFrame(at point: float2) {
    self.setMouse(point)
    self.input.leftMouseDown = true
    self.input.leftMouseUp = true
    self.input.clickCount = 1
    self.step()
  }

  /// Two clicks at `point`, as AppKit reports a double click: the second counts 2.
  func doubleClick(at point: float2) {
    self.click(at: point, count: 1)
    self.click(at: point, count: 2)
  }

  /// The pointer leaving the window, as `MyMTKView.mouseExited` reports it.
  func mouseExit() {
    let input = self.input
    let outside = float2(repeating: -1_000_000)
    input.mouseDelta = outside - input.prevMousePosition
    input.mousePosition = outside
    input.mousePositionFromCenter = outside
    input.prevMousePosition = outside
    input.isPointerInView = false
    self.step()
  }

  /// The pointer's shape, as the view would show it.
  var pointerStyle: PointerStyle { self.context.pointerStyle }

  func click(on hittable: any Hittable) {
    self.click(at: hittable.hitPosition + hittable.hitSize * 0.5)
  }

  func click(on focusable: FocusableElement) {
    self.click(at: focusable.position + focusable.size * 0.5)
  }

  /// A wheel or trackpad scroll of `delta` points over `point`; positive y moves content down.
  func scroll(by delta: float2, at point: float2) {
    self.setMouse(point)
    self.step()
    self.input.scrollDelta = delta
    self.input.mouseScroll = delta
    self.step()
  }

  /// The left button going down at `point`, and staying down until `mouseUp`.
  func mouseDown(at point: float2) {
    self.setMouse(point)
    self.input.leftMousePressed = true
    self.input.leftMouseDown = true
    self.input.clickCount = 1
    self.step()
  }

  /// Moves the pointer to `point` with the button still down.
  func mouseDrag(to point: float2) {
    self.setMouse(point)
    self.step()
  }

  /// The left button coming up at `point`.
  func mouseUp(at point: float2) {
    self.setMouse(point)
    self.input.leftMousePressed = false
    self.input.leftMouseUp = true
    self.step()
  }

  /// A press at `from`, `steps` moves in a straight line to `to`, a frame each, and a release
  /// there, as a real drag arrives.
  func drag(from: float2, to: float2, steps: Int = 4) {
    self.mouseDown(at: from)
    for step in 1 ... max(steps, 1) {
      self.mouseDrag(to: from + (to - from) * Float(step) / Float(max(steps, 1)))
    }
    self.mouseUp(at: to)
  }

  private func setMouse(_ point: float2) {
    let input = self.input
    input.mouseDelta = point - input.prevMousePosition
    if input.mouseDelta == .zero {
      // `UIContext` hit-tests only when something about the mouse changed.
      input.mouseDelta = float2(0, 0.001)
    }
    input.mousePosition = point
    input.prevMousePosition = point
    input.mousePositionFromCenter = (point - self.size * 0.5) * float2(1, -1)
    input.isPointerInView = ClipRect(position: .zero, size: self.size).contains(point)
  }

  // MARK: - Keys

  /// A key's down and up, both in one frame.
  func press(_ key: KeyEquivalent, characters: String? = nil, modifiers: NSEvent.ModifierFlags = []) {
    let characters = characters ?? String(key.character)
    self.input.keyPresses.append(KeyPress(key: key, characters: characters, modifiers: modifiers, phase: .down))
    self.input.keyPresses.append(KeyPress(key: key, characters: characters, modifiers: modifiers, phase: .up))
    self.step()
  }

  /// Types `text` a character at a time, a frame each.
  func type(_ text: String) {
    for character in text {
      self.press(KeyEquivalent(Character(character.lowercased())), characters: String(character))
    }
  }

  // MARK: - Tree

  /// Every element of type `T` in the tree, in pre-order.
  func all<T: UIElement>(_ type: T.Type) -> [T] {
    var found: [T] = []
    func visit(_ element: UIElement) {
      if let match = element as? T { found.append(match) }
      element.forEachChild(visit)
    }
    visit(self.root)
    return found
  }

  func first<T: UIElement>(_ type: T.Type) -> T? {
    self.all(type).first
  }

  // MARK: - Pixels

  /// The last frame drawn. Steps first if something is waiting to be drawn.
  func snapshot() -> CGImage {
    if self.context.needsRender { self.step(0) }
    let pixels = self.graphics.readPixels(self.target)
    return makeImage(width: pixels.width, height: pixels.height, bgra: pixels.bgra)
  }

  /// The colour at `point` (points) in the last frame drawn, RGBA 0...255.
  func pixel(at point: float2) -> SIMD4<UInt8> {
    if self.context.needsRender { self.step(0) }
    let pixels = self.graphics.readPixels(self.target)
    let x = min(pixels.width - 1, Int(point.x * self.pixelsPerPoint))
    let y = min(pixels.height - 1, Int(point.y * self.pixelsPerPoint))
    let i = (y * pixels.width + x) * 4
    return SIMD4(pixels.bgra[i + 2], pixels.bgra[i + 1], pixels.bgra[i], pixels.bgra[i + 3])
  }
}

/// A BGRA byte buffer as an opaque image; `compute2D` leaves alpha to the layer.
func makeImage(width: Int, height: Int, bgra: [UInt8]) -> CGImage {
  let data = CFDataCreate(nil, bgra, bgra.count)!
  return CGImage(
    width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: width * 4,
    space: CGColorSpace(name: CGColorSpace.sRGB)!,
    bitmapInfo: CGBitmapInfo(rawValue: CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.noneSkipFirst.rawValue),
    provider: CGDataProvider(data: data)!, decode: nil, shouldInterpolate: false, intent: .defaultIntent
  )!
}
