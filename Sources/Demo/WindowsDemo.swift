import MetalGraphicsLib
import ReactiveUI

// Several windows over one `@Model`.
//
// - ⌘N opens another Demos window; pick this tab there too. Every control here writes
//   `AppModel.shared`, and every window reading it updates, the ones in the background included.
// - "Open Shared State window" opens a second kind of window, with a root of its own over the
//   same model. It is a single window: opening it again brings it to the front.
// - Each window keeps its own selected tab, across hot reloads and relaunches.
@Component
final class WindowsDemo : SingleChildElement {
  @Bindable let model: AppModel = .shared

  @UIElementBuilder var body: [UIElement] {
    Form {
      Section("Shared by every window") {
        Stepper("Count: \(self.model.count)", value: $model.count, in: 0 ... 99)
        HStack(spacing: 12) {
          Button("−") { self.model.count = max(0, self.model.count - 1) }.buttonStyle(.bordered)
          Button("+") { withAnimation(.easeOut()) { self.model.count += 1 } }.buttonStyle(.bordered)
        }
        TextField("Message", text: $model.message)
        Toggle("Highlight", isOn: $model.highlighted)
        ColorPicker("Tint", selection: $model.tint)
      }
      Section("Preview") {
        LabeledContent("Message", value: self.model.message)
        LabeledContent("Swatch") {
          Rectangle(self.model.highlighted ? self.model.tint : float4(0.6, 0.6, 0.6, 1))
            .frame(width: 24 + Float(self.model.count) * 4, height: 18)
            .cornerRadius(4)
        }
        if self.model.highlighted {
          Text("Highlighted in every window").foregroundColor(self.model.tint)
        }
      }
      Section("Windows") {
        Button("Open Shared State window") { openWindow(id: SharedStateWindow.id) }
          .buttonStyle(.borderedProminent)
        Text("⌘N opens another Demos window.")
        Button("Reset") { self.model.reset() }
      }
    }
    .frame(width: 520, height: 600)
  }
}
