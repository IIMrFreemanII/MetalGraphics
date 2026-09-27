import MetalGraphicsLib
import ReactiveUI
import simd

// A markdown editor: the text styled as it is written — headings in their sizes, emphasis,
// code, links, quotes, lists — soft-wrapped at the width, the markup dimmed but kept. An image
// written `![caption](name)` shows below its line, and "Insert chip" puts a small tappable
// element into the text at the caret: both are attachments, elements of the tree hosted in the
// text and made by `MarkdownAttachments` as they scroll into view.
@Component
final class MarkdownEditorDemo : SingleChildElement {
  private static let font = TextFont.system(size: 14)
  private static let lightTheme: EditorTheme = {
    var theme = EditorTheme.light
    theme.lineSpacing = 7
    theme.textInset = float2(12, 10)
    theme.currentLine = nil
    return theme
  }()
  private static let darkTheme: EditorTheme = {
    var theme = EditorTheme.dark
    theme.lineSpacing = 7
    theme.textInset = float2(12, 10)
    theme.currentLine = nil
    return theme
  }()

  let document = TextDocument(MarkdownEditorDemo.sample)
  let attachments = MarkdownAttachments()

  @State var caret: Int = 0
  @State var chips: Int = 0
  @State var dark: Bool = false

  @UIElementBuilder var body: [UIElement] {
    VStack(alignment: .leading, spacing: 10) {
      HStack(spacing: 16) {
        Button("Insert chip") { self.insertChip() }
        Toggle("Dark", isOn: $dark)
      }
      TextEditor(document: self.document)
        .styler(MarkdownStyler())
        .lineWrapping(.soft)
        .attachmentProvider(self.attachments)
        .editorTheme(self.dark ? Self.darkTheme : Self.lightTheme)
        .onSelectionChange { selection in self.caret = selection.primary.head }
        .font(Self.font)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
  }

  private func insertChip() {
    self.chips += 1
    self.document.insertAttachment(MarkdownAttachments.chip(self.chips), at: self.caret)
  }

  static let sample = """
  # Markdown, as it is written

  Text is **strong**, *emphasized*, ~~struck~~ or `code`, and [links](https://example.com) \
  show as links. Lines wrap at the width of the editor, however long they are, and the caret \
  moves along the lines as they are shown.

  ## Lists and quotes

  - A list item
  - Another, with **bold** in it
  1. Numbered
  2. Items

  > A quote is italic and grey.

  ### Code

  ```swift
  struct Greeting {
    let name: String
    func text() -> String { "Hello, \\(name)!" }
  }
  ```

  ### Images

  An image below its line:

  ![A photo](photo)

  ---

  Put the caret anywhere and press *Insert chip*: a chip goes into the text there.
  """
}

/// Makes the demo's attachments: an image for each `![caption](name)`, a chip for each inserted
/// one.
final class MarkdownAttachments : TextAttachmentProvider {
  private static let chipBase = 1_000_000

  static func chip(_ number: Int) -> TextAttachmentID {
    TextAttachmentID(Self.chipBase + number)
  }

  func makeElement(for id: TextAttachmentID, source: String?) -> UIElement {
    if let source {
      return Image(source, bundle: .module).resizable().scaledToFit()
    }
    return Chip(number: id.rawValue - Self.chipBase)
  }

  func size(for id: TextAttachmentID, source: String?, maxWidth: Float) -> float2 {
    source != nil ? float2(min(maxWidth, 280), 160) : float2(74, 20)
  }
}

/// A small tappable element inside the text.
@Component
final class Chip : SingleChildElement {
  private static let font = TextFont.system(size: 11, weight: .semibold)
  private static let color = float4(0.2, 0.45, 0.95, 1)

  let number: Int
  @State var taps: Int = 0

  init(number: Int) {
    self.number = number
    super.init()
  }

  @UIElementBuilder var body: [UIElement] {
    Text("Chip \(self.number) · \(self.taps)")
      .font(Self.font)
      .foregroundColor(.white)
      .frame(width: 74, height: 20)
      .background(Self.color)
      .cornerRadius(10)
      .onTap { _ in self.taps += 1 }
  }
}
