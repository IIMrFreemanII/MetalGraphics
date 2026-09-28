import simd

/// A `FindBar`'s sizes and type.
public enum FindBarMetrics {
  public static let height: Float = 36
  public static let font = TextFont.system(size: 12)
  public static let countFont = TextFont.system(size: 11)
  public static let queryWidth: Float = 220
  public static let countWidth: Float = 72
  public static let replaceWidth: Float = 160
  public static let spacing: Float = 8
  public static let inset = Inset(horizontal: 12)
  public static let background: float4 = .barOverContent
}

/// An editor's find and replace bar, over its text: the query with a magnifier, the match count,
/// ‹ › for the previous and next match, the Aa, Word and .* options, a hairline, the replacement
/// with Replace and All, and Done. Return in the query goes to the next match, in the replacement
/// replaces it. Not in SwiftUI.
///
///     FindBar(query: $query, replacement: $replacement, count: self.matches,
///             caseSensitive: $caseSensitive, wholeWord: $wholeWord, regex: $regex, focused: self.findFocused,
///             onNext: { … }, onPrevious: { … }, onReplace: { … }, onReplaceAll: { … }, onDone: { … })
///
/// Controlled, as a `TextField` is: each change is reported, and it shows what it is given.
public final class FindBar : SingleChildElement {
  public var onQueryChange: ((String) -> Void)?
  public var onReplacementChange: ((String) -> Void)?
  public var onCaseSensitiveChange: ((Bool) -> Void)?
  public var onWholeWordChange: ((Bool) -> Void)?
  public var onRegexChange: ((Bool) -> Void)?
  public var onNext: (() -> Void)?
  public var onPrevious: (() -> Void)?
  public var onReplace: (() -> Void)?
  public var onReplaceAll: (() -> Void)?
  public var onDone: (() -> Void)?

  public private(set) var showReplace: Bool
  private let queryField: TextField
  private let replaceField: TextField
  private let count: Text
  private let caseChip: ToggleChip
  private let wordChip: ToggleChip
  private let regexChip: ToggleChip
  private let row = HStack(spacing: FindBarMetrics.spacing)
  private let leading: [UIElement]
  private let replacing: [UIElement]
  private let trailing: [UIElement]

  public init(
    query: String, replacement: String = "", count: String = "",
    caseSensitive: Bool = false, wholeWord: Bool = false, regex: Bool = false,
    showReplace: Bool = true, focused: Bool = false,
    onQueryChange: ((String) -> Void)? = nil, onReplacementChange: ((String) -> Void)? = nil,
    onCaseSensitiveChange: ((Bool) -> Void)? = nil, onWholeWordChange: ((Bool) -> Void)? = nil,
    onRegexChange: ((Bool) -> Void)? = nil,
    onNext: (() -> Void)? = nil, onPrevious: (() -> Void)? = nil, onReplace: (() -> Void)? = nil,
    onReplaceAll: (() -> Void)? = nil, onDone: (() -> Void)? = nil
  ) {
    self.showReplace = showReplace
    self.onQueryChange = onQueryChange
    self.onReplacementChange = onReplacementChange
    self.onCaseSensitiveChange = onCaseSensitiveChange
    self.onWholeWordChange = onWholeWordChange
    self.onRegexChange = onRegexChange
    self.onNext = onNext
    self.onPrevious = onPrevious
    self.onReplace = onReplace
    self.onReplaceAll = onReplaceAll
    self.onDone = onDone

    let queryField = TextField("", text: query, prompt: "Find").leadingIcon(.magnifier).focused(focused)
    let replaceField = TextField("", text: replacement, prompt: "Replace")
    let count = Text(count)
      .font(FindBarMetrics.countFont)
      .foregroundColor(.secondaryLabel)
      .lineLimit(1)
    let previous = Button(action: nil) { Image(icon: .chevronLeft) }.buttonStyle(.bordered)
    let next = Button(action: nil) { Image(icon: .chevronRight) }.buttonStyle(.bordered)
    let replace = Button("Replace", action: nil).buttonStyle(.bordered)
    let all = Button("All", action: nil).buttonStyle(.bordered)
    let done = Button("Done", action: nil).buttonStyle(.borderless)
    self.queryField = queryField
    self.replaceField = replaceField
    self.count = count
    self.caseChip = ToggleChip("Aa", isOn: caseSensitive)
    self.wordChip = ToggleChip("Word", isOn: wholeWord)
    self.regexChip = ToggleChip(".*", isOn: regex)
    self.leading = [
      queryField.frame(width: FindBarMetrics.queryWidth),
      count.frame(width: FindBarMetrics.countWidth, alignment: .leading),
      previous, next, self.caseChip, self.wordChip, self.regexChip,
    ]
    self.replacing = [
      Rectangle(.separator).frame(width: 0.5, height: 18),
      replaceField.frame(width: FindBarMetrics.replaceWidth),
      replace, all,
    ]
    self.trailing = [Spacer(), done]
    super.init()

    self.row.applyContent(self.rowContent())
    self.applyContent([
      self.row
        .font(FindBarMetrics.font)
        .padding(FindBarMetrics.inset)
        .frame(maxWidth: .infinity, minHeight: FindBarMetrics.height, alignment: .leading)
        .background(FindBarMetrics.background)
        .overlay(alignment: .bottom) {
          Rectangle(.separator)
            .frame(height: 0.5)
        }
    ])

    queryField.onTextChange = { [unowned self] in self.onQueryChange?($0) }
    queryField.onSubmit = { [unowned self] in self.onNext?() }
    replaceField.onTextChange = { [unowned self] in self.onReplacementChange?($0) }
    replaceField.onSubmit = { [unowned self] in self.onReplace?() }
    previous.action = { [unowned self] in self.onPrevious?() }
    next.action = { [unowned self] in self.onNext?() }
    replace.action = { [unowned self] in self.onReplace?() }
    all.action = { [unowned self] in self.onReplaceAll?() }
    done.action = { [unowned self] in self.onDone?() }
    self.caseChip.onIsOnChange = { [unowned self] in self.onCaseSensitiveChange?($0) }
    self.wordChip.onIsOnChange = { [unowned self] in self.onWholeWordChange?($0) }
    self.regexChip.onIsOnChange = { [unowned self] in self.onRegexChange?($0) }
  }

  /// A hand-built bar over bindings. In a `@Component` body `$state` is lowered instead, and
  /// this is never called.
  public convenience init(
    query: Binding<String>, replacement: Binding<String>, count: String = "",
    caseSensitive: Binding<Bool>, wholeWord: Binding<Bool>, regex: Binding<Bool>,
    showReplace: Bool = true, focused: Bool = false,
    onNext: (() -> Void)? = nil, onPrevious: (() -> Void)? = nil, onReplace: (() -> Void)? = nil,
    onReplaceAll: (() -> Void)? = nil, onDone: (() -> Void)? = nil
  ) {
    self.init(
      query: query.wrappedValue, replacement: replacement.wrappedValue, count: count,
      caseSensitive: caseSensitive.wrappedValue, wholeWord: wholeWord.wrappedValue, regex: regex.wrappedValue,
      showReplace: showReplace, focused: focused,
      onNext: onNext, onPrevious: onPrevious, onReplace: onReplace, onReplaceAll: onReplaceAll, onDone: onDone
    )
    self.onQueryChange = { [unowned self] in
      query.wrappedValue = $0
      if let context = self.context { self.setQuery(query.wrappedValue, context) }
    }
    self.onReplacementChange = { [unowned self] in
      replacement.wrappedValue = $0
      if let context = self.context { self.setReplacement(replacement.wrappedValue, context) }
    }
    self.onCaseSensitiveChange = { [unowned self] in
      caseSensitive.wrappedValue = $0
      if let context = self.context { self.setCaseSensitive(caseSensitive.wrappedValue, context) }
    }
    self.onWholeWordChange = { [unowned self] in
      wholeWord.wrappedValue = $0
      if let context = self.context { self.setWholeWord(wholeWord.wrappedValue, context) }
    }
    self.onRegexChange = { [unowned self] in
      regex.wrappedValue = $0
      if let context = self.context { self.setRegex(regex.wrappedValue, context) }
    }
  }

  private weak var context: UIContext?

  public override func mount(_ context: UIContext) {
    self.context = context
  }

  public override func unmount(_ context: UIContext) {
    self.context = nil
  }

  private func rowContent() -> [UIElement] {
    self.leading + (self.showReplace ? self.replacing : []) + self.trailing
  }

  public var query: String { self.queryField.text }

  public func setQuery(_ value: String, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.queryField.setText(value, context, animation: animation)
  }

  public func setReplacement(_ value: String, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.replaceField.setText(value, context, animation: animation)
  }

  /// "2 of 8", "No matches".
  public func setCount(_ value: String, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    guard value != self.count.text else { return }
    self.count.setText(value, context, animation: animation)
  }

  public func setCaseSensitive(_ value: Bool, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.caseChip.setIsOn(value, context, animation: animation)
  }

  public func setWholeWord(_ value: Bool, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.wordChip.setIsOn(value, context, animation: animation)
  }

  public func setRegex(_ value: Bool, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.regexChip.setIsOn(value, context, animation: animation)
  }

  /// Focuses the query, or lets it go.
  public func setFocused(_ value: Bool, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.queryField.setFocused(value, context)
  }

  public func setShowReplace(_ value: Bool, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    guard value != self.showReplace else { return }
    self.showReplace = value
    self.row.replaceChildren(self.rowContent(), context, animation: animation)
  }
}
