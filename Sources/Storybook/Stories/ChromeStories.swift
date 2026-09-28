import Foundation
import MetalGraphicsLib
import simd

enum SurfaceStories {
  static let all: [ComponentStories] = [popover, menu, menuPanel, contextMenu, sheet, alert, confirmationDialog, tooltip, scrim]

  static let popover = ComponentStories(
    .surfaces, "Popover", summary: "A popover's card: glass, radius 10, a hairline and a shadow. .popover(isPresented:) shows one next to its anchor.",
    source: "Sources/MetalGraphicsLib/RetainedModeUI/Presentation/Surfaces.swift",
    args: [ArgType("text", .text, .text("A popover points at what shows it."), "What it says.")],
    stories: [Story("Card")],
    render: { args, _ in Popover { Text(args.string("text")).padding(14) } },
    snippet: { args in "Button(\"Info\") { showing = true }\n  .popover(isPresented: $showing) {\n    Text(\(swiftString(args.string("text")))).padding(14)\n  }" }
  )

  static let menu = ComponentStories(
    .surfaces, "Menu", summary: "A button that opens a menu of commands on menu glass; ↑ ↓ and Return choose, a click outside closes.",
    source: "Sources/MetalGraphicsLib/RetainedModeUI/Presentation/Menu.swift",
    args: [
      ArgType("title", .text, .text("Sort"), "The button's title."),
      ArgType("selection", .options(["Name", "Date", "Size"]), .option("Name"), "The checked item: a binding."),
    ],
    stories: [Story("Sort")],
    render: { args, context in
      Menu(args.string("title")) {
        MenuItem("Name", checked: args.option("selection") == "Name") { context.option("selection").wrappedValue = "Name" }
        MenuItem("Date", checked: args.option("selection") == "Date") { context.option("selection").wrappedValue = "Date" }
        MenuItem("Size", checked: args.option("selection") == "Size") { context.option("selection").wrappedValue = "Size" }
        MenuSeparator()
        MenuItem("Reverse Order", shortcut: "⌘R", action: context.action("reverse"))
      }
    },
    snippet: { args in
      "Menu(\(swiftString(args.string("title")))) {\n  MenuItem(\"Name\", checked: sort == .name) { sort = .name }\n  MenuItem(\"Date\", checked: sort == .date) { sort = .date }\n  MenuSeparator()\n  MenuItem(\"Reverse Order\", shortcut: \"⌘R\") { reverse() }\n}"
    }
  )

  static let menuPanel = ComponentStories(
    .surfaces, "MenuPanel", web: "Menu", summary: "An open menu in place: items with checks and shortcuts, separators, a destructive and a disabled item.",
    source: "Sources/MetalGraphicsLib/RetainedModeUI/Presentation/Menu.swift",
    args: [
      ArgType("minimap", .bool, .bool(true), "The checked item: a binding."),
      ArgType("width", .number(140 ... 320, step: 10), .number(220), "Its width."),
    ],
    stories: [Story("Edit")],
    render: { args, context in
      MenuPanel(width: args.float("width")) {
        MenuItem("Cut", shortcut: "⌘X", action: context.action("cut"))
        MenuItem("Copy", shortcut: "⌘C", action: context.action("copy"))
        MenuItem("Paste", shortcut: "⌘V", action: context.action("paste"))
        MenuSeparator()
        MenuItem("Show Minimap", checked: args.bool("minimap")) { context.bool("minimap").wrappedValue.toggle() }
        MenuSeparator()
        MenuItem("Delete", role: .destructive, action: context.action("delete"))
        MenuItem("Rename…", disabled: true)
      }
    },
    snippet: { _ in "MenuPanel {\n  MenuItem(\"Cut\", shortcut: \"⌘X\") { cut() }\n  MenuSeparator()\n  MenuItem(\"Delete\", role: .destructive) { delete() }\n}" }
  )

  static let contextMenu = ComponentStories(
    .surfaces, "ContextMenu", summary: ".contextMenu { … }: a right click opens a menu under the element; a left click still taps.",
    source: "Sources/MetalGraphicsLib/RetainedModeUI/Presentation/Menu.swift",
    args: [],
    stories: [Story("On a row")],
    render: { _, context in
      ListRow("Right-click me", action: context.action("tapped"), content: { Image(icon: .document).foregroundColor(.hue(.orange)) })
        .contextMenu {
          MenuItem("Open", action: context.action("open"))
          MenuItem("Rename…", action: context.action("rename"))
          MenuSeparator()
          MenuItem("Move to Trash", role: .destructive, action: context.action("trash"))
        }
        .frame(width: 260)
    },
    snippet: { _ in "row.contextMenu {\n  MenuItem(\"Open\") { open() }\n  MenuSeparator()\n  MenuItem(\"Move to Trash\", role: .destructive) { trash() }\n}" }
  )

  static let sheet = ComponentStories(
    .surfaces, "Sheet", summary: "A sheet's card: title, content and actions on sheet glass, radius 12. In a .sheet, use SheetLayout for the same layout.",
    source: "Sources/MetalGraphicsLib/RetainedModeUI/Presentation/Surfaces.swift",
    args: [
      ArgType("title", .text, .text("Go to Line"), "Its title."),
      ArgType("width", .number(240 ... 560, step: 20), .number(320), "Its width."),
    ],
    stories: [Story("Go to line")],
    render: { args, context in
      Sheet(title: args.string("title"), width: args.float("width")) {
        TextField("", text: .constant("12"), prompt: "Line, or line:column")
      } actions: {
        Button("Cancel", role: .cancel, action: context.action("cancel"))
        Button("Go", action: context.action("go")).buttonStyle(.borderedProminent)
      }
    },
    snippet: { args in
      ".sheet(isPresented: $goingToLine) {\n  SheetLayout(title: \(swiftString(args.string("title")))) {\n    TextField(\"\", text: $line, prompt: \"Line\")\n  } actions: {\n    Button(\"Cancel\", role: .cancel) { … }\n    Button(\"Go\") { … }.buttonStyle(.borderedProminent)\n  }\n}"
    }
  )

  static let alert = ComponentStories(
    .surfaces, "Alert", summary: "An alert's card: title, message and actions. The first without a role is prominent; two sit side by side, cancel left; more stack, cancel last.",
    source: "Sources/MetalGraphicsLib/RetainedModeUI/Presentation/Surfaces.swift",
    args: [
      ArgType("title", .text, .text("Delete “Notes”?"), "Its title."),
      ArgType("message", .text, .text("This can’t be undone."), "Under the title."),
      ArgType("actions", .options(["two", "three"]), .option("two"), "How many actions."),
      ArgType("layout", .options(["automatic", "row", "stack"]), .option("automatic"), "Side by side or stacked."),
    ],
    stories: [Story("Two actions"), Story("Three actions", ["title": .text("Save changes to “Greeter.swift”?"), "message": .text("Your changes will be lost if you don’t save them."), "actions": .option("three")])],
    render: { args, context in
      let layout: AlertLayout = switch args.option("layout") {
      case "row": .row
      case "stack": .stack
      default: .automatic
      }
      if args.option("actions") == "three" {
        return Alert(args.string("title"), message: args.string("message"), layout: layout) {
          Button("Save", action: context.action("save"))
          Button("Don’t Save", role: .destructive, action: context.action("don't save"))
          Button("Cancel", role: .cancel, action: context.action("cancel"))
        }
      }
      return Alert(args.string("title"), message: args.string("message"), layout: layout) {
        Button("Cancel", role: .cancel, action: context.action("cancel"))
        Button("Delete", role: .destructive, action: context.action("delete"))
      }
    },
    snippet: { args in
      ".alert(\(swiftString(args.string("title"))), isPresented: $confirming) {\n  Button(\"Cancel\", role: .cancel) {}\n  Button(\"Delete\", role: .destructive) { delete() }\n} message: {\n  Text(\(swiftString(args.string("message"))))\n}"
    }
  )

  static let confirmationDialog = ComponentStories(
    .surfaces, "ConfirmationDialog", summary: "Choices stacked at full width, with Cancel added when none is given.",
    source: "Sources/MetalGraphicsLib/RetainedModeUI/Presentation/Surfaces.swift",
    args: [
      ArgType("title", .text, .text("Discard the draft?"), "Its title."),
      ArgType("titleVisible", .bool, .bool(true), "Whether the title shows."),
    ],
    stories: [Story("Discard")],
    render: { args, context in
      ConfirmationDialog(args.string("title"), message: "You can’t undo this.", titleVisible: args.bool("titleVisible")) {
        Button("Discard Draft", role: .destructive, action: context.action("discard"))
        Button("Save Draft", action: context.action("save"))
      }
    },
    snippet: { args in ".confirmationDialog(\(swiftString(args.string("title"))), isPresented: $asking, titleVisibility: .\(args.bool("titleVisible") ? "visible" : "hidden")) {\n  Button(\"Discard Draft\", role: .destructive) { discard() }\n}" }
  )

  static let tooltip = ComponentStories(
    .surfaces, "Tooltip", summary: "A small label on tooltip glass; multiline, a hover card of up to 420 points.",
    source: "Sources/MetalGraphicsLib/RetainedModeUI/Presentation/Tooltip.swift",
    args: [
      ArgType("text", .text, .text("Build and run (⌘R)"), "What it says."),
      ArgType("multiline", .bool, .bool(false), "A hover card: several lines, wrapped at 420."),
    ],
    stories: [
      Story("One line"),
      Story("Hover card", ["text": .text("let greeting: String\nThe text to print, made by a Greeter from its name."), "multiline": .bool(true)]),
    ],
    render: { args, _ in Tooltip(args.string("text").replacingOccurrences(of: "\\n", with: "\n"), multiline: args.bool("multiline")) },
    snippet: { args in "Tooltip(\(swiftString(args.string("text")))\(args.bool("multiline") ? ", multiline: true" : ""))" }
  )

  static let scrim = ComponentStories(
    .surfaces, "Scrim", summary: "What dims a window behind a sheet or an alert.",
    source: "Sources/MetalGraphicsLib/RetainedModeUI/Presentation/Surfaces.swift",
    args: [],
    stories: [Story("Over content", layout: .fullscreen)],
    render: { _, _ in
      ZStack {
        VStack(alignment: .leading, spacing: 8) {
          Text("Content under the scrim").font(.system(size: 15, weight: .semibold))
          Text("A sheet or an alert dims what is behind it.").foregroundColor(.secondaryLabel)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        Scrim {
          Text("Sheet").padding(40).background(.card, in: .rect(cornerRadius: 12))
        }
      }
    },
    snippet: { _ in "Scrim {\n  sheetContent\n}" }
  )
}

enum NavigationStories {
  static let all: [ComponentStories] = [sidebarTitle, splitView]

  static let sidebarTitle = ComponentStories(
    .navigation, "SidebarTitle", web: "Sidebar", summary: "The small heading over a sidebar's links.",
    source: "Sources/MetalGraphicsLib/RetainedModeUI/Navigation/Sidebar.swift",
    args: [ArgType("title", .text, .text("Demos"), "What it says.")],
    stories: [Story("With links", layout: .padded)],
    render: { args, _ in
      VStack(alignment: .leading, spacing: 0) {
        SidebarTitle(args.string("title"))
        ListRow("Conditional", height: NavigationMetrics.sidebarRowHeight, margin: 0)
        ListRow("Form", selected: true, height: NavigationMetrics.sidebarRowHeight, margin: 0)
        ListRow("Docking", height: NavigationMetrics.sidebarRowHeight, margin: 0)
      }
      .padding(Inset(vertical: 8, horizontal: NavigationMetrics.sidebarInset))
      .frame(width: NavigationMetrics.sidebarWidth, alignment: .leading)
      .background(.sidebarTint)
    },
    snippet: { args in "SidebarTitle(\(swiftString(args.string("title"))))" }
  )

  enum Mailbox : String, Hashable, CaseIterable { case inbox = "Inbox", sent = "Sent", archive = "Archive" }

  static let splitView = ComponentStories(
    .navigation, "NavigationSplitView", summary: "A sidebar beside a detail column: value links select, the detail shows the selection's destination under a navigation bar.",
    source: "Sources/MetalGraphicsLib/RetainedModeUI/Navigation/NavigationSplitView.swift",
    args: [],
    stories: [Story("Mail", layout: .fullscreen)],
    render: { _, _ in
      NavigationSplitView {
        SidebarTitle("Mailboxes")
        NavigationLink("Inbox", value: Mailbox.inbox)
        NavigationLink("Sent", value: Mailbox.sent)
        NavigationLink("Archive", value: Mailbox.archive)
          .navigationDestination(for: Mailbox.self) { box in
            Text("No messages in \(box.rawValue)")
              .foregroundColor(.secondaryLabel)
              .frame(maxWidth: .infinity, maxHeight: .infinity)
              .navigationTitle(box.rawValue)
          }
      } detail: {
        Text("Select a mailbox").foregroundColor(.secondaryLabel)
      }
      .frame(height: 360)
    },
    snippet: { _ in
      "NavigationSplitView {\n  NavigationLink(\"Inbox\", value: Mailbox.inbox)\n    .navigationDestination(for: Mailbox.self) { box in MailboxView(box) }\n} detail: {\n  Text(\"Select a mailbox\")\n}"
    }
  )
}

enum DockingStories {
  static let all: [ComponentStories] = [dockGap]

  static let dockGap = ComponentStories(
    .docking, "DockGap", summary: "The 1 pt line between two docked panes.",
    source: "Sources/MetalGraphicsLib/RetainedModeUI/Docking/DockChrome.swift",
    args: [ArgType("vertical", .bool, .bool(true), "Between panes side by side, or one over the other.")],
    stories: [Story("Between panes")],
    render: { args, _ in
      let pane = { (title: String) -> UIElement in
        Text(title).foregroundColor(.secondaryLabel).frame(width: 140, height: 90).background(.contentBackground)
      }
      if args.bool("vertical") {
        return HStack(spacing: 0) { pane("Outline"); DockGap(vertical: true).frame(height: 90); pane("Editor") }
      }
      return VStack(spacing: 0) { pane("Editor"); DockGap(vertical: false).frame(width: 140); pane("Console") }
    },
    snippet: { args in "DockGap(vertical: \(args.bool("vertical")))" }
  )
}

enum EditorStories {
  static let all: [ComponentStories] = [codeEditor, findBar, completionList, statusBar]

  static let sampleCode = """
  struct Greeter {
    var name: String

    var greeting: String { "Hello, \\(name)!" }
  }

  let greeting = Greeter(name: "World").greeting
  print(greeting)
  """

  static let codeEditor = ComponentStories(
    .editor, "CodeEditor", web: "CodeEditor", summary: "TextEditor: styled, editable code with line numbers, the current line, brackets and search matches, in the theme's editor colours.",
    source: "Sources/MetalGraphicsLib/RetainedModeUI/TextEditor/View/TextEditor.swift",
    args: [
      ArgType("lineNumbers", .bool, .bool(true), "The gutter's numbers."),
      ArgType("search", .text, .text("greeting"), "Matches highlighted."),
      ArgType("editable", .bool, .bool(true), "Whether it takes typing."),
    ],
    stories: [Story("Swift", layout: .padded)],
    render: { args, _ in
      TextEditor(document: TextDocument(EditorStories.sampleCode))
        .styler(SwiftStyler())
        .lineNumbers(args.bool("lineNumbers"))
        .bracketMatching(true)
        .searchQuery(args.string("search"))
        .editable(args.bool("editable"))
        .frame(width: 560, height: 200)
        .border(.separator, width: 0.5, in: .rect(cornerRadius: 6))
    },
    snippet: { args in
      "TextEditor(document: document)\n  .styler(SwiftStyler())\n  .lineNumbers(\(args.bool("lineNumbers")))\n  .searchQuery(\(swiftString(args.string("search"))))"
    }
  )

  static let findBar = ComponentStories(
    .editor, "FindBar", summary: "An editor's find and replace bar: query, count, ‹ ›, Aa / Word / .*, the replacement with Replace and All, and Done.",
    source: "Sources/MetalGraphicsLib/RetainedModeUI/TextEditor/Chrome/FindBar.swift",
    args: [
      ArgType("query", .text, .text("blurRadius"), "What it finds: a binding."),
      ArgType("replacement", .text, .text("radius"), "What it replaces with: a binding."),
      ArgType("count", .text, .text("4 of 8"), "The match count."),
      ArgType("caseSensitive", .bool, .bool(true), "Aa."),
      ArgType("wholeWord", .bool, .bool(false), "Word."),
      ArgType("regex", .bool, .bool(false), ".*"),
      ArgType("showReplace", .bool, .bool(true), "The replace half."),
    ],
    stories: [
      Story("Find and replace", layout: .padded),
      Story("No results", layout: .padded, ["query": .text("glass\\w+Tint"), "count": .text("No results"), "regex": .bool(true), "caseSensitive": .bool(false), "showReplace": .bool(false)]),
    ],
    render: { args, context in
      FindBar(
        query: context.text("query"), replacement: context.text("replacement"), count: args.string("count"),
        caseSensitive: context.bool("caseSensitive"), wholeWord: context.bool("wholeWord"), regex: context.bool("regex"),
        showReplace: args.bool("showReplace"),
        onNext: context.action("next"), onPrevious: context.action("previous"), onReplace: context.action("replace"),
        onReplaceAll: context.action("replace all"), onDone: context.action("done")
      )
      .frame(width: 820)
    },
    snippet: { args in
      "FindBar(\n  query: $query, replacement: $replacement, count: \(swiftString(args.string("count"))),\n  caseSensitive: $caseSensitive, wholeWord: $wholeWord, regex: $regex,\n  showReplace: \(args.bool("showReplace")),\n  onNext: { findNext() }, onDone: { closeFind() }\n)"
    }
  )

  static let completionList = ComponentStories(
    .editor, "CompletionList", summary: "The completion popup on menu glass: a row per candidate with its kind, name and type, and the selected one's detail.",
    source: "Sources/MetalGraphicsLib/RetainedModeUI/TextEditor/Chrome/CompletionList.swift",
    args: [
      ArgType("items", .lines, .text("M print(_:) Void, M precondition(_:) Void, K private, P count Int, S Greeter"), "Candidates: badge, name and type, by commas."),
      ArgType("selected", .number(0 ... 9, step: 1), .number(0), "Which row is selected."),
      ArgType("footer", .text, .text("func print(_ items: Any...)"), "The line under the rows."),
    ],
    stories: [Story("Candidates")],
    render: { args, context in
      let selected = Int(args.number("selected"))
      let items = args.lines("items").enumerated().map { index, line -> CompletionItem in
        let parts = line.split(separator: " ").map(String.init)
        return CompletionItem(
          id: "\(index)\(index == selected ? "*" : "")", label: parts.count > 1 ? parts[1] : line,
          detail: parts.count > 2 ? parts[2...].joined(separator: " ") : "", badge: parts.first ?? "K",
          isSelected: index == selected, index: index
        )
      }
      return CompletionList(items: items, footer: args.string("footer"), onPick: context.action("picked", Int.self))
    },
    snippet: { args in "CompletionList(items: items, footer: \(swiftString(args.string("footer")))) { index in accept(index) }" }
  )

  static let statusBar = ComponentStories(
    .editor, "StatusBar", summary: "The line under an editor: the caret's place, a problem, and the file.",
    source: "Sources/MetalGraphicsLib/RetainedModeUI/TextEditor/Chrome/StatusBar.swift",
    args: [
      ArgType("position", .text, .text("Ln 4, Col 36"), "Where the caret is."),
      ArgType("problem", .text, .text(""), "What went wrong, in red."),
      ArgType("file", .text, .text("Greeter.swift"), "The file's name."),
    ],
    stories: [Story("Default", layout: .padded), Story("Problem", layout: .padded, ["problem": .text("The file changed on disk.")])],
    render: { args, _ in
      StatusBar(position: args.string("position"), problem: args.string("problem"), file: args.string("file")).frame(width: 560)
    },
    snippet: { args in
      "StatusBar(position: \(swiftString(args.string("position"))), problem: \(swiftString(args.string("problem"))), file: \(swiftString(args.string("file"))))"
    }
  )
}
