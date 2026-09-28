import Foundation
import MetalGraphicsLib
import simd

enum SurfaceStories {
  static let all: [ComponentStories] = [tooltip, scrim]

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
