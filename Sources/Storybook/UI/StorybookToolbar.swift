import MetalGraphicsLib
import ReactiveUI

/// Above the canvas: Canvas or Docs, the appearance, the background, the width, the zoom, the
/// layout outline, and Reset. Each is bound to the model; the canvas keeps them in the window's
/// storage.
@Component
final class StorybookToolbar : SingleChildElement {
  static let height: Float = 38
  static let captionFont = TextFont.system(size: 11)

  @Bindable let model: StorybookModel = .shared

  @UIElementBuilder var body: [UIElement] {
    HStack(spacing: 10) {
      Picker("", selection: $model.mode) {
        Text("Canvas").tag(CanvasMode.canvas)
        Text("Docs").tag(CanvasMode.docs)
      }
      .pickerStyle(.segmented)
      Picker("", selection: $model.appearance) {
        Text("Auto").tag(CanvasAppearance.window)
        Text("Light").tag(CanvasAppearance.light)
        Text("Dark").tag(CanvasAppearance.dark)
        Text("Both").tag(CanvasAppearance.sideBySide)
      }
      .pickerStyle(.segmented)
      Spacer()
      Picker("", selection: $model.background) {
        Text("Content").tag(CanvasBackground.content)
        Text("Grouped").tag(CanvasBackground.grouped)
        Text("Window").tag(CanvasBackground.window)
        Text("Card").tag(CanvasBackground.card)
        Text("Wallpaper").tag(CanvasBackground.wallpaper)
      }
      Picker("", selection: $model.viewport) {
        Text("Fit").tag(Viewport.fit)
        Text("320").tag(Viewport.w320)
        Text("480").tag(Viewport.w480)
        Text("600").tag(Viewport.w600)
        Text("800").tag(Viewport.w800)
        Text("1024").tag(Viewport.w1024)
      }
      Picker("", selection: $model.zoom) {
        Text("50%").tag(0.5)
        Text("75%").tag(0.75)
        Text("100%").tag(1.0)
        Text("125%").tag(1.25)
        Text("150%").tag(1.5)
        Text("200%").tag(2.0)
      }
      ToggleChip("Outline", isOn: $model.outline)
      Button("Reset") { self.model.resetArgs(in: StoryRegistry.catalog()) }
        .buttonStyle(.bordered)
    }
    .padding(Inset(horizontal: 12))
    .frame(maxWidth: .infinity, minHeight: StorybookToolbar.height, alignment: .leading)
    .background(.barOverContent)
    .overlay(alignment: .bottom) {
      Rectangle(.separator)
        .frame(height: 0.5)
    }
  }
}
