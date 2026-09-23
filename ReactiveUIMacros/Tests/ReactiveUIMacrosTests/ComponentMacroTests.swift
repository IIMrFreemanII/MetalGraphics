import SwiftSyntaxMacros
import SwiftSyntaxMacrosGenericTestSupport
import Testing

@testable import ReactiveUIMacrosPlugin

@Suite("@Component expansion")
struct ComponentMacroTests {

  // The anchor test: every CodeGen change is checked against this.
  @Test("ToggleDemo: a conditional, a container, and a reactive argument")
  func toggleDemo() {
    assertMacroExpansion(
      """
      @Component
      final class ToggleDemo: SingleChildElement {
        @State var color: float4 = .blue
        @State var isLoggedIn: Bool = false

        @UIElementBuilder var body: [UIElement] {
          VStack(spacing: 10) {
            if self.isLoggedIn {
              Rectangle(.green)
                .frame(width: 100, height: 100)
            } else {
              Rectangle(.red)
                .frame(width: 100, height: 100)
            }
            Rectangle(self.color)
              .frame(width: 100, height: 100)
              .onTap { _ in
                self.isLoggedIn.toggle()
              }
          }
        }
      }
      """,
      expandedSource: """
      final class ToggleDemo: SingleChildElement {
        @State var color: float4 = .blue
        @State var isLoggedIn: Bool = false

        @UIElementBuilder var body: [UIElement] {
          VStack(spacing: 10) {
            if self.isLoggedIn {
              Rectangle(.green)
                .frame(width: 100, height: 100)
            } else {
              Rectangle(.red)
                .frame(width: 100, height: 100)
            }
            Rectangle(self.color)
              .frame(width: 100, height: 100)
              .onTap { _ in
                self.isLoggedIn.toggle()
              }
          }
        }

          private var __context: UIContext? = nil

          private var __needsRefresh: Bool = false

          private var __built: Bool = false

          private var __n0a: VStack? = nil

          private var __n0_0_0_0a: Rectangle? = nil

          private var __n0_0_0_0b: Frame? = nil

          private var __n0_0_1_0a: Rectangle? = nil

          private var __n0_0_1_0b: Frame? = nil

          private var __n0_1a: Rectangle? = nil

          private var __n0_1b: Frame? = nil

          private var __n0_1c: HittableView? = nil

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
            self.__armHandlers()
          }

          public override func unmount(_ context: UIContext) {
            self.__disarmHandlers()
            self.__context = nil
          }

          private func __refreshAll() {
            self.__update_color(false)
            self.__update_isLoggedIn(false)
          }

          private func __build(_ context: UIContext) -> UIElement {
            let n0a = VStack(spacing: 10)
            self.__n0a = n0a
            self.__tag0_0 = self.__evalTag0_0()
            self.__slot0_0 = self.__enter0_0(self.__tag0_0, context)
            let n0_1a = Rectangle(self._color)
            self.__n0_1a = n0_1a
            let n0_1b = n0_1a.frame(width: 100, height: 100)
            self.__n0_1b = n0_1b
            let n0_1c = n0_1b.onTap { _ in
            }
            self.__n0_1c = n0_1c
            self.__applyChildren0(context, animation: nil)
            var root: [UIElement] = []
            if let e = self.__n0a {
                root.append(e)
            }
            return root.first ?? EmptyElement()
          }

          private func __armHandlers() {
            self.__n0_1c?.onTap = { _ in
                    self.isLoggedIn.toggle()
                  }
          }

          private func __disarmHandlers() {
            self.__n0_1c?.onTap = nil
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
            if let e = self.__n0_1c {
                children.append(e)
            }
            if let owner = self.__n0a {
                owner.replaceChildren(children, context, animation: animation)
            }
          }

          private func __evalTag0_0() -> Int {
            (self._isLoggedIn) ? 0 : 1
          }

          private func __enter0_0(_ tag: Int, _ context: UIContext) -> [UIElement] {
            switch tag {
            case 0:
              let n0_0_0_0a = Rectangle(.green)
              self.__n0_0_0_0a = n0_0_0_0a
              let n0_0_0_0b = n0_0_0_0a.frame(width: 100, height: 100)
              self.__n0_0_0_0b = n0_0_0_0b
              var elements: [UIElement] = []
              if let e = self.__n0_0_0_0b {
                  elements.append(e)
              }
              return elements
            case 1:
              let n0_0_1_0a = Rectangle(.red)
              self.__n0_0_1_0a = n0_0_1_0a
              let n0_0_1_0b = n0_0_1_0a.frame(width: 100, height: 100)
              self.__n0_0_1_0b = n0_0_1_0b
              var elements: [UIElement] = []
              if let e = self.__n0_0_1_0b {
                  elements.append(e)
              }
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
            case 1:
              self.__n0_0_1_0a = nil
              self.__n0_0_1_0b = nil
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
            self.__armHandlers()
            self.__applyChildren0(context, animation: animation)
          }

          private func __update_color(_ animated: Bool = true) {
            guard let context = self.__context else {
              self.__needsRefresh = true
              return
            }
            let transaction = animated ? UITransaction.animation : nil
            if let n = self.__n0_1a {
                n.setColor(self._color, context, animation: transaction)
            }
          }

          private func __update_isLoggedIn(_ animated: Bool = true) {
            guard let context = self.__context else {
              self.__needsRefresh = true
              return
            }
            let transaction = animated ? UITransaction.animation : nil
            self.__swap0_0(context, animation: transaction)
          }
      }

      extension ToggleDemo: ReactiveComponent {
      }
      """,
      macros: ["Component": ComponentMacro.self]
    )
  }

  // One expression reading three states is emitted into all three update methods. The
  // redundant store when a non-deciding state changes is the intended trade: there is no
  // re-tracking, and it is still cheaper than the subscription churn it replaced.
  @Test("a multi-state expression fans out to every state it reads")
  func multiStateExpression() {
    assertMacroExpansion(
      """
      @Component
      final class C: SingleChildElement {
        @State var isOn: Bool = false
        @State var a: float4 = .red
        @State var b: float4 = .blue

        @UIElementBuilder var body: [UIElement] {
          Rectangle(self.isOn ? self.a : self.b)
        }
      }
      """,
      expandedSource: """
      final class C: SingleChildElement {
        @State var isOn: Bool = false
        @State var a: float4 = .red
        @State var b: float4 = .blue

        @UIElementBuilder var body: [UIElement] {
          Rectangle(self.isOn ? self.a : self.b)
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
            self.__update_isOn(false)
            self.__update_a(false)
            self.__update_b(false)
          }

          private func __build(_ context: UIContext) -> UIElement {
            let n0a = Rectangle(self._isOn ? self._a : self._b)
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

          private func __update_isOn(_ animated: Bool = true) {
            guard let context = self.__context else {
              self.__needsRefresh = true
              return
            }
            let transaction = animated ? UITransaction.animation : nil
            if let n = self.__n0a {
                n.setColor(self._isOn ? self._a : self._b, context, animation: transaction)
            }
          }

          private func __update_a(_ animated: Bool = true) {
            guard let context = self.__context else {
              self.__needsRefresh = true
              return
            }
            let transaction = animated ? UITransaction.animation : nil
            if let n = self.__n0a {
                n.setColor(self._isOn ? self._a : self._b, context, animation: transaction)
            }
          }

          private func __update_b(_ animated: Bool = true) {
            guard let context = self.__context else {
              self.__needsRefresh = true
              return
            }
            let transaction = animated ? UITransaction.animation : nil
            if let n = self.__n0a {
                n.setColor(self._isOn ? self._a : self._b, context, animation: transaction)
            }
          }
      }

      extension C: ReactiveComponent {
      }
      """,
      macros: ["Component": ComponentMacro.self]
    )
  }

  // The layout-vs-render distinction lives in the library's setters, so what the macro has to
  // get right is only which setter name an argument maps to.
  @Test("arguments route to the right setter: size is layout, color is not")
  func setterRouting() {
    assertMacroExpansion(
      """
      @Component
      final class C: SingleChildElement {
        @State var w: Float = 10
        @State var c: float4 = .red

        @UIElementBuilder var body: [UIElement] {
          Rectangle(self.c)
            .frame(width: self.w, height: 100)
        }
      }
      """,
      expandedSource: """
      final class C: SingleChildElement {
        @State var w: Float = 10
        @State var c: float4 = .red

        @UIElementBuilder var body: [UIElement] {
          Rectangle(self.c)
            .frame(width: self.w, height: 100)
        }

          private var __context: UIContext? = nil

          private var __needsRefresh: Bool = false

          private var __built: Bool = false

          private var __n0a: Rectangle? = nil

          private var __n0b: Frame? = nil

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
            self.__update_w(false)
            self.__update_c(false)
          }

          private func __build(_ context: UIContext) -> UIElement {
            let n0a = Rectangle(self._c)
            self.__n0a = n0a
            let n0b = n0a.frame(width: self._w, height: 100)
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

          private func __update_w(_ animated: Bool = true) {
            guard let context = self.__context else {
              self.__needsRefresh = true
              return
            }
            let transaction = animated ? UITransaction.animation : nil
            if let n = self.__n0b {
                n.setSize(float2(self._w, 100), context, animation: transaction)
            }
          }

          private func __update_c(_ animated: Bool = true) {
            guard let context = self.__context else {
              self.__needsRefresh = true
              return
            }
            let transaction = animated ? UITransaction.animation : nil
            if let n = self.__n0a {
                n.setColor(self._c, context, animation: transaction)
            }
          }
      }

      extension C: ReactiveComponent {
      }
      """,
      macros: ["Component": ComponentMacro.self]
    )
  }

  // A handler is the one thing in a body that is *not* emitted with the chain. The closure
  // captures `self` strongly and the element stores it, so emitting it in `__build` would leave
  // the component reachable from its own tree for good. Instead the chain gets a placeholder of
  // the right arity and the real closure is assigned on mount, cleared on unmount — which is what
  // lets the body be written without `[weak self]`.
  //
  // What this pins: the placeholder in `__build`, the closure appearing exactly once (in
  // `__armHandlers`), the nil-out in `__disarmHandlers`, and both call sites on the lifecycle.
  @Test("a handler is armed on mount and cleared on unmount, not emitted into the chain")
  func handlerArming() {
    assertMacroExpansion(
      """
      @Component
      final class C: SingleChildElement {
        @State var color: float4 = .blue

        @UIElementBuilder var body: [UIElement] {
          Rectangle(self.color)
            .onTap { _ in
              self.color = .red
            }
        }
      }
      """,
      expandedSource: """
      final class C: SingleChildElement {
        @State var color: float4 = .blue

        @UIElementBuilder var body: [UIElement] {
          Rectangle(self.color)
            .onTap { _ in
              self.color = .red
            }
        }

          private var __context: UIContext? = nil

          private var __needsRefresh: Bool = false

          private var __built: Bool = false

          private var __n0a: Rectangle? = nil

          private var __n0b: HittableView? = nil

          public override func mount(_ context: UIContext) {
            self.__context = context
            if !self.__built {
              self.__built = true
              self.setChild(self.__build(context), context)
            } else if self.__needsRefresh {
              self.__needsRefresh = false
              self.__refreshAll()
            }
            self.__armHandlers()
          }

          public override func unmount(_ context: UIContext) {
            self.__disarmHandlers()
            self.__context = nil
          }

          private func __refreshAll() {
            self.__update_color(false)
          }

          private func __build(_ context: UIContext) -> UIElement {
            let n0a = Rectangle(self._color)
            self.__n0a = n0a
            let n0b = n0a.onTap { _ in
            }
            self.__n0b = n0b
            var root: [UIElement] = []
            if let e = self.__n0b {
                root.append(e)
            }
            return root.first ?? EmptyElement()
          }

          private func __armHandlers() {
            self.__n0b?.onTap = { _ in
                  self.color = .red
                }
          }

          private func __disarmHandlers() {
            self.__n0b?.onTap = nil
          }

          private func __applyChildrenRoot(_ context: UIContext, animation: UIAnimation?) {
            var children: [UIElement] = []
            if let e = self.__n0b {
                children.append(e)
            }
            self.setChild(children.first ?? EmptyElement(), context, animation: animation)
          }

          private func __update_color(_ animated: Bool = true) {
            guard let context = self.__context else {
              self.__needsRefresh = true
              return
            }
            let transaction = animated ? UITransaction.animation : nil
            if let n = self.__n0a {
                n.setColor(self._color, context, animation: transaction)
            }
          }
      }

      extension C: ReactiveComponent {
      }
      """,
      macros: ["Component": ComponentMacro.self]
    )
  }
}
