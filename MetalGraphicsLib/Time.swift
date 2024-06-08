public struct Time {
  public static var time: Float = 0
  public static var deltaTime: Float = 0
  
  public static var cursorTime = Float()
  public static var cursorSinBlinking = Float()
  public static func resetCursorBlinking() {
    Self.cursorTime = 0
  }
}
