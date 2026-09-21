import SwiftSyntax

// What the macro knows about the element library.
//
// A macro has no cross-file visibility: it cannot look up `Frame.size` to discover that changing
// it needs a re-layout. So the knowledge is split in two. *Shape* — which argument feeds which
// property — lives here. *Semantics* — whether that property invalidates layout or only render —
// lives in MetalGraphicsLib, in the `setX(_:_:)` methods this table names. Adding an element
// therefore means touching two places, and anything not listed here is a hard error (F4).

enum Arity {
  case leaf     // no children
  case single   // SingleChildElement: setChild(_:_:)
  case multi    // MultiChildElement: setChildren(_:_:)
}

/// One constructor argument, and the setter that updates it later (nil = not reactive).
struct ArgSpec {
  let label: String?
  let setter: String?

  init(_ label: String?, _ setter: String?) {
    self.label = label
    self.setter = setter
  }
}

struct TypeSpec {
  let name: String
  let args: [ArgSpec]
  let arity: Arity
  /// The type to give the node field. Generic elements use a non-generic superclass, since
  /// the macro cannot infer a generic argument from syntax alone — and the reactive
  /// properties live on that superclass anyway.
  let fieldType: String
  /// False for the lists, whose trailing closure is a row factory rather than content.
  let takesContent: Bool
  /// The label of an argument whose element type specialises this element's node field, e.g.
  /// `items` on `VList`, giving a field typed `VList<DemoItem>`.
  ///
  /// This also makes the argument load-bearing beyond its own value: `@Component` will only
  /// accept a direct `@State` array reference here (F10), because the incremental
  /// `insertRow`/`removeRow` path assumes the list's children are index-for-index with that
  /// array. Binding this argument to a computed expression would break that silently.
  let genericOverItemsOf: String?

  init(
    name: String, args: [ArgSpec], arity: Arity,
    fieldType: String? = nil, takesContent: Bool = true, genericOverItemsOf: String? = nil
  ) {
    self.name = name
    self.args = args
    self.arity = arity
    self.fieldType = fieldType ?? name
    self.takesContent = takesContent
    self.genericOverItemsOf = genericOverItemsOf
  }

  func spec(forLabel label: String?, position: Int) -> ArgSpec? {
    if let label { return args.first { $0.label == label } }
    return position < args.count ? args[position] : nil
  }
}

/// How a modifier's arguments combine into the single value its setter takes.
enum ArgCombine {
  case identity           // one argument, passed through
  case float2             // two arguments -> float2(a, b)
}

/// A modifier from UIElement+Modifiers.swift. These wrap the receiver in a new element.
/// Generated code calls the modifier itself rather than the wrapper's constructor, which keeps
/// it to public API and preserves the declarative chain's exact semantics.
struct ModifierSpec {
  let name: String
  let labels: [String?]
  let produces: String
  let setter: String?
  let combine: ArgCombine
}

enum ElementCatalog {
  static let types: [String: TypeSpec] = [
    "Rectangle": TypeSpec(name: "Rectangle", args: [ArgSpec(nil, "setColor")], arity: .single),
    "Background": TypeSpec(name: "Background", args: [ArgSpec(nil, "setColor")], arity: .single),
    "Frame": TypeSpec(
      name: "Frame",
      args: [ArgSpec(nil, "setSize"), ArgSpec(nil, "setAlignment")],
      arity: .single
    ),
    "Padding": TypeSpec(name: "Padding", args: [ArgSpec(nil, "setInset")], arity: .single),
    "VStack": TypeSpec(
      name: "VStack",
      args: [ArgSpec("alignment", "setAlignment"), ArgSpec("spacing", "setSpacing")],
      arity: .multi
    ),
    "HStack": TypeSpec(
      name: "HStack",
      args: [ArgSpec("alignment", "setAlignment"), ArgSpec("spacing", "setSpacing")],
      arity: .multi
    ),
    "ExpandedFrame": TypeSpec(
      name: "ExpandedFrame",
      args: [ArgSpec("axis", "setAxis"), ArgSpec("alignment", "setAlignment")],
      arity: .single
    ),
    // The lists own their own children, so from the macro's side they are leaves. `onCreate`
    // is opaque: it is copied verbatim and never scanned, exactly like an event handler.
    "VList": TypeSpec(
      name: "VList",
      args: [ArgSpec("alignment", "setAlignment"), ArgSpec("spacing", "setSpacing"),
             ArgSpec("items", "setItems"), ArgSpec("onCreate", nil)],
      arity: .leaf, takesContent: false, genericOverItemsOf: "items"
    ),
    "HList": TypeSpec(
      name: "HList",
      args: [ArgSpec("alignment", "setAlignment"), ArgSpec("spacing", "setSpacing"),
             ArgSpec("items", "setItems"), ArgSpec("onCreate", nil)],
      arity: .leaf, takesContent: false, genericOverItemsOf: "items"
    ),
    "Spacer": TypeSpec(name: "Spacer", args: [], arity: .leaf),
    "EmptyElement": TypeSpec(name: "EmptyElement", args: [], arity: .leaf),
  ]

  static let modifiers: [String: ModifierSpec] = [
    "frame": ModifierSpec(
      name: "frame", labels: ["width", "height"],
      produces: "Frame", setter: "setSize", combine: .float2
    ),
    "padding": ModifierSpec(
      name: "padding", labels: [nil],
      produces: "Padding", setter: "setInset", combine: .identity
    ),
    "background": ModifierSpec(
      name: "background", labels: [nil],
      produces: "Background", setter: "setColor", combine: .identity
    ),
    // The handler is opaque: closure bodies are never dependency sites.
    "onTap": ModifierSpec(
      name: "onTap", labels: [nil],
      produces: "HittableView", setter: nil, combine: .identity
    ),
    "onHover": ModifierSpec(
      name: "onHover", labels: [nil],
      produces: "HittableView", setter: nil, combine: .identity
    ),
  ]
}
