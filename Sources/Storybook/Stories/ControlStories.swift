import MetalGraphicsLib
import simd

enum ControlStories {
  static let all: [ComponentStories] = [
    button, toggle, textField, secureField, picker, slider, progressView, stepper, toggleChip, disclosureGroup, labeledContent,
  ]

  static let buttonStyles = ["bordered", "borderedProminent", "borderless", "plain"]

  static func buttonStyle(_ name: String) -> ButtonStyle {
    switch name {
    case "borderedProminent": .borderedProminent
    case "borderless": .borderless
    case "plain": .plain
    default: .bordered
    }
  }

  static let button = ComponentStories(
    .controls, "Button", summary: "A button in one of four styles; a role tints it. Every state from the Components board: rest, hover, pressed, disabled, focus.",
    source: "Sources/MetalGraphicsLib/RetainedModeUI/Form/Button.swift",
    args: [
      ArgType("title", .text, .text("Save"), "Its label."),
      ArgType("style", .options(["all"] + buttonStyles), .option("bordered"), "How it is drawn; all shows each."),
      ArgType("role", .options(["none", "destructive", "cancel"]), .option("none"), "What it does, which tints it."),
      ArgType("disabled", .bool, .bool(false), "Greyed, and it takes no clicks."),
    ],
    stories: [
      Story("Styles", layout: .padded, ["style": .option("all")]),
      Story("Bordered"),
      Story("Prominent", ["style": .option("borderedProminent")]),
      Story("Destructive", ["role": .option("destructive"), "title": .text("Delete")]),
      Story("Disabled", ["disabled": .bool(true)]),
    ],
    render: { args, context in
      let make = { (style: String) -> UIElement in
        let role: ButtonRole? = switch args.option("role") {
        case "destructive": .destructive
        case "cancel": .cancel
        default: nil
        }
        return Button(args.string("title"), role: role, action: context.action("tapped \(args.string("title"))"))
          .buttonStyle(Self.buttonStyle(style))
          .disabled(args.bool("disabled"))
      }
      guard args.option("style") == "all" else { return make(args.option("style")) }
      return gallery(columns: 4, spacing: 16, Self.buttonStyles.map { style in
        VStack(spacing: 6) {
          make(style)
          caption(".\(style)")
        }
      })
    },
    snippet: { args in
      let role = args.option("role") == "none" ? "" : ", role: .\(args.option("role"))"
      let style = args.option("style") == "all" ? "bordered" : args.option("style")
      return "Button(\(swiftString(args.string("title")))\(role)) { save() }\n  .buttonStyle(.\(style))" + (args.bool("disabled") ? "\n  .disabled(true)" : "")
    }
  )

  static let toggle = ComponentStories(
    .controls, "Toggle", summary: "A switch with a label; a click anywhere on the row flips it.",
    source: "Sources/MetalGraphicsLib/RetainedModeUI/Form/Toggle.swift",
    args: [
      ArgType("label", .text, .text("Show line numbers"), "Its label."),
      ArgType("isOn", .bool, .bool(true), "On or off: a binding."),
      ArgType("disabled", .bool, .bool(false), "Greyed, and it takes no clicks."),
    ],
    stories: [Story("On"), Story("Off", ["isOn": .bool(false)]), Story("Disabled", ["disabled": .bool(true)])],
    render: { args, context in
      Toggle(args.string("label"), isOn: context.bool("isOn")).disabled(args.bool("disabled")).frame(width: 300)
    },
    snippet: { args in "Toggle(\(swiftString(args.string("label"))), isOn: $isOn)" }
  )

  static let textField = ComponentStories(
    .controls, "TextField", summary: "One line of text: a label beside it in a form, a prompt while empty, an icon before it.",
    source: "Sources/MetalGraphicsLib/RetainedModeUI/Form/TextField.swift",
    args: [
      ArgType("label", .text, .text(""), "Its label, beside it in a form."),
      ArgType("text", .text, .text(""), "Its text: a binding."),
      ArgType("prompt", .text, .text("Search"), "What shows while it is empty."),
      ArgType("icon", .options(["none"] + iconNames), .option("magnifier"), "A glyph before the text."),
      ArgType("disabled", .bool, .bool(false), "Greyed, and it takes no keys."),
    ],
    stories: [
      Story("Search"),
      Story("Filled", ["text": .text("Greeter.swift")]),
      Story("In a form", ["label": .text("Name"), "prompt": .text("Required"), "icon": .option("none")]),
      Story("Disabled", ["disabled": .bool(true), "text": .text("Read only")]),
    ],
    render: { args, context in
      let field = TextField(args.string("label"), text: context.text("text"), prompt: args.string("prompt"))
      if let icon = ThemeIcon.allCases.first(where: { "\($0)" == args.option("icon") }) { _ = field.leadingIcon(icon) }
      return field.disabled(args.bool("disabled")).frame(width: args.string("label").isEmpty ? 240 : 420)
    },
    snippet: { args in
      "TextField(\(swiftString(args.string("label"))), text: $text, prompt: \(swiftString(args.string("prompt"))))"
        + (args.option("icon") == "none" ? "" : "\n  .leadingIcon(.\(args.option("icon")))")
    }
  )

  static let secureField = ComponentStories(
    .controls, "SecureField", summary: "A text field that shows dots.",
    source: "Sources/MetalGraphicsLib/RetainedModeUI/Form/TextField.swift",
    args: [
      ArgType("label", .text, .text("Password"), "Its label."),
      ArgType("text", .text, .text("hunter2"), "Its text: a binding."),
      ArgType("prompt", .text, .text("At least 8 characters"), "What shows while it is empty."),
    ],
    stories: [Story("Filled"), Story("Empty", ["text": .text("")])],
    render: { args, context in
      SecureField(args.string("label"), text: context.text("text"), prompt: args.string("prompt")).frame(width: 420)
    },
    snippet: { args in "SecureField(\(swiftString(args.string("label"))), text: $password, prompt: \(swiftString(args.string("prompt"))))" }
  )

  static let picker = ComponentStories(
    .controls, "Picker", summary: "One option of several: a menu, segments, or an inline list with a check.",
    source: "Sources/MetalGraphicsLib/RetainedModeUI/Form/Picker.swift",
    args: [
      ArgType("label", .text, .text("Theme"), "Its label."),
      ArgType("options", .lines, .text("System, Light, Dark"), "The options, by commas."),
      ArgType("selection", .text, .text("System"), "The option picked: a binding."),
      ArgType("style", .options(["menu", "segmented", "inline"]), .option("menu"), "How the options show."),
      ArgType("chevrons", .bool, .bool(true), "The menu style's ⌃⌄; off, a plain pill."),
    ],
    stories: [
      Story("Menu"),
      Story("Segmented", ["label": .text("Indent with"), "options": .text("Spaces, Tabs"), "selection": .text("Spaces"), "style": .option("segmented")]),
      Story("Inline", ["style": .option("inline")]),
      Story("Pill", ["label": .text(""), "options": .text("Oct 1, 2026"), "selection": .text("Oct 1, 2026"), "chevrons": .bool(false)]),
    ],
    render: { args, context in
      let options = args.lines("options")
      let picker = Picker(args.string("label"), selection: context.text("selection"), content: {
        return options.map { Text($0).tag($0) as UIElement }
      })
      let style: PickerStyle = switch args.option("style") {
      case "segmented": .segmented
      case "inline": .inline
      default: .menu
      }
      return picker.pickerStyle(style).menuIndicator(args.bool("chevrons") ? .automatic : .hidden)
        .frame(width: args.string("label").isEmpty ? nil : 360)
    },
    snippet: { args in
      var lines = ["Picker(\(swiftString(args.string("label"))), selection: $selection) {"]
      lines += args.lines("options").map { "  Text(\(swiftString($0))).tag(\(swiftString($0)))" }
      lines.append("}")
      if args.option("style") != "menu" { lines.append(".pickerStyle(.\(args.option("style")))") }
      if !args.bool("chevrons") { lines.append(".menuIndicator(.hidden)") }
      return lines.joined(separator: "\n")
    }
  )

  static let slider = ComponentStories(
    .controls, "Slider", summary: "A value in a range, dragged along a track.",
    source: "Sources/MetalGraphicsLib/RetainedModeUI/Form/Slider.swift",
    args: [
      ArgType("label", .text, .text("Volume"), "Its label."),
      ArgType("value", .number(0 ... 1, step: 0.01), .number(0.6), "Its value: a binding."),
    ],
    stories: [Story("Default"), Story("Empty", ["value": .number(0)])],
    render: { args, context in Slider(args.string("label"), value: context.number("value"), in: 0 ... 1).frame(width: 360) },
    snippet: { args in "Slider(\(swiftString(args.string("label"))), value: $volume, in: 0 ... 1)" }
  )

  static let progressView = ComponentStories(
    .controls, "ProgressView", summary: "How far along something is.",
    source: "Sources/MetalGraphicsLib/RetainedModeUI/Form/Slider.swift",
    args: [ArgType("value", .number(0 ... 1, step: 0.01), .number(0.4), "Done, of 1.")],
    stories: [Story("Default"), Story("Done", ["value": .number(1)])],
    render: { args, _ in ProgressView(value: args.number("value")).frame(width: 300) },
    snippet: { args in "ProgressView(value: \(swiftNumber(args.number("value"))))" }
  )

  static let stepper = ComponentStories(
    .controls, "Stepper", summary: "− and + to change a number a step at a time.",
    source: "Sources/MetalGraphicsLib/RetainedModeUI/Form/Stepper.swift",
    args: [
      ArgType("label", .text, .text("Lives"), "Its label."),
      ArgType("value", .number(1 ... 9, step: 1), .number(3), "Its value: a binding."),
    ],
    stories: [Story("Default")],
    render: { args, context in
      let value = Binding<Int>(get: { Int(context.number("value").wrappedValue) }, set: { context.number("value").wrappedValue = Double($0) })
      return Stepper("\(args.string("label")): \(Int(args.number("value")))", value: value, in: 1 ... 9).frame(width: 300)
    },
    snippet: { args in "Stepper(\"\(args.string("label")): \\(lives)\", value: $lives, in: 1 ... 9)" }
  )

  static let toggleChip = ComponentStories(
    .controls, "ToggleChip", summary: "A small on/off chip: a find bar's Aa, Word, .* options.",
    source: "Sources/MetalGraphicsLib/RetainedModeUI/Form/ToggleChip.swift",
    args: [
      ArgType("title", .text, .text("Aa"), "Its label."),
      ArgType("isOn", .bool, .bool(true), "On or off: a binding."),
    ],
    stories: [Story("On"), Story("Off", ["isOn": .bool(false)])],
    render: { args, context in ToggleChip(args.string("title"), isOn: context.bool("isOn")) },
    snippet: { args in "ToggleChip(\(swiftString(args.string("title"))), isOn: $caseSensitive)" }
  )

  static let disclosureGroup = ComponentStories(
    .controls, "DisclosureGroup", summary: "A label that shows or hides what is under it.",
    source: "Sources/MetalGraphicsLib/RetainedModeUI/Form/DisclosureGroup.swift",
    args: [
      ArgType("label", .text, .text("Advanced"), "Its label."),
      ArgType("isExpanded", .bool, .bool(true), "Open or closed: a binding."),
    ],
    stories: [Story("Open"), Story("Closed", ["isExpanded": .bool(false)])],
    render: { args, context in
      DisclosureGroup(args.string("label"), isExpanded: context.bool("isExpanded")) {
        Toggle("Debug overlay", isOn: .constant(false))
        Toggle("Verbose logging", isOn: .constant(true))
      }
      .frame(width: 320)
    },
    snippet: { args in "DisclosureGroup(\(swiftString(args.string("label"))), isExpanded: $advanced) {\n  Toggle(\"Debug overlay\", isOn: $debug)\n}" }
  )

  static let labeledContent = ComponentStories(
    .controls, "LabeledContent", web: "FormRow", summary: "A label and a value, or any view, as a form row.",
    source: "Sources/MetalGraphicsLib/RetainedModeUI/Form/LabeledContent.swift",
    args: [
      ArgType("label", .text, .text("Signed in as"), "Its label."),
      ArgType("value", .text, .text("Ada"), "What it shows."),
    ],
    stories: [Story("Default")],
    render: { args, _ in LabeledContent(args.string("label"), value: args.string("value")).frame(width: 360) },
    snippet: { args in "LabeledContent(\(swiftString(args.string("label"))), value: \(swiftString(args.string("value"))))" }
  )
}
