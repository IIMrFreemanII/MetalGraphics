import Foundation
import simd

/// How a `DatePicker` shows its date.
public enum DatePickerStyle : Sendable {
  /// A pill with the date and one with the time, each opening a popover to change it. The default.
  case compact
  /// A month calendar in the row, under the label, and the time pill below it.
  case graphical
}

/// A date and time: `DatePicker("Due", selection: $due, in: range, displayedComponents: [.date, .hourAndMinute])`.
///
/// A date is picked on a month calendar, the time with hour and minute steppers. A date or time
/// outside `in:` cannot be picked. Picking a day keeps the time of day, and changing the time
/// keeps the day. Dates follow `Calendar.current`.
public final class DatePicker : FormControl {
  public struct Components : OptionSet, Sendable {
    public let rawValue: UInt8
    public init(rawValue: UInt8) { self.rawValue = rawValue }

    public static let date = Components(rawValue: 1 << 0)
    public static let hourAndMinute = Components(rawValue: 1 << 1)
  }

  public private(set) var selection: Date
  public let range: ClosedRange<Date>?
  public let components: Components
  public private(set) var style: DatePickerStyle = .compact
  /// Where a pick reports the new date. `@Component` arms it with the binding's write-back.
  public var onSelectionChange: ((Date) -> Void)?

  private let label: Text
  private let dateTitle = Text("").font(FormMetrics.font).foregroundColor(FormMetrics.labelColor)
  private let timeTitle = Text("").font(FormMetrics.font).foregroundColor(FormMetrics.labelColor)
  private var datePill: HittableView?
  private var timePill: HittableView?
  /// The calendar on screen, inline or in the open popover.
  private var calendar: CalendarView?
  /// The time steppers in the open popover.
  private var hourStepper: Stepper?
  private var minuteStepper: Stepper?
  private var popover: PopoverHandle?

  public init(
    _ label: String, selection: Date, in range: ClosedRange<Date>? = nil,
    displayedComponents: Components = [.date, .hourAndMinute], onSelectionChange: ((Date) -> Void)? = nil
  ) {
    self.selection = selection
    self.range = range
    self.components = displayedComponents
    self.onSelectionChange = onSelectionChange
    self.label = Text(label).font(FormMetrics.font).foregroundColor(FormMetrics.labelColor)
    super.init(content: EmptyElement())
    self.retitle(nil)
    self.rebuild(nil)
  }

  /// A hand-built picker over a binding. In a `@Component` body `$state` is lowered instead.
  public convenience init(
    _ label: String, selection: Binding<Date>, in range: ClosedRange<Date>? = nil,
    displayedComponents: Components = [.date, .hourAndMinute]
  ) {
    self.init(label, selection: selection.wrappedValue, in: range, displayedComponents: displayedComponents)
    self.onSelectionChange = { [unowned self] date in
      selection.wrappedValue = date
      if let context = self.context { self.setSelection(selection.wrappedValue, context) }
    }
  }

  public override func unmount(_ context: UIContext) {
    self.closePopover(animated: false)
    super.unmount(context)
  }

  // MARK: - Building

  private func rebuild(_ animation: UIAnimation?) {
    self.closePopover(animated: false)
    self.datePill = nil
    self.timePill = nil
    self.calendar = nil

    let label = self.label
    let time = self.components.contains(.hourAndMinute) ? self.makePill(self.timeTitle, time: true) : nil
    let tree: UIElement
    switch self.style {
    case .compact:
      let date = self.components.contains(.date) ? self.makePill(self.dateTitle, time: false) : nil
      tree = HStack(spacing: 8) {
        if !label.text.isEmpty {
          label
          Spacer(minLength: FormMetrics.labelSpacing)
        }
        if let date { date }
        if let time { time }
      }
    case .graphical:
      let calendar = self.makeCalendar()
      tree = VStack(alignment: .leading, spacing: 8) {
        if !label.text.isEmpty { label }
        if self.components.contains(.date) { calendar }
        if let time {
          HStack(spacing: FormMetrics.labelSpacing) {
            Text("Time").font(FormMetrics.font).foregroundColor(FormMetrics.secondaryColor)
            Spacer()
            time
          }
        }
      }
      if self.components.contains(.date) { self.calendar = calendar }
    }
    self.setContent(tree, animation: animation)
  }

  private func makePill(_ title: Text, time: Bool) -> HittableView {
    let pill = HittableView(onTap: nil) { PopupFace(chevrons: false) { title } }
    pill.onTap = { [unowned self] _ in
      if time { self.openTime() } else { self.openCalendar() }
    }
    if time { self.timePill = pill } else { self.datePill = pill }
    return pill
  }

  private func makeCalendar() -> CalendarView {
    CalendarView(selection: self.selection, range: self.range) { [unowned self] day in self.pick(day: day) }
  }

  /// The pills' texts, from the selection.
  private func retitle(_ context: UIContext?) {
    let date = self.selection.formatted(date: .abbreviated, time: .omitted)
    let time = self.selection.formatted(date: .omitted, time: .shortened)
    if let context {
      if date != self.dateTitle.text { self.dateTitle.setText(date, context) }
      if time != self.timeTitle.text { self.timeTitle.setText(time, context) }
    } else {
      self.dateTitle.text = date
      self.timeTitle.text = time
    }
  }

  // MARK: - Popovers

  private func openCalendar() {
    guard !self.isDisabled, let context = self.context, let pill = self.datePill, self.popover?.isPresented != true
    else { return }
    let calendar = self.makeCalendar()
    self.calendar = calendar
    self.popover = context.presentPopover(calendar.padding(10), anchor: pill) { [weak self] in
      self?.popover = nil
      self?.calendar = nil
    }
  }

  private func openTime() {
    guard !self.isDisabled, let context = self.context, let pill = self.timePill, self.popover?.isPresented != true
    else { return }
    let parts = Calendar.current.dateComponents([.hour, .minute], from: self.selection)
    let hour = Stepper(Self.hourLabel(parts.hour ?? 0), value: parts.hour ?? 0, in: 0 ... 23) { [unowned self] value in
      self.setTime(hour: Int(value), minute: nil)
    }
    let minute = Stepper(Self.minuteLabel(parts.minute ?? 0), value: parts.minute ?? 0, in: 0 ... 59) { [unowned self] value in
      self.setTime(hour: nil, minute: Int(value))
    }
    self.hourStepper = hour
    self.minuteStepper = minute
    let content = VStack(alignment: .leading, spacing: 10) { hour; minute }
      .frame(width: 180)
      .padding(12)
    self.popover = context.presentPopover(content, anchor: pill) { [weak self] in
      self?.popover = nil
      self?.hourStepper = nil
      self?.minuteStepper = nil
    }
  }

  private func closePopover(animated: Bool) {
    guard let popover = self.popover, let context = self.context else { return }
    context.dismissPopover(popover, animated: animated)
  }

  private static func hourLabel(_ hour: Int) -> String { "Hour: \(hour)" }
  private static func minuteLabel(_ minute: Int) -> String { String(format: "Minute: %02d", minute) }

  // MARK: - Picking

  /// `day`'s date with the selection's time of day.
  private func pick(day: Date) {
    let calendar = Calendar.current
    var parts = calendar.dateComponents([.year, .month, .day], from: day)
    let time = calendar.dateComponents([.hour, .minute, .second], from: self.selection)
    (parts.hour, parts.minute, parts.second) = (time.hour, time.minute, time.second)
    guard let date = calendar.date(from: parts) else { return }
    self.report(date)
    if self.style == .compact { self.closePopover(animated: true) }
  }

  private func setTime(hour: Int?, minute: Int?) {
    let calendar = Calendar.current
    var parts = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: self.selection)
    if let hour { parts.hour = hour }
    if let minute { parts.minute = minute }
    parts.second = 0
    guard let date = calendar.date(from: parts) else { return }
    self.report(date)
  }

  private func report(_ date: Date) {
    guard !self.isDisabled, let report = self.onSelectionChange else { return }
    var date = date
    if let range = self.range { date = min(max(date, range.lowerBound), range.upperBound) }
    guard date != self.selection else { return }
    self.commit { report(date) }
  }

  // MARK: - Setters

  public func setSelection(_ value: Date, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    guard value != self.selection else { return }
    self.selection = value
    self.retitle(context)
    self.calendar?.setSelection(value, context)
    let parts = Calendar.current.dateComponents([.hour, .minute], from: value)
    if let hour = self.hourStepper, let value = parts.hour {
      hour.setValue(value, context)
      hour.setLabel(Self.hourLabel(value), context)
    }
    if let minute = self.minuteStepper, let value = parts.minute {
      minute.setValue(value, context)
      minute.setLabel(Self.minuteLabel(value), context)
    }
  }

  public func setDatePickerStyle(_ value: DatePickerStyle, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    guard value != self.style else { return }
    self.style = value
    self.rebuild(animation)
  }

  /// Built in `style`: `.datePickerStyle(.graphical)`. Sets this picker's own style and returns it.
  public func datePickerStyle(_ style: DatePickerStyle) -> Self {
    if style != self.style {
      self.style = style
      self.rebuild(nil)
    }
    return self
  }

  public func setLabel(_ value: String, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    guard value != self.label.text else { return }
    self.label.setText(value, context, animation: animation)
  }
}

/// A month of days to pick one from: a title with ‹ › to change month, the weekdays, and a
/// 6 × 7 grid of days. The grid's 42 cells are built once; changing month relabels them.
final class CalendarView : SingleChildElement {
  static let cellSize = float2(32, 28)
  static let titleFont = TextFont.custom(FontManager.shared.font(named: "HelveticaNeue-Medium"), size: 14)
  static let dayFont = TextFont.custom(FormMetrics.face, size: 13)

  private var selection: Date
  private let range: ClosedRange<Date>?
  private let onPick: (Date) -> Void
  /// The first day of the month shown.
  private var month: Date
  private let title = Text("").font(CalendarView.titleFont).foregroundColor(FormMetrics.labelColor)
  private var cells: [DayCell] = []
  private weak var context: UIContext?

  init(selection: Date, range: ClosedRange<Date>?, onPick: @escaping (Date) -> Void) {
    self.selection = selection
    self.range = range
    self.onPick = onPick
    self.month = Self.firstOfMonth(selection)
    super.init()

    let calendar = Calendar.current
    let symbols = calendar.veryShortStandaloneWeekdaySymbols
    let weekdays = HStack(spacing: 0)
    weekdays.applyContent((0 ..< 7).map { column in
      Text(symbols[(column + calendar.firstWeekday - 1) % 7])
        .font(CalendarView.dayFont).foregroundColor(FormMetrics.secondaryColor)
        .frame(width: Self.cellSize.x, height: 18)
    })
    let grid = VStack(spacing: 0)
    grid.applyContent((0 ..< 6).map { row in
      let week = HStack(spacing: 0)
      week.applyContent((0 ..< 7).map { column in
        let cell = DayCell()
        self.cells.append(cell)
        let index = row * 7 + column
        return HittableView(onTap: { [unowned self] _ in self.tapped(index) }) { cell }
      })
      return week
    })
    let previous = DisclosureChevron()
    previous.progress = 2   // turned to point left
    let next = DisclosureChevron()
    let title = self.title
    self.applyContent([
      VStack(alignment: .leading, spacing: 6) {
        HStack(spacing: 10) {
          title
          Spacer()
          HittableView(onTap: { [unowned self] _ in self.showMonth(by: -1) }) { previous.padding(4) }
          HittableView(onTap: { [unowned self] _ in self.showMonth(by: 1) }) { next.padding(4) }
        }
        .padding(Inset(left: 6, right: 0))
        weekdays
        grid
      }
    ])
    self.relabel()
  }

  override func mount(_ context: UIContext) {
    self.context = context
  }

  override func unmount(_ context: UIContext) {
    self.context = nil
  }

  private static func firstOfMonth(_ date: Date) -> Date {
    let calendar = Calendar.current
    return calendar.date(from: calendar.dateComponents([.year, .month], from: date)) ?? date
  }

  /// The day each cell shows, from the week the month starts in.
  private func day(_ index: Int) -> Date {
    let calendar = Calendar.current
    let weekday = calendar.component(.weekday, from: self.month)
    let lead = (weekday - calendar.firstWeekday + 7) % 7
    return calendar.date(byAdding: .day, value: index - lead, to: self.month) ?? self.month
  }

  private func isPickable(_ day: Date) -> Bool {
    guard let range = self.range else { return true }
    let calendar = Calendar.current
    let start = calendar.startOfDay(for: range.lowerBound)
    return day >= start && day <= range.upperBound
  }

  /// Every cell's number and look, for the month and selection.
  private func relabel() {
    let calendar = Calendar.current
    let context = self.context
    let title = self.month.formatted(.dateTime.month(.wide).year())
    if let context, title != self.title.text { self.title.setText(title, context) } else if context == nil { self.title.text = title }
    let today = Date()
    for (index, cell) in self.cells.enumerated() {
      let day = self.day(index)
      cell.update(
        number: calendar.component(.day, from: day),
        inMonth: calendar.isDate(day, equalTo: self.month, toGranularity: .month),
        selected: calendar.isDate(day, inSameDayAs: self.selection),
        today: calendar.isDate(day, inSameDayAs: today),
        pickable: self.isPickable(day),
        context
      )
    }
  }

  private func showMonth(by months: Int) {
    guard let month = Calendar.current.date(byAdding: .month, value: months, to: self.month) else { return }
    self.month = month
    self.relabel()
  }

  private func tapped(_ index: Int) {
    let day = self.day(index)
    guard self.isPickable(day) else { return }
    self.onPick(day)
  }

  func setSelection(_ value: Date, _ context: UIContext) {
    self.selection = value
    if !Calendar.current.isDate(value, equalTo: self.month, toGranularity: .month) {
      self.month = Self.firstOfMonth(value)
    }
    self.relabel()
  }
}

/// One day in a calendar: its number, on an accent circle when selected, in the accent colour
/// when it is today, and faded when it is outside the month or cannot be picked.
final class DayCell : UIRenderableElement {
  private let number = Text("").font(CalendarView.dayFont)
  private(set) var position: float2 = .zero
  private var selected = false

  override init() {
    super.init()
    self.applyContent([self.number])
  }

  override func mount(_ context: UIContext) {
    context.registerRenderableView(self)
  }

  override func unmount(_ context: UIContext) {
    context.unregisterRenderableView(self)
  }

  func update(number: Int, inMonth: Bool, selected: Bool, today: Bool, pickable: Bool, _ context: UIContext?) {
    let text = "\(number)"
    let color: float4 = selected ? .white
      : !pickable ? FormMetrics.labelColor.withAlpha(0.2)
      : today ? FormMetrics.accentColor
      : inMonth ? FormMetrics.labelColor : FormMetrics.labelColor.withAlpha(0.35)
    if let context {
      if text != self.number.text { self.number.setText(text, context) }
      self.number.setForegroundColor(color, context)
      if selected != self.selected { context.invalidate() }
    } else {
      self.number.text = text
      _ = self.number.foregroundColor(color)
    }
    self.selected = selected
  }

  override func getSize() -> float2 {
    CalendarView.cellSize
  }

  override func sizeThatFits(_ proposal: ProposedSize) -> float2 {
    CalendarView.cellSize
  }

  override func calcSize(_ proposal: ProposedSize) -> float2 {
    _ = self.number.calcSize(.unspecified)
    return CalendarView.cellSize
  }

  // The number centred.
  override func calcPosition(_ position: float2) {
    self.position = position
    self.number.calcPosition(position + (CalendarView.cellSize - self.number.getSize()) * 0.5)
  }

  override func render(_ renderer: Graphics2D, _ effect: EffectState) {
    guard self.selected, effect.opacity > 0 else { return }
    let s = effect.scale
    let diameter = (CalendarView.cellSize.y - 2) * s
    let center = effect.apply(to: self.position + CalendarView.cellSize * 0.5) - renderer.size * 0.5
    var fill = FormMetrics.accentColor
    fill.w *= effect.opacity
    renderer.draw(
      roundedRect: center - diameter * 0.5, size: float2(repeating: diameter),
      radii: float4(repeating: diameter * 0.5), color: fill
    )
  }
}
