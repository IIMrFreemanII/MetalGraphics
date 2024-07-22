import SwiftUI
import simd

public struct Number2Field<T: SIMDScalar> : View {
  public var label: String
  @Binding public var value: SIMD2<T>
  
  
  public var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(label)
        .font(.title3)
      HStack {
        NumberField(label: "X:", value: $value.x)
        NumberField(label: "Y:", value: $value.y)
      }
    }
  }
}

#Preview {
  @State var value: SIMD2<Int> = .init(0, 1)
  
  return Number2Field(label: "Position:", value: $value)
    .frame(width: 300, height: 100)
}
