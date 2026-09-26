import AppKit
import simd

/// A single line of editable text with a label: `TextField("Name", text: $name, prompt: "Required")`.
///
/// Editing works as in an AppKit text field:
/// - a click or Tab focuses it; a click places the caret, a drag selects, a double-click selects
///   a word;
/// - typing and pasting replace the selection; Delete and forward delete remove it, or a
///   character, or with ⌥ a word, or with ⌘ to the line's end;
/// - the arrows, Home and End move the caret, by word with ⌥ and to the ends with ⌘, and extend
///   the selection with ⇧; ⌘A selects all;
/// - ⌘C ⌘X ⌘V copy, cut and paste — a `SecureField` does not copy or cut;
/// - ⌘Z undoes and ⇧⌘Z redoes, typing coalesced into one step until the caret jumps;
/// - Return runs `onSubmit`, Escape gives up focus.
///
/// There is no input method. The caret does not blink: a blinking one would redraw twice a
/// second for as long as the field has focus, and an idle app should draw nothing.
public class TextField : FormControl {
  public private(set) var text: String
  public private(set) var prompt: String
  /// Where an edit reports the new text. `@Component` arms it with the binding's write-back.
  public var onTextChange: ((String) -> Void)?
  /// Run by Return. Set by `.onSubmit { }`, which `@Component` arms like a handler.
  public var onSubmit: (() -> Void)?

  let isSecure: Bool
  /// Characters before the caret.
  public private(set) var caret: Int
  /// The selection's other end; the caret itself when nothing is selected.
  public private(set) var anchor: Int
  /// The selected characters, empty when there is only a caret.
  public var selection: Range<Int> { min(self.caret, self.anchor) ..< max(self.caret, self.anchor) }

  /// Where the caret and anchor go once an edit being reported comes back through `setText`.
  private var pendingCaret = 0
  private var pendingAnchor = 0

  private struct Snapshot {
    var text: String
    var caret: Int
    var anchor: Int
  }

  private enum EditKind {
    case typing
    case deleting
    case other
  }

  private var undoStack: [Snapshot] = []
  private var redoStack: [Snapshot] = []
  /// The last edit, while it can still be extended into the same undo step: its kind, and where
  /// it left the caret.
  private var openEdit: (kind: EditKind, end: Int)? = nil
  private static let undoLimit = 100

  private let label: Text
  private let displayed: Text
  private let box: FieldBox
  private let focusable: FocusableElement

  init(_ label: String, text: String, prompt: String, secure: Bool, onTextChange: ((String) -> Void)?) {
    self.text = text
    self.prompt = prompt
    self.isSecure = secure
    self.caret = text.count
    self.anchor = text.count
    self.onTextChange = onTextChange
    let label = Text(label).font(FormMetrics.font).foregroundColor(FormMetrics.labelColor)
    let displayed = Text("").font(FormMetrics.font)
    let box = FieldBox(displayed)
    // Swallows the tap, so a click in the field reaches nothing under it.
    let pointer = HittableView(onTap: { _ in }) { box }
    let focusable = FocusableElement { pointer }
    let keys = KeyPressElement(phases: [.down, .repeat], action: nil) { focusable }
    self.label = label
    self.displayed = displayed
    self.box = box
    self.focusable = focusable
    super.init(content: HStack(spacing: FormMetrics.labelSpacing) {
      if !label.text.isEmpty { label }
      keys
    })
    keys.action = { [unowned self] press in self.handle(press) }
    focusable.onFocusChange = { [unowned self] focused in self.focusChanged(focused) }
    pointer.onPress = { [unowned self] down, input in
      if down { self.pressed(at: input.mousePosition.x, clicks: input.clickCount, extending: input.shiftPressed) }
    }
    pointer.onDrag = { [unowned self] input in self.dragged(to: input.mousePosition.x) }
    // An I-beam over the text, as AppKit's fields show.
    pointer.pointerStyle = .horizontalText
    self.refresh(nil)
  }

  public convenience init(_ label: String, text: String, prompt: String = "", onTextChange: ((String) -> Void)? = nil) {
    self.init(label, text: text, prompt: prompt, secure: false, onTextChange: onTextChange)
  }

  /// A hand-built field over a binding. In a `@Component` body `$state` is lowered instead.
  public convenience init(_ label: String, text: Binding<String>, prompt: String = "") {
    self.init(label, text: text.wrappedValue, prompt: prompt, secure: false, onTextChange: nil)
    self.bind(text)
  }

  func bind(_ text: Binding<String>) {
    self.onTextChange = { [unowned self] value in
      text.wrappedValue = value
      if let context = self.context { self.setText(text.wrappedValue, context) }
    }
  }

  // MARK: - Keys

  private func handle(_ press: KeyPress) -> KeyPress.Result {
    guard !self.isDisabled else { return .ignored }
    let command = press.modifiers.contains(.command)
    let option = press.modifiers.contains(.option)
    let shift = press.modifiers.contains(.shift)
    let count = self.text.count
    let selection = self.selection

    switch press.key {
    case .tab:
      return .ignored   // moves focus
    case .return:
      self.onSubmit?()
    case .escape:
      self.context?.focus(nil)
    case .delete:
      if !selection.isEmpty {
        self.replace(selection, with: "", kind: .other)
      } else if self.caret > 0 {
        let start = command ? 0 : option ? self.wordStart(before: self.caret) : self.caret - 1
        self.replace(start ..< self.caret, with: "", kind: command || option ? .other : .deleting)
      }
    case .deleteForward:
      if !selection.isEmpty {
        self.replace(selection, with: "", kind: .other)
      } else if self.caret < count {
        let end = command ? count : option ? self.wordEnd(after: self.caret) : self.caret + 1
        self.replace(self.caret ..< end, with: "", kind: .other)
      }
    case .leftArrow:
      let target = command ? 0
        : option ? self.wordStart(before: self.caret)
        : (!shift && !selection.isEmpty) ? selection.lowerBound : self.caret - 1
      self.moveCaret(to: target, extending: shift)
    case .rightArrow:
      let target = command ? count
        : option ? self.wordEnd(after: self.caret)
        : (!shift && !selection.isEmpty) ? selection.upperBound : self.caret + 1
      self.moveCaret(to: target, extending: shift)
    case .home, .upArrow, .pageUp:
      self.moveCaret(to: 0, extending: shift)
    case .end, .downArrow, .pageDown:
      self.moveCaret(to: count, extending: shift)
    default:
      if command {
        return self.command(press.key.character.lowercased(), shift: shift)
      } else if press.modifiers.contains(.control) {
        return .ignored
      } else {
        self.insert(press.characters)
      }
    }
    return .handled
  }

  private func command(_ key: String, shift: Bool) -> KeyPress.Result {
    switch key {
    case "a":
      self.select(0 ..< self.text.count)
    case "c":
      self.copySelection()
    case "x":
      guard !self.isSecure, !self.selection.isEmpty else { break }
      self.copySelection()
      self.replace(self.selection, with: "", kind: .other)
    case "v":
      if let pasted = NSPasteboard.general.string(forType: .string) {
        self.insert(pasted, kind: .other)
      }
    case "z":
      if shift { self.redo() } else { self.undo() }
    default:
      return .ignored
    }
    return .handled
  }

  // MARK: - Editing

  /// Replaces the selection with what can be typed on one line: no control characters, no
  /// function-key characters.
  private func insert(_ characters: String, kind: EditKind = .typing) {
    let typed = String(String.UnicodeScalarView(characters.unicodeScalars.filter { scalar in
      scalar.value >= 0x20 && scalar.value != 0x7F && !(0xF700 ... 0xF8FF).contains(scalar.value)
    }))
    guard !typed.isEmpty else { return }
    self.replace(self.selection, with: typed, kind: self.selection.isEmpty ? kind : .other)
  }

  /// Replaces `range` with `string` and reports the result, recording the step to undo first.
  private func replace(_ range: Range<Int>, with string: String, kind: EditKind) {
    guard self.onTextChange != nil else { return }
    var text = self.text
    let lower = text.index(text.startIndex, offsetBy: range.lowerBound)
    let upper = text.index(lower, offsetBy: range.count)
    text.replaceSubrange(lower ..< upper, with: string)
    guard text != self.text else { return }

    // A run of typing, or of deleting backwards, is one step to undo.
    let continues: Bool
    if let open = self.openEdit, open.kind == kind, kind != .other, self.selection.isEmpty {
      continues = kind == .typing ? range.lowerBound == open.end : range.upperBound == open.end
    } else {
      continues = false
    }
    if !continues {
      self.undoStack.append(Snapshot(text: self.text, caret: self.caret, anchor: self.anchor))
      if self.undoStack.count > Self.undoLimit { self.undoStack.removeFirst() }
    }
    self.redoStack.removeAll()

    let caret = range.lowerBound + string.count
    self.openEdit = (kind, caret)
    self.report(text, caret: caret, anchor: caret)
  }

  private func undo() {
    guard let snapshot = self.undoStack.popLast() else { return }
    self.redoStack.append(Snapshot(text: self.text, caret: self.caret, anchor: self.anchor))
    self.restore(snapshot)
  }

  private func redo() {
    guard let snapshot = self.redoStack.popLast() else { return }
    self.undoStack.append(Snapshot(text: self.text, caret: self.caret, anchor: self.anchor))
    self.restore(snapshot)
  }

  private func restore(_ snapshot: Snapshot) {
    self.openEdit = nil
    if snapshot.text == self.text {
      self.setCaret(snapshot.caret, anchor: snapshot.anchor)
    } else {
      self.report(snapshot.text, caret: snapshot.caret, anchor: snapshot.anchor)
    }
  }

  /// Reports an edit. With nothing to report to, the text is a constant and the edit is dropped.
  private func report(_ text: String, caret: Int, anchor: Int) {
    guard let report = self.onTextChange else { return }
    self.pendingCaret = caret
    self.pendingAnchor = anchor
    self.commit { report(text) }
  }

  private func copySelection() {
    let selection = self.selection
    guard !self.isSecure, !selection.isEmpty else { return }
    let start = self.text.index(self.text.startIndex, offsetBy: selection.lowerBound)
    let end = self.text.index(start, offsetBy: selection.count)
    NSPasteboard.general.clearContents()
    NSPasteboard.general.setString(String(self.text[start ..< end]), forType: .string)
  }

  // MARK: - Caret and selection

  private func moveCaret(to position: Int, extending: Bool) {
    self.openEdit = nil
    let position = position.clamped(to: 0 ... self.text.count)
    self.setCaret(position, anchor: extending ? self.anchor : position)
  }

  /// Selects `range`, the caret at its upper end: or its lower, for a range written backwards.
  private func select(_ range: Range<Int>) {
    self.openEdit = nil
    self.setCaret(range.upperBound, anchor: range.lowerBound)
  }

  private func setCaret(_ caret: Int, anchor: Int) {
    let count = self.text.count
    let caret = caret.clamped(to: 0 ... count)
    let anchor = anchor.clamped(to: 0 ... count)
    guard caret != self.caret || anchor != self.anchor else { return }
    self.caret = caret
    self.anchor = anchor
    self.box.setSelection(caret: caret, anchor: anchor, self.context)
  }

  private func isWordCharacter(_ character: Character) -> Bool {
    character.isLetter || character.isNumber || character == "_"
  }

  /// The start of the word at or before `index`, skipping the non-word characters before it.
  private func wordStart(before index: Int) -> Int {
    let characters = Array(self.text)
    var i = min(index, characters.count)
    while i > 0, !self.isWordCharacter(characters[i - 1]) { i -= 1 }
    while i > 0, self.isWordCharacter(characters[i - 1]) { i -= 1 }
    return i
  }

  /// The end of the word at or after `index`, skipping the non-word characters after it.
  private func wordEnd(after index: Int) -> Int {
    let characters = Array(self.text)
    var i = max(index, 0)
    while i < characters.count, !self.isWordCharacter(characters[i]) { i += 1 }
    while i < characters.count, self.isWordCharacter(characters[i]) { i += 1 }
    return i
  }

  // MARK: - Pointer

  private func pressed(at x: Float, clicks: Int, extending: Bool) {
    guard !self.isDisabled else { return }
    let index = self.box.index(atX: x)
    self.openEdit = nil
    if clicks >= 2 {
      // The word under the pointer; in a secure field, everything, as AppKit does.
      guard !self.isSecure else {
        self.select(0 ..< self.text.count)
        return
      }
      let characters = Array(self.text)
      guard index < characters.count || index > 0 else { return }
      let at = index < characters.count ? index : index - 1
      if self.isWordCharacter(characters[at]) {
        self.select(self.wordStart(before: at + 1) ..< self.wordEnd(after: at))
      } else {
        self.select(at ..< at + 1)
      }
    } else {
      self.setCaret(index, anchor: extending ? self.anchor : index)
    }
  }

  private func dragged(to x: Float) {
    guard !self.isDisabled else { return }
    self.setCaret(self.box.index(atX: x), anchor: self.anchor)
  }

  private func focusChanged(_ focused: Bool) {
    guard let context = self.context else { return }
    if !focused {
      // The selection goes with focus.
      self.openEdit = nil
      self.setCaret(self.caret, anchor: self.caret)
    }
    self.box.setFocused(focused, context)
  }

  // MARK: - Display

  /// Shows the text, or the prompt when there is none, and measures where the caret can go.
  private func refresh(_ context: UIContext?) {
    let shown = self.text.isEmpty ? self.prompt
      : self.isSecure ? String(repeating: "•", count: self.text.count) : self.text
    let color = self.text.isEmpty ? FormMetrics.secondaryColor.withAlpha(0.7) : FormMetrics.labelColor
    if let context {
      self.displayed.setText(shown, context)
      self.displayed.setForegroundColor(color, context)
    } else {
      self.displayed.text = shown
      _ = self.displayed.foregroundColor(color)
    }
    // The prompt is not text: its caret offsets are the empty text's.
    let measured = self.text.isEmpty ? "" : shown
    self.box.offsets = caretOffsets(measured, font: FormMetrics.font)
    self.box.setSelection(caret: self.caret, anchor: self.anchor, context, force: true)
  }

  override func disabledChanged(_ context: UIContext) {
    self.focusable.setFocusable(!self.isDisabled, context)
  }

  // MARK: - Setters

  /// A new text from state. After an edit reported from here the caret and selection go where
  /// the edit left them; after any other change the caret goes to the end, and the undo history,
  /// which no longer leads to this text, is dropped.
  public func setText(_ value: String, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    guard value != self.text else { return }
    self.text = value
    let count = value.count
    if self.isInteracting {
      self.caret = self.pendingCaret.clamped(to: 0 ... count)
      self.anchor = self.pendingAnchor.clamped(to: 0 ... count)
    } else {
      self.caret = count
      self.anchor = count
      self.undoStack.removeAll()
      self.redoStack.removeAll()
      self.openEdit = nil
    }
    self.refresh(context)
  }

  public func setPrompt(_ value: String, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    guard value != self.prompt else { return }
    self.prompt = value
    if self.text.isEmpty { self.refresh(context) }
  }

  public func setLabel(_ value: String, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    guard value != self.label.text else { return }
    self.label.setText(value, context, animation: animation)
  }

  /// What Return runs. Sets this field's own handler and returns it.
  public func onSubmit(_ action: @escaping () -> Void) -> Self {
    self.onSubmit = action
    return self
  }
}

/// A text field that shows a bullet for each character: `SecureField("Password", text: $password)`.
public final class SecureField : TextField {
  public init(_ label: String, text: String, prompt: String = "", onTextChange: ((String) -> Void)? = nil) {
    super.init(label, text: text, prompt: prompt, secure: true, onTextChange: onTextChange)
  }

  public convenience init(_ label: String, text: Binding<String>, prompt: String = "") {
    self.init(label, text: text.wrappedValue, prompt: prompt)
    self.bind(text)
  }
}

/// A text field's rounded box, its focus ring, selection and caret, around the text it clips.
/// Scrolls the text sideways to keep the caret in view.
final class FieldBox : UIRenderableElement {
  static let inset = float2(7, 4)
  static let idealWidth: Float = 180
  static let minWidth: Float = 60

  private(set) var position: float2 = .zero
  private(set) var size: float2 = .zero
  private var focused = false
  /// Where a caret goes before each character of what is shown, and after the last; see
  /// `caretOffsets`. Set whenever the text changes.
  var offsets: [Float] = [0]
  private var caret = 0
  private var anchor = 0
  /// How far the text is scrolled left.
  private var scroll: Float = 0

  init(_ text: Text) {
    super.init()
    self.applyContent([text])
  }

  override func mount(_ context: UIContext) {
    context.registerRenderableView(self)
  }

  override func unmount(_ context: UIContext) {
    context.unregisterRenderableView(self)
    self.focused = false
  }

  func setFocused(_ value: Bool, _ context: UIContext) {
    guard value != self.focused else { return }
    self.focused = value
    context.invalidate()
  }

  /// A new caret or selection. A layout pass then scrolls the text to keep the caret in view.
  func setSelection(caret: Int, anchor: Int, _ context: UIContext?, force: Bool = false) {
    let last = self.offsets.count - 1
    let caret = caret.clamped(to: 0 ... last)
    let anchor = anchor.clamped(to: 0 ... last)
    guard force || caret != self.caret || anchor != self.anchor else { return }
    self.caret = caret
    self.anchor = anchor
    context?.invalidate(.layout)
  }

  private func offset(_ index: Int) -> Float {
    self.offsets[index.clamped(to: 0 ... self.offsets.count - 1)]
  }

  /// The character boundary nearest `x`, window top left origin: a binary search of the offsets.
  func index(atX x: Float) -> Int {
    let local = x - (self.position.x + Self.inset.x - self.scroll)
    var low = 0
    var high = self.offsets.count - 1
    while low < high {
      let middle = (low + high + 1) / 2
      if self.offsets[middle] <= local { low = middle } else { high = middle - 1 }
    }
    if low + 1 < self.offsets.count, local - self.offsets[low] > self.offsets[low + 1] - local {
      return low + 1
    }
    return low
  }

  override func getSize() -> float2 {
    self.size
  }

  // As wide as it is offered, down to a usable minimum; one line tall.
  override func sizeThatFits(_ proposal: ProposedSize) -> float2 {
    let line = self.child?.measure(.unspecified).y ?? 0
    return float2(max(proposal.width ?? Self.idealWidth, Self.minWidth), line + Self.inset.y * 2)
  }

  override func calcSize(_ proposal: ProposedSize) -> float2 {
    let line = self.child?.calcSize(.unspecified).y ?? 0
    self.size = float2(max(proposal.width ?? Self.idealWidth, Self.minWidth), line + Self.inset.y * 2)
    return self.size
  }

  override func calcPosition(_ position: float2) {
    self.position = position
    // Just enough to keep the caret in the box, never more than the text needs.
    let visible = self.size.x - Self.inset.x * 2 - 1
    let caret = self.offset(self.caret)
    if caret - self.scroll > visible {
      self.scroll = caret - visible
    } else if caret < self.scroll {
      self.scroll = caret
    }
    let textWidth = self.offsets.last ?? 0
    self.scroll = max(0, min(self.scroll, textWidth - visible))
    self.child?.calcPosition(position + Self.inset - float2(self.scroll, 0))
  }

  // The text only: the box, selection and caret are drawn by the box itself, outside its clip.
  override var clipRect: ClipRect? {
    ClipRect(position: self.position + float2(Self.inset.x - 1, 0), size: self.size - float2(Self.inset.x * 2 - 2, 0))
  }

  override func render(_ renderer: Graphics2D, _ effect: EffectState) {
    guard effect.opacity > 0 else { return }
    let s = effect.scale
    let origin = effect.apply(to: self.position) - renderer.size * 0.5
    let size = self.size * s
    let radii = float4(repeating: 6 * s)
    renderer.draw(roundedRect: origin, size: size, radii: radii, color: float4(1, 1, 1, effect.opacity))
    var border = self.focused ? FormMetrics.accentColor : FormMetrics.strokeColor
    border.w *= effect.opacity
    renderer.draw(roundedRect: origin, size: size, radii: radii, color: border, strokeWidth: (self.focused ? 2 : 1) * s)

    guard self.focused else { return }
    let height = (self.size.y - Self.inset.y * 2) * s
    let textX = origin.x + (Self.inset.x - self.scroll) * s
    if self.caret != self.anchor {
      // Kept inside the box, like the text it covers.
      let low = max(self.offset(min(self.caret, self.anchor)) - self.scroll, -1) * s
      let high = min(self.offset(max(self.caret, self.anchor)) - self.scroll, self.size.x - Self.inset.x * 2 + 1) * s
      var fill = FormMetrics.accentColor
      fill.w *= 0.25 * effect.opacity
      renderer.draw(
        square: Square(position: float2(textX + self.scroll * s + (low + high) * 0.5, origin.y + size.y * 0.5),
                       size: float2(high - low, height), color: fill)
      )
    } else {
      var caret = FormMetrics.accentColor
      caret.w *= effect.opacity
      let x = textX + self.offset(self.caret) * s
      renderer.draw(square: Square(position: float2(x, origin.y + size.y * 0.5), size: float2(1.5 * s, height), color: caret))
    }
  }
}

extension float4 {
  func withAlpha(_ alpha: Float) -> float4 {
    float4(self.x, self.y, self.z, self.w * alpha)
  }
}
