import MetalGraphicsLib
import ReactiveUI

/// A note the demo opens on a sheet of its own with `.sheet(item:)`.
struct DemoNote : Identifiable, Hashable {
  let id: Int
  let title: String
  let text: String

  static let all = [
    DemoNote(id: 1, title: "Groceries", text: "Milk, eggs, bread."),
    DemoNote(id: 2, title: "Ideas", text: "A popover that points from a window's edge."),
    DemoNote(id: 3, title: "Travel", text: "Pack light."),
  ]
}

// SwiftUI's modal presentations: a sheet with a component of its own that edits a binding and
// dismisses itself, an alert on it, a destructive alert whose title follows the state, a
// confirmation dialog, a full-screen cover, a popover, and `.sheet(item:)`. The picker at the top
// shows them over the app's window, or in windows of their own: attached to it, or floating.
@Component
final class ModalDemo : SingleChildElement {
  private static let captionFont = TextFont.system(size: 12)
  private static let captionColor = float4(0.45, 0.45, 0.45, 1)

  @State var placement: PresentationWindowStyle.Placement = .inline
  @State var resizable: Bool = false
  @State var name: String = "Notes"
  @State var editing: Bool = false
  @State var confirmingDelete: Bool = false
  @State var choosingSave: Bool = false
  @State var covering: Bool = false
  @State var showingInfo: Bool = false
  @State var showingInline: Bool = false
  @State var selectedNote: DemoNote? = nil
  @State var lastAction: String = "Nothing yet"

  @UIElementBuilder var body: [UIElement] {
    VStack(alignment: .leading, spacing: 16) {
      Picker("Show in", selection: $placement) {
        Text("App window").tag(PresentationWindowStyle.Placement.inline)
        Text("Attached window").tag(PresentationWindowStyle.Placement.attached)
        Text("Floating window").tag(PresentationWindowStyle.Placement.floating)
      }
      .pickerStyle(.segmented)
      Toggle("Resizable sheet window", isOn: $resizable)

      Text("Document: \(self.name)")
        .font(.title)
      HStack(spacing: 10) {
        Button("Rename…") { self.editing = true }
          .buttonStyle(.bordered)
          .sheet(isPresented: $editing, onDismiss: { self.lastAction = "Closed the rename sheet" }) {
            ModalRenameSheet(name: self.$name)
          }
        Button("Delete…", role: .destructive) { self.confirmingDelete = true }
          .buttonStyle(.bordered)
          .alert("Delete “\(self.name)”?", isPresented: $confirmingDelete) {
            Button("Delete", role: .destructive) { self.lastAction = "Deleted \(self.name)" }
            Button("Cancel", role: .cancel) { self.lastAction = "Kept \(self.name)" }
          } message: {
            Text("This cannot be undone.")
          }
        Button("Close…") { self.choosingSave = true }
          .buttonStyle(.bordered)
          .confirmationDialog("Save changes to “\(self.name)”?", isPresented: $choosingSave) {
            Button("Save") { self.lastAction = "Saved \(self.name)" }
            Button("Don’t Save", role: .destructive) { self.lastAction = "Discarded the changes" }
          }
        Button("Cover") { self.covering = true }
          .buttonStyle(.bordered)
          .fullScreenCover(isPresented: $covering) { ModalCoverPage() }
        Button("Info") { self.showingInfo = true }
          .buttonStyle(.bordered)
          .popover(isPresented: $showingInfo) {
            Text("A popover points at what shows it.")
              .padding(12)
          }
      }

      Text("Notes, each on a sheet of its own")
        .font(Self.captionFont)
        .foregroundColor(Self.captionColor)
      HStack(spacing: 10) {
        Button("Groceries") { self.selectedNote = DemoNote.all[0] }
        Button("Ideas") { self.selectedNote = DemoNote.all[1] }
        Button("Travel") { self.selectedNote = DemoNote.all[2] }
      }
      .sheet(item: $selectedNote) { note in
        ModalNotePage(note: note)
      }

      Button("Always over the app window") { self.showingInline = true }
        .alert("Over the app window", isPresented: $showingInline) {}
        .presentationWindow(.inline)

      Text("Last: \(self.lastAction)")
        .font(Self.captionFont)
        .foregroundColor(Self.captionColor)
    }
    .presentationWindow(PresentationWindowStyle(self.placement, isResizable: self.resizable))
  }
}

/// Edits a copy of the name and saves it through its binding. Its own state starts afresh each
/// time the sheet opens.
@Component
final class ModalRenameSheet : SingleChildElement {
  @Environment(\.dismiss) private var dismiss

  let name: Binding<String>
  @State var draft: String
  @State var confirmingDiscard: Bool = false

  init(name: Binding<String>) {
    self.name = name
    self.draft = name.wrappedValue
    super.init()
  }

  @UIElementBuilder var body: [UIElement] {
    VStack(alignment: .leading, spacing: 14) {
      Text("Rename")
        .font(.title)
      TextField("Name", text: $draft, prompt: "Document name")
        .frame(width: 260)
      HStack(spacing: 8) {
        Spacer()
        Button("Discard…") { self.confirmingDiscard = true }
          .alert("Discard the new name?", isPresented: $confirmingDiscard) {
            Button("Discard", role: .destructive) { self.dismiss() }
            Button("Keep Editing", role: .cancel) {}
          }
        Button("Save") {
          self.name.wrappedValue = self.draft
          self.dismiss()
        }
        .buttonStyle(.borderedProminent)
      }
    }
    .padding(20)
    .frame(width: 320)
  }
}

@Component
final class ModalCoverPage : SingleChildElement {
  @Environment(\.dismiss) private var dismiss

  @UIElementBuilder var body: [UIElement] {
    VStack(spacing: 16) {
      Text("Full-screen cover")
        .font(.title)
      Text("Escape or the button closes it.")
      Button("Close") { self.dismiss() }
        .buttonStyle(.borderedProminent)
    }
  }
}

@Component
final class ModalNotePage : SingleChildElement {
  @Environment(\.dismiss) private var dismiss

  let note: DemoNote

  init(note: DemoNote) {
    self.note = note
    super.init()
  }

  @UIElementBuilder var body: [UIElement] {
    VStack(alignment: .leading, spacing: 10) {
      Text(self.note.title)
        .font(.title)
      Text(self.note.text)
      Button("Done") { self.dismiss() }
        .buttonStyle(.borderedProminent)
    }
    .padding(20)
    .frame(width: 280)
  }
}
