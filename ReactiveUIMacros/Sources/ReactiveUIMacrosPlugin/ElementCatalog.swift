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
  case multi    // MultiChildElement: replaceChildren(_:_:)
}

/// One constructor argument, and the setter that updates it later (nil = not reactive).
///
/// `animatable` marks setters that also take `animation: UIAnimation?`. That is every setter
/// whose value can be interpolated (colours, sizes, insets, spacing, opacity, offset, a text's
/// color and size), and every setter that moves other elements when it changes layout (text,
/// alignment, axis): those snap their own value, but what the new layout moves slides there.
struct ArgSpec {
  let label: String?
  let setter: String?
  let animatable: Bool

  init(_ label: String?, _ setter: String?, animatable: Bool = false) {
    self.label = label
    self.setter = setter
    self.animatable = animatable
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
  case labeled(String)    // only the argument with this label; the others are built once
}

/// A modifier from UIElement+Modifiers.swift. These wrap the receiver in a new element.
/// Generated code calls the modifier itself rather than the wrapper's constructor, which keeps
/// it to public API and preserves the declarative chain's exact semantics.
/// A modifier whose argument is a stored callback rather than a value.
///
/// The closure is not emitted inline the way a value argument is. It captures `self` strongly, so
/// leaving it on the element would make the component reach itself; instead the macro assigns it
/// to `property` on mount and clears it on unmount. `placeholder` is what the chain is built with
/// in the meantime — an empty closure of the right arity, since the modifier has to be called with
/// something to produce the element at all.
struct HandlerSpec {
  let property: String
  let placeholder: String
}

struct ModifierSpec {
  let name: String
  let labels: [String?]
  let produces: String
  let setter: String?
  let combine: ArgCombine
  /// Set for `onTap`/`onHover`. Mutually exclusive with `setter`: a handler has no reactive value.
  let handler: HandlerSpec?
  /// The setter takes `animation: UIAnimation?`. See `ArgSpec.animatable`.
  let animatable: Bool
  /// `.animation(_:value:)`: not an element but a scope marker. It produces no link; the parser
  /// records an `AnimationScope` instead.
  let isScope: Bool
  /// Set for modifiers that wrap nothing: they set a property of the element they are called on,
  /// which must be of this type (F13), and return it. `.font` and `.foregroundColor` on `Text`.
  ///
  /// Still a link of its own, with its own field — holding the same element as the receiver's —
  /// so everything positional, like which `.animation` scope covers it, works as for any link.
  let inPlaceOn: String?

  init(
    name: String, labels: [String?], produces: String,
    setter: String?, combine: ArgCombine, handler: HandlerSpec? = nil,
    animatable: Bool = false, isScope: Bool = false, inPlaceOn: String? = nil
  ) {
    self.name = name
    self.labels = labels
    self.produces = produces
    self.setter = setter
    self.combine = combine
    self.handler = handler
    self.animatable = animatable
    self.isScope = isScope
    self.inPlaceOn = inPlaceOn
  }
}

enum ElementCatalog {
  static let types: [String: TypeSpec] = [
    "Rectangle": TypeSpec(name: "Rectangle", args: [ArgSpec(nil, "setColor", animatable: true)], arity: .single),
    "Background": TypeSpec(name: "Background", args: [ArgSpec(nil, "setColor", animatable: true)], arity: .single),
    "Frame": TypeSpec(
      name: "Frame",
      args: [ArgSpec(nil, "setSize", animatable: true), ArgSpec(nil, "setAlignment", animatable: true)],
      arity: .single
    ),
    "Padding": TypeSpec(name: "Padding", args: [ArgSpec(nil, "setInset", animatable: true)], arity: .single),
    "VStack": TypeSpec(
      name: "VStack",
      args: [ArgSpec("alignment", "setAlignment", animatable: true), ArgSpec("spacing", "setSpacing", animatable: true)],
      arity: .multi
    ),
    "HStack": TypeSpec(
      name: "HStack",
      args: [ArgSpec("alignment", "setAlignment", animatable: true), ArgSpec("spacing", "setSpacing", animatable: true)],
      arity: .multi
    ),
    "ExpandedFrame": TypeSpec(
      name: "ExpandedFrame",
      args: [ArgSpec("axis", "setAxis", animatable: true), ArgSpec("alignment", "setAlignment", animatable: true)],
      arity: .single
    ),
    // The lists own their own children, so from the macro's side they are leaves. `onCreate`
    // is opaque: it is copied verbatim and never scanned, exactly like an event handler.
    "VList": TypeSpec(
      name: "VList",
      args: [ArgSpec("alignment", "setAlignment"), ArgSpec("spacing", "setSpacing", animatable: true),
             ArgSpec("items", "setItems"), ArgSpec("onCreate", nil)],
      arity: .leaf, takesContent: false, genericOverItemsOf: "items"
    ),
    "HList": TypeSpec(
      name: "HList",
      args: [ArgSpec("alignment", "setAlignment"), ArgSpec("spacing", "setSpacing", animatable: true),
             ArgSpec("items", "setItems"), ArgSpec("onCreate", nil)],
      arity: .leaf, takesContent: false, genericOverItemsOf: "items"
    ),
    "Text": TypeSpec(
      name: "Text",
      args: [ArgSpec(nil, "setText", animatable: true)],
      arity: .leaf
    ),
    "Spacer": TypeSpec(name: "Spacer", args: [], arity: .leaf),
    "EmptyElement": TypeSpec(name: "EmptyElement", args: [], arity: .leaf),
  ]

  static let modifiers: [String: ModifierSpec] = [
    "frame": ModifierSpec(
      name: "frame", labels: ["width", "height"],
      produces: "Frame", setter: "setSize", combine: .float2, animatable: true
    ),
    "padding": ModifierSpec(
      name: "padding", labels: [nil],
      produces: "Padding", setter: "setInset", combine: .identity, animatable: true
    ),
    "background": ModifierSpec(
      name: "background", labels: [nil],
      produces: "Background", setter: "setColor", combine: .identity, animatable: true
    ),
    "opacity": ModifierSpec(
      name: "opacity", labels: [nil],
      produces: "EffectElement", setter: "setOpacity", combine: .identity, animatable: true
    ),
    "offset": ModifierSpec(
      name: "offset", labels: [nil],
      produces: "EffectElement", setter: "setOffset", combine: .identity, animatable: true
    ),
    // Only `trigger` is reactive: the tracks are built once, with the element.
    "keyframes": ModifierSpec(
      name: "keyframes", labels: [nil, "trigger"],
      produces: "KeyframeElement", setter: "setTrigger", combine: .labeled("trigger")
    ),
    "font": ModifierSpec(
      name: "font", labels: [nil],
      produces: "Text", setter: "setFont", combine: .identity, animatable: true, inPlaceOn: "Text"
    ),
    "foregroundColor": ModifierSpec(
      name: "foregroundColor", labels: [nil],
      produces: "Text", setter: "setForegroundColor", combine: .identity, animatable: true,
      inPlaceOn: "Text"
    ),
    // Constant: a transition is how an element enters and leaves, not a value that changes.
    "transition": ModifierSpec(
      name: "transition", labels: [nil],
      produces: "TransitionElement", setter: nil, combine: .identity
    ),
    "animation": ModifierSpec(
      name: "animation", labels: [nil, "value"],
      produces: "", setter: nil, combine: .identity, isScope: true
    ),
    // The handler is opaque: closure bodies are never dependency sites.
    "onTap": ModifierSpec(
      name: "onTap", labels: [nil],
      produces: "HittableView", setter: nil, combine: .identity,
      handler: HandlerSpec(property: "onTap", placeholder: "{ _ in }")
    ),
    "onHover": ModifierSpec(
      name: "onHover", labels: [nil],
      produces: "HittableView", setter: nil, combine: .identity,
      handler: HandlerSpec(property: "onHover", placeholder: "{ _, _ in }")
    ),
  ]
}
