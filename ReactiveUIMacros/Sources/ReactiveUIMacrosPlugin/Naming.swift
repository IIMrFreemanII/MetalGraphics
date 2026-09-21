// The naming contract between `@State` and `@Component`.
//
// The two macros expand independently and neither reads the other's output, so every name
// they share is defined here and nowhere else. All generated names are `private`, which in
// Swift means "this type and extensions in the same file" — and both macros always expand
// into the same type in the same file.
enum Naming {
  /// Backing storage for a `@State` property. Written by `@State`'s peer expansion,
  /// read by `@Component` (expression rewriting and tree construction).
  static func storage(_ property: String) -> String { "_\(property)" }

  /// Per-state update entry point. Written by `@Component`, called from `@State`'s setter.
  /// `@Component` must emit one for *every* `@State`, including states no node reads.
  static func update(_ property: String) -> String { "__update_\(property)" }

  /// Turns a missing `@Component` into a readable conformance error instead of
  /// "cannot find '__update_x' in scope".
  static func requiresComponent(_ property: String) -> String { "__requiresComponent_\(property)" }

  /// Marker protocol, declared in MetalGraphicsLib.
  static let componentProtocol = "ReactiveComponent"

  /// Node field for chain link `index` at `path`, e.g. "__n0_1a". Links are lettered
  /// innermost-first so a chain reads in construction order.
  static func node(_ path: String, _ index: Int) -> String { "__n\(path)\(letter(index))" }
  static func local(_ path: String, _ index: Int) -> String { "n\(path)\(letter(index))" }

  private static func letter(_ index: Int) -> String {
    let alphabet = Array("abcdefghijklmnopqrstuvwxyz")
    return index < alphabet.count ? String(alphabet[index]) : "z\(index)"
  }

  /// Branch bookkeeping, all derived from the branch's path.
  static func tag(_ path: String) -> String { "__tag\(path)" }
  static func slot(_ path: String) -> String { "__slot\(path)" }
  static func evalTag(_ path: String) -> String { "__evalTag\(path)" }
  static func enterBranch(_ path: String) -> String { "__enter\(path)" }
  static func leaveBranch(_ path: String) -> String { "__leave\(path)" }
  static func swapBranch(_ path: String) -> String { "__swap\(path)" }

  /// Rebuilds one container's children from its slots.
  static func applyChildren(_ path: String) -> String { "__applyChildren\(path.isEmpty ? "Root" : path)" }

  /// Mutation methods generated for a `@State` array, e.g. `items` -> `appendItems(_:)`.
  /// Unlike everything else here these are *public* API of the component: the whole point is
  /// that the call site names the operation, so the generated code never has to work out what
  /// changed. A collision with a method the user wrote is reported as F11.
  static func mutationAppend(_ property: String) -> String { "append\(capitalized(property))" }
  static func mutationInsert(_ property: String) -> String { "insert\(capitalized(property))" }
  static func mutationRemove(_ property: String) -> String { "remove\(capitalized(property))" }
  static func mutationReplace(_ property: String) -> String { "replace\(capitalized(property))" }

  /// The incremental appliers behind those methods. They exist only when at least one list
  /// binds the property; otherwise the mutation methods fall through to `update(_:)`.
  static func didInsert(_ property: String) -> String { "__\(property)_didInsert" }
  static func didRemove(_ property: String) -> String { "__\(property)_didRemove" }

  private static func capitalized(_ name: String) -> String {
    name.prefix(1).uppercased() + name.dropFirst()
  }

  /// The component's captured `UIContext`, and the remount replay flag.
  static let context = "__context"
  static let needsRefresh = "__needsRefresh"
  static let refreshAll = "__refreshAll"
  static let build = "__build"
}
