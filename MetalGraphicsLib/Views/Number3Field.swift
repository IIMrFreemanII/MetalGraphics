import SwiftUI
import simd

public struct Number3Field<T: SIMDScalar> : View {
  public var label: String
  @Binding public var value: SIMD3<T>
  
  
  public var body: some View {
    SwiftUI.VStack(alignment: .leading, spacing: 4) {
      Text(label)
        .font(.title3)
      SwiftUI.HStack {
        NumberField(label: "X", value: $value.x)
        NumberField(label: "Y", value: $value.y)
        NumberField(label: "Z", value: $value.z)
      }
    }
  }
}

#Preview {
  @Previewable @State var value: SIMD3<Int> = .init(0, 1, 2)
  
  return Number3Field(label: "Position:", value: $value)
    .frame(width: 300, height: 100)
}
