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
  /// Set for a binding argument, `isOn: $wifi`: the control property that takes the write-back
  /// closure. The argument is lowered at compile time into its two directions — the value
  /// `self.wifi`, bound to `setter` like any argument, and `{ self.wifi = $0 }`, armed into this
  /// property on mount. Only `$state[.member…]` and `.constant(v)` can be lowered (F14).
  let binding: HandlerSpec?
  /// Set for a callback argument, `Button("OK") { … }`: armed on mount and cleared on unmount like
  /// a handler modifier, instead of being copied into the constructor where it would capture
  /// `self` for good. The argument (or the trailing closure) is dropped from the constructor, so
  /// its parameter must be optional.
  let handler: HandlerSpec?

  init(
    _ label: String?, _ setter: String?, animatable: Bool = false,
    binding: HandlerSpec? = nil, handler: HandlerSpec? = nil
  ) {
    self.label = label
    self.setter = setter
    self.animatable = animatable
    self.binding = binding
    self.handler = handler
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
  /// Content closures besides the constructor's own, by label, and the method each is applied
  /// through: `Section { … } header: { … }` has `["header": "replaceHeader", …]`. Written
  /// trailing or as a labeled argument, each is parsed like content and never emitted.
  let namedContents: [String: String]

  init(
    name: String, args: [ArgSpec], arity: Arity,
    fieldType: String? = nil, takesContent: Bool = true, genericOverItemsOf: String? = nil,
    namedContents: [String: String] = [:]
  ) {
    self.name = name
    self.args = args
    self.arity = arity
    self.fieldType = fieldType ?? name
    self.takesContent = takesContent
    self.genericOverItemsOf = genericOverItemsOf
    self.namedContents = namedContents
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
  case construct(String)  // every argument, in order, into this initializer: `Inset(edges, length)`
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
  /// Wraps the closure when it is assigned, for a property that takes more than one closure
  /// shape: `KeyPressElement.adapt` fits `.onKeyPress`'s zero-argument handlers to its `action`.
  let adapter: String?
  /// The argument label it is written with. Nil for a modifier's main handler, which is its
  /// trailing closure, its `action:` closure, or else its first closure; set for the others,
  /// which are found by label, as an argument or a further trailing closure: `isTargeted:`.
  let label: String?

  init(property: String, placeholder: String, adapter: String? = nil, label: String? = nil) {
    self.property = property
    self.placeholder = placeholder
    self.adapter = adapter
    self.label = label
  }
}

struct ModifierSpec {
  let name: String
  let labels: [String?]
  let produces: String
  let setter: String?
  let combine: ArgCombine
  /// Set for `onTap`/`onHover`. Mutually exclusive with `setter`: a handler has no reactive value.
  let handler: HandlerSpec?
  /// Handlers besides `handler`, each found by its label: `.dropDestination`'s `isTargeted:`.
  /// Left out of the chain, where the modifier's default stands in until they are armed.
  let labeledHandlers: [HandlerSpec]
  /// The setter takes `animation: UIAnimation?`. See `ArgSpec.animatable`.
  let animatable: Bool
  /// `.animation(_:value:)`: not an element but a scope marker. It produces no link; the parser
  /// records an `AnimationScope` instead.
  let isScope: Bool
  /// Set for modifiers that wrap nothing: they set a property of the element they are called on,
  /// which must be one of these types (F13), and return it. `.font` on `Text`, `.foregroundColor`
  /// on `Text` and `Image`, `.resizable` and the other image modifiers on `Image`.
  ///
  /// Still a link of its own, with its own field — holding the same element as the receiver's,
  /// and typed as the receiver — so everything positional, like which `.animation` scope covers
  /// it, works as for any link.
  let inPlaceOn: Set<String>?
  /// With `inPlaceOn`: called on anything else, the modifier wraps it in `produces` as usual
  /// instead of being an error. `.offset`, `.opacity` and the handlers set a vector shape's own
  /// property, and wrap every other element.
  let wrapsOtherwise: Bool
  /// Binds each argument to a setter of its own, found by label, instead of combining them into
  /// one value for `setter`: `.stroke(color, lineWidth:)` updates the color and the width apart.
  let argSetters: [ArgSpec]?
  /// Sets a property every element has, and returns the element it is called on, whatever it
  /// is: `.layoutPriority`. Like `inPlaceOn`, but with no type to check.
  let inPlaceOnAny: Bool
  /// Among overloads, this one is only picked when called with exactly `labels`, not a subset.
  let exactLabels: Bool
  /// Its trailing or `content:` closure is content, parsed like a container's and applied with
  /// the element's `replaceContent`: `.overlay { … }`.
  let takesContent: Bool
  /// The label of a `T.self` argument that specialises `produces`, e.g. `for` on
  /// `.onGeometryChange(for: float2.self, …)`, giving a field typed
  /// `GeometryChangeElement<float2>`.
  let genericOverTypeOf: String?
  /// The label `takesContent`'s closure may be written with instead of trailing: `.draggable(x,
  /// preview: { … })`.
  let contentLabel: String

  init(
    name: String, labels: [String?], produces: String,
    setter: String?, combine: ArgCombine, handler: HandlerSpec? = nil,
    animatable: Bool = false, isScope: Bool = false, inPlaceOn: Set<String>? = nil,
    wrapsOtherwise: Bool = false, argSetters: [ArgSpec]? = nil, inPlaceOnAny: Bool = false,
    exactLabels: Bool = false, takesContent: Bool = false, genericOverTypeOf: String? = nil,
    labeledHandlers: [HandlerSpec] = [], contentLabel: String = "content"
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
    self.wrapsOtherwise = wrapsOtherwise
    self.argSetters = argSetters
    self.inPlaceOnAny = inPlaceOnAny
    self.exactLabels = exactLabels
    self.takesContent = takesContent
    self.genericOverTypeOf = genericOverTypeOf
    self.labeledHandlers = labeledHandlers
    self.contentLabel = contentLabel
  }

  /// Every closure label a handler of this modifier is written with, the main one's included.
  var handlerLabels: Set<String> {
    Set(([self.handler?.label ?? "action"]) + self.labeledHandlers.compactMap(\.label))
  }

  /// Whether a call with these argument labels, in order, is this overload.
  func accepts(_ labels: [String?]) -> Bool {
    self.exactLabels ? labels == self.labels : labels.allSatisfy { self.labels.contains($0) }
  }
}

enum ElementCatalog {
  /// The shapes a `VectorCanvas` draws.
  static let vectorShapes: Set<String> = ["Circle", "Ellipse", "RoundedRectangle", "Capsule", "Path"]

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
    "ZStack": TypeSpec(
      name: "ZStack", args: [ArgSpec("alignment", "setAlignment", animatable: true)], arity: .multi
    ),
    "Grid": TypeSpec(
      name: "Grid",
      args: [ArgSpec("alignment", "setAlignment", animatable: true),
             ArgSpec("horizontalSpacing", "setHorizontalSpacing", animatable: true),
             ArgSpec("verticalSpacing", "setVerticalSpacing", animatable: true)],
      arity: .multi
    ),
    "GridRow": TypeSpec(name: "GridRow", args: [ArgSpec("alignment", "setAlignment", animatable: true)], arity: .multi),
    "LazyVGrid": TypeSpec(
      name: "LazyVGrid",
      args: [ArgSpec("columns", "setItems", animatable: true), ArgSpec("alignment", "setAlignment", animatable: true),
             ArgSpec("spacing", "setSpacing", animatable: true)],
      arity: .multi
    ),
    "LazyHGrid": TypeSpec(
      name: "LazyHGrid",
      args: [ArgSpec("rows", "setItems", animatable: true), ArgSpec("alignment", "setAlignment", animatable: true),
             ArgSpec("spacing", "setSpacing", animatable: true)],
      arity: .multi
    ),
    "ViewThatFits": TypeSpec(name: "ViewThatFits", args: [ArgSpec("in", "setAxes", animatable: true)], arity: .multi),
    // Keeps its children when the layout changes; with an animation they slide.
    "LayoutView": TypeSpec(name: "LayoutView", args: [ArgSpec(nil, "setLayout", animatable: true)], arity: .multi),
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
    // Like the lists: rows come from `items` through `onCreate`, built only near what shows.
    "LazyVStack": TypeSpec(
      name: "LazyVStack",
      args: [ArgSpec("alignment", "setAlignment"), ArgSpec("spacing", "setSpacing", animatable: true),
             ArgSpec("items", "setItems"), ArgSpec("onCreate", nil)],
      arity: .leaf, takesContent: false, genericOverItemsOf: "items"
    ),
    "LazyHStack": TypeSpec(
      name: "LazyHStack",
      args: [ArgSpec("alignment", "setAlignment"), ArgSpec("spacing", "setSpacing", animatable: true),
             ArgSpec("items", "setItems"), ArgSpec("onCreate", nil)],
      arity: .leaf, takesContent: false, genericOverItemsOf: "items"
    ),
    // A lazy list with columns. The trailing closure is its columns, opaque like `onCreate`;
    // selection and sort order are values in, callbacks out.
    "Table": TypeSpec(
      name: "Table",
      args: [ArgSpec("items", "setItems"), ArgSpec("selection", "setSelection"),
             ArgSpec("sortOrder", "setSortOrder"), ArgSpec("onSelectionChange", nil),
             ArgSpec("onSortOrderChange", nil), ArgSpec("columns", nil)],
      arity: .leaf, takesContent: false, genericOverItemsOf: "items"
    ),
    "ScrollView": TypeSpec(
      name: "ScrollView",
      args: [ArgSpec(nil, "setAxes", animatable: true), ArgSpec("showsIndicators", "setShowsIndicators")],
      arity: .single
    ),
    "Text": TypeSpec(
      name: "Text",
      args: [ArgSpec(nil, "setText", animatable: true)],
      arity: .leaf
    ),
    "Image": TypeSpec(
      name: "Image",
      args: [ArgSpec(nil, "setName", animatable: true), ArgSpec("bundle", nil),
             ArgSpec("nsImage", "setNSImage", animatable: true), ArgSpec("svg", "setSVG", animatable: true)],
      arity: .leaf
    ),
    "VectorCanvas": TypeSpec(
      name: "VectorCanvas", args: [ArgSpec("width", nil), ArgSpec("height", nil)], arity: .multi
    ),
    "Circle": TypeSpec(
      name: "Circle",
      args: [ArgSpec("center", "setCenter", animatable: true), ArgSpec("radius", "setRadius", animatable: true)],
      arity: .leaf
    ),
    "Ellipse": TypeSpec(
      name: "Ellipse",
      args: [ArgSpec("center", "setCenter", animatable: true), ArgSpec("radii", "setRadii", animatable: true)],
      arity: .leaf
    ),
    "RoundedRectangle": TypeSpec(
      name: "RoundedRectangle",
      args: [ArgSpec("origin", "setOrigin", animatable: true), ArgSpec("size", "setSize", animatable: true),
             ArgSpec("cornerRadius", "setCornerRadius", animatable: true)],
      arity: .leaf
    ),
    "Capsule": TypeSpec(
      name: "Capsule",
      args: [ArgSpec("origin", "setOrigin", animatable: true), ArgSpec("size", "setSize", animatable: true)],
      arity: .leaf
    ),
    // A trailing builder closure is opaque and stays in the constructor: `takesContent` is false.
    "Path": TypeSpec(
      name: "Path",
      args: [ArgSpec(nil, "setValue", animatable: true), ArgSpec("d", "setD", animatable: true)],
      arity: .leaf, takesContent: false
    ),
    "Divider": TypeSpec(name: "Divider", args: [ArgSpec("color", nil), ArgSpec("thickness", nil)], arity: .leaf),
    "Spacer": TypeSpec(name: "Spacer", args: [ArgSpec("minLength", "setMinLength", animatable: true)], arity: .leaf),
    "FlexFrame": TypeSpec(name: "FlexFrame", args: flexFrameArgs, arity: .single),
    "EmptyElement": TypeSpec(name: "EmptyElement", args: [], arity: .leaf),

    // Forms. The containers and the controls that take content own an internal tree, so their
    // content goes through their own `replaceChildren` (arity `.multi`), never `setChild`, which
    // would replace that tree.
    "Form": TypeSpec(name: "Form", args: [], arity: .multi),
    "Section": TypeSpec(
      name: "Section",
      args: [ArgSpec(nil, "setHeader", animatable: true), ArgSpec("footer", "setFooter", animatable: true)],
      arity: .multi, namedContents: ["header": "replaceHeader", "footer": "replaceFooter"]
    ),
    "LabeledContent": TypeSpec(
      name: "LabeledContent",
      args: [ArgSpec(nil, "setLabel", animatable: true), ArgSpec("value", "setValue", animatable: true)],
      arity: .multi
    ),
    "Toggle": TypeSpec(
      name: "Toggle",
      args: [ArgSpec(nil, "setLabel", animatable: true),
             ArgSpec("isOn", "setIsOn", animatable: true, binding: HandlerSpec(property: "onIsOnChange", placeholder: ""))],
      arity: .leaf
    ),
    // As in SwiftUI, the trailing closure is the action unless `action:` was passed, and then it
    // is the label: `Button("OK") { … }`, `Button { … } label: { … }`, `Button(action: f) { … }`.
    // The label goes through the button's own `replaceChildren`.
    "Button": TypeSpec(
      name: "Button",
      args: [ArgSpec(nil, "setTitle", animatable: true), ArgSpec("role", nil),
             ArgSpec("action", nil, handler: HandlerSpec(property: "action", placeholder: ""))],
      arity: .multi, namedContents: ["label": "replaceChildren"]
    ),
    // A numeric binding is adapted: the control works in `Double`, the state in its own type.
    "Slider": TypeSpec(
      name: "Slider",
      args: [ArgSpec(nil, "setLabel", animatable: true),
             ArgSpec("value", "setValue", animatable: true,
                     binding: HandlerSpec(property: "onValueChange", placeholder: "", adapter: "Slider.adapt")),
             ArgSpec("in", nil), ArgSpec("step", nil)],
      arity: .leaf
    ),
    "Stepper": TypeSpec(
      name: "Stepper",
      args: [ArgSpec(nil, "setLabel", animatable: true),
             ArgSpec("value", "setValue",
                     binding: HandlerSpec(property: "onValueChange", placeholder: "", adapter: "Stepper.adapt")),
             ArgSpec("in", nil), ArgSpec("step", nil)],
      arity: .leaf
    ),
    "TextField": TypeSpec(
      name: "TextField",
      args: [ArgSpec(nil, "setLabel", animatable: true),
             ArgSpec("text", "setText", animatable: true, binding: HandlerSpec(property: "onTextChange", placeholder: "")),
             ArgSpec("prompt", "setPrompt", animatable: true)],
      arity: .leaf
    ),
    "SecureField": TypeSpec(
      name: "SecureField",
      args: [ArgSpec(nil, "setLabel", animatable: true),
             ArgSpec("text", "setText", animatable: true, binding: HandlerSpec(property: "onTextChange", placeholder: "")),
             ArgSpec("prompt", "setPrompt", animatable: true)],
      arity: .leaf
    ),
    // Its content is the options, each tagged with the value it selects.
    "Picker": TypeSpec(
      name: "Picker",
      args: [ArgSpec(nil, "setLabel", animatable: true),
             ArgSpec("selection", "setSelection", animatable: true,
                     binding: HandlerSpec(property: "onSelectionChange", placeholder: "", adapter: "Picker.adapt"))],
      arity: .multi
    ),
    "DisclosureGroup": TypeSpec(
      name: "DisclosureGroup",
      args: [ArgSpec(nil, "setLabel", animatable: true),
             ArgSpec("isExpanded", "setIsExpanded", animatable: true,
                     binding: HandlerSpec(property: "onIsExpandedChange", placeholder: ""))],
      arity: .multi
    ),
    // `in:` and `displayedComponents:` are built once.
    "DatePicker": TypeSpec(
      name: "DatePicker",
      args: [ArgSpec(nil, "setLabel", animatable: true),
             ArgSpec("selection", "setSelection", binding: HandlerSpec(property: "onSelectionChange", placeholder: "")),
             ArgSpec("in", nil), ArgSpec("displayedComponents", nil)],
      arity: .leaf
    ),
    "ColorPicker": TypeSpec(
      name: "ColorPicker",
      args: [ArgSpec(nil, "setLabel", animatable: true),
             ArgSpec("selection", "setSelection", animatable: true,
                     binding: HandlerSpec(property: "onSelectionChange", placeholder: "")),
             ArgSpec("supportsOpacity", nil)],
      arity: .leaf
    ),
    "ProgressView": TypeSpec(
      name: "ProgressView",
      args: [ArgSpec("value", "setValue", animatable: true), ArgSpec("total", "setTotal", animatable: true)],
      arity: .leaf
    ),
  ]

  /// What `.disabled` can be called on.
  static let formControls: Set<String> = [
    "Toggle", "Button", "Slider", "Stepper", "TextField", "SecureField", "Picker", "DisclosureGroup",
    "DatePicker", "ColorPicker",
  ]

  static let flexFrameArgs: [ArgSpec] = [
    ArgSpec("minWidth", "setMinWidth", animatable: true), ArgSpec("idealWidth", "setIdealWidth", animatable: true),
    ArgSpec("maxWidth", "setMaxWidth", animatable: true), ArgSpec("minHeight", "setMinHeight", animatable: true),
    ArgSpec("idealHeight", "setIdealHeight", animatable: true), ArgSpec("maxHeight", "setMaxHeight", animatable: true),
    ArgSpec("alignment", "setAlignment", animatable: true),
  ]

  /// Modifiers spelled the same that make different elements, or bind differently, told apart by
  /// their argument labels. The first overload that accepts a call's labels is the one.
  static let modifierOverloads: [String: [ModifierSpec]] = [
    "padding": [
      // `.padding(.horizontal, 8)`: both into one inset.
      ModifierSpec(
        name: "padding", labels: [nil, nil],
        produces: "Padding", setter: "setInset", combine: .construct("Inset"), animatable: true, exactLabels: true
      ),
      // `.padding(Inset(…))`, `.padding(8)`, `.padding(.horizontal)` or `.padding()`: the setter
      // is overloaded on the argument's type.
      ModifierSpec(
        name: "padding", labels: [nil],
        produces: "Padding", setter: "setInset", combine: .identity, animatable: true
      ),
    ],
    "offset": [
      ModifierSpec(
        name: "offset", labels: [nil],
        produces: "EffectElement", setter: "setOffset", combine: .identity, animatable: true,
        inPlaceOn: vectorShapes, wrapsOtherwise: true, exactLabels: true
      ),
      ModifierSpec(
        name: "offset", labels: ["x", "y"],
        produces: "EffectElement", setter: "setOffset", combine: .float2, animatable: true,
        inPlaceOn: vectorShapes, wrapsOtherwise: true, exactLabels: true
      ),
      // One of the two: built once, like the element.
      ModifierSpec(
        name: "offset", labels: ["x", "y"],
        produces: "EffectElement", setter: nil, combine: .identity,
        inPlaceOn: vectorShapes, wrapsOtherwise: true
      ),
    ],
    "position": [
      ModifierSpec(
        name: "position", labels: [nil],
        produces: "PositionElement", setter: "setPoint", combine: .identity, animatable: true, exactLabels: true
      ),
      ModifierSpec(
        name: "position", labels: ["x", "y"],
        produces: "PositionElement", setter: "setPoint", combine: .float2, animatable: true, exactLabels: true
      ),
      ModifierSpec(name: "position", labels: ["x", "y"], produces: "PositionElement", setter: nil, combine: .identity),
    ],
    "background": [
      ModifierSpec(
        name: "background", labels: [nil],
        produces: "Background", setter: "setColor", combine: .identity, animatable: true, exactLabels: true
      ),
      // `.background(.blue, in: .capsule)`: the color and the shape each on their own.
      ModifierSpec(
        name: "background", labels: [nil, "in"],
        produces: "Background", setter: nil, combine: .identity,
        argSetters: [ArgSpec(nil, "setColor", animatable: true), ArgSpec("in", "setShape", animatable: true)],
        exactLabels: true
      ),
      contentModifier("background"),
    ],
    "frame": [
      // Both sides: one animatable size, as it always was.
      ModifierSpec(
        name: "frame", labels: ["width", "height"],
        produces: "Frame", setter: "setSize", combine: .float2, animatable: true, exactLabels: true
      ),
      // Either side, or none, and an alignment: each bound on its own.
      ModifierSpec(
        name: "frame", labels: ["width", "height", "alignment"],
        produces: "Frame", setter: nil, combine: .identity,
        argSetters: [ArgSpec("width", "setWidth", animatable: true), ArgSpec("height", "setHeight", animatable: true),
                     ArgSpec("alignment", "setAlignment", animatable: true)]
      ),
      ModifierSpec(
        name: "frame", labels: flexFrameArgs.map(\.label),
        produces: "FlexFrame", setter: nil, combine: .identity, argSetters: flexFrameArgs
      ),
    ],
  ]

  /// `.overlay(alignment:) { … }` and `.background(alignment:) { … }`.
  static func contentModifier(_ name: String) -> ModifierSpec {
    ModifierSpec(
      name: name, labels: ["alignment", "content"],
      produces: "OverlayElement", setter: nil, combine: .identity,
      argSetters: [ArgSpec("alignment", "setAlignment", animatable: true)], takesContent: true
    )
  }

  /// The modifier `name` called with `labels`, or nil when there is none.
  static func modifier(named name: String, labels: [String?]) -> ModifierSpec? {
    if let overloads = modifierOverloads[name] {
      return overloads.first { $0.accepts(labels) }
    }
    return modifiers[name]
  }

  static let modifiers: [String: ModifierSpec] = [
    // In place on any element: a priority is read through the wrappers around it.
    "layoutPriority": ModifierSpec(
      name: "layoutPriority", labels: [nil],
      produces: "UIElement", setter: "setLayoutPriority", combine: .identity, animatable: true, inPlaceOnAny: true
    ),
    "overlay": contentModifier("overlay"),
    // Constant, as in SwiftUI.
    "fixedSize": ModifierSpec(
      name: "fixedSize", labels: ["horizontal", "vertical"], produces: "FixedSizeElement", setter: nil, combine: .identity
    ),
    // How a `Grid` lays out a cell: in place on any element, read through its wrappers.
    "gridCellColumns": ModifierSpec(
      name: "gridCellColumns", labels: [nil], produces: "UIElement", setter: "setGridCellColumns",
      combine: .identity, animatable: true, inPlaceOnAny: true
    ),
    "gridColumnAlignment": ModifierSpec(
      name: "gridColumnAlignment", labels: [nil], produces: "UIElement", setter: "setGridColumnAlignment",
      combine: .identity, animatable: true, inPlaceOnAny: true
    ),
    "gridCellAnchor": ModifierSpec(
      name: "gridCellAnchor", labels: [nil], produces: "UIElement", setter: "setGridCellAnchor",
      combine: .identity, animatable: true, inPlaceOnAny: true
    ),
    "gridCellUnsizedAxes": ModifierSpec(
      name: "gridCellUnsizedAxes", labels: [nil], produces: "UIElement", setter: "setGridCellUnsizedAxes",
      combine: .identity, animatable: true, inPlaceOnAny: true
    ),
    "clipped": ModifierSpec(name: "clipped", labels: [], produces: "ClipElement", setter: nil, combine: .identity),
    // Corner radii animate; a change of shape kind snaps.
    "clipShape": ModifierSpec(
      name: "clipShape", labels: [nil],
      produces: "ClipElement", setter: "setShape", combine: .identity, animatable: true
    ),
    "cornerRadius": ModifierSpec(
      name: "cornerRadius", labels: [nil],
      produces: "ClipElement", setter: "setCornerRadius", combine: .identity, animatable: true
    ),
    "border": ModifierSpec(
      name: "border", labels: [nil, "width", "in"],
      produces: "BorderElement", setter: nil, combine: .identity,
      argSetters: [ArgSpec(nil, "setColor", animatable: true), ArgSpec("width", "setLineWidth", animatable: true),
                   ArgSpec("in", "setShape", animatable: true)]
    ),
    "shadow": ModifierSpec(
      name: "shadow", labels: ["color", "radius", "x", "y"],
      produces: "ShadowElement", setter: nil, combine: .identity,
      argSetters: [ArgSpec("color", "setColor", animatable: true), ArgSpec("radius", "setRadius", animatable: true),
                   ArgSpec("x", "setX", animatable: true), ArgSpec("y", "setY", animatable: true)]
    ),
    "blur": ModifierSpec(
      name: "blur", labels: ["radius"],
      produces: "BlurElement", setter: nil, combine: .identity,
      argSetters: [ArgSpec("radius", "setRadius", animatable: true)]
    ),
    // `.glass(.thin, in: .rect(cornerRadius: 16))`: the material snaps, the shape animates.
    "glass": ModifierSpec(
      name: "glass", labels: [nil, "in"],
      produces: "GlassBackground", setter: nil, combine: .identity,
      argSetters: [ArgSpec(nil, "setMaterial"), ArgSpec("in", "setShape", animatable: true)]
    ),
    // The closure is copied as written and runs at layout time; nothing in it is bound.
    "alignmentGuide": ModifierSpec(
      name: "alignmentGuide", labels: [nil, "computeValue"],
      produces: "UIElement", setter: nil, combine: .identity, inPlaceOnAny: true
    ),
    "hidden": ModifierSpec(
      name: "hidden", labels: [], produces: "UIElement", setter: nil, combine: .identity, inPlaceOnAny: true
    ),
    // Reorders what is drawn; nothing to interpolate.
    "zIndex": ModifierSpec(
      name: "zIndex", labels: [nil],
      produces: "UIElement", setter: "setZIndex", combine: .identity, inPlaceOnAny: true
    ),
    "opacity": ModifierSpec(
      name: "opacity", labels: [nil],
      produces: "EffectElement", setter: "setOpacity", combine: .identity, animatable: true,
      inPlaceOn: vectorShapes, wrapsOtherwise: true
    ),
    // How a vector shape is painted and moved.
    "fill": ModifierSpec(
      name: "fill", labels: [nil],
      produces: "Path", setter: "setColor", combine: .identity, animatable: true, inPlaceOn: vectorShapes
    ),
    "stroke": ModifierSpec(
      name: "stroke", labels: [nil, "lineWidth"],
      produces: "Path", setter: nil, combine: .identity, inPlaceOn: vectorShapes,
      argSetters: [ArgSpec(nil, "setColor", animatable: true), ArgSpec("lineWidth", "setLineWidth", animatable: true)]
    ),
    "trim": ModifierSpec(
      name: "trim", labels: ["from", "to"],
      produces: "Path", setter: nil, combine: .identity, inPlaceOn: vectorShapes,
      argSetters: [ArgSpec("from", "setTrimFrom", animatable: true), ArgSpec("to", "setTrimTo", animatable: true)]
    ),
    "rotationEffect": ModifierSpec(
      name: "rotationEffect", labels: [nil, "anchor"],
      produces: "Path", setter: nil, combine: .identity, inPlaceOn: vectorShapes,
      argSetters: [ArgSpec(nil, "setRotation", animatable: true), ArgSpec("anchor", "setRotationAnchor")]
    ),
    "scaleEffect": ModifierSpec(
      name: "scaleEffect", labels: [nil, "anchor"],
      produces: "Path", setter: nil, combine: .identity, inPlaceOn: vectorShapes,
      argSetters: [ArgSpec(nil, "setScale", animatable: true), ArgSpec("anchor", "setScaleAnchor")]
    ),
    // Only `trigger` is reactive: the tracks are built once, with the element.
    "keyframes": ModifierSpec(
      name: "keyframes", labels: [nil, "trigger"],
      produces: "KeyframeElement", setter: "setTrigger", combine: .labeled("trigger")
    ),
    "font": ModifierSpec(
      name: "font", labels: [nil],
      produces: "Text", setter: "setFont", combine: .identity, animatable: true, inPlaceOn: ["Text"]
    ),
    "scrollDisabled": ModifierSpec(
      name: "scrollDisabled", labels: [nil],
      produces: "ScrollView", setter: "setScrollDisabled", combine: .identity, inPlaceOn: ["ScrollView"]
    ),
    "scrollIndicators": ModifierSpec(
      name: "scrollIndicators", labels: [nil],
      produces: "ScrollView", setter: "setIndicatorVisibility", combine: .identity, inPlaceOn: ["ScrollView"]
    ),
    // Constant: an id is what `ScrollViewProxy.scrollTo` finds the element by.
    "id": ModifierSpec(
      name: "id", labels: [nil],
      produces: "IDElement", setter: nil, combine: .identity
    ),
    // `produces` is only a default: an in-place link is typed as its receiver.
    "foregroundColor": ModifierSpec(
      name: "foregroundColor", labels: [nil],
      produces: "Text", setter: "setForegroundColor", combine: .identity, animatable: true,
      inPlaceOn: ["Text", "Image"]
    ),
    // How an image is sized and drawn: constant, built once with it.
    "resizable": ModifierSpec(
      name: "resizable", labels: [], produces: "Image", setter: nil, combine: .identity,
      inPlaceOn: ["Image", "VectorCanvas"]
    ),
    // On an image, its own; on anything else, an `AspectRatioElement` around it.
    "aspectRatio": ModifierSpec(
      name: "aspectRatio", labels: [nil, "contentMode"],
      produces: "AspectRatioElement", setter: nil, combine: .identity, inPlaceOn: ["Image"], wrapsOtherwise: true
    ),
    "scaledToFit": ModifierSpec(
      name: "scaledToFit", labels: [], produces: "AspectRatioElement", setter: nil, combine: .identity,
      inPlaceOn: ["Image"], wrapsOtherwise: true
    ),
    "scaledToFill": ModifierSpec(
      name: "scaledToFill", labels: [], produces: "AspectRatioElement", setter: nil, combine: .identity,
      inPlaceOn: ["Image"], wrapsOtherwise: true
    ),
    "renderingMode": ModifierSpec(
      name: "renderingMode", labels: [nil],
      produces: "Image", setter: nil, combine: .identity, inPlaceOn: ["Image"]
    ),
    "interpolation": ModifierSpec(
      name: "interpolation", labels: [nil],
      produces: "Image", setter: nil, combine: .identity, inPlaceOn: ["Image"]
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
    // On a vector shape, hit only inside its outline.
    "onTap": ModifierSpec(
      name: "onTap", labels: [nil],
      produces: "HittableView", setter: nil, combine: .identity,
      handler: HandlerSpec(property: "onTap", placeholder: "{ _ in }"),
      inPlaceOn: vectorShapes, wrapsOtherwise: true
    ),
    "onHover": ModifierSpec(
      name: "onHover", labels: [nil],
      produces: "HittableView", setter: nil, combine: .identity,
      handler: HandlerSpec(property: "onHover", placeholder: "{ _, _ in }"),
      inPlaceOn: vectorShapes, wrapsOtherwise: true
    ),
    // The action is a handler, armed on mount; `for:` and `of:` are built once.
    "onGeometryChange": ModifierSpec(
      name: "onGeometryChange", labels: ["for", "of", "action"],
      produces: "GeometryChangeElement", setter: nil, combine: .identity,
      handler: HandlerSpec(property: "action", placeholder: "{ _ in }"), genericOverTypeOf: "for"
    ),
    // The payload is reactive, so a row's draggable carries its current value; the preview is
    // content, applied through `DraggableElement.replaceContent`.
    "draggable": ModifierSpec(
      name: "draggable", labels: [nil, "preview"],
      produces: "DraggableElement", setter: nil, combine: .identity,
      argSetters: [ArgSpec(nil, "setDragPayload")], takesContent: true, contentLabel: "preview"
    ),
    // Two handlers: the drop, and whether a drag is over it. `for:` is built once.
    "dropDestination": ModifierSpec(
      name: "dropDestination", labels: ["for", "action", "isTargeted"],
      produces: "DropDestinationElement", setter: nil, combine: .identity,
      handler: HandlerSpec(property: "action", placeholder: "{ _, _ in false }"),
      genericOverTypeOf: "for",
      labeledHandlers: [HandlerSpec(property: "isTargeted", placeholder: "{ _ in }", label: "isTargeted")]
    ),
    // On a `VList` or `HList`: drag-to-reorder its rows.
    "onMove": ModifierSpec(
      name: "onMove", labels: ["perform"],
      produces: "ReorderElement", setter: nil, combine: .identity,
      handler: HandlerSpec(property: "action", placeholder: "{ _, _ in }", label: "perform")
    ),
    "onPress": ModifierSpec(
      name: "onPress", labels: [nil],
      produces: "HittableView", setter: nil, combine: .identity,
      handler: HandlerSpec(property: "onPress", placeholder: "{ _, _ in }"),
      inPlaceOn: vectorShapes, wrapsOtherwise: true
    ),
    // Every overload makes the same element with the same handler, so one spec covers them. The
    // key, keys, characters and phases are built once.
    "onKeyPress": ModifierSpec(
      name: "onKeyPress", labels: [nil, "keys", "characters", "phases", "action"],
      produces: "KeyPressElement", setter: nil, combine: .identity,
      handler: HandlerSpec(property: "action", placeholder: "{ _ in .ignored }", adapter: "KeyPressElement.adapt")
    ),
    "focusable": ModifierSpec(
      name: "focusable", labels: [nil],
      produces: "FocusableElement", setter: "setFocusable", combine: .identity
    ),
    // In place: they set the focusable element's own focus and handler.
    "focused": ModifierSpec(
      name: "focused", labels: [nil],
      produces: "FocusableElement", setter: "setFocused", combine: .identity,
      inPlaceOn: ["FocusableElement"]
    ),
    "onFocusChange": ModifierSpec(
      name: "onFocusChange", labels: [nil],
      produces: "FocusableElement", setter: nil, combine: .identity,
      handler: HandlerSpec(property: "onFocusChange", placeholder: "{ _ in }"),
      inPlaceOn: ["FocusableElement"]
    ),
    // Forms. A tag is what a picker option selects: constant, like an id.
    "tag": ModifierSpec(
      name: "tag", labels: [nil], produces: "UIElement", setter: nil, combine: .identity, inPlaceOnAny: true
    ),
    "pickerStyle": ModifierSpec(
      name: "pickerStyle", labels: [nil],
      produces: "Picker", setter: "setPickerStyle", combine: .identity, animatable: true, inPlaceOn: ["Picker"]
    ),
    "buttonStyle": ModifierSpec(
      name: "buttonStyle", labels: [nil],
      produces: "Button", setter: "setButtonStyle", combine: .identity, animatable: true, inPlaceOn: ["Button"]
    ),
    "datePickerStyle": ModifierSpec(
      name: "datePickerStyle", labels: [nil],
      produces: "DatePicker", setter: "setDatePickerStyle", combine: .identity, animatable: true, inPlaceOn: ["DatePicker"]
    ),
    "disabled": ModifierSpec(
      name: "disabled", labels: [nil],
      produces: "FormControl", setter: "setDisabled", combine: .identity, animatable: true, inPlaceOn: formControls
    ),
    "onSubmit": ModifierSpec(
      name: "onSubmit", labels: [nil],
      produces: "TextField", setter: nil, combine: .identity,
      handler: HandlerSpec(property: "onSubmit", placeholder: "{}"),
      inPlaceOn: ["TextField", "SecureField"]
    ),
  ]
}
