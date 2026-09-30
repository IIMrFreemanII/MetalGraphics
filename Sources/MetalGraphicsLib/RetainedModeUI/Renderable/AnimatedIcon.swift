import CoreText
import simd

/// One of the design system's animated glyphs (`AnimatedGlyph`), drawn and played as the Claude
/// Design template "Animated icons" plays its `<mg-anim-icon>`: in its own box, the size of the
/// static icon at scale 1, in the foreground colour.
///
///     ListRow("Sources", content: {
///       AnimatedIcon(.chevronRight, active: isOpen).foregroundColor(.secondaryLabel)
///       AnimatedIcon(.folder, active: isOpen).foregroundColor(.hue(.folder))
///     })
///
/// Its host is the nearest `HittableView` around it: the row, button or link it sits in. The
/// host's hover plays a one-shot as the pointer enters and holds a pose while it stays; its press
/// squashes the glyph; `active` holds an end state (nil leaves it unset: the checkmark drawn,
/// sort unsorted); `loop` repeats a motion; `mount` plays an entrance as it appears. Not in
/// SwiftUI; mirrors the web design system's `AnimatedIcon`.
///
/// The glyph's CSS is evaluated as a browser would: when its state changes the matching rules
/// give each part new values, a changed value moves by its transition, and an animation plays
/// over it. Its shapes are baked once per window and shared by every icon in it; a frame draws
/// one vector item per shape, moved by its part's transform. It renders only while something
/// moves: a finished motion stops drawing, and the spinner and loops, which go on for as long as
/// they are shown, step on timed wakes at 30 Hz instead of keeping the display link running.
public final class AnimatedIcon: UIRenderableElement, HostFollower, WakeTarget {
  /// What its host does to it.
  public enum Trigger: String, CaseIterable, Sendable {
    /// The host's hover and press (the default).
    case hover
    /// The same, and a click on the host toggles `active`.
    case click
    /// Kept for `active`-driven icons: the same as `hover`, whose hover and press still play.
    case active
    /// The same as `hover`, looping.
    case loop
    /// Nothing from the host: only `active`, `loop` and `mount`.
    case none
  }

  public internal(set) var glyph: AnimatedGlyph
  public internal(set) var trigger: Trigger
  /// Its state: `true` or `false`, or nil for none (the template's absent `active`).
  public internal(set) var active: Bool?
  public internal(set) var isLooping: Bool
  /// Whether it plays its entrance when it mounts.
  public internal(set) var playsMount: Bool
  /// The glyph's colour: a role or a hue. The inherited text colour, else `.label`, when nil.
  public internal(set) var color: float4? = nil
  /// Its size is its glyph's box times this; 1 draws it at the static icon's size.
  public internal(set) var scale: Float = 1
  /// When set, the scale that fits the box's longer side to this many points.
  public internal(set) var iconSize: Float? = nil
  /// How fast it plays: 0.5 is the template's `--mgi-t: 2`.
  public internal(set) var speed: Float = 1
  /// Colours for the parts the page may colour (a split's fill, the bell's badge…).
  public internal(set) var tints = GlyphTints()

  public var position = float2()
  public var size = float2()

  /// Whether its box is `active`-true, for a caller that toggles it.
  public var isOn: Bool { self.active == true }

  // MARK: State: the template's `data-*` flags

  private var flags = [Bool](repeating: false, count: GlyphFlag.allCases.count)
  /// `data-to`'s value while its pulse lasts.
  private var toValue: String? = nil
  /// When each pulsed flag (`hover`, `to`, `mount`) comes off, in clock seconds.
  private var pulseEnds = [Double?](repeating: nil, count: GlyphFlag.allCases.count)
  /// The eye's pupil offset, in box units.
  private var pointerOffset = SIMD2<Float>(0, 0)

  // MARK: Per part

  private var style: AnimatedGlyphStyle
  private var computed: [PartStyle] = []
  /// Running transitions, `part * 4 + property`.
  private var transitions: [Transition?] = []
  /// Each part's animation and when it started.
  private var animations: [(animation: GlyphAnimation, start: Double)?] = []
  /// Where each part is this frame; reused.
  private var poses: [GlyphPose] = []

  /// The clock's time as of this frame.
  private var now: Double = 0
  private var clockBase: Double = 0

  // The play/pause morph: a spring the template drives by hand.
  private var morph = MorphSpring()
  private var morphPaths: [Int: Path] = [:]

  private weak var host: HittableView? = nil
  private weak var context: UIContext? = nil
  private var hostPressed = false

  public init(_ glyph: AnimatedGlyph, trigger: Trigger = .hover, active: Bool? = nil, loop: Bool = false, mount: Bool = false) {
    self.glyph = glyph
    self.trigger = trigger
    self.active = active
    self.isLooping = loop || trigger == .loop
    self.playsMount = mount
    self.style = glyph.style
    super.init()
    self.reset()
  }

  /// The animated glyph of a static `ThemeIcon`: what a component that took one draws.
  public convenience init(icon: ThemeIcon, trigger: Trigger = .hover, active: Bool? = nil) {
    self.init(AnimatedGlyph(icon), trigger: trigger, active: active)
  }

  // MARK: - Element

  public override func mount(_ context: UIContext) {
    context.registerRenderableView(self)
    self.context = context
    self.now = context.clock()
    self.attachHost()
    if self.playsMount { self.pulse(.mount, context) }
    self.runClock(context)
  }

  public override func unmount(_ context: UIContext) {
    self.detachHost()
    context.cancelWake(for: self)
    self.nextLoopFrame = nil
    context.animator.cancel(self, .progress)
    for flag in [GlyphFlag.hover, .hovering, .press, .to, .mount] { self.flags[flag.rawValue] = false }
    self.pulseEnds = self.pulseEnds.map { _ in nil }
    self.toValue = nil
    self.restyle(animate: false)
    for path in self.morphPaths.values { path.releaseBake() }
    self.morphPaths.removeAll()
    context.unregisterRenderableView(self)
    self.context = nil
  }

  private var naturalSize: float2 {
    let box = self.glyph.box
    let scale = self.iconSize.map { $0 / max(box.x, box.y) } ?? self.scale
    return box * scale
  }

  public override func getSize() -> float2 { self.size }

  public override func sizeThatFits(_ proposal: ProposedSize) -> float2 { self.naturalSize }

  public override func calcSize(_ proposal: ProposedSize) -> float2 {
    self.size = self.naturalSize
    return self.size
  }

  public override func calcPosition(_ position: float2) {
    self.position = position
  }

  // MARK: - Host

  /// The view whose hover plays it when that is not the nearest one around it: a dock tab's
  /// icon follows the tab's press area, a sibling. Set before it mounts.
  weak var explicitHost: HittableView? = nil

  var wantsPointer: Bool { self.style.pointerReach != nil }

  private func attachHost() {
    guard self.trigger != .none, let host = self.explicitHost ?? self.nearestAncestor(HittableView.self) else { return }
    self.host = host
    host.addFollower(self)
    self.hostPressed = host.isPressed || host.isPointerDown
    if host.isHovered, let context { self.hostChanged(hovered: true, pressed: host.isPressed, context) }
  }

  private func detachHost() {
    self.host?.removeFollower(self)
    self.host = nil
  }

  func hostChanged(hovered: Bool, pressed: Bool) {
    guard self.mounted, let context else { return }
    self.hostChanged(hovered: hovered, pressed: pressed, context)
  }

  private func hostChanged(hovered: Bool, pressed: Bool, _ context: UIContext) {
    self.now = context.clock()
    if self.trigger == .click, self.hostPressed, !pressed, hovered {
      // a press let go over the host is a click
      self.setActive(!(self.active ?? false), context)
    }
    self.hostPressed = pressed

    let wasHovering = self.flags[GlyphFlag.hovering.rawValue]
    if hovered != wasHovering {
      self.flags[GlyphFlag.hovering.rawValue] = hovered
      if hovered {
        self.pulse(.hover, context)
      } else {
        // pointerleave: the hover pose and the press end, the pupil comes home
        self.flags[GlyphFlag.press.rawValue] = false
        self.pointerOffset = .zero
      }
    }
    // pointerdown and pointerup
    if hovered || !pressed { self.flags[GlyphFlag.press.rawValue] = pressed && hovered }
    if self.restyle(animate: true) { context.invalidate() }
    self.runClock(context)
  }

  func hostPointerMoved(_ point: float2) {
    guard let reach = self.style.pointerReach, self.mounted, let context, self.size.x > 0 else { return }
    let center = self.position + self.size * 0.5
    func clamp(_ v: Float) -> Float { min(max(v, -1), 1) }
    let offset = SIMD2(
      (clamp((point.x - center.x) / (self.size.x * 1.2)) * reach.x * 100).rounded() / 100,
      (clamp((point.y - center.y) / (self.size.y * 1.2)) * reach.y * 100).rounded() / 100
    )
    guard offset != self.pointerOffset else { return }
    self.pointerOffset = offset
    self.now = context.clock()
    if self.restyle(animate: true) { context.invalidate() }
    self.runClock(context)
  }

  // MARK: - The cascade

  /// A part's values and timing under the current flags.
  struct PartStyle {
    var transform = GlyphTransform.identity.packed
    var opacity = SIMD8<Float>(repeating: 0)
    var dashOffset = SIMD8<Float>(repeating: 0)
    var dashArray = SIMD8<Float>(repeating: 0)
    var hasDashArray = false
    var origin: (GlyphLength, GlyphLength) = (.px(0), .px(0))
    var fillBox = false
    var stroke: GlyphColor? = nil
    var transitionProperties: [GlyphProperty?] = []
    var transitionDurations: [Float] = [0]
    var transitionEasings: [GlyphEasing] = [.ease]
    var transitionDelays: [Float] = [0]
    var animation: GlyphAnimation? = nil

    func value(_ property: GlyphProperty) -> SIMD8<Float> {
      switch property {
      case .transform: self.transform
      case .opacity: self.opacity
      case .dashOffset: self.dashOffset
      case .dashArray: self.dashArray
      }
    }

    /// Duration, delay (seconds at speed 1) and easing of the transition for `property`.
    func transition(for property: GlyphProperty) -> (duration: Float, delay: Float, easing: GlyphEasing)? {
      guard let i = self.transitionProperties.lastIndex(where: { $0 == property }) else { return nil }
      return (
        self.transitionDurations[i % self.transitionDurations.count],
        self.transitionDelays[i % self.transitionDelays.count],
        self.transitionEasings[i % self.transitionEasings.count]
      )
    }
  }

  private struct Transition {
    var from: SIMD8<Float>
    var to: SIMD8<Float>
    var start: Double
    var delay: Double
    var duration: Double
    var easing: GlyphEasing

    var end: Double { self.start + self.delay + self.duration }

    func value(at now: Double) -> SIMD8<Float> {
      let u = self.duration > 0 ? Float((now - self.start - self.delay) / self.duration) : 1
      if u <= 0 { return self.from }
      let e = self.easing(min(u, 1))
      return self.from + (self.to - self.from) * e
    }

    /// Its output progress now, for shortening a reversal.
    func progress(at now: Double) -> Float {
      let u = self.duration > 0 ? Float((now - self.start - self.delay) / self.duration) : 1
      return min(max(self.easing(min(max(u, 0), 1)), 0), 1)
    }
  }

  private func holds(_ condition: GlyphCondition) -> Bool {
    switch condition {
    case .has(let f): self.flags[f.rawValue]
    case .lacks(let f): !self.flags[f.rawValue]
    case .equals(.active, let v): self.activeValue == v
    case .equals(.to, let v): self.flags[GlyphFlag.to.rawValue] && self.toValue == v
    case .equals: false
    case .differs(.active, let v): self.activeValue != v
    case .differs(.to, let v): !(self.flags[GlyphFlag.to.rawValue] && self.toValue == v)
    case .differs: true
    }
  }

  private var activeValue: String? {
    self.active.map { $0 ? "true" : "false" }
  }

  private func resolve(_ index: Int) -> PartStyle {
    let node = self.style.nodes[index]
    var s = PartStyle()
    s.opacity[0] = node.opacity
    for rule in self.style.rules where rule.matches(node) && rule.conditions.allSatisfy(self.holds) {
      for decl in rule.declarations {
        switch decl {
        case .transform(let t): s.transform = t.packed
        case .pointerTransform: s.transform = GlyphTransform.translate(self.pointerOffset.x, self.pointerOffset.y).packed
        case .origin(let x, let y): s.origin = (x, y)
        case .fillBox(let f): s.fillBox = f
        case .opacity(let o): s.opacity[0] = o
        case .dashOffset(let o): s.dashOffset[0] = o
        case .dashArray(let a): s.dashArray[0] = a.x; s.dashArray[1] = a.y; s.hasDashArray = true
        case .stroke(let c): s.stroke = c
        case .transition(let p, let d, let e, let delay):
          s.transitionProperties = p; s.transitionDurations = d; s.transitionEasings = e; s.transitionDelays = delay
        case .transitionDuration(let d): if !d.isEmpty { s.transitionDurations = d }
        case .transitionDelay(let d): if !d.isEmpty { s.transitionDelays = d }
        case .animation(let a): s.animation = a
        }
      }
    }
    return s
  }

  /// Gives every part its values under the current flags. With `animate`, a changed value moves
  /// by its transition and a newly named animation starts; without, everything snaps.
  /// `animationsOnly` updates only which animations run: the first half of a pulse. Returns
  /// whether anything it draws changed.
  @discardableResult
  private func restyle(animate: Bool, animationsOnly: Bool = false) -> Bool {
    let now = self.now
    let rate = Double(max(self.speed, 0.05))
    var changed = false
    for i in self.style.nodes.indices {
      let new = self.resolve(i)
      let old = self.computed[i]

      // Animations restart when the name they run changes.
      let running = self.animations[i]
      if let a = new.animation {
        if running?.animation.keyframes !== a.keyframes || !animate {
          self.animations[i] = (a, now)
          changed = true
        } else {
          self.animations[i]!.animation = a
        }
      } else if running != nil {
        changed = changed || self.inEffect(i)
        self.animations[i] = nil
      }
      if animationsOnly {
        self.computed[i].animation = new.animation
        continue
      }

      if new.hasDashArray != old.hasDashArray || new.stroke != old.stroke { changed = true }
      for property in GlyphProperty.allCases {
        let slot = i * 4 + property.rawValue
        let to = new.value(property), from = old.value(property)
        guard to != from else { continue }
        changed = true
        guard animate, let spec = new.transition(for: property), spec.duration + spec.delay > 0 else {
          self.transitions[slot] = nil
          continue
        }
        // from where it is now, not counting animations
        var current = from
        var duration = Double(spec.duration), delay = Double(spec.delay)
        if let t = self.transitions[slot], now < t.end {
          current = t.value(at: now)
          if to == t.from {
            // reversing: as far back as it came
            let factor = Double(t.progress(at: now))
            duration *= factor
            if delay < 0 { delay *= factor }
          }
        }
        self.transitions[slot] = Transition(
          from: current, to: to, start: now, delay: delay / rate, duration: duration / rate, easing: spec.easing
        )
      }
      self.computed[i] = new
    }

    if self.style.hasMorph {
      let target: Float = self.active == true ? 1 : 0
      if target != self.morph.target { changed = true }
      if animate { self.morph.retarget(target, at: now, speed: self.speed) } else { self.morph.snap(target) }
    }
    return changed
  }

  /// Whether a part's animation still shows: running, or holding its last frame.
  private func inEffect(_ i: Int) -> Bool {
    guard let (a, start) = self.animations[i] else { return false }
    if a.fillsForwards || a.iterations.isInfinite { return true }
    let rate = Double(max(self.speed, 0.05))
    return self.now < start + Double(a.delay + a.duration * a.iterations) / rate
  }

  /// Sets a flag and takes it off after the template's pulse (hover 1.6 s, the others 1.4 s),
  /// restarting whatever animation it names.
  private func pulse(_ flag: GlyphFlag, value: String? = nil, _ context: UIContext) {
    self.now = context.clock()
    // off, then on: as the template removes the attribute, reflows and sets it again
    self.flags[flag.rawValue] = false
    self.restyle(animate: true, animationsOnly: true)
    self.flags[flag.rawValue] = true
    if flag == .to { self.toValue = value }
    if self.restyle(animate: true) { context.invalidate() }
    let seconds = (flag == .hover ? 1.6 : 1.4) / Double(max(self.speed, 0.05))
    self.pulseEnds[flag.rawValue] = self.now + seconds
    self.scheduleWake(context)
    self.runClock(context)
  }

  /// Asks for the next pulse's end or loop frame, whichever comes first; none when neither is due.
  private func scheduleWake(_ context: UIContext) {
    guard self.mounted else { return }
    var next = self.pulseEnds.compactMap { $0 }.min()
    if self.hasLoop {
      let frame = self.nextLoopFrame ?? self.now + Self.loopFrameInterval
      self.nextLoopFrame = frame
      next = min(next ?? frame, frame)
    } else {
      self.nextLoopFrame = nil
    }
    if let next {
      context.requestWake(at: next, for: self)
    } else {
      context.cancelWake(for: self)
    }
  }

  public func wake(_ context: UIContext, now: Double) {
    self.now = now
    if let frame = self.nextLoopFrame, now >= frame {
      // a loop's next frame: drawn at the new time
      self.nextLoopFrame = max(frame + Self.loopFrameInterval, now)
      context.invalidate()
    }
    var changed = false
    for flag in GlyphFlag.allCases {
      if let end = self.pulseEnds[flag.rawValue], now >= end {
        self.pulseEnds[flag.rawValue] = nil
        self.flags[flag.rawValue] = false
        if flag == .to { self.toValue = nil }
        changed = true
      }
    }
    if changed, self.restyle(animate: true) {
      context.invalidate()
      self.runClock(context)
    }
    self.scheduleWake(context)
  }

  // MARK: - The clock

  /// Seconds between a loop's frames. A loop runs for as long as it is shown (the spinner
  /// always), so it steps on timed wakes rather than keep its window's display link running.
  static let loopFrameInterval: Double = 1.0 / 30
  private var nextLoopFrame: Double? = nil

  /// Whether an animation that never ends is running: a loop, the spinner.
  private var hasLoop: Bool {
    self.animations.contains { $0?.animation.iterations.isInfinite == true }
  }

  /// When every finite motion running now has finished.
  private var settlesAt: Double {
    var end = self.now
    for t in self.transitions { if let t { end = max(end, t.end) } }
    let rate = Double(max(self.speed, 0.05))
    for a in self.animations {
      guard let (animation, start) = a, !animation.iterations.isInfinite else { continue }
      end = max(end, start + Double(animation.delay + animation.duration * animation.iterations) / rate)
    }
    if self.style.hasMorph { end = max(end, self.morph.settlesAt) }
    return end
  }

  /// Keeps frames coming, and `now` current, until every finite motion has finished; loops go on
  /// by wakes.
  private func runClock(_ context: UIContext) {
    guard self.mounted else { return }
    self.scheduleWake(context)
    let settles = self.settlesAt
    guard settles > self.now else {
      context.animator.cancel(self, .progress)
      return
    }
    self.clockBase = self.now
    let length = Float(settles - self.now)
    context.animator.run(
      self, .progress, from: Float(0).packed, to: length.packed, .linear(length), context,
      restart: true, group: nil,
      apply: { element, value, context in
        let icon = unsafeDowncast(element, to: AnimatedIcon.self)
        icon.now = icon.clockBase + Double(value.x)
        context.invalidate()
      },
      completion: nil
    )
    context.invalidate()
  }

  // MARK: - Evaluating a part

  /// Where a part is now: transitions over animations over its style, as CSS layers them.
  private func presented(_ i: Int, _ property: GlyphProperty) -> SIMD8<Float> {
    let base = self.computed[i].value(property)
    if let t = self.transitions[i * 4 + property.rawValue], self.now < t.end {
      return t.value(at: self.now)
    }
    if let (animation, start) = self.animations[i],
       let v = Self.keyframeValue(animation, property, elapsed: self.now - start, speed: self.speed, underlying: base) {
      return v
    }
    return base
  }

  private static func keyframeValue(
    _ a: GlyphAnimation, _ property: GlyphProperty, elapsed: Double, speed: Float, underlying: SIMD8<Float>
  ) -> SIMD8<Float>? {
    let stops = a.keyframes.stops[property.rawValue]
    guard !stops.isEmpty else { return nil }
    let rate = Double(max(speed, 0.05))
    let duration = Double(a.duration) / rate
    let t = elapsed - Double(a.delay) / rate
    var progress: Float
    if t < 0 {
      guard a.fillsBackwards else { return nil }
      progress = 0
    } else if duration <= 0 || t >= duration * Double(a.iterations) {
      guard a.fillsForwards else { return nil }
      progress = 1
    } else {
      progress = Float((t / duration).truncatingRemainder(dividingBy: 1))
    }
    // the stops, with the underlying value where the first and last are missing
    var prevOffset: Float = 0, prevValue = underlying
    if stops[0].offset <= 0 { prevValue = stops[0].value }
    for stop in stops {
      if stop.offset < progress || (stop.offset == 0 && progress == 0) {
        prevOffset = stop.offset; prevValue = stop.value
        continue
      }
      let span = stop.offset - prevOffset
      let u = span > 0 ? (progress - prevOffset) / span : 1
      return prevValue + (stop.value - prevValue) * a.easing(u)
    }
    // past the last stop: to the underlying value at 100 %
    let span = 1 - prevOffset
    let u = span > 0 ? (progress - prevOffset) / span : 1
    return prevValue + (underlying - prevValue) * a.easing(u)
  }

  // MARK: - Drawing

  /// A shape of a glyph, filled or stroked (`variant` 1 for a morph's active outline): the key of
  /// the window's shared `VectorShape`s.
  struct ShapeKey: Hashable {
    var glyph: AnimatedGlyph
    var node: UInt16
    var fill: Bool
    var variant: UInt8
  }

  public override func render(_ renderer: Graphics2D, _ effect: EffectState) {
    guard effect.opacity > 0, self.size.x > 0 else { return }
    let topLeft = effect.apply(to: self.position) - renderer.size * 0.5
    let extent = self.size * effect.scale
    let base = self.color ?? renderer.textForeground ?? .label

    for i in self.style.nodes.indices {
      let s = self.computed[i]
      self.poses[i] = GlyphPose(
        transform: GlyphTransform(packed: self.presented(i, .transform)),
        opacity: self.presented(i, .opacity)[0],
        dashOffset: self.presented(i, .dashOffset)[0],
        dashArray: s.hasDashArray ? SIMD2(self.presented(i, .dashArray)[0], self.presented(i, .dashArray)[1]) : nil,
        stroke: s.stroke, origin: s.origin, fillBox: s.fillBox
      )
    }
    let p = self.style.hasMorph ? self.morph.value(at: self.now) : 0
    Self.draw(
      self.style, self.poses, renderer, topLeft: topLeft, extent: extent, color: base, tints: self.tints,
      opacity: effect.opacity, morph: p, owner: self
    )
  }

  /// The icon's own path for a morphing part partway, re-baked as it moves.
  private func morphPath(_ node: Int, _ from: String, _ to: String, _ progress: Float) -> Path {
    let path = self.morphPaths[node] ?? {
      let made = Path(morphing: from, to: to)
      self.morphPaths[node] = made
      return made
    }()
    if path.morphProgress != progress {
      path.morphProgress = progress
      path.outlineChanged = true
    }
    return path
  }

  /// Draws a glyph with no motion, at rest or in its end state, where no element can hold it: a
  /// code editor's fold marks, drawn line by line. `topLeft` is window centered, in points;
  /// `size` fits its box's longer side. Its pose is worked out once per window.
  static func draw(
    _ glyph: AnimatedGlyph, active: Bool?, in renderer: Graphics2D, topLeft: float2, size: Float,
    color: float4, opacity: Float = 1
  ) {
    let style = glyph.style
    let key = PoseKey(glyph: glyph, active: active)
    let poses = renderer.glyphPoses[key] ?? {
      let icon = AnimatedIcon(glyph, trigger: .none, active: active)
      var poses: [GlyphPose] = []
      for i in style.nodes.indices {
        let s = icon.computed[i]
        poses.append(GlyphPose(
          transform: GlyphTransform(packed: s.transform), opacity: s.opacity[0], dashOffset: s.dashOffset[0],
          dashArray: s.hasDashArray ? SIMD2(s.dashArray[0], s.dashArray[1]) : nil,
          stroke: s.stroke, origin: s.origin, fillBox: s.fillBox
        ))
      }
      renderer.glyphPoses[key] = poses
      return poses
    }()
    let box = glyph.box
    Self.draw(
      style, poses, renderer, topLeft: topLeft, extent: box * (size / max(box.x, box.y)), color: color,
      tints: GlyphTints(), opacity: opacity, morph: active == true ? 1 : 0, owner: nil
    )
  }

  struct PoseKey: Hashable {
    var glyph: AnimatedGlyph
    var active: Bool?
  }

  private static func draw(
    _ style: AnimatedGlyphStyle, _ poses: [GlyphPose], _ renderer: Graphics2D,
    topLeft: float2, extent: float2, color: float4, tints: GlyphTints, opacity effectOpacity: Float,
    morph: Float, owner: AnimatedIcon?
  ) {
    let unitScale = extent.x / style.box.x
    // Parts move a little past the box (a nudge, an overshoot): room for them, cut beyond.
    let clipMin = topLeft - extent * 0.5
    let clipMax = topLeft + extent * 1.5
    let nodes = style.nodes
    // world maps and opacities, parents first, on the stack for the few parts a glyph has
    withUnsafeTemporaryAllocation(of: (simd_float2x2, SIMD2<Float>, Float).self, capacity: nodes.count) { world in
      for i in nodes.indices {
        let node = nodes[i], pose = poses[i]
        var linear = matrix_identity_float2x2, translation = SIMD2<Float>(0, 0)
        if let attr = node.attrTransform {
          linear = attr.linear; translation = attr.translation
        } else if !pose.transform.isIdentity {
          let origin = Self.origin(pose, node, box: style.box)
          if let m = Self.affine(pose.transform, origin: origin) { linear = m.linear; translation = m.translation }
        }
        var alpha = pose.opacity
        if node.parent >= 0 {
          let (pl, pt, po) = world[node.parent]
          translation = pl * translation + pt
          linear = pl * linear
          alpha *= po
        }
        world[i] = (linear, translation, alpha)
        guard !node.isGroup, alpha > 0, abs(linear.determinant) > 1e-6 else { continue }
        let extra = (linear: linear, translation: translation)

        let fill = Self.resolve(node.fill, color, tints)
        if let fill {
          let shape = Self.shape(renderer, style, i, fill: true, morph: morph, owner: owner)
          shape.color = fill
          shape.opacity = alpha
          shape.extraTransform = extra
          shape.draw(renderer, origin: topLeft, unitScale: unitScale, clipMin: clipMin, clipMax: clipMax, opacity: effectOpacity)
        }
        guard let stroke = Self.resolve(pose.stroke ?? node.stroke, color, tints), node.strokeWidth > 0
        else { continue }
        let shape = Self.shape(renderer, style, i, fill: false, morph: morph, owner: owner)
        shape.color = stroke
        shape.opacity = alpha
        shape.lineWidth = node.strokeWidth
        shape.extraTransform = extra
        // a dash pattern drawn as up to two trimmed pieces
        guard let dash = pose.dashArray, dash.x + dash.y > 0 else {
          shape.trim = float2(0, 1)
          shape.draw(renderer, origin: topLeft, unitScale: unitScale, clipMin: clipMin, clipMax: clipMax, opacity: effectOpacity)
          continue
        }
        let length = node.pathLength ?? 1
        let period = dash.x + dash.y
        var k = ((pose.dashOffset - dash.x) / period).rounded(.down)
        var drawn = 0
        while drawn < 3 {
          let a = k * period - pose.dashOffset
          if a >= length { break }
          let lo = max(a, 0), hi = min(a + dash.x, length)
          if hi > lo {
            shape.trim = float2(lo / length, hi / length)
            shape.draw(renderer, origin: topLeft, unitScale: unitScale, clipMin: clipMin, clipMax: clipMax, opacity: effectOpacity)
            drawn += 1
          }
          k += 1
        }
      }
    }
  }

  /// The part's transform origin, in its box units.
  private static func origin(_ pose: GlyphPose, _ node: GlyphNode, box: SIMD2<Float>) -> SIMD2<Float> {
    let (ref0, refSize) = pose.fillBox ? (node.bounds.min, node.bounds.max - node.bounds.min) : (SIMD2<Float>(0, 0), box)
    func resolve(_ l: GlyphLength, _ axis: Int) -> Float {
      switch l {
      case .px(let v): v
      case .percent(let p): refSize[axis] * p
      }
    }
    return ref0 + SIMD2(resolve(pose.origin.0, 0), resolve(pose.origin.1, 1))
  }

  private static func resolve(_ c: GlyphColor, _ base: float4, _ tints: GlyphTints) -> float4? {
    switch c {
    case .none: nil
    case .current: base
    case .hue(let h): .hue(h)
    case .role(let r): .role(r)
    case .literal(let v): v
    case .tint(let t, let fallback): tints[t] ?? Self.resolve(fallback, base, tints)
    }
  }

  private static func shape(
    _ renderer: Graphics2D, _ style: AnimatedGlyphStyle, _ i: Int, fill: Bool,
    morph: Float, owner: AnimatedIcon?
  ) -> VectorShape {
    let node = style.nodes[i]
    if let to = node.morph, case .path(let from) = node.shape {
      // partway, overshoot included: the icon's own path; at either end, the shared one
      if morph != 0, morph != 1, let owner {
        let path = owner.morphPath(i, from, to, morph)
        return fill ? path.fill(.label) : path.stroke(.label, lineWidth: 1)
      }
      let variant: UInt8 = morph >= 1 ? 1 : 0
      return Self.cached(renderer, ShapeKey(glyph: style.glyph, node: UInt16(i), fill: fill, variant: variant)) {
        Path(d: variant == 1 ? to : from)
      }
    }
    return Self.cached(renderer, ShapeKey(glyph: style.glyph, node: UInt16(i), fill: fill, variant: 0)) {
      switch node.shape {
      case .path(let d): Path(d: d)
      case .circle(let c, let r): Circle(center: c, radius: r)
      case .rect(let o, let s, let r): RoundedRectangle(origin: o, size: s, cornerRadius: r)
      case .text(let text): Self.outline(text)
      case .group: Path(d: "")
      }
    }
  }

  private static func cached(_ renderer: Graphics2D, _ key: ShapeKey, _ make: () -> VectorShape) -> VectorShape {
    if let made = renderer.glyphShapes[key] { return made }
    let made = make()
    _ = key.fill ? made.fill(.label) : made.stroke(.label, lineWidth: 1)
    renderer.glyphShapes[key] = made
    return made
  }

  /// A badge's text as its outline, in the bold system face the template's `-apple-system`
  /// draws (or Georgia): centred on its anchor, on its central baseline.
  static func outline(_ text: GlyphText) -> Path {
    // made large and scaled down, so CoreText's hinting has no say
    let big: CGFloat = 100, k = CGFloat(text.size) / big
    let font: CTFont = text.serif
      ? CTFontCreateWithName("Georgia-Bold" as CFString, big, nil)
      : CTFontCreateUIFontForLanguage(.emphasizedSystem, big, nil) ?? CTFontCreateWithName("Helvetica-Bold" as CFString, big, nil)
    let attributed = CFAttributedStringCreate(nil, text.string as CFString, [kCTFontAttributeName: font] as CFDictionary)!
    let line = CTLineCreateWithAttributedString(attributed)
    let width = CTLineGetTypographicBounds(line, nil, nil, nil)
    let ascent = CTFontGetAscent(font), descent = CTFontGetDescent(font)
    let x0 = CGFloat(text.anchor.x) - width * k / 2
    // `dominant-baseline: central`: the middle of ascent and descent on the anchor
    let baseline = CGFloat(text.anchor.y) + (ascent - descent) / 2 * k
    return Path { builder in
      for run in CTLineGetGlyphRuns(line) as! [CTRun] {
        let count = CTRunGetGlyphCount(run)
        var glyphs = [CGGlyph](repeating: 0, count: count)
        var positions = [CGPoint](repeating: .zero, count: count)
        CTRunGetGlyphs(run, CFRange(), &glyphs)
        CTRunGetPositions(run, CFRange(), &positions)
        for (g, p) in zip(glyphs, positions) {
          guard let outline = CTFontCreatePathForGlyph(font, g, nil) else { continue }
          func map(_ q: CGPoint) -> float2 {
            float2(Float(x0 + (p.x + q.x) * k), Float(baseline - (p.y + q.y) * k))
          }
          outline.applyWithBlock { element in
            let e = element.pointee, pts = e.points
            switch e.type {
            case .moveToPoint: builder.move(to: map(pts[0]))
            case .addLineToPoint: builder.addLine(to: map(pts[0]))
            case .addQuadCurveToPoint: builder.addQuadCurve(to: map(pts[1]), control: map(pts[0]))
            case .addCurveToPoint: builder.addCurve(to: map(pts[2]), control1: map(pts[0]), control2: map(pts[1]))
            case .closeSubpath: builder.closeSubpath()
            @unknown default: break
            }
          }
        }
      }
    }
  }

  /// The part's transform about its origin, as a map of box units; nil when it does not move.
  static func affine(_ t: GlyphTransform, origin: float2) -> (linear: float2x2, translation: float2)? {
    guard !t.isIdentity else { return nil }
    let r = t.rotation * .pi / 180, c = cos(r), s = sin(r)
    let rotate = float2x2(columns: (float2(c, s), float2(-s, c)))
    let skew = float2x2(columns: (float2(1, 0), float2(tan(t.skewX * .pi / 180), 1)))
    let scale = float2x2(columns: (float2(t.sx, 0), float2(0, t.sy)))
    let linear = rotate * skew * scale
    return (linear, origin + float2(t.tx, t.ty) - linear * origin)
  }

  // MARK: - Setting up

  /// Sizes the per-part storage for its glyph and gives every part its values, snapped.
  private func reset() {
    let count = self.style.nodes.count
    self.computed = [PartStyle](repeating: PartStyle(), count: count)
    self.transitions = [Transition?](repeating: nil, count: count * 4)
    self.animations = [(animation: GlyphAnimation, start: Double)?](repeating: nil, count: count)
    self.poses = [GlyphPose](repeating: GlyphPose(), count: count)
    self.flags[GlyphFlag.loop.rawValue] = self.isLooping
    for path in self.morphPaths.values { path.releaseBake() }
    self.morphPaths.removeAll()
    self.restyle(animate: false)
  }

  // MARK: - Modifiers

  /// Its colour: a role or a hue. Sets this icon and returns it.
  public func foregroundColor(_ color: float4) -> Self {
    self.color = color
    return self
  }

  /// Its size is its box times `scale`. Sets this icon and returns it.
  public func scale(_ scale: Float) -> Self {
    self.scale = scale
    self.iconSize = nil
    return self
  }

  /// Fits its box's longer side to `size` points. Sets this icon and returns it.
  public func iconSize(_ size: Float) -> Self {
    self.iconSize = size
    return self
  }

  /// How fast it plays. Sets this icon and returns it.
  public func speed(_ speed: Float) -> Self {
    self.speed = speed
    return self
  }

  /// A colour for the parts the page may colour. Sets this icon and returns it.
  public func tint(_ tint: GlyphTint, _ color: float4) -> Self {
    self.tints[tint] = color
    return self
  }

  /// Loops its motion. Sets this icon and returns it.
  public func loop(_ loop: Bool = true) -> Self {
    self.isLooping = loop
    self.flags[GlyphFlag.loop.rawValue] = loop
    self.restyle(animate: false)
    return self
  }

  /// Plays its entrance when it mounts. Sets this icon and returns it.
  public func mountAnimation(_ plays: Bool = true) -> Self {
    self.playsMount = plays
    return self
  }

  // MARK: - Setters

  public func setGlyph(_ glyph: AnimatedGlyph, _ context: UIContext, animation: UIAnimation? = nil) {
    guard glyph != self.glyph else { return }
    let wasHost = self.host != nil
    self.detachHost()
    self.glyph = glyph
    self.style = glyph.style
    self.now = context.clock()
    self.reset()
    if wasHost, self.mounted { self.attachHost() }
    self.runClock(context)
    context.invalidate(.layout)
  }

  public func setTrigger(_ trigger: Trigger, _ context: UIContext, animation: UIAnimation? = nil) {
    guard trigger != self.trigger else { return }
    self.detachHost()
    self.trigger = trigger
    if self.mounted { self.attachHost() }
    if trigger == .loop { self.setLoop(true, context) }
  }

  public func setActive(_ active: Bool?, _ context: UIContext, animation: UIAnimation? = nil) {
    guard active != self.active else { return }
    self.active = active
    self.now = context.clock()
    guard self.mounted else {
      self.restyle(animate: false)
      return
    }
    if self.restyle(animate: true) { context.invalidate() }
    if let active { self.pulse(.to, value: active ? "true" : "false", context) }
    self.runClock(context)
  }

  public func setLoop(_ loop: Bool, _ context: UIContext, animation: UIAnimation? = nil) {
    guard loop != self.isLooping else { return }
    self.isLooping = loop
    self.flags[GlyphFlag.loop.rawValue] = loop
    self.now = context.clock()
    if self.restyle(animate: self.mounted) { context.invalidate() }
    self.runClock(context)
  }

  /// Plays its entrance again: the template's `replay`.
  public func replay(_ context: UIContext) {
    guard self.mounted else { return }
    self.pulse(.mount, context)
  }

  public func setForegroundColor(_ value: float4, _ context: UIContext, animation: UIAnimation? = nil) {
    context.animator.set(self, .color, from: self.color ?? value, to: value, animation, context) { element, value, context in
      unsafeDowncast(element, to: AnimatedIcon.self).color = float4(packed: value)
      context.invalidate()
    }
  }

  public func setScale(_ value: Float, _ context: UIContext, animation: UIAnimation? = nil) {
    guard value != self.scale || self.iconSize != nil else { return }
    self.scale = value
    self.iconSize = nil
    context.invalidate(.layout, animation: animation)
  }

  public func setIconSize(_ value: Float, _ context: UIContext, animation: UIAnimation? = nil) {
    guard value != self.iconSize else { return }
    self.iconSize = value
    context.invalidate(.layout, animation: animation)
  }

  public func setSpeed(_ value: Float, _ context: UIContext, animation: UIAnimation? = nil) {
    self.speed = value
  }

  public func setTint(_ tint: GlyphTint, _ value: float4, _ context: UIContext) {
    guard self.tints[tint] != value else { return }
    self.tints[tint] = value
    context.invalidate()
  }

  /// Gives every part its values under the current flags, snapped: a change made before it
  /// mounts, when there is no clock to move by.
  func restyleAtRest() {
    self.flags[GlyphFlag.loop.rawValue] = self.isLooping
    self.restyle(animate: false)
  }

  // MARK: - For tests

  /// Whether anything is moving: a transition, an animation, the morph.
  var isMoving: Bool { self.settlesAt > self.now || self.hasLoop }

  /// Whether the host's hover pose is held.
  var isHovering: Bool { self.flags[GlyphFlag.hovering.rawValue] }
  var isPressedDown: Bool { self.flags[GlyphFlag.press.rawValue] }
}

/// Where a part is: its transform about its origin, its opacity and its dash.
struct GlyphPose {
  var transform = GlyphTransform.identity
  var opacity: Float = 1
  var dashOffset: Float = 0
  var dashArray: SIMD2<Float>? = nil
  var stroke: GlyphColor? = nil
  var origin: (GlyphLength, GlyphLength) = (.px(0), .px(0))
  var fillBox = false
}

/// The colours a page gives an icon's tintable parts, by `GlyphTint`.
public struct GlyphTints: Equatable, Sendable {
  private var fill: float4? = nil, badge: float4? = nil, check: float4? = nil, swift: float4? = nil, fileType: float4? = nil

  public init() {}

  public subscript(_ tint: GlyphTint) -> float4? {
    get {
      switch tint {
      case .fill: self.fill
      case .badge: self.badge
      case .check: self.check
      case .swift: self.swift
      case .fileType: self.fileType
      }
    }
    set {
      switch tint {
      case .fill: self.fill = newValue
      case .badge: self.badge = newValue
      case .check: self.check = newValue
      case .swift: self.swift = newValue
      case .fileType: self.fileType = newValue
      }
    }
  }
}

/// The play/pause morph's spring (stiffness 380, damping 0.34), as the template steps it by
/// hand: retargeted from where it is, keeping its velocity.
struct MorphSpring {
  var from: Float = 0
  var velocity: Float = 0
  var target: Float = 0
  var start: Double = 0
  var speed: Float = 1
  var settlesAt: Double = 0

  static let stiffness: Float = 380
  static let damping: Float = 0.34

  func state(at now: Double) -> (x: Float, v: Float) {
    guard now < self.settlesAt else { return (self.target, 0) }
    let t = Float(now - self.start) * self.speed
    return GlyphEasing.spring(t, from: self.from, velocity: self.velocity, to: self.target, stiffness: Self.stiffness, damping: Self.damping)
  }

  func value(at now: Double) -> Float { self.state(at: now).x }

  mutating func snap(_ target: Float) {
    self = MorphSpring(from: target, velocity: 0, target: target, start: 0, speed: 1, settlesAt: 0)
  }

  mutating func retarget(_ target: Float, at now: Double, speed: Float) {
    let (x, v) = self.state(at: now)
    guard target != self.target || now < self.settlesAt else { return }
    self.from = x
    self.velocity = v
    self.target = target
    self.start = now
    self.speed = max(speed, 0.05)
    // settled as the template stops: within 0.001, slower than 0.01 a second
    var t: Float = 0
    while t < 3 {
      t += 1 / 240
      let s = GlyphEasing.spring(t, from: x, velocity: v, to: target, stiffness: Self.stiffness, damping: Self.damping)
      if abs(s.x - target) < 0.001 && abs(s.v) < 0.01 { break }
    }
    self.settlesAt = now + Double(t / self.speed)
  }
}
