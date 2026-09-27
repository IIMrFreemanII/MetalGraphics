import AppKit

/// Where text copied in a window's tree goes. The pasteboard belongs to the main thread and a
/// window runs on its own, so a copy is posted there. Tests replace `write` to see what was
/// copied without touching the real pasteboard.
public enum Pasteboard {
  nonisolated(unsafe) public static var write: @Sendable (String) -> Void = { text in
    DispatchQueue.main.async {
      NSPasteboard.general.clearContents()
      NSPasteboard.general.setString(text, forType: .string)
    }
  }
}
