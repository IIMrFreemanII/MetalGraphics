import MetalGraphicsLib
import ReactiveUI

/// A place in the demo's stack. Hashable, as a path's values must be; Identifiable for the list.
struct Route : Hashable, Identifiable {
  let number: Int

  var id: Int { self.number }
  var name: String { "Route \(self.number)" }
  var next: Route { Route(number: self.number + 1) }
}

enum Swatch : String, Hashable {
  case red, green, blue

  var color: float4 {
    switch self {
    case .red: .hue(.red)
    case .green: .hue(.green)
    case .blue: .hue(.blue)
    }
  }
}

// SwiftUI's navigation: a `NavigationStack` bound to a `@State` path, value links resolved by
// `.navigationDestination`, a link to a view, titles, the back button, Escape and ⌘[, and edits
// to the path from outside the stack. Beside it, a `NavigationSplitView` whose sidebar selects
// what the detail column shows.
@Component
final class NavigationDemo : SingleChildElement {
  private static let captionFont = TextFont.system(size: 12)
  private static let captionColor: float4 = .secondaryLabel
  private static let panelSize = float2(380, 360)
  private static let border: float4 = .separator

  @State var path: [Route] = []
  @State var routes: [Route] = (1...5).map { Route(number: $0) }

  @UIElementBuilder var body: [UIElement] {
    HStack(alignment: .top, spacing: 32) {
      VStack(alignment: .leading, spacing: 8) {
        Text("NavigationStack(path: $path) — depth \(self.path.count)")
          .font(Self.captionFont)
          .foregroundColor(Self.captionColor)
        HStack(spacing: 12) {
          Button("Deep link to 2 › 3 › 4") {
            self.path = [Route(number: 2), Route(number: 3), Route(number: 4)]
          }
          Button("Pop to root") { self.path.removeAll() }
            .disabled(self.path.isEmpty)
        }
        Frame(Self.panelSize) {
          NavigationStack(path: $path) {
            VStack(alignment: .leading, spacing: 4) {
              VList(alignment: .leading, spacing: 4, items: self.routes) { route in
                NavigationLink(route.name, value: route)
              }
              NavigationLink("About this demo") { NavigationAboutPage() }
            }
            .navigationTitle("Routes")
            .navigationDestination(for: Route.self) { route in NavigationRoutePage(route: route) }
          }
        }
        .border(Self.border)
      }
      VStack(alignment: .leading, spacing: 8) {
        Text("NavigationSplitView")
          .font(Self.captionFont)
          .foregroundColor(Self.captionColor)
        Frame(float2(480, 360)) {
          NavigationSplitView {
            NavigationLink("Red", value: Swatch.red)
            NavigationLink("Green", value: Swatch.green)
            NavigationLink("Blue", value: Swatch.blue)
              .navigationDestination(for: Swatch.self) { swatch in NavigationSwatchPage(swatch: swatch) }
          } detail: {
            Text("Select a colour")
              .foregroundColor(Self.captionColor)
          }
        }
        .border(Self.border)
      }
    }
  }
}

/// A pushed page with state of its own, kept while a page covers it.
@Component
final class NavigationRoutePage : SingleChildElement {
  let route: Route
  @State var taps: Int = 0

  init(route: Route) {
    self.route = route
    super.init()
  }

  @UIElementBuilder var body: [UIElement] {
    VStack(spacing: 12) {
      Text(self.route.name)
        .font(.title)
      Button("Tapped \(self.taps) times") { self.taps += 1 }
        .buttonStyle(.bordered)
      NavigationLink("Next: \(self.route.next.name)", value: self.route.next)
      Text("Escape or ⌘[ goes back")
        .font(.caption)
        .foregroundColor(.secondaryLabel)
    }
    .navigationTitle(self.route.name)
  }
}

@Component
final class NavigationAboutPage : SingleChildElement {
  @UIElementBuilder var body: [UIElement] {
    VStack(spacing: 8) {
      Text("Pushed by NavigationLink(destination:)")
      Text("It is not part of the path.")
        .foregroundColor(.secondaryLabel)
    }
    .navigationTitle("About")
  }
}

@Component
final class NavigationSwatchPage : SingleChildElement {
  let swatch: Swatch

  init(swatch: Swatch) {
    self.swatch = swatch
    super.init()
  }

  @UIElementBuilder var body: [UIElement] {
    VStack(spacing: 12) {
      Rectangle(self.swatch.color)
        .frame(width: 120, height: 80)
        .cornerRadius(8)
      NavigationLink("More \(self.swatch.rawValue)", destination: { NavigationAboutPage() })
    }
    .navigationTitle(self.swatch.rawValue.capitalized)
  }
}
