import SwiftUI

//struct Window<Content: View>: View {
//  // State variable to store the view's current position
////  @ObservedObject private var state: WindowState
//  let content: () -> Content
//  
//  init(name: String, @ViewBuilder content: @escaping () -> Content) {
//    self.content = content
////    self.state = Global.shared.getWindowState(name) ?? WindowState(name: name)
//  }
//  
//  func close() {
//    self.state.setOpen(false)
//  }
//  
//  var body: some View {
//    HStack {
//      if self.state.open {
//        HStack {
//          VStack(alignment: .leading) {
//            HStack(alignment: .center) {
//              Button(action: self.close) {
//                Image(systemName: "xmark.circle.fill")
//                  .foregroundColor(.secondary)
//              }
//              .buttonStyle(PlainButtonStyle())
//              
//              Text(self.state.name)
//                .bold()
//            }
//            .padding(.bottom, 8)
//            
//            VStack(alignment: .leading) {
//              self.content()
//            }
//          }
//          Spacer()
//        }
//        .frame(maxWidth: 200)
//        .padding()
//        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10.0))
//        .foregroundStyle(.secondary)
//        // Offset the view by the current position
//        .position(self.state.position)
//        .offset(self.state.offset)
//        // Apply the drag gesture
//        .gesture(
//          DragGesture()
//            .onChanged { value in
//              // Update the position as the view is dragged
//              self.state.setOffset(value.translation)
//            }
//            .onEnded { _ in
//              // Update the position when the drag gesture ends
//              self.state.setPosition(CGPoint(x: self.state.position.x + self.state.offset.width, y: self.state.position.y + self.state.offset.height))
//              self.state.setOffset(.zero)
//            }
//        )
//      }
//    }
//    .onAppear {
////      Global.shared.setWindowState(self.state.name, self.state)
//    }
//  }
//}

//struct DebugWindow: View {
//  @EnvironmentObject private var reload: Reload
//  
//  var body: some View {
//    Window(name: name(of: DebugWindow.self)) {
//      //      Toggle("Debug grid", isOn: Binding(get: { Graphics2D.shared.sceneData.debug.drawGrid }, set: { newValue, _ in
//      //        Graphics2D.shared.sceneData.debug.drawGrid = newValue
//      //        self.reload.toggle()
//      //      }))
//      //      if Graphics2D.sceneData.debug.drawGrid {
//      //        Toggle("Show filled cells", isOn: Binding(get: { Graphics2D.shared.sceneData.debug.showFilledCells }, set: { newValue, _ in
//      //          Graphics2D.sceneData.debug.showFilledCells = newValue
//      //          self.reload.toggle()
//      //        }))
//      //        .padding(.leading)
//      //      }
//    }
//  }
//}

struct ToggleView: View {
  @ObservedObject var state: WindowState
  
  var body: some View {
    Toggle("\(self.state.name)", isOn: Binding(get: { self.state.open }, set: { value in self.state.open = value }))
  }
}

struct Navigation: View {
  @ObservedObject public var renderer: ViewRenderer
  
  var body: some View {
    renderer.navigationView
  }
}

struct Inspector: View {
  @ObservedObject public var renderer: ViewRenderer
  
  var body: some View {
    renderer.inspectorView
  }
}

public struct Editor: View {
  @State private var showDetails = true
  @ObservedObject private var global = Global.shared
  public var renderer: ViewRenderer
  
  public init(renderer: ViewRenderer) {
    self.renderer = renderer
  }
  
  public var body: some View {
    NavigationSplitView {
      Navigation(renderer: renderer)
    } detail: {
      ZStack {
        MetalView(viewRenderer: renderer)
      }
//      .frame(minWidth: 300)
      .inspector(isPresented: $showDetails) {
        Inspector(renderer: renderer)
          .padding()
          .inspectorColumnWidth(min: 200, ideal: 250, max: 700)
      }
    }
    .toolbar {
      ToolbarItem {
        Button(action: {
          withAnimation {
            self.showDetails.toggle()
          }
        }) {
          Image(systemName: "sidebar.right")
            .font(.title)
        }
      }
    }
    .environmentObject(Global.shared.reload)
  }
}
