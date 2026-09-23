open class UIRenderableElement : SingleChildElement {
  /// Draws the element. `effect` is every `EffectElement` above it, already composed: apply it
  /// to the laid-out rect and multiply it into the colour's alpha.
  open func render(_ renderer: Graphics2D, _ effect: EffectState) -> Void {}
}
