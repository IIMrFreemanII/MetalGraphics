import SwiftUI
import simd

private func stringToSIMDScalar<T: SIMDScalar>(_ str: String, _ type: T.Type) -> T? {
  if T.self == Double.self, let value = Double(str) as? T {
    return value
  }
  if T.self == Float.self, let value = Float(str) as? T {
    return value
  }
  if T.self == Int.self, let value = Int(str) as? T {
    return value
  }
  
  return nil
}

public struct NumberField<T : SIMDScalar> : View {
  public var label: String
  @Binding public var value: T
  
  @State private var text: String = "0"
  @State private var isValid: Bool = true
  
  private func validateNumber() {
    if let value = stringToSIMDScalar(text, T.self) {
      self.value = value
      isValid = true
      return
    }
    
    isValid = false
  }
  
  public var body: some View {
    VStack(spacing: 0) {
      HStack(spacing: 0) {
        Text(self.label)
        Text(" ")
        TextField("", text: $text, onEditingChanged: { _ in validateNumber() })
          .textFieldStyle(.roundedBorder)
          .background(RoundedRectangle(cornerRadius: 5)
            .stroke(isValid ? SwiftUI.Color.clear : SwiftUI.Color.red, lineWidth: 1)
          )
          .foregroundStyle(isValid ? SwiftUI.Color.primary : SwiftUI.Color.red)
          .onAppear {
            text = "\(value)"
          }
      }
    }
  }
}

#Preview {
  @State var value: Int = 3
  
  return NumberField(label: "X:", value: $value)
    .frame(width: 200, height: 100)
}
