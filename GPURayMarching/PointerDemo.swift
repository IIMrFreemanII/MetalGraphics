import MetalGraphicsLib
import ReactiveUI

// SwiftUI's pointer handling: a cursor per element (`.pointerStyle`), continuous hover, tap
// gestures with a click count and a location, a drag gesture, and control over what the pointer
// can hit (`.allowsHitTesting`, `.contentShape`).
@Component
final class PointerDemo : SingleChildElement {
  private static let captionFont = TextFont.system(size: 12)
  private static let captionColor = float4(0.45, 0.45, 0.45, 1)
  private static let chipColor = float4(0.9, 0.9, 0.92, 1)
  private static let chipInset = Inset(vertical: 6, horizontal: 10)
  private static let accent = float4(0.2, 0.4, 0.9, 1)

  @State var cardOffset: float2 = .zero
  @State var cardRest: float2 = .zero
  @State var dragging: Bool = false
  @State var doubleTaps: Int = 0
  @State var tapLocation: String = "nowhere yet"
  @State var hoverPoint: float2 = .zero
  @State var hovering: Bool = false
  @State var underTaps: Int = 0
  @State var circleTaps: Int = 0

  @UIElementBuilder var body: [UIElement] {
    HStack(alignment: .top, spacing: 40) {
      VStack(alignment: .leading, spacing: 8) {
        Text("Pointer styles: hover each")
          .font(Self.captionFont)
          .foregroundColor(Self.captionColor)
        HStack(spacing: 6) {
          Text("link").padding(Self.chipInset).background(Self.chipColor).pointerStyle(.link)
          Text("text").padding(Self.chipInset).background(Self.chipColor).pointerStyle(.horizontalText)
          Text("crosshair").padding(Self.chipInset).background(Self.chipColor).pointerStyle(.rectSelection)
          Text("grab").padding(Self.chipInset).background(Self.chipColor).pointerStyle(.grabIdle)
        }
        HStack(spacing: 6) {
          Text("columns").padding(Self.chipInset).background(Self.chipColor).pointerStyle(.columnResize)
          Text("rows").padding(Self.chipInset).background(Self.chipColor).pointerStyle(.rowResize)
          Text("corner").padding(Self.chipInset).background(Self.chipColor)
            .pointerStyle(.frameResize(position: .bottomTrailing))
          Text("zoom").padding(Self.chipInset).background(Self.chipColor).pointerStyle(.zoomIn)
        }

        Text("Drag gesture")
          .font(Self.captionFont)
          .foregroundColor(Self.captionColor)
        Frame(float2(300, 140), .topLeading) {
          Text(self.dragging ? "Dragging" : "Drag me")
            .foregroundColor(.white)
            .padding(Inset(vertical: 20, horizontal: 24))
            .background(Self.accent)
            .offset(self.cardOffset)
            .gesture(
              DragGesture(minimumDistance: 2, coordinateSpace: .global)
                .onChanged { value in
                  self.dragging = true
                  self.cardOffset = self.cardRest + value.translation
                }
                .onEnded { value in
                  self.dragging = false
                  self.cardRest = self.cardRest + value.translation
                  self.cardOffset = self.cardRest
                }
            )
            .pointerStyle(self.dragging ? .grabActive : .grabIdle)
        }
        .background(Self.chipColor)

        Text("Tap gestures")
          .font(Self.captionFont)
          .foregroundColor(Self.captionColor)
        Text("Double-clicked \(self.doubleTaps) times")
          .padding(Self.chipInset)
          .background(Self.chipColor)
          .onTapGesture(count: 2) { self.doubleTaps += 1 }
        Text("Tapped at \(self.tapLocation)")
          .padding(Self.chipInset)
          .background(Self.chipColor)
          .onTapGesture { location in self.tapLocation = "\(Int(location.x)), \(Int(location.y))" }
      }

      VStack(alignment: .leading, spacing: 8) {
        Text("Continuous hover")
          .font(Self.captionFont)
          .foregroundColor(Self.captionColor)
        ZStack(alignment: .topLeading) {
          Rectangle(Self.chipColor)
            .frame(width: 240, height: 140)
          Rectangle(.red)
            .frame(width: 8, height: 8)
            .offset(self.hoverPoint - float2(4, 4))
            .opacity(self.hovering ? 1 : 0)
          Text(self.hovering ? "\(Int(self.hoverPoint.x)), \(Int(self.hoverPoint.y))" : "Move the pointer here")
            .font(Self.captionFont)
            .padding(6)
        }
        .onContinuousHover { phase in
          switch phase {
          case .active(let location):
            self.hovering = true
            self.hoverPoint = location
          case .ended:
            self.hovering = false
          }
        }
        .pointerStyle(.rectSelection)

        Text("allowsHitTesting(false) overlay")
          .font(Self.captionFont)
          .foregroundColor(Self.captionColor)
        ZStack {
          Button("Tapped \(self.underTaps) times through the overlay") { self.underTaps += 1 }
          Rectangle(float4(0.2, 0.4, 0.9, 0.15))
            .frame(width: 280, height: 36)
            .allowsHitTesting(false)
        }

        Text("contentShape(.circle)")
          .font(Self.captionFont)
          .foregroundColor(Self.captionColor)
        HStack(spacing: 12) {
          Rectangle(Self.accent)
            .frame(width: 80, height: 80)
            .contentShape(.circle)
            .onTapGesture { self.circleTaps += 1 }
            .pointerStyle(.link)
          Text("Hit only inside the circle: \(self.circleTaps)")
        }
      }
    }
    .padding(Inset(all: 16))
  }
}
