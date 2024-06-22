import MetalGraphicsLib
import SwiftUI

struct Window: View {
  @EnvironmentObject var reload: Reload

  // State variable to store the view's current position
  @State private var viewPosition = CGPoint(x: 200, y: 100)
  @State private var viewOffset = CGSize.zero
  var name: String = "Default name"

  func onClose() {
    print("click")
  }

  var body: some View {
    HStack {
      VStack(alignment: .leading) {
        HStack(alignment: .center) {
          Button(action: self.onClose) {
            Image(systemName: "xmark.circle.fill")
              .foregroundColor(.secondary)
          }
          .buttonStyle(PlainButtonStyle())

          Text(self.name)
            .bold()
        }
        .padding(.bottom, 8)

        VStack(alignment: .leading) {
          Toggle("Debug grid", isOn: Binding(get: { Graphics.shared.sceneData.debug.drawGrid }, set: { newValue, _ in
            Graphics.shared.sceneData.debug.drawGrid = newValue
            self.reload.toggle()
          }))
          if Graphics.shared.sceneData.debug.drawGrid {
            Toggle("Show filled cells", isOn: Binding(get: { Graphics.shared.sceneData.debug.showFilledCells }, set: { newValue, _ in
              Graphics.shared.sceneData.debug.showFilledCells = newValue
              self.reload.toggle()
            }))
            .padding(.leading)
          }
        }
      }
      Spacer()
    }
    .frame(maxWidth: 200)
    .padding()
    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10.0))
    .foregroundStyle(.secondary)
    // Offset the view by the current position
    .position(self.viewPosition)
    .offset(self.viewOffset)
    // Apply the drag gesture
    .gesture(
      DragGesture()
        .onChanged { value in
          // Update the position as the view is dragged
          self.viewOffset = value.translation
        }
        .onEnded { _ in
          // Update the position when the drag gesture ends
          self.viewPosition = CGPoint(x: self.viewPosition.x + self.viewOffset.width, y: self.viewPosition.y + self.viewOffset.height)
          self.viewOffset = .zero
        }
    )
  }
}

struct Sidebar: View {
  @EnvironmentObject var reload: Reload

  var body: some View {
    VStack(alignment: .leading) {
      Text("Test data")
      Spacer()
    }
    .padding()
  }
}

struct ContentView: View {
  private var renderer = TestViewRenderer()

  var body: some View {
    ZStack {
      HStack {
        Sidebar()
        MetalView(viewRenderer: self.renderer)
      }
      Window(name: "Debug info")
    }
  }
}

#Preview {
  ContentView()
}
