import SwiftSyntaxMacros
import SwiftSyntaxMacrosGenericTestSupport
import Testing

@testable import ReactiveUIMacrosPlugin

// `.animation(_:value:)` is resolved at compile time: each update method passes the animation of
// the innermost scope covering a binding and triggered by that state, or else
// `UITransaction.animation` (set by `withAnimation`). The remount replay passes `animated: false`.
@Suite("Animation scopes")
struct AnimationMacroTests {
  private static let macros: [String: Macro.Type] = [
    "Component": ComponentMacro.self, "State": StateMacro.self,
  ]

  // The Rectangle is written before the scope, so a write to `c` animates it with the scope's
  // constant animation. The Background comes after the scope, and the Frame reads only `w`,
  // which the scope does not trigger on: both fall back to the transaction.
  @Test("a scope animates the links before it, and only for the states its value reads")
  func scopeCoversLinksBeforeIt() {
    assertMacroExpansion(
      """
      @Component
      final class Chain: SingleChildElement {
        @State var c: float4 = .red
        @State var w: Float = 10

        @UIElementBuilder var body: [UIElement] {
          Rectangle(self.c)
            .frame(width: self.w, height: 10)
            .animation(.easeOut(0.2), value: self.c)
            .background(self.c)
        }
      }
      """,
      expandedSource: """
      final class Chain: SingleChildElement {
        var c: float4 {
            @storageRestrictions(initializes: _c)
            init(initialValue) {
              _c = initialValue
            }
            get {
              _c
            }
            set {
              _c = newValue
              self.__update_c()
            }
            _modify {
              yield &_c
              self.__update_c()
            }
        }

        private var _c: float4

        var $c: Binding<float4> {
          Binding(unowned: self, \\.c)
        }

        private func __requiresComponent_c() {
          let _: any ReactiveComponent = self
        }
        var w: Float {
            @storageRestrictions(initializes: _w)
            init(initialValue) {
              _w = initialValue
            }
            get {
              _w
            }
            set {
              _w = newValue
              self.__update_w()
            }
            _modify {
              yield &_w
              self.__update_w()
            }
        }

        private var _w: Float

        var $w: Binding<Float> {
          Binding(unowned: self, \\.w)
        }

        private func __requiresComponent_w() {
          let _: any ReactiveComponent = self
        }

        @UIElementBuilder var body: [UIElement] {
          Rectangle(self.c)
            .frame(width: self.w, height: 10)
            .animation(.easeOut(0.2), value: self.c)
            .background(self.c)
        }

          private var __context: UIContext? = nil

          private var __needsRefresh: Bool = false

          private var __built: Bool = false

          private var __n0a: Rectangle? = nil

          private var __n0b: Frame? = nil

          private var __n0c: Background? = nil

          private static let __anim0_0: UIAnimation? = .easeOut(0.2)

          public override func mount(_ context: UIContext) {
            self.__context = context
            if !self.__built {
              self.__built = true
              self.setChild(self.__build(context), context)
            } else if self.__needsRefresh {
              self.__needsRefresh = false
              self.__refreshAll()
            }
          }

          public override func unmount(_ context: UIContext) {
            self.__context = nil
          }

          private func __refreshAll() {
            self.__update_c(false)
            self.__update_w(false)
          }

          private func __build(_ context: UIContext) -> UIElement {
            let n0a = Rectangle(self._c)
            self.__n0a = n0a
            let n0b = n0a.frame(width: self._w, height: 10)
            self.__n0b = n0b
            let n0c = n0b.background(self._c)
            self.__n0c = n0c
            var root: [UIElement] = []
            if let e = self.__n0c {
                root.append(e)
            }
            return root.first ?? EmptyElement()
          }

          private func __applyChildrenRoot(_ context: UIContext, animation: UIAnimation?) {
            var children: [UIElement] = []
            if let e = self.__n0c {
                children.append(e)
            }
            self.setChild(children.first ?? EmptyElement(), context, animation: animation)
          }

          private func __update_c(_ animated: Bool = true) {
            guard let context = self.__context else {
              self.__needsRefresh = true
              return
            }
            let transaction = animated ? UITransaction.animation : nil
            if let n = self.__n0a {
                n.setColor(self._c, context, animation: animated ? Self.__anim0_0 : nil)
            }
            if let n = self.__n0c {
                n.setColor(self._c, context, animation: transaction)
            }
          }

          private func __update_w(_ animated: Bool = true) {
            guard let context = self.__context else {
              self.__needsRefresh = true
              return
            }
            let transaction = animated ? UITransaction.animation : nil
            if let n = self.__n0b {
                n.setSize(float2(self._w, 10), context, animation: transaction)
            }
          }
      }

      extension Chain: ReactiveComponent {
      }
      """,
      macros: Self.macros
    )
  }

  // `on` animates the VStack with its own easeIn scope and the Rectangle with the linear
  // scope written right on it. `title` triggers only the spring scope: the Text below it and
  // its frame both get it — the frame springs, and the text, which snaps itself, hands it to
  // the layout change so whatever it moves slides.
  // Two scopes written back to back cover the same links, so constants are named by position.
  @Test("the innermost scope a state triggers wins, and reaches text and frame alike")
  func innermostScopeWins() {
    assertMacroExpansion(
      """
      @Component
      final class Nested: SingleChildElement {
        @State var on: Bool = false
        @State var title: String = ""

        @UIElementBuilder var body: [UIElement] {
          VStack(spacing: self.on ? 4 : 8) {
            Rectangle(self.on ? .red : .blue)
              .animation(.linear(0.1), value: self.on)
            Text(self.title)
              .frame(width: self.title.isEmpty ? 0 : 100, height: 20)
          }
          .animation(.easeIn(0.5), value: self.on)
          .animation(.spring(), value: self.title)
        }
      }
      """,
      expandedSource: """
      final class Nested: SingleChildElement {
        var on: Bool {
            @storageRestrictions(initializes: _on)
            init(initialValue) {
              _on = initialValue
            }
            get {
              _on
            }
            set {
              _on = newValue
              self.__update_on()
            }
            _modify {
              yield &_on
              self.__update_on()
            }
        }

        private var _on: Bool

        var $on: Binding<Bool> {
          Binding(unowned: self, \\.on)
        }

        private func __requiresComponent_on() {
          let _: any ReactiveComponent = self
        }
        var title: String {
            @storageRestrictions(initializes: _title)
            init(initialValue) {
              _title = initialValue
            }
            get {
              _title
            }
            set {
              _title = newValue
              self.__update_title()
            }
            _modify {
              yield &_title
              self.__update_title()
            }
        }

        private var _title: String

        var $title: Binding<String> {
          Binding(unowned: self, \\.title)
        }

        private func __requiresComponent_title() {
          let _: any ReactiveComponent = self
        }

        @UIElementBuilder var body: [UIElement] {
          VStack(spacing: self.on ? 4 : 8) {
            Rectangle(self.on ? .red : .blue)
              .animation(.linear(0.1), value: self.on)
            Text(self.title)
              .frame(width: self.title.isEmpty ? 0 : 100, height: 20)
          }
          .animation(.easeIn(0.5), value: self.on)
          .animation(.spring(), value: self.title)
        }

          private var __context: UIContext? = nil

          private var __needsRefresh: Bool = false

          private var __built: Bool = false

          private var __n0a: VStack? = nil

          private var __n0_0a: Rectangle? = nil

          private var __n0_1a: Text? = nil

          private var __n0_1b: Frame? = nil

          private static let __anim0_0: UIAnimation? = .easeIn(0.5)

          private static let __anim0_1: UIAnimation? = .spring()

          private static let __anim0_0_0: UIAnimation? = .linear(0.1)

          public override func mount(_ context: UIContext) {
            self.__context = context
            if !self.__built {
              self.__built = true
              self.setChild(self.__build(context), context)
            } else if self.__needsRefresh {
              self.__needsRefresh = false
              self.__refreshAll()
            }
          }

          public override func unmount(_ context: UIContext) {
            self.__context = nil
          }

          private func __refreshAll() {
            self.__update_on(false)
            self.__update_title(false)
          }

          private func __build(_ context: UIContext) -> UIElement {
            let n0a = VStack(spacing: self._on ? 4 : 8)
            self.__n0a = n0a
            let n0_0a = Rectangle(self._on ? .red : .blue)
            self.__n0_0a = n0_0a
            let n0_1a = Text(self._title)
            self.__n0_1a = n0_1a
            let n0_1b = n0_1a.frame(width: self._title.isEmpty ? 0 : 100, height: 20)
            self.__n0_1b = n0_1b
            self.__applyChildren0(context, animation: nil)
            var root: [UIElement] = []
            if let e = self.__n0a {
                root.append(e)
            }
            return root.first ?? EmptyElement()
          }

          private func __applyChildrenRoot(_ context: UIContext, animation: UIAnimation?) {
            var children: [UIElement] = []
            if let e = self.__n0a {
                children.append(e)
            }
            self.setChild(children.first ?? EmptyElement(), context, animation: animation)
          }

          private func __applyChildren0(_ context: UIContext, animation: UIAnimation?) {
            var children: [UIElement] = []
            if let e = self.__n0_0a {
                children.append(e)
            }
            if let e = self.__n0_1b {
                children.append(e)
            }
            if let owner = self.__n0a {
                owner.replaceChildren(children, context, animation: animation)
            }
          }

          private func __update_on(_ animated: Bool = true) {
            guard let context = self.__context else {
              self.__needsRefresh = true
              return
            }
            if let n = self.__n0a {
                n.setSpacing(self._on ? 4 : 8, context, animation: animated ? Self.__anim0_0 : nil)
            }
            if let n = self.__n0_0a {
                n.setColor(self._on ? .red : .blue, context, animation: animated ? Self.__anim0_0_0 : nil)
            }
          }

          private func __update_title(_ animated: Bool = true) {
            guard let context = self.__context else {
              self.__needsRefresh = true
              return
            }
            if let n = self.__n0_1a {
                n.setText(self._title, context, animation: animated ? Self.__anim0_1 : nil)
            }
            if let n = self.__n0_1b {
                n.setSize(float2(self._title.isEmpty ? 0 : 100, 20), context, animation: animated ? Self.__anim0_1 : nil)
            }
          }
      }

      extension Nested: ReactiveComponent {
      }
      """,
      macros: Self.macros
    )
  }

  // The animation reads `fast`, so it is evaluated in place rather than hoisted. `.opacity`
  // reads `fast` too, but the scope does not trigger on `fast`: that write uses the transaction.
  @Test("a branch swap under a scope carries the scope's animation to replaceChildren")
  func branchSwapUnderScope() {
    assertMacroExpansion(
      """
      @Component
      final class Swap: SingleChildElement {
        @State var on: Bool = false
        @State var fast: Bool = false

        @UIElementBuilder var body: [UIElement] {
          VStack {
            if self.on {
              Rectangle(.red)
                .opacity(self.fast ? 1 : 0.5)
                .transition(.opacity)
            }
          }
          .animation(self.fast ? .linear(0.1) : .spring(), value: self.on)
        }
      }
      """,
      expandedSource: """
      final class Swap: SingleChildElement {
        var on: Bool {
            @storageRestrictions(initializes: _on)
            init(initialValue) {
              _on = initialValue
            }
            get {
              _on
            }
            set {
              _on = newValue
              self.__update_on()
            }
            _modify {
              yield &_on
              self.__update_on()
            }
        }

        private var _on: Bool

        var $on: Binding<Bool> {
          Binding(unowned: self, \\.on)
        }

        private func __requiresComponent_on() {
          let _: any ReactiveComponent = self
        }
        var fast: Bool {
            @storageRestrictions(initializes: _fast)
            init(initialValue) {
              _fast = initialValue
            }
            get {
              _fast
            }
            set {
              _fast = newValue
              self.__update_fast()
            }
            _modify {
              yield &_fast
              self.__update_fast()
            }
        }

        private var _fast: Bool

        var $fast: Binding<Bool> {
          Binding(unowned: self, \\.fast)
        }

        private func __requiresComponent_fast() {
          let _: any ReactiveComponent = self
        }

        @UIElementBuilder var body: [UIElement] {
          VStack {
            if self.on {
              Rectangle(.red)
                .opacity(self.fast ? 1 : 0.5)
                .transition(.opacity)
            }
          }
          .animation(self.fast ? .linear(0.1) : .spring(), value: self.on)
        }

          private var __context: UIContext? = nil

          private var __needsRefresh: Bool = false

          private var __built: Bool = false

          private var __n0a: VStack? = nil

          private var __n0_0_0_0a: Rectangle? = nil

          private var __n0_0_0_0b: EffectElement? = nil

          private var __n0_0_0_0c: TransitionElement? = nil

          private var __tag0_0: Int = -1

          private var __slot0_0: [UIElement] = []

          public override func mount(_ context: UIContext) {
            self.__context = context
            if !self.__built {
              self.__built = true
              self.setChild(self.__build(context), context)
            } else if self.__needsRefresh {
              self.__needsRefresh = false
              self.__refreshAll()
            }
          }

          public override func unmount(_ context: UIContext) {
            self.__context = nil
          }

          private func __refreshAll() {
            self.__update_on(false)
            self.__update_fast(false)
          }

          private func __build(_ context: UIContext) -> UIElement {
            let n0a = VStack ()
            self.__n0a = n0a
            self.__tag0_0 = self.__evalTag0_0()
            self.__slot0_0 = self.__enter0_0(self.__tag0_0, context)
            self.__applyChildren0(context, animation: nil)
            var root: [UIElement] = []
            if let e = self.__n0a {
                root.append(e)
            }
            return root.first ?? EmptyElement()
          }

          private func __applyChildrenRoot(_ context: UIContext, animation: UIAnimation?) {
            var children: [UIElement] = []
            if let e = self.__n0a {
                children.append(e)
            }
            self.setChild(children.first ?? EmptyElement(), context, animation: animation)
          }

          private func __applyChildren0(_ context: UIContext, animation: UIAnimation?) {
            var children: [UIElement] = []
            children.append(contentsOf: self.__slot0_0)
            if let owner = self.__n0a {
                owner.replaceChildren(children, context, animation: animation)
            }
          }

          private func __evalTag0_0() -> Int {
            (self._on) ? 0 : 1
          }

          private func __enter0_0(_ tag: Int, _ context: UIContext) -> [UIElement] {
            switch tag {
            case 0:
              let n0_0_0_0a = Rectangle(.red)
              self.__n0_0_0_0a = n0_0_0_0a
              let n0_0_0_0b = n0_0_0_0a.opacity(self._fast ? 1 : 0.5)
              self.__n0_0_0_0b = n0_0_0_0b
              let n0_0_0_0c = n0_0_0_0b.transition(.opacity)
              self.__n0_0_0_0c = n0_0_0_0c
              var elements: [UIElement] = []
              if let e = self.__n0_0_0_0c {
                  elements.append(e)
              }
              return elements
            case 1:
              let elements: [UIElement] = []
              return elements
            default:
              return []
            }
          }

          private func __leave0_0(_ tag: Int) {
            switch tag {
            case 0:
              self.__n0_0_0_0a = nil
              self.__n0_0_0_0b = nil
              self.__n0_0_0_0c = nil
            case 1:
              break
            default:
              break
            }
          }

          private func __swap0_0(_ context: UIContext, animation: UIAnimation?) {
            let tag = self.__evalTag0_0()
            guard tag != self.__tag0_0 else {
              return
            }
            let previous = self.__tag0_0
            self.__tag0_0 = tag
            self.__slot0_0 = self.__enter0_0(tag, context)
            self.__leave0_0(previous)
            self.__applyChildren0(context, animation: animation)
          }

          private func __update_on(_ animated: Bool = true) {
            guard let context = self.__context else {
              self.__needsRefresh = true
              return
            }
            self.__swap0_0(context, animation: animated ? (self._fast ? .linear(0.1) : .spring()) as UIAnimation? : nil)
          }

          private func __update_fast(_ animated: Bool = true) {
            guard let context = self.__context else {
              self.__needsRefresh = true
              return
            }
            let transaction = animated ? UITransaction.animation : nil
            if let n = self.__n0_0_0_0b {
                n.setOpacity(self._fast ? 1 : 0.5, context, animation: transaction)
            }
          }
      }

      extension Swap: ReactiveComponent {
      }
      """,
      macros: Self.macros
    )
  }

  // The row factory is opaque to the macro, so `.transition(.opacity)` inside it is plain
  // runtime code; what the macro adds is the animation handed to setItems/insertRow/removeRow.
  @Test("a list under a scope animates full, inserted and removed rows alike")
  func listRowsUnderScope() {
    assertMacroExpansion(
      """
      @Component
      final class Rows: SingleChildElement {
        @State var rows: [Row] = []

        @UIElementBuilder var body: [UIElement] {
          VList(items: self.rows) { row in
            Text(row.name).transition(.opacity)
          }
          .animation(.easeOut(0.3), value: self.rows)
        }
      }
      """,
      expandedSource: """
      final class Rows: SingleChildElement {
        var rows: [Row] {
            @storageRestrictions(initializes: _rows)
            init(initialValue) {
              _rows = initialValue
            }
            get {
              _rows
            }
            set {
              _rows = newValue
              self.__update_rows()
            }
            _modify {
              yield &_rows
              self.__update_rows()
            }
        }

        private var _rows: [Row]

        var $rows: Binding<[Row]> {
          Binding(unowned: self, \\.rows)
        }

        private func __requiresComponent_rows() {
          let _: any ReactiveComponent = self
        }

        @UIElementBuilder var body: [UIElement] {
          VList(items: self.rows) { row in
            Text(row.name).transition(.opacity)
          }
          .animation(.easeOut(0.3), value: self.rows)
        }

          private var __context: UIContext? = nil

          private var __needsRefresh: Bool = false

          private var __built: Bool = false

          private var __n0a: VList<Row>? = nil

          private static let __anim0_0: UIAnimation? = .easeOut(0.3)

          public override func mount(_ context: UIContext) {
            self.__context = context
            if !self.__built {
              self.__built = true
              self.setChild(self.__build(context), context)
            } else if self.__needsRefresh {
              self.__needsRefresh = false
              self.__refreshAll()
            }
          }

          public override func unmount(_ context: UIContext) {
            self.__context = nil
          }

          private func __refreshAll() {
            self.__update_rows(false)
          }

          private func __build(_ context: UIContext) -> UIElement {
            let n0a = VList(items: self._rows) { row in
                Text(row.name).transition(.opacity)
              }
            self.__n0a = n0a
            var root: [UIElement] = []
            if let e = self.__n0a {
                root.append(e)
            }
            return root.first ?? EmptyElement()
          }

          private func __applyChildrenRoot(_ context: UIContext, animation: UIAnimation?) {
            var children: [UIElement] = []
            if let e = self.__n0a {
                children.append(e)
            }
            self.setChild(children.first ?? EmptyElement(), context, animation: animation)
          }

          private func __update_rows(_ animated: Bool = true) {
            guard let context = self.__context else {
              self.__needsRefresh = true
              return
            }
            if let n = self.__n0a {
                n.setItems(self._rows, context, animation: animated ? Self.__anim0_0 : nil)
            }
          }

          public func appendRows(_ element: Row) {
            let index = self._rows.count
            self._rows.append(element)
            self.__rows_didInsert(element, at: index)
          }

          public func insertRows(_ element: Row, at position: Int) {
            let index = Swift.min(Swift.max(position, 0), self._rows.count)
            self._rows.insert(element, at: index)
            self.__rows_didInsert(element, at: index)
          }

          @discardableResult
          public func removeRows(at index: Int) -> Row? {
            guard self._rows.indices.contains(index) else {
                return nil
            }
            let removed = self._rows.remove(at: index)
            self.__rows_didRemove(removed, at: index)
            return removed
          }

          public func removeRows(where predicate: (Row) -> Bool) {
            let matches = self._rows.indices.filter {
                predicate(self._rows[$0])
            }
            guard matches.count == 1, let index = matches.first else {
              guard !matches.isEmpty else {
                  return
              }
              self._rows.removeAll(where: predicate)
              self.__update_rows()
              return
            }
            let removed = self._rows.remove(at: index)
            self.__rows_didRemove(removed, at: index)
          }

          public func replaceRows(_ newValue: [Row]) {
            self._rows = newValue
            self.__update_rows()
          }

          private func __rows_didInsert(_ element: Row, at index: Int, _ animated: Bool = true) {
            guard let context = self.__context else {
              self.__needsRefresh = true
              return
            }
            if let n = self.__n0a {
                n.insertRow(element, at: index, context, animation: animated ? Self.__anim0_0 : nil)
            }
          }

          private func __rows_didRemove(_ element: Row, at index: Int, _ animated: Bool = true) {
            guard let context = self.__context else {
              self.__needsRefresh = true
              return
            }
            if let n = self.__n0a {
                n.removeRow(element, at: index, context, animation: animated ? Self.__anim0_0 : nil)
            }
          }
      }

      extension Rows: ReactiveComponent {
      }
      """,
      macros: Self.macros
    )
  }

  // `.font` and `.foregroundColor` wrap nothing: each is a link of its own, typed `Text`, whose
  // field holds the same Text. The scope sits between them, so the font (before it) springs with
  // the scope and the color (after it) falls back to the transaction.
  @Test("in-place Text modifiers bind to the Text, and a scope between them splits them")
  func inPlaceTextModifiers() {
    assertMacroExpansion(
      """
      @Component
      final class Styled: SingleChildElement {
        @State var big: Bool = false

        @UIElementBuilder var body: [UIElement] {
          Text("hi")
            .font(.system(size: self.big ? 24 : 14))
            .animation(.spring(), value: self.big)
            .foregroundColor(self.big ? .red : .white)
        }
      }
      """,
      expandedSource: """
      final class Styled: SingleChildElement {
        var big: Bool {
            @storageRestrictions(initializes: _big)
            init(initialValue) {
              _big = initialValue
            }
            get {
              _big
            }
            set {
              _big = newValue
              self.__update_big()
            }
            _modify {
              yield &_big
              self.__update_big()
            }
        }

        private var _big: Bool

        var $big: Binding<Bool> {
          Binding(unowned: self, \\.big)
        }

        private func __requiresComponent_big() {
          let _: any ReactiveComponent = self
        }

        @UIElementBuilder var body: [UIElement] {
          Text("hi")
            .font(.system(size: self.big ? 24 : 14))
            .animation(.spring(), value: self.big)
            .foregroundColor(self.big ? .red : .white)
        }

          private var __context: UIContext? = nil

          private var __needsRefresh: Bool = false

          private var __built: Bool = false

          private var __n0a: Text? = nil

          private var __n0b: Text? = nil

          private var __n0c: Text? = nil

          private static let __anim0_0: UIAnimation? = .spring()

          public override func mount(_ context: UIContext) {
            self.__context = context
            if !self.__built {
              self.__built = true
              self.setChild(self.__build(context), context)
            } else if self.__needsRefresh {
              self.__needsRefresh = false
              self.__refreshAll()
            }
          }

          public override func unmount(_ context: UIContext) {
            self.__context = nil
          }

          private func __refreshAll() {
            self.__update_big(false)
          }

          private func __build(_ context: UIContext) -> UIElement {
            let n0a = Text("hi")
            self.__n0a = n0a
            let n0b = n0a.font(.system(size: self._big ? 24 : 14))
            self.__n0b = n0b
            let n0c = n0b.foregroundColor(self._big ? .red : .white)
            self.__n0c = n0c
            var root: [UIElement] = []
            if let e = self.__n0c {
                root.append(e)
            }
            return root.first ?? EmptyElement()
          }

          private func __applyChildrenRoot(_ context: UIContext, animation: UIAnimation?) {
            var children: [UIElement] = []
            if let e = self.__n0c {
                children.append(e)
            }
            self.setChild(children.first ?? EmptyElement(), context, animation: animation)
          }

          private func __update_big(_ animated: Bool = true) {
            guard let context = self.__context else {
              self.__needsRefresh = true
              return
            }
            let transaction = animated ? UITransaction.animation : nil
            if let n = self.__n0b {
                n.setFont(.system(size: self._big ? 24 : 14), context, animation: animated ? Self.__anim0_0 : nil)
            }
            if let n = self.__n0c {
                n.setForegroundColor(self._big ? .red : .white, context, animation: transaction)
            }
          }
      }

      extension Styled: ReactiveComponent {
      }
      """,
      macros: Self.macros
    )
  }

  // Only `trigger:` is reactive: the tracks are copied into the chain and built once.
  @Test("keyframes bind their trigger only")
  func keyframesTrigger() {
    assertMacroExpansion(
      """
      @Component
      final class Shaker: SingleChildElement {
        @State var shakes: Int = 0

        @UIElementBuilder var body: [UIElement] {
          Rectangle(.red)
            .keyframes(UIKeyframes(offset: [.linear(float2(8, 0), duration: 0.1)]), trigger: self.shakes)
        }
      }
      """,
      expandedSource: """
      final class Shaker: SingleChildElement {
        var shakes: Int {
            @storageRestrictions(initializes: _shakes)
            init(initialValue) {
              _shakes = initialValue
            }
            get {
              _shakes
            }
            set {
              _shakes = newValue
              self.__update_shakes()
            }
            _modify {
              yield &_shakes
              self.__update_shakes()
            }
        }

        private var _shakes: Int

        var $shakes: Binding<Int> {
          Binding(unowned: self, \\.shakes)
        }

        private func __requiresComponent_shakes() {
          let _: any ReactiveComponent = self
        }

        @UIElementBuilder var body: [UIElement] {
          Rectangle(.red)
            .keyframes(UIKeyframes(offset: [.linear(float2(8, 0), duration: 0.1)]), trigger: self.shakes)
        }

          private var __context: UIContext? = nil

          private var __needsRefresh: Bool = false

          private var __built: Bool = false

          private var __n0a: Rectangle? = nil

          private var __n0b: KeyframeElement? = nil

          public override func mount(_ context: UIContext) {
            self.__context = context
            if !self.__built {
              self.__built = true
              self.setChild(self.__build(context), context)
            } else if self.__needsRefresh {
              self.__needsRefresh = false
              self.__refreshAll()
            }
          }

          public override func unmount(_ context: UIContext) {
            self.__context = nil
          }

          private func __refreshAll() {
            self.__update_shakes(false)
          }

          private func __build(_ context: UIContext) -> UIElement {
            let n0a = Rectangle(.red)
            self.__n0a = n0a
            let n0b = n0a.keyframes(UIKeyframes(offset: [.linear(float2(8, 0), duration: 0.1)]), trigger: self._shakes)
            self.__n0b = n0b
            var root: [UIElement] = []
            if let e = self.__n0b {
                root.append(e)
            }
            return root.first ?? EmptyElement()
          }

          private func __applyChildrenRoot(_ context: UIContext, animation: UIAnimation?) {
            var children: [UIElement] = []
            if let e = self.__n0b {
                children.append(e)
            }
            self.setChild(children.first ?? EmptyElement(), context, animation: animation)
          }

          private func __update_shakes(_ animated: Bool = true) {
            guard let context = self.__context else {
              self.__needsRefresh = true
              return
            }
            if let n = self.__n0b {
                n.setTrigger(self._shakes, context)
            }
          }
      }

      extension Shaker: ReactiveComponent {
      }
      """,
      macros: Self.macros
    )
  }

  // A stored property's initializer cannot reference `Self`, so an animation naming a static of
  // the component is not hoisted into a `static let` of its own: it is evaluated in place.
  @Test("an animation naming Self is evaluated in place, not hoisted")
  func selfAnimationNotHoisted() {
    assertMacroExpansion(
      """
      @Component
      final class Fader: SingleChildElement {
        private static let fade = UIAnimation.easeOut(0.2)

        @State var color: float4 = .red

        @UIElementBuilder var body: [UIElement] {
          Rectangle(self.color)
            .animation(Self.fade, value: self.color)
        }
      }
      """,
      expandedSource: """
      final class Fader: SingleChildElement {
        private static let fade = UIAnimation.easeOut(0.2)

        var color: float4 {
            @storageRestrictions(initializes: _color)
            init(initialValue) {
              _color = initialValue
            }
            get {
              _color
            }
            set {
              _color = newValue
              self.__update_color()
            }
            _modify {
              yield &_color
              self.__update_color()
            }
        }

        private var _color: float4

        var $color: Binding<float4> {
          Binding(unowned: self, \\.color)
        }

        private func __requiresComponent_color() {
          let _: any ReactiveComponent = self
        }

        @UIElementBuilder var body: [UIElement] {
          Rectangle(self.color)
            .animation(Self.fade, value: self.color)
        }

          private var __context: UIContext? = nil

          private var __needsRefresh: Bool = false

          private var __built: Bool = false

          private var __n0a: Rectangle? = nil

          public override func mount(_ context: UIContext) {
            self.__context = context
            if !self.__built {
              self.__built = true
              self.setChild(self.__build(context), context)
            } else if self.__needsRefresh {
              self.__needsRefresh = false
              self.__refreshAll()
            }
          }

          public override func unmount(_ context: UIContext) {
            self.__context = nil
          }

          private func __refreshAll() {
            self.__update_color(false)
          }

          private func __build(_ context: UIContext) -> UIElement {
            let n0a = Rectangle(self._color)
            self.__n0a = n0a
            var root: [UIElement] = []
            if let e = self.__n0a {
                root.append(e)
            }
            return root.first ?? EmptyElement()
          }

          private func __applyChildrenRoot(_ context: UIContext, animation: UIAnimation?) {
            var children: [UIElement] = []
            if let e = self.__n0a {
                children.append(e)
            }
            self.setChild(children.first ?? EmptyElement(), context, animation: animation)
          }

          private func __update_color(_ animated: Bool = true) {
            guard let context = self.__context else {
              self.__needsRefresh = true
              return
            }
            if let n = self.__n0a {
                n.setColor(self._color, context, animation: animated ? (Self.fade) as UIAnimation? : nil)
            }
          }
      }

      extension Fader: ReactiveComponent {
      }
      """,
      macros: Self.macros
    )
  }
}
