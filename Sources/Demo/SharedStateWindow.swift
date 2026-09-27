import MetalGraphicsLib
import ReactiveUI

// The root of the "Shared State" window: a different tree from the Demos windows, over the same
// `AppModel`.
@Component
final class SharedStateWindow : SingleChildElement {
  static let id = "shared"

  @Bindable let model: AppModel = .shared

  @UIElementBuilder var body: [UIElement] {
    VStack(alignment: .leading, spacing: 12) {
      Text("\(self.model.count)")
        .font(.system(size: 64, weight: .bold))
        .foregroundColor(self.model.highlighted ? self.model.tint : .black)
      Text(self.model.message)
      Toggle("Highlight", isOn: $model.highlighted)
      HStack(spacing: 12) {
        Button("+") { withAnimation(.easeOut()) { self.model.count += 1 } }.buttonStyle(.bordered)
        Button("Reset") { self.model.reset() }
      }
    }
    .padding(20)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
  }
}
