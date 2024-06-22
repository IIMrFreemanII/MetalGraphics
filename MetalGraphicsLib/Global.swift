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
  @Published var open = true

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

public class Global: ObservableObject {
  public static var shared: Global = .init()

  let reload = Reload()
  @Published var windowsMap: [String: WindowState] = [:]

  func setWindowState(_ name: String, _ value: WindowState) {
    self.windowsMap[name] = value
  }
  
  func getWindowState(_ name: String) -> WindowState? {
    return self.windowsMap[name]
  }
}
