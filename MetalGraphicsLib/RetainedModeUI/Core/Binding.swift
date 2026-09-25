/// A read-write reference to a value owned elsewhere, as SwiftUI's.
///
/// Inside a `@Component` body a binding is only a spelling. `Toggle("Wi-Fi", isOn: $wifi)` is
/// lowered at compile time into the two directions it stands for, and `$wifi` is never evaluated:
///
/// - state to control: the ordinary generated setter line, `n.setIsOn(self._wifi, …)`, in
///   `__update_wifi`, exactly like any other bound argument;
/// - control to state: `{ self.wifi = $0 }`, armed on mount into the control's `onIsOnChange`
///   and cleared on unmount, like an `onTap` handler.
///
/// So a component pays nothing for a binding at runtime but that one closure. `$wifi.volume`
/// lowers the same way through the member path, and `.constant(v)` to the value alone.
///
/// Outside a component — a hand-built tree, or an `onTap` that calls `self.$wifi` — this is a
/// real binding, a get/set closure pair, and the control initializers taking one work as in
/// SwiftUI.
@MainActor @dynamicMemberLookup
public struct Binding<Value> {
  private let get: () -> Value
  private let set: (Value) -> Void

  public init(get: @escaping () -> Value, set: @escaping (Value) -> Void) {
    self.get = get
    self.set = set
  }

  /// `root[keyPath:]`, holding `root` unowned: what `@State`'s `$name` returns. Writing goes
  /// through the property's setter, so the state's update runs.
  public init<Root: AnyObject>(unowned root: Root, _ keyPath: ReferenceWritableKeyPath<Root, Value>) {
    self.init(
      get: { [unowned root] in root[keyPath: keyPath] },
      set: { [unowned root] in root[keyPath: keyPath] = $0 }
    )
  }

  public var wrappedValue: Value {
    get { self.get() }
    nonmutating set { self.set(newValue) }
  }

  /// A binding that ignores writes: a control given one keeps showing `value`.
  public static func constant(_ value: Value) -> Binding<Value> {
    Binding(get: { value }, set: { _ in })
  }

  /// `$settings.volume`: a binding to a member of the bound value.
  public subscript<Member>(dynamicMember keyPath: WritableKeyPath<Value, Member>) -> Binding<Member> {
    Binding<Member>(
      get: { self.wrappedValue[keyPath: keyPath] },
      set: { self.wrappedValue[keyPath: keyPath] = $0 }
    )
  }
}
