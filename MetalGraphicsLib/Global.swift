import Combine

class Reload: ObservableObject {
  @Published private var value = true

  func toggle() {
    self.value.toggle()
  }
}

class WindowState: ObservableObject {
  @Published var name: String
  @Published var position = CGPoint(x: 200, y: 100)
  @Published var offset = CGSize.zero
  @Published var open = false

  init(name: String) {
    self.name = name
  }

  func setPosition(_ value: CGPoint) {
    self.position = value
  }

  func setOffset(_ value: CGSize) {
    self.offset = value
  }

  func setOpen(_ value: Bool) {
    self.open = value
  }
}

enum Event: Int, CaseIterable {
  case Navigation
  case Inspector
}

public class Application: ObservableObject {
  @MainActor public static var shared: Application = .init()
  
  init() {
    print(Event.allCases)
    for event in Event.allCases {
      print(event)
      events.append(Reload())
    }
  }
  
  private var events: [Reload] = []
  
  @MainActor static func register(_ event: Event) -> Reload {
    return shared.events[event.rawValue]
  }
  
  @MainActor static func trigger(_ event: Event) -> Void {
    shared.events[event.rawValue].toggle()
  }
}

public class Global: ObservableObject {
  @MainActor public static var shared: Global = .init()

  let reload = Reload()
  @Published var windowsMap: [String: WindowState] = [:]

//  func setWindowState(_ name: String, _ value: WindowState) {
//    self.windowsMap[name] = value
//  }
//
//  func getWindowState(_ name: String) -> WindowState? {
//    self.windowsMap[name]
//  }
}
