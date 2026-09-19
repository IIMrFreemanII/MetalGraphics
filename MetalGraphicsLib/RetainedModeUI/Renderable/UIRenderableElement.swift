open class UIRenderableElement : SingleChildElement, @MainActor Identifiable {
  public var id: UInt = .random(in: .min ... .max)
  
  open func render(_ renderer: Graphics2D) -> Void {}
}
