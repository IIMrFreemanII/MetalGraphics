import Foundation
import MetalGraphicsLib
import simd

enum PickerStories {
  static let all: [ComponentStories] = [colorPicker, colorWell, colorPickerPanel, datePicker, calendarView, timePanel]

  /// A popover's card around `content`, as a picker shows it open.
  static func card(_ content: UIElement) -> UIElement {
    Popover { content }
  }

  static let colorWell = ComponentStories(
    .pickers, "ColorWell", summary: "A colour on a rounded well, 44 × 24, over a checkerboard when translucent.",
    source: "Sources/MetalGraphicsLib/RetainedModeUI/Form/ColorPicker.swift",
    args: [ArgType("color", .color, .color(SIMD4<Float>(0.19, 0.69, 0.78, 1)), "The colour.")],  // design: a colour picker edits a plain colour
    stories: [Story("Opaque"), Story("Translucent", ["color": .color(SIMD4<Float>(1, 0.23, 0.19, 0.4))])],  // design: a colour picker edits a plain colour
    render: { args, _ in ColorWell(args.color("color")) },
    snippet: { args in "ColorWell(float4\(StoryValue.color(args.color("color")).display))" }
  )

  static let colorPickerPanel = ComponentStories(
    .pickers, "ColorPickerPanel", summary: "What a colour well opens: the swatch grid, the selection ringed, and hue, saturation, brightness and opacity sliders.",
    source: "Sources/MetalGraphicsLib/RetainedModeUI/Form/ColorPicker.swift",
    args: [
      ArgType("selection", .color, .color(ColorPickerPanel.palette[1][7]), "The colour: a binding."),
      ArgType("supportsOpacity", .bool, .bool(true), "The opacity slider."),
    ],
    stories: [Story("Open")],
    render: { args, context in
      card(ColorPickerPanel(selection: args.color("selection"), supportsOpacity: args.bool("supportsOpacity")) { color in
        context.color("selection").wrappedValue = color
      })
    },
    snippet: { args in "ColorPickerPanel(selection: tint, supportsOpacity: \(args.bool("supportsOpacity"))) { color in tint = color }" }
  )

  static let calendarView = ComponentStories(
    .pickers, "CalendarView", summary: "A month: title with ‹ ›, weekdays and six weeks. The selection on an accent circle, today in the accent, other months faded.",
    source: "Sources/MetalGraphicsLib/RetainedModeUI/Form/DatePicker.swift",
    args: [
      ArgType("selection", .date, .date(StoryFixtures.due), "The day picked: a binding."),
      ArgType("limited", .bool, .bool(false), "Only today onwards can be picked."),
    ],
    stories: [Story("October"), Story("From today", ["limited": .bool(true), "selection": .date(StoryFixtures.now)])],
    render: { args, context in
      let range: ClosedRange<Date>? = args.bool("limited") ? StoryFixtures.now ... StoryFixtures.now.addingTimeInterval(60 * 86400) : nil
      return card(CalendarView(selection: args.date("selection"), in: range, today: StoryFixtures.now) { day in
        context.date("selection").wrappedValue = day
      }.frame(width: 7 * CalendarView.cellSize.x).padding(10))
    },
    snippet: { args in "CalendarView(selection: due\(args.bool("limited") ? ", in: Date() ... end" : "")) { day in due = day }" }
  )

  static let timePanel = ComponentStories(
    .pickers, "TimePanel", summary: "What a compact date picker's time pill opens: hour and minute steppers.",
    source: "Sources/MetalGraphicsLib/RetainedModeUI/Form/DatePicker.swift",
    args: [ArgType("selection", .date, .date(StoryFixtures.due), "The time: a binding.")],
    stories: [Story("Open")],
    render: { args, context in
      card(TimePanel(selection: args.date("selection")) { date in context.date("selection").wrappedValue = date })
    },
    snippet: { _ in "TimePanel(selection: due) { date in due = date }" }
  )

  static let colorPicker = ComponentStories(
    .pickers, "ColorPicker", summary: "A form row with a colour well; a click opens the swatch grid and hue, saturation, brightness and opacity sliders.",
    source: "Sources/MetalGraphicsLib/RetainedModeUI/Form/ColorPicker.swift",
    args: [
      ArgType("label", .text, .text("Tint"), "Its label."),
      ArgType("selection", .color, .color(SIMD4<Float>(0.0, 0.48, 1.0, 1)), "The colour: a binding."),  // design: a colour picker edits a plain colour
      ArgType("supportsOpacity", .bool, .bool(true), "Whether it has an opacity slider."),
    ],
    stories: [Story("Default"), Story("Translucent", ["selection": .color(SIMD4<Float>(0.2, 0.78, 0.35, 0.5))])],  // design: a colour picker edits a plain colour
    render: { args, context in
      ColorPicker(args.string("label"), selection: context.color("selection"), supportsOpacity: args.bool("supportsOpacity")).frame(width: 360)
    },
    snippet: { args in "ColorPicker(\(swiftString(args.string("label"))), selection: $tint, supportsOpacity: \(args.bool("supportsOpacity")))" }
  )

  static let datePicker = ComponentStories(
    .pickers, "DatePicker", summary: "A date and time: compact pills that open a calendar and time steppers, or the calendar in place.",
    source: "Sources/MetalGraphicsLib/RetainedModeUI/Form/DatePicker.swift",
    args: [
      ArgType("label", .text, .text("Due"), "Its label."),
      ArgType("selection", .date, .date(StoryFixtures.due), "The date: a binding."),
      ArgType("style", .options(["compact", "graphical"]), .option("compact"), "Pills, or the calendar in place."),
      ArgType("time", .bool, .bool(true), "Whether it picks the time too."),
    ],
    stories: [
      Story("Compact"),
      Story("Graphical", layout: .padded, ["style": .option("graphical"), "label": .text("Start"), "time": .bool(false)]),
    ],
    render: { args, context in
      let components: DatePicker.Components = args.bool("time") ? [.date, .hourAndMinute] : .date
      let picker = DatePicker(args.string("label"), selection: context.date("selection"), displayedComponents: components)
      return (args.option("style") == "graphical" ? picker.datePickerStyle(.graphical) : picker).frame(width: 380)
    },
    snippet: { args in
      "DatePicker(\(swiftString(args.string("label"))), selection: $due\(args.bool("time") ? "" : ", displayedComponents: .date"))"
        + (args.option("style") == "graphical" ? "\n  .datePickerStyle(.graphical)" : "")
    }
  )
}

enum ListStories {
  static let all: [ComponentStories] = [listRow, kindBadge, insertionLine, table]

  static let listRow = ComponentStories(
    .lists, "ListRow", summary: "A row of a sidebar, tree, outline or list: fixed height, inset, rounded highlight on hover and when selected. With a label, a subtitle, a detail and a status square.",
    source: "Sources/MetalGraphicsLib/RetainedModeUI/Layout/ListRow.swift",
    args: [
      ArgType("label", .text, .text("Greeter.swift"), "Its label."),
      ArgType("subtitle", .text, .text(""), "A second line under the label."),
      ArgType("detail", .text, .text(""), "At the trailing edge."),
      ArgType("status", .options(["none", "error", "warning", "note"]), .option("none"), "A square before it: a problem's severity."),
      ArgType("selected", .bool, .bool(false), "Highlighted."),
      ArgType("prominent", .bool, .bool(false), "Selected on the accent, as a menu's row."),
      ArgType("badge", .options(["none", "C", "S", "E", "P", "M", "V", "Pr"]), .option("none"), "A kind badge before the label."),
      ArgType("height", .number(20 ... 44, step: 2), .number(24), "24 in lists, 26 in a sidebar, 38 with a subtitle."),
      ArgType("indent", .number(0 ... 60, step: 2), .number(0), "How deep in a tree."),
    ],
    stories: [
      Story("File"),
      Story("Selected", ["selected": .bool(true)]),
      Story("Problem", ["label": .text("cannot find 'nam' in scope"), "subtitle": .text("Sources/App/Greeter.swift:4:36"), "status": .option("error"), "height": .number(38)]),
      Story("Completion", ["label": .text("print(_:)"), "detail": .text("Void"), "badge": .option("M"), "selected": .bool(true), "prominent": .bool(true), "height": .number(26)]),
      Story("Outline", ["label": .text("greeting"), "badge": .option("P"), "indent": .number(14)]),
    ],
    render: { args, context in
      let status: ListRowStatus? = switch args.option("status") {
      case "error": .error
      case "warning": .warning
      case "note": .note
      default: nil
      }
      let badge = args.option("badge")
      return ListRow(
        args.string("label"),
        subtitle: args.string("subtitle").isEmpty ? nil : args.string("subtitle"),
        detail: args.string("detail").isEmpty ? nil : args.string("detail"),
        status: status, selected: args.bool("selected"), selectionStyle: args.bool("prominent") ? .prominent : .standard,
        height: args.float("height"), indent: args.float("indent"), spacing: status == nil ? 6 : 10,
        action: context.action("tapped \(args.string("label"))"),
        content: { () -> [UIElement] in
          return badge == "none" ? [] : [KindBadge(badge, color: KindBadge.color(forLetter: badge))]
        }
      )
      .frame(width: 360)
    },
    snippet: { args in
      var parts = [swiftString(args.string("label"))]
      if !args.string("subtitle").isEmpty { parts.append("subtitle: \(swiftString(args.string("subtitle")))") }
      if !args.string("detail").isEmpty { parts.append("detail: \(swiftString(args.string("detail")))") }
      if args.option("status") != "none" { parts.append("status: .\(args.option("status"))") }
      if args.bool("selected") { parts.append("selected: true") }
      if args.bool("prominent") { parts.append("selectionStyle: .prominent") }
      if args.number("height") != 24 { parts.append("height: \(swiftNumber(args.number("height")))") }
      if args.number("indent") != 0 { parts.append("indent: \(swiftNumber(args.number("indent")))") }
      parts.append("action: { open() }")
      let badge = args.option("badge")
      return "ListRow(\(parts.joined(separator: ", "))" + (badge == "none" ? ")" : ", content: {\n  KindBadge(\"\(badge)\", color: KindBadge.color(forLetter: \"\(badge)\"))\n})")
    }
  )

  static let kindBadge = ComponentStories(
    .lists, "KindBadge", summary: "A symbol's kind as a small coloured tile with a letter.",
    source: "Sources/MetalGraphicsLib/RetainedModeUI/Layout/ListRow.swift",
    args: [ArgType("letter", .options(["all", "C", "S", "E", "P", "M", "V", "Pr", "K"]), .option("S"), "The kind; all shows each.")],
    stories: [Story("Struct"), Story("Every kind", layout: .padded, ["letter": .option("all")])],
    render: { args, _ in
      guard args.option("letter") == "all" else {
        return KindBadge(args.option("letter"), color: KindBadge.color(forLetter: args.option("letter")))
      }
      return gallery(columns: 8, ["C", "S", "E", "P", "M", "V", "Pr", "K"].map { letter in
        VStack(spacing: 6) {
          KindBadge(letter, color: KindBadge.color(forLetter: letter))
          caption(letter)
        }
      })
    },
    snippet: { args in
      let letter = args.option("letter") == "all" ? "S" : args.option("letter")
      return "KindBadge(\"\(letter)\", color: KindBadge.color(forLetter: \"\(letter)\"))"
    }
  )

  static let insertionLine = ComponentStories(
    .lists, "InsertionLine", summary: "Where a dragged row would land: a 2 pt accent capsule across the list.",
    source: "Sources/MetalGraphicsLib/RetainedModeUI/Layout/InsertionLine.swift",
    args: [ArgType("indent", .number(0 ... 40, step: 2), .number(8), "Leading inset.")],
    stories: [Story("Between rows")],
    render: { args, _ in
      VStack(alignment: .leading, spacing: 2) {
        ListRow("Outline")
        InsertionLine(indent: args.float("indent"))
        ListRow("Inspector")
      }
      .frame(width: 280)
    },
    snippet: { args in "InsertionLine(indent: \(swiftNumber(args.number("indent"))))" }
  )

  struct Person : Identifiable, Sendable {
    let id: Int
    let name: String
    let role: String
  }

  static let table = ComponentStories(
    .lists, "Table", summary: "Rows of columns with a header.",
    source: "Sources/MetalGraphicsLib/RetainedModeUI/Table/Table.swift",
    args: [ArgType("rows", .number(1 ... 12, step: 1), .number(5), "How many rows.")],
    stories: [Story("People", layout: .padded)],
    render: { args, _ in
      let names = ["Ada", "Grace", "Alan", "Edsger", "Barbara", "Donald", "Margaret", "Ken", "Dennis", "Niklaus", "John", "Frances"]
      let roles = ["Engineer", "Admiral", "Mathematician", "Professor", "Scientist", "Author"]
      let people = (0 ..< Int(args.number("rows"))).map { Person(id: $0, name: names[$0 % names.count], role: roles[$0 % roles.count]) }
      return Table(items: people) {
        TableColumn("Name", value: \Person.name)
        TableColumn("Role", value: \Person.role)
      }
      .frame(width: 420, height: 60 + Float(people.count) * 26)
    },
    snippet: { _ in "Table(items: people) {\n  TableColumn(\"Name\", value: \\.name)\n  TableColumn(\"Role\", value: \\.role)\n}" }
  )
}

enum FormStories {
  static let all: [ComponentStories] = [form]

  static let form = ComponentStories(
    .forms, "Form", summary: "Settings: a 600 pt column of outlined cards, one per Section, with a header and footer, on the grouped background.",
    source: "Sources/MetalGraphicsLib/RetainedModeUI/Form/Form.swift",
    args: [
      ArgType("header", .text, .text("Editor"), "The section's header."),
      ArgType("footer", .text, .text("Applies to every open file."), "The section's footer."),
      ArgType("lineNumbers", .bool, .bool(true), "A toggle's value: a binding."),
    ],
    stories: [Story("Settings", layout: .fullscreen)],
    render: { args, context in
      Form {
        Section {
          Toggle("Show line numbers", isOn: context.bool("lineNumbers"))
          Picker("Indent with", selection: "Spaces", content: {
            Text("Spaces").tag("Spaces")
            Text("Tabs").tag("Tabs")
          })
          .pickerStyle(.segmented)
          Stepper("Tab width: 2", value: .constant(2), in: 1 ... 8)
        } header: {
          Text(args.string("header"))
        } footer: {
          Text(args.string("footer"))
        }
        Section("Account") {
          TextField("Name", text: .constant(""), prompt: "Required")
          LabeledContent("Signed in as", value: "Guest")
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .background(.groupedBackground)
    },
    snippet: { args in
      "Form {\n  Section {\n    Toggle(\"Show line numbers\", isOn: $lineNumbers)\n  } header: {\n    Text(\(swiftString(args.string("header"))))\n  } footer: {\n    Text(\(swiftString(args.string("footer"))))\n  }\n}"
    }
  )
}
