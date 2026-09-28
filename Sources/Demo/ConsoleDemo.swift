import Foundation
import MetalGraphicsLib
import ReactiveUI
import simd

// A console: output above, a prompt below it. The history is read-only — it can be selected
// and copied, and typing there goes to the prompt instead — Return runs the line, ↑ and ↓ recall
// earlier ones, and the view keeps to the end as output arrives. Output is coloured by the
// tokens it is stored with. "count 100000" adds a hundred thousand lines at once.
@Component
final class ConsoleDemo : SingleChildElement {
  private static let captionFont = TextFont.system(size: 12)
  private static let captionColor: float4 = .secondaryLabel
  private static let font = TextFont.system(size: 12, design: .monospaced)
  private static let theme: EditorTheme = {
    var theme = EditorTheme.dark
    theme.currentLine = nil
    theme.lineSpacing = 2
    theme.textInset = float2(10, 8)
    return theme
  }()

  let session = ConsoleSession()

  @UIElementBuilder var body: [UIElement] {
    VStack(alignment: .leading, spacing: 8) {
      Text("Try help, echo, count 100000, error, time, clear. ↑ and ↓ recall what was typed.")
        .font(Self.captionFont)
        .foregroundColor(Self.captionColor)
      TextEditor(document: self.session.document)
        .editorTheme(Self.theme)
        .followsTail(true)
        .onCommand { command in self.session.handle(command) }
        .editFilter { transaction, state in self.session.filter(&transaction, state) }
        .onSelectionChange { selection in self.session.caret = selection.primary.head }
        .font(Self.font)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
  }
}

/// A console's text, and what it does with a line typed at its prompt.
final class ConsoleSession {
  static let prompt = "› "
  /// Lines kept: older ones are dropped from the top.
  static let scrollback = 200_000

  let document = TextDocument()
  /// Where the caret is, as the editor last reported it.
  var caret = 0
  private var history: [String] = []
  /// Which line of `history` is shown at the prompt, while ↑ and ↓ page through it.
  private var recalled: Int? = nil
  /// What was typed before ↑, brought back by ↓ past the last line.
  private var draft = ""
  /// The read-only mark over everything before the input.
  private var readOnly: Int? = nil

  init() {
    self.document.append("MetalGraphics console. Type help and press Return.\n", token: .success)
    self.showPrompt()
  }

  /// Where what is being typed starts: the end of the prompt.
  var inputStart: Int {
    self.readOnly.flatMap { self.document.readOnly.mark($0)?.range.upperBound } ?? 0
  }

  var input: String {
    self.document.substring(self.inputStart ..< self.document.length)
  }

  // MARK: - Editing

  /// The console's own commands: Return runs the line, ↑ and ↓ at the prompt recall.
  func handle(_ command: EditorCommand) -> Bool {
    switch command {
    case .insertNewline, .insertLineBreak:
      self.submit()
      return true
    case let .move(.visualLine, forward, false) where self.caret >= self.inputStart:
      self.recall(forward: forward)
      return true
    default:
      return false
    }
  }

  /// Typing in the history goes to the end of the input instead; deleting there is refused.
  func filter(_ transaction: inout EditorTransaction, _ state: EditorState) -> Bool {
    let start = self.inputStart
    guard transaction.changes.changes.contains(where: { $0.range.lowerBound < start }) else { return true }
    guard transaction.changes.changes.allSatisfy({ $0.range.isEmpty }) else { return false }
    let text = transaction.changes.changes.flatMap(\.text)
    let end = state.document.length
    transaction.changes = ChangeSet(TextChange(range: end ..< end, text: text))
    transaction.selection = .caret(end + text.count)
    return true
  }

  private func showPrompt() {
    self.document.append(Self.prompt, token: .prompt)
    self.protectAll()
  }

  /// Everything so far becomes read-only history.
  private func protectAll() {
    let all = 0 ..< self.document.length
    if let id = self.readOnly, self.document.readOnly.mark(id) != nil {
      self.document.readOnly.setRange(all, of: id)
    } else {
      self.readOnly = self.document.readOnly.add(all, ())
    }
  }

  func submit() {
    let line = self.input
    self.document.append("\n")
    self.protectAll()
    if !line.trimmingCharacters(in: .whitespaces).isEmpty {
      self.history.append(line)
    }
    self.recalled = nil
    self.run(line)
    self.trimScrollback()
    self.showPrompt()
  }

  private func recall(forward: Bool) {
    guard !self.history.isEmpty else { return }
    var index: Int
    if let recalled = self.recalled {
      index = recalled + (forward ? 1 : -1)
    } else {
      guard !forward else { return }
      self.draft = self.input
      index = self.history.count - 1
    }
    index = max(index, 0)
    let text: String
    if index >= self.history.count {
      self.recalled = nil
      text = self.draft
    } else {
      self.recalled = index
      text = self.history[index]
    }
    self.document.replace(self.inputStart ..< self.document.length, with: text)
  }

  private func trimScrollback() {
    let excess = self.document.lineCount - Self.scrollback
    guard excess > 0 else { return }
    self.document.replace(0 ..< self.document.lineStart(excess), with: "")
  }

  // MARK: - Commands

  private func out(_ text: String, _ token: TextToken = .output) {
    self.document.append(text + "\n", token: token)
  }

  private func run(_ line: String) {
    let parts = line.trimmingCharacters(in: .whitespaces).split(separator: " ", maxSplits: 1)
    guard let name = parts.first else { return }
    let rest = parts.count > 1 ? String(parts[1]) : ""
    switch name {
    case "help":
      self.out("""
      help            this list
      echo <text>     prints the text
      count <n>       prints n numbered lines
      error <text>    prints the text as an error
      time            the time now
      history         what was typed
      clear           clears the console
      """)
    case "echo":
      self.out(rest)
    case "count":
      let count = max(0, min(Int(rest) ?? 10, 1_000_000))
      var lines = ""
      lines.reserveCapacity(count * 12)
      for i in 1 ... max(count, 1) where count > 0 {
        lines += "line \(i)\n"
      }
      self.document.append(lines, token: .output)
      self.out("\(count) lines", .success)
    case "error":
      self.out(rest.isEmpty ? "something went wrong" : rest, .error)
    case "time":
      self.out(Date().formatted(date: .abbreviated, time: .standard))
    case "history":
      self.out(self.history.enumerated().map { "\($0.offset + 1)  \($0.element)" }.joined(separator: "\n"))
    case "clear":
      self.document.setText("")
      self.readOnly = nil
    default:
      self.out("\(name): command not found", .error)
    }
  }
}
