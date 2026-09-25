import SwiftSyntaxMacros
import SwiftSyntaxMacrosGenericTestSupport
import Testing

@testable import ReactiveUIMacrosPlugin

@Suite("Layout elements and modifiers")
struct LayoutMacroTests {

  @Test("frame overloads by label, in-place layoutPriority, and a spacer's minimum length")
  func frameOverloadsAndPriority() {
    assertMacroExpansion(
      """
      @Component
      final class Sizes: SingleChildElement {
        @State var wide: Bool = false

        @UIElementBuilder var body: [UIElement] {
          HStack {
            Text("a")
              .layoutPriority(self.wide ? 1 : 0)
              .frame(width: self.wide ? 200 : 100)
            Spacer(minLength: self.wide ? 20 : 0)
            Rectangle(.red)
              .frame(maxWidth: self.wide ? .infinity : 50, alignment: .leading)
          }
        }
      }
      """,
      expandedSource: """
      final class Sizes: SingleChildElement {
        @State var wide: Bool = false

        @UIElementBuilder var body: [UIElement] {
          HStack {
            Text("a")
              .layoutPriority(self.wide ? 1 : 0)
              .frame(width: self.wide ? 200 : 100)
            Spacer(minLength: self.wide ? 20 : 0)
            Rectangle(.red)
              .frame(maxWidth: self.wide ? .infinity : 50, alignment: .leading)
          }
        }

          private var __context: UIContext? = nil

          private var __needsRefresh: Bool = false

          private var __built: Bool = false

          private var __n0a: HStack? = nil

          private var __n0_0a: Text? = nil

          private var __n0_0b: Text? = nil

          private var __n0_0c: Frame? = nil

          private var __n0_1a: Spacer? = nil

          private var __n0_2a: Rectangle? = nil

          private var __n0_2b: FlexFrame? = nil

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
            self.__update_wide(false)
          }

          private func __build(_ context: UIContext) -> UIElement {
            let n0a = HStack ()
            self.__n0a = n0a
            let n0_0a = Text("a")
            self.__n0_0a = n0_0a
            let n0_0b = n0_0a.layoutPriority(self._wide ? 1 : 0)
            self.__n0_0b = n0_0b
            let n0_0c = n0_0b.frame(width: self._wide ? 200 : 100)
            self.__n0_0c = n0_0c
            let n0_1a = Spacer(minLength: self._wide ? 20 : 0)
            self.__n0_1a = n0_1a
            let n0_2a = Rectangle(.red)
            self.__n0_2a = n0_2a
            let n0_2b = n0_2a.frame(maxWidth: self._wide ? .infinity : 50, alignment: .leading)
            self.__n0_2b = n0_2b
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
            if let e = self.__n0_0c {
                children.append(e)
            }
            if let e = self.__n0_1a {
                children.append(e)
            }
            if let e = self.__n0_2b {
                children.append(e)
            }
            if let owner = self.__n0a {
                owner.replaceChildren(children, context, animation: animation)
            }
          }

          private func __update_wide(_ animated: Bool = true) {
            guard let context = self.__context else {
              self.__needsRefresh = true
              return
            }
            let transaction = animated ? UITransaction.animation : nil
            if let n = self.__n0_0b {
                n.setLayoutPriority(self._wide ? 1 : 0, context, animation: transaction)
            }
            if let n = self.__n0_0c {
                n.setWidth(self._wide ? 200 : 100, context, animation: transaction)
            }
            if let n = self.__n0_1a {
                n.setMinLength(self._wide ? 20 : 0, context, animation: transaction)
            }
            if let n = self.__n0_2b {
                n.setMaxWidth(self._wide ? .infinity : 50, context, animation: transaction)
            }
          }
      }

      extension Sizes: ReactiveComponent {
      }
      """,
      macros: ["Component": ComponentMacro.self]
    )
  }

  @Test("ZStack, zIndex in place, and overlay/background content with a branch under a scope")
  func overlayContent() {
    assertMacroExpansion(
      """
      @Component
      final class Badge: SingleChildElement {
        @State var count: Int = 0
        @State var front: Bool = false

        @UIElementBuilder var body: [UIElement] {
          ZStack(alignment: .topLeading) {
            Rectangle(.blue)
              .zIndex(self.front ? 1 : 0)
            Text("inbox")
              .overlay(alignment: .topTrailing) {
                if self.count > 0 {
                  Text("\\(self.count)")
                }
              }
              .animation(.default, value: self.count)
              .background { Rectangle(.gray) }
          }
        }
      }
      """,
      expandedSource: """
      final class Badge: SingleChildElement {
        @State var count: Int = 0
        @State var front: Bool = false

        @UIElementBuilder var body: [UIElement] {
          ZStack(alignment: .topLeading) {
            Rectangle(.blue)
              .zIndex(self.front ? 1 : 0)
            Text("inbox")
              .overlay(alignment: .topTrailing) {
                if self.count > 0 {
                  Text("\\(self.count)")
                }
              }
              .animation(.default, value: self.count)
              .background { Rectangle(.gray) }
          }
        }

          private var __context: UIContext? = nil

          private var __needsRefresh: Bool = false

          private var __built: Bool = false

          private var __n0a: ZStack? = nil

          private var __n0_0a: Rectangle? = nil

          private var __n0_0b: Rectangle? = nil

          private var __n0_1a: Text? = nil

          private var __n0_1b: OverlayElement? = nil

          private var __n0_1c: OverlayElement? = nil

          private var __n0_1o1_0_0_0a: Text? = nil

          private var __n0_1o2_0a: Rectangle? = nil

          private var __tag0_1o1_0: Int = -1

          private var __slot0_1o1_0: [UIElement] = []

          private static let __anim0_1_0: UIAnimation? = .default

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
            self.__update_count(false)
            self.__update_front(false)
          }

          private func __build(_ context: UIContext) -> UIElement {
            let n0a = ZStack(alignment: .topLeading)
            self.__n0a = n0a
            let n0_0a = Rectangle(.blue)
            self.__n0_0a = n0_0a
            let n0_0b = n0_0a.zIndex(self._front ? 1 : 0)
            self.__n0_0b = n0_0b
            let n0_1a = Text("inbox")
            self.__n0_1a = n0_1a
            let n0_1b = n0_1a.overlay(alignment: .topTrailing)
            self.__n0_1b = n0_1b
            let n0_1c = n0_1b.background ()
            self.__n0_1c = n0_1c
            self.__tag0_1o1_0 = self.__evalTag0_1o1_0()
            self.__slot0_1o1_0 = self.__enter0_1o1_0(self.__tag0_1o1_0, context)
            self.__applyChildren0_1o1(context, animation: nil)
            let n0_1o2_0a = Rectangle(.gray)
            self.__n0_1o2_0a = n0_1o2_0a
            self.__applyChildren0_1o2(context, animation: nil)
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
            if let e = self.__n0_0b {
                children.append(e)
            }
            if let e = self.__n0_1c {
                children.append(e)
            }
            if let owner = self.__n0a {
                owner.replaceChildren(children, context, animation: animation)
            }
          }

          private func __applyChildren0_1o1(_ context: UIContext, animation: UIAnimation?) {
            var children: [UIElement] = []
            children.append(contentsOf: self.__slot0_1o1_0)
            if let owner = self.__n0_1b {
                owner.replaceContent(children, context, animation: animation)
            }
          }

          private func __applyChildren0_1o2(_ context: UIContext, animation: UIAnimation?) {
            var children: [UIElement] = []
            if let e = self.__n0_1o2_0a {
                children.append(e)
            }
            if let owner = self.__n0_1c {
                owner.replaceContent(children, context, animation: animation)
            }
          }

          private func __evalTag0_1o1_0() -> Int {
            (self._count > 0) ? 0 : 1
          }

          private func __enter0_1o1_0(_ tag: Int, _ context: UIContext) -> [UIElement] {
            switch tag {
            case 0:
              let n0_1o1_0_0_0a = Text("\\(self._count)")
              self.__n0_1o1_0_0_0a = n0_1o1_0_0_0a
              var elements: [UIElement] = []
              if let e = self.__n0_1o1_0_0_0a {
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

          private func __leave0_1o1_0(_ tag: Int) {
            switch tag {
            case 0:
              self.__n0_1o1_0_0_0a = nil
            case 1:
              break
            default:
              break
            }
          }

          private func __swap0_1o1_0(_ context: UIContext, animation: UIAnimation?) {
            let tag = self.__evalTag0_1o1_0()
            guard tag != self.__tag0_1o1_0 else {
              return
            }
            let previous = self.__tag0_1o1_0
            self.__tag0_1o1_0 = tag
            self.__slot0_1o1_0 = self.__enter0_1o1_0(tag, context)
            self.__leave0_1o1_0(previous)
            self.__applyChildren0_1o1(context, animation: animation)
          }

          private func __update_count(_ animated: Bool = true) {
            guard let context = self.__context else {
              self.__needsRefresh = true
              return
            }
            if let n = self.__n0_1o1_0_0_0a {
                n.setText("\\(self._count)", context, animation: animated ? Self.__anim0_1_0 : nil)
            }
            self.__swap0_1o1_0(context, animation: animated ? Self.__anim0_1_0 : nil)
          }

          private func __update_front(_ animated: Bool = true) {
            guard let context = self.__context else {
              self.__needsRefresh = true
              return
            }
            if let n = self.__n0_0b {
                n.setZIndex(self._front ? 1 : 0, context)
            }
          }
      }

      extension Badge: ReactiveComponent {
      }
      """,
      macros: ["Component": ComponentMacro.self]
    )
  }

  @Test("padding overloads, fixedSize, Divider, aspectRatio wrapping, clipped, offset and position by x and y, hidden in place")
  func sizingModifiers() {
    assertMacroExpansion(
      """
      @Component
      final class Card: SingleChildElement {
        @State var inset: Float = 8
        @State var shift: Float = 0

        @UIElementBuilder var body: [UIElement] {
          VStack {
            Text("title")
              .padding(.horizontal, self.inset)
              .fixedSize()
            Divider()
            Rectangle(.red)
              .aspectRatio(2, contentMode: .fit)
              .clipped()
              .offset(x: self.shift, y: 0)
            Text("dot")
              .hidden()
              .position(x: self.shift, y: 10)
          }
        }
      }
      """,
      expandedSource: """
      final class Card: SingleChildElement {
        @State var inset: Float = 8
        @State var shift: Float = 0

        @UIElementBuilder var body: [UIElement] {
          VStack {
            Text("title")
              .padding(.horizontal, self.inset)
              .fixedSize()
            Divider()
            Rectangle(.red)
              .aspectRatio(2, contentMode: .fit)
              .clipped()
              .offset(x: self.shift, y: 0)
            Text("dot")
              .hidden()
              .position(x: self.shift, y: 10)
          }
        }

          private var __context: UIContext? = nil

          private var __needsRefresh: Bool = false

          private var __built: Bool = false

          private var __n0a: VStack? = nil

          private var __n0_0a: Text? = nil

          private var __n0_0b: Padding? = nil

          private var __n0_0c: FixedSizeElement? = nil

          private var __n0_1a: Divider? = nil

          private var __n0_2a: Rectangle? = nil

          private var __n0_2b: AspectRatioElement? = nil

          private var __n0_2c: ClipElement? = nil

          private var __n0_2d: EffectElement? = nil

          private var __n0_3a: Text? = nil

          private var __n0_3b: Text? = nil

          private var __n0_3c: PositionElement? = nil

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
            self.__update_inset(false)
            self.__update_shift(false)
          }

          private func __build(_ context: UIContext) -> UIElement {
            let n0a = VStack ()
            self.__n0a = n0a
            let n0_0a = Text("title")
            self.__n0_0a = n0_0a
            let n0_0b = n0_0a.padding(.horizontal, self._inset)
            self.__n0_0b = n0_0b
            let n0_0c = n0_0b.fixedSize()
            self.__n0_0c = n0_0c
            let n0_1a = Divider()
            self.__n0_1a = n0_1a
            let n0_2a = Rectangle(.red)
            self.__n0_2a = n0_2a
            let n0_2b = n0_2a.aspectRatio(2, contentMode: .fit)
            self.__n0_2b = n0_2b
            let n0_2c = n0_2b.clipped()
            self.__n0_2c = n0_2c
            let n0_2d = n0_2c.offset(x: self._shift, y: 0)
            self.__n0_2d = n0_2d
            let n0_3a = Text("dot")
            self.__n0_3a = n0_3a
            let n0_3b = n0_3a.hidden()
            self.__n0_3b = n0_3b
            let n0_3c = n0_3b.position(x: self._shift, y: 10)
            self.__n0_3c = n0_3c
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
            if let e = self.__n0_0c {
                children.append(e)
            }
            if let e = self.__n0_1a {
                children.append(e)
            }
            if let e = self.__n0_2d {
                children.append(e)
            }
            if let e = self.__n0_3c {
                children.append(e)
            }
            if let owner = self.__n0a {
                owner.replaceChildren(children, context, animation: animation)
            }
          }

          private func __update_inset(_ animated: Bool = true) {
            guard let context = self.__context else {
              self.__needsRefresh = true
              return
            }
            let transaction = animated ? UITransaction.animation : nil
            if let n = self.__n0_0b {
                n.setInset(Inset(.horizontal, self._inset), context, animation: transaction)
            }
          }

          private func __update_shift(_ animated: Bool = true) {
            guard let context = self.__context else {
              self.__needsRefresh = true
              return
            }
            let transaction = animated ? UITransaction.animation : nil
            if let n = self.__n0_2d {
                n.setOffset(float2(self._shift, 0), context, animation: transaction)
            }
            if let n = self.__n0_3c {
                n.setPoint(float2(self._shift, 10), context, animation: transaction)
            }
          }
      }

      extension Card: ReactiveComponent {
      }
      """,
      macros: ["Component": ComponentMacro.self]
    )
  }

  @Test("alignmentGuide in place with its closure as written, and a reactive baseline alignment")
  func alignmentGuides() {
    assertMacroExpansion(
      """
      @Component
      final class Rows: SingleChildElement {
        @State var baseline: Bool = true

        @UIElementBuilder var body: [UIElement] {
          HStack(alignment: self.baseline ? .firstTextBaseline : .center) {
            Text("Big")
              .alignmentGuide(.firstTextBaseline) { d in d.height * 0.5 }
              .padding(.top, 4)
            Text("small")
          }
        }
      }
      """,
      expandedSource: """
      final class Rows: SingleChildElement {
        @State var baseline: Bool = true

        @UIElementBuilder var body: [UIElement] {
          HStack(alignment: self.baseline ? .firstTextBaseline : .center) {
            Text("Big")
              .alignmentGuide(.firstTextBaseline) { d in d.height * 0.5 }
              .padding(.top, 4)
            Text("small")
          }
        }

          private var __context: UIContext? = nil

          private var __needsRefresh: Bool = false

          private var __built: Bool = false

          private var __n0a: HStack? = nil

          private var __n0_0a: Text? = nil

          private var __n0_0b: Text? = nil

          private var __n0_0c: Padding? = nil

          private var __n0_1a: Text? = nil

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
            self.__update_baseline(false)
          }

          private func __build(_ context: UIContext) -> UIElement {
            let n0a = HStack(alignment: self._baseline ? .firstTextBaseline : .center)
            self.__n0a = n0a
            let n0_0a = Text("Big")
            self.__n0_0a = n0_0a
            let n0_0b = n0_0a.alignmentGuide(.firstTextBaseline) { d in
                d.height * 0.5
            }
            self.__n0_0b = n0_0b
            let n0_0c = n0_0b.padding(.top, 4)
            self.__n0_0c = n0_0c
            let n0_1a = Text("small")
            self.__n0_1a = n0_1a
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
            if let e = self.__n0_0c {
                children.append(e)
            }
            if let e = self.__n0_1a {
                children.append(e)
            }
            if let owner = self.__n0a {
                owner.replaceChildren(children, context, animation: animation)
            }
          }

          private func __update_baseline(_ animated: Bool = true) {
            guard let context = self.__context else {
              self.__needsRefresh = true
              return
            }
            let transaction = animated ? UITransaction.animation : nil
            if let n = self.__n0a {
                n.setAlignment(self._baseline ? .firstTextBaseline : .center, context, animation: transaction)
            }
          }
      }

      extension Rows: ReactiveComponent {
      }
      """,
      macros: ["Component": ComponentMacro.self]
    )
  }

  @Test("Grid, GridRow and a free row, grid cell modifiers in place, and a LazyVGrid bound to its columns")
  func grids() {
    assertMacroExpansion(
      """
      @Component
      final class Table: SingleChildElement {
        @State var wide: Bool = false
        @State var columns: [GridItem] = [GridItem(.flexible())]

        @UIElementBuilder var body: [UIElement] {
          VStack {
            Grid(horizontalSpacing: self.wide ? 16 : 8) {
              GridRow(alignment: .top) {
                Text("a")
                Text("b")
                  .gridColumnAlignment(.trailing)
              }
              Divider()
              GridRow {
                Text("c")
                  .gridCellColumns(self.wide ? 2 : 1)
              }
            }
            LazyVGrid(columns: self.columns, spacing: 4) {
              Text("d")
            }
          }
        }
      }
      """,
      expandedSource: """
      final class Table: SingleChildElement {
        @State var wide: Bool = false
        @State var columns: [GridItem] = [GridItem(.flexible())]

        @UIElementBuilder var body: [UIElement] {
          VStack {
            Grid(horizontalSpacing: self.wide ? 16 : 8) {
              GridRow(alignment: .top) {
                Text("a")
                Text("b")
                  .gridColumnAlignment(.trailing)
              }
              Divider()
              GridRow {
                Text("c")
                  .gridCellColumns(self.wide ? 2 : 1)
              }
            }
            LazyVGrid(columns: self.columns, spacing: 4) {
              Text("d")
            }
          }
        }

          private var __context: UIContext? = nil

          private var __needsRefresh: Bool = false

          private var __built: Bool = false

          private var __n0a: VStack? = nil

          private var __n0_0a: Grid? = nil

          private var __n0_0_0a: GridRow? = nil

          private var __n0_0_0_0a: Text? = nil

          private var __n0_0_0_1a: Text? = nil

          private var __n0_0_0_1b: Text? = nil

          private var __n0_0_1a: Divider? = nil

          private var __n0_0_2a: GridRow? = nil

          private var __n0_0_2_0a: Text? = nil

          private var __n0_0_2_0b: Text? = nil

          private var __n0_1a: LazyVGrid? = nil

          private var __n0_1_0a: Text? = nil

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
            self.__update_wide(false)
            self.__update_columns(false)
          }

          private func __build(_ context: UIContext) -> UIElement {
            let n0a = VStack ()
            self.__n0a = n0a
            let n0_0a = Grid(horizontalSpacing: self._wide ? 16 : 8)
            self.__n0_0a = n0_0a
            let n0_0_0a = GridRow(alignment: .top)
            self.__n0_0_0a = n0_0_0a
            let n0_0_0_0a = Text("a")
            self.__n0_0_0_0a = n0_0_0_0a
            let n0_0_0_1a = Text("b")
            self.__n0_0_0_1a = n0_0_0_1a
            let n0_0_0_1b = n0_0_0_1a.gridColumnAlignment(.trailing)
            self.__n0_0_0_1b = n0_0_0_1b
            self.__applyChildren0_0_0(context, animation: nil)
            let n0_0_1a = Divider()
            self.__n0_0_1a = n0_0_1a
            let n0_0_2a = GridRow ()
            self.__n0_0_2a = n0_0_2a
            let n0_0_2_0a = Text("c")
            self.__n0_0_2_0a = n0_0_2_0a
            let n0_0_2_0b = n0_0_2_0a.gridCellColumns(self._wide ? 2 : 1)
            self.__n0_0_2_0b = n0_0_2_0b
            self.__applyChildren0_0_2(context, animation: nil)
            self.__applyChildren0_0(context, animation: nil)
            let n0_1a = LazyVGrid(columns: self._columns, spacing: 4)
            self.__n0_1a = n0_1a
            let n0_1_0a = Text("d")
            self.__n0_1_0a = n0_1_0a
            self.__applyChildren0_1(context, animation: nil)
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
            if let e = self.__n0_1a {
                children.append(e)
            }
            if let owner = self.__n0a {
                owner.replaceChildren(children, context, animation: animation)
            }
          }

          private func __applyChildren0_0(_ context: UIContext, animation: UIAnimation?) {
            var children: [UIElement] = []
            if let e = self.__n0_0_0a {
                children.append(e)
            }
            if let e = self.__n0_0_1a {
                children.append(e)
            }
            if let e = self.__n0_0_2a {
                children.append(e)
            }
            if let owner = self.__n0_0a {
                owner.replaceChildren(children, context, animation: animation)
            }
          }

          private func __applyChildren0_0_0(_ context: UIContext, animation: UIAnimation?) {
            var children: [UIElement] = []
            if let e = self.__n0_0_0_0a {
                children.append(e)
            }
            if let e = self.__n0_0_0_1b {
                children.append(e)
            }
            if let owner = self.__n0_0_0a {
                owner.replaceChildren(children, context, animation: animation)
            }
          }

          private func __applyChildren0_0_2(_ context: UIContext, animation: UIAnimation?) {
            var children: [UIElement] = []
            if let e = self.__n0_0_2_0b {
                children.append(e)
            }
            if let owner = self.__n0_0_2a {
                owner.replaceChildren(children, context, animation: animation)
            }
          }

          private func __applyChildren0_1(_ context: UIContext, animation: UIAnimation?) {
            var children: [UIElement] = []
            if let e = self.__n0_1_0a {
                children.append(e)
            }
            if let owner = self.__n0_1a {
                owner.replaceChildren(children, context, animation: animation)
            }
          }

          private func __update_wide(_ animated: Bool = true) {
            guard let context = self.__context else {
              self.__needsRefresh = true
              return
            }
            let transaction = animated ? UITransaction.animation : nil
            if let n = self.__n0_0a {
                n.setHorizontalSpacing(self._wide ? 16 : 8, context, animation: transaction)
            }
            if let n = self.__n0_0_2_0b {
                n.setGridCellColumns(self._wide ? 2 : 1, context, animation: transaction)
            }
          }

          private func __update_columns(_ animated: Bool = true) {
            guard let context = self.__context else {
              self.__needsRefresh = true
              return
            }
            let transaction = animated ? UITransaction.animation : nil
            if let n = self.__n0_1a {
                n.setItems(self._columns, context, animation: transaction)
            }
          }

          public func appendColumns(_ element: GridItem) {
            self._columns.append(element)
            self.__update_columns()
          }

          public func insertColumns(_ element: GridItem, at position: Int) {
            let index = Swift.min(Swift.max(position, 0), self._columns.count)
            self._columns.insert(element, at: index)
            self.__update_columns()
          }

          @discardableResult
          public func removeColumns(at index: Int) -> GridItem? {
            guard self._columns.indices.contains(index) else {
                return nil
            }
            let removed = self._columns.remove(at: index)
            self.__update_columns()
            return removed
          }

          public func removeColumns(where predicate: (GridItem) -> Bool) {
            let matches = self._columns.indices.filter {
                predicate(self._columns[$0])
            }
            guard matches.count == 1, let index = matches.first else {
              guard !matches.isEmpty else {
                  return
              }
              self._columns.removeAll(where: predicate)
              self.__update_columns()
              return
            }
            self._columns.remove(at: index)
            self.__update_columns()
          }

          public func replaceColumns(_ newValue: [GridItem]) {
            self._columns = newValue
            self.__update_columns()
          }
      }

      extension Table: ReactiveComponent {
      }
      """,
      macros: ["Component": ComponentMacro.self]
    )
  }

  @Test("ViewThatFits, a LayoutView switching layouts, and onGeometryChange typed by its value with its action armed on mount")
  func adaptiveAndCustomLayout() {
    assertMacroExpansion(
      """
      @Component
      final class Adaptive: SingleChildElement {
        @State var vertical: Bool = false
        @State var width: Float = 0

        @UIElementBuilder var body: [UIElement] {
          VStack {
            ViewThatFits(in: .horizontal) {
              Text("a long title that may not fit")
              Text("short")
            }
            LayoutView(self.vertical ? AnyLayout(VStackLayout()) : AnyLayout(HStackLayout())) {
              Text("one")
              Text("two")
            }
            .onGeometryChange(for: Float.self, of: { $0.size.x }) { width in
              self.width = width
            }
          }
        }
      }
      """,
      expandedSource: """
      final class Adaptive: SingleChildElement {
        @State var vertical: Bool = false
        @State var width: Float = 0

        @UIElementBuilder var body: [UIElement] {
          VStack {
            ViewThatFits(in: .horizontal) {
              Text("a long title that may not fit")
              Text("short")
            }
            LayoutView(self.vertical ? AnyLayout(VStackLayout()) : AnyLayout(HStackLayout())) {
              Text("one")
              Text("two")
            }
            .onGeometryChange(for: Float.self, of: { $0.size.x }) { width in
              self.width = width
            }
          }
        }

          private var __context: UIContext? = nil

          private var __needsRefresh: Bool = false

          private var __built: Bool = false

          private var __n0a: VStack? = nil

          private var __n0_0a: ViewThatFits? = nil

          private var __n0_0_0a: Text? = nil

          private var __n0_0_1a: Text? = nil

          private var __n0_1a: LayoutView? = nil

          private var __n0_1b: GeometryChangeElement<Float>? = nil

          private var __n0_1_0a: Text? = nil

          private var __n0_1_1a: Text? = nil

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
            self.__update_vertical(false)
            self.__update_width(false)
          }

          private func __build(_ context: UIContext) -> UIElement {
            let n0a = VStack ()
            self.__n0a = n0a
            let n0_0a = ViewThatFits(in: .horizontal)
            self.__n0_0a = n0_0a
            let n0_0_0a = Text("a long title that may not fit")
            self.__n0_0_0a = n0_0_0a
            let n0_0_1a = Text("short")
            self.__n0_0_1a = n0_0_1a
            self.__applyChildren0_0(context, animation: nil)
            let n0_1a = LayoutView(self._vertical ? AnyLayout(VStackLayout()) : AnyLayout(HStackLayout()))
            self.__n0_1a = n0_1a
            let n0_1b = n0_1a.onGeometryChange(for: Float.self, of: {
                    $0.size.x
                }) { _ in
            }
            self.__n0_1b = n0_1b
            let n0_1_0a = Text("one")
            self.__n0_1_0a = n0_1_0a
            let n0_1_1a = Text("two")
            self.__n0_1_1a = n0_1_1a
            self.__applyChildren0_1(context, animation: nil)
            self.__applyChildren0(context, animation: nil)
            var root: [UIElement] = []
            if let e = self.__n0a {
                root.append(e)
            }
            return root.first ?? EmptyElement()
          }

          private func __armHandlers() {
            self.__n0_1b?.action = { width in
                  self.width = width
                }
          }

          private func __disarmHandlers() {
            self.__n0_1b?.action = nil
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

          private func __applyChildren0_0(_ context: UIContext, animation: UIAnimation?) {
            var children: [UIElement] = []
            if let e = self.__n0_0_0a {
                children.append(e)
            }
            if let e = self.__n0_0_1a {
                children.append(e)
            }
            if let owner = self.__n0_0a {
                owner.replaceChildren(children, context, animation: animation)
            }
          }

          private func __applyChildren0_1(_ context: UIContext, animation: UIAnimation?) {
            var children: [UIElement] = []
            if let e = self.__n0_1_0a {
                children.append(e)
            }
            if let e = self.__n0_1_1a {
                children.append(e)
            }
            if let owner = self.__n0_1a {
                owner.replaceChildren(children, context, animation: animation)
            }
          }

          private func __update_vertical(_ animated: Bool = true) {
            guard let context = self.__context else {
              self.__needsRefresh = true
              return
            }
            let transaction = animated ? UITransaction.animation : nil
            if let n = self.__n0_1a {
                n.setLayout(self._vertical ? AnyLayout(VStackLayout()) : AnyLayout(HStackLayout()), context, animation: transaction)
            }
          }

          private func __update_width(_ animated: Bool = true) {
            if self.__context == nil {
              self.__needsRefresh = true
            }
          }
      }

      extension Adaptive: ReactiveComponent {
      }
      """,
      macros: ["Component": ComponentMacro.self]
    )
  }

  @Test("clipShape and cornerRadius update the clip's shape; border and background(_:in:) bind each argument apart")
  func shapeModifiers() {
    assertMacroExpansion(
      """
      @Component
      final class Card: SingleChildElement {
        @State var hovered: Bool = false

        @UIElementBuilder var body: [UIElement] {
          VStack {
            Text("a")
              .background(.blue, in: self.hovered ? .capsule : .rect(cornerRadius: 4))
              .border(self.hovered ? .red : .black, width: self.hovered ? 2 : 1, in: .capsule)
            Rectangle(.red)
              .cornerRadius(self.hovered ? 12 : 4)
              .clipShape(self.hovered ? .circle : .rect)
          }
        }
      }
      """,
      expandedSource: """
      final class Card: SingleChildElement {
        @State var hovered: Bool = false

        @UIElementBuilder var body: [UIElement] {
          VStack {
            Text("a")
              .background(.blue, in: self.hovered ? .capsule : .rect(cornerRadius: 4))
              .border(self.hovered ? .red : .black, width: self.hovered ? 2 : 1, in: .capsule)
            Rectangle(.red)
              .cornerRadius(self.hovered ? 12 : 4)
              .clipShape(self.hovered ? .circle : .rect)
          }
        }

          private var __context: UIContext? = nil

          private var __needsRefresh: Bool = false

          private var __built: Bool = false

          private var __n0a: VStack? = nil

          private var __n0_0a: Text? = nil

          private var __n0_0b: Background? = nil

          private var __n0_0c: BorderElement? = nil

          private var __n0_1a: Rectangle? = nil

          private var __n0_1b: ClipElement? = nil

          private var __n0_1c: ClipElement? = nil

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
            self.__update_hovered(false)
          }

          private func __build(_ context: UIContext) -> UIElement {
            let n0a = VStack ()
            self.__n0a = n0a
            let n0_0a = Text("a")
            self.__n0_0a = n0_0a
            let n0_0b = n0_0a.background(.blue, in: self._hovered ? .capsule : .rect(cornerRadius: 4))
            self.__n0_0b = n0_0b
            let n0_0c = n0_0b.border(self._hovered ? .red : .black, width: self._hovered ? 2 : 1, in: .capsule)
            self.__n0_0c = n0_0c
            let n0_1a = Rectangle(.red)
            self.__n0_1a = n0_1a
            let n0_1b = n0_1a.cornerRadius(self._hovered ? 12 : 4)
            self.__n0_1b = n0_1b
            let n0_1c = n0_1b.clipShape(self._hovered ? .circle : .rect)
            self.__n0_1c = n0_1c
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
            if let e = self.__n0_0c {
                children.append(e)
            }
            if let e = self.__n0_1c {
                children.append(e)
            }
            if let owner = self.__n0a {
                owner.replaceChildren(children, context, animation: animation)
            }
          }

          private func __update_hovered(_ animated: Bool = true) {
            guard let context = self.__context else {
              self.__needsRefresh = true
              return
            }
            let transaction = animated ? UITransaction.animation : nil
            if let n = self.__n0_0b {
                n.setShape(self._hovered ? .capsule : .rect(cornerRadius: 4), context, animation: transaction)
            }
            if let n = self.__n0_0c {
                n.setColor(self._hovered ? .red : .black, context, animation: transaction)
            }
            if let n = self.__n0_0c {
                n.setLineWidth(self._hovered ? 2 : 1, context, animation: transaction)
            }
            if let n = self.__n0_1b {
                n.setCornerRadius(self._hovered ? 12 : 4, context, animation: transaction)
            }
            if let n = self.__n0_1c {
                n.setShape(self._hovered ? .circle : .rect, context, animation: transaction)
            }
          }
      }

      extension Card: ReactiveComponent {
      }
      """,
      macros: ["Component": ComponentMacro.self]
    )
  }

  @Test("shadow binds each argument apart; one that reads no state is not bound")
  func shadowModifier() {
    assertMacroExpansion(
      """
      @Component
      final class Card: SingleChildElement {
        @State var hovered: Bool = false

        @UIElementBuilder var body: [UIElement] {
          Rectangle(.white)
            .shadow(color: .black, radius: self.hovered ? 12 : 4, y: self.hovered ? 8 : 2)
        }
      }
      """,
      expandedSource: """
      final class Card: SingleChildElement {
        @State var hovered: Bool = false

        @UIElementBuilder var body: [UIElement] {
          Rectangle(.white)
            .shadow(color: .black, radius: self.hovered ? 12 : 4, y: self.hovered ? 8 : 2)
        }

          private var __context: UIContext? = nil

          private var __needsRefresh: Bool = false

          private var __built: Bool = false

          private var __n0a: Rectangle? = nil

          private var __n0b: ShadowElement? = nil

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
            self.__update_hovered(false)
          }

          private func __build(_ context: UIContext) -> UIElement {
            let n0a = Rectangle(.white)
            self.__n0a = n0a
            let n0b = n0a.shadow(color: .black, radius: self._hovered ? 12 : 4, y: self._hovered ? 8 : 2)
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

          private func __update_hovered(_ animated: Bool = true) {
            guard let context = self.__context else {
              self.__needsRefresh = true
              return
            }
            let transaction = animated ? UITransaction.animation : nil
            if let n = self.__n0b {
                n.setRadius(self._hovered ? 12 : 4, context, animation: transaction)
            }
            if let n = self.__n0b {
                n.setY(self._hovered ? 8 : 2, context, animation: transaction)
            }
          }
      }

      extension Card: ReactiveComponent {
      }
      """,
      macros: ["Component": ComponentMacro.self]
    )
  }

  @Test("blur binds its radius animated; glass binds its material without animation")
  func blurAndGlassModifiers() {
    assertMacroExpansion(
      """
      @Component
      final class Card: SingleChildElement {
        @State var focused: Bool = false

        @UIElementBuilder var body: [UIElement] {
          Rectangle(.white)
            .blur(radius: self.focused ? 0 : 8)
            .glass(self.focused ? .thick : .thin)
        }
      }
      """,
      expandedSource: """
      final class Card: SingleChildElement {
        @State var focused: Bool = false

        @UIElementBuilder var body: [UIElement] {
          Rectangle(.white)
            .blur(radius: self.focused ? 0 : 8)
            .glass(self.focused ? .thick : .thin)
        }

          private var __context: UIContext? = nil

          private var __needsRefresh: Bool = false

          private var __built: Bool = false

          private var __n0a: Rectangle? = nil

          private var __n0b: BlurElement? = nil

          private var __n0c: GlassBackground? = nil

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
            self.__update_focused(false)
          }

          private func __build(_ context: UIContext) -> UIElement {
            let n0a = Rectangle(.white)
            self.__n0a = n0a
            let n0b = n0a.blur(radius: self._focused ? 0 : 8)
            self.__n0b = n0b
            let n0c = n0b.glass(self._focused ? .thick : .thin)
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

          private func __update_focused(_ animated: Bool = true) {
            guard let context = self.__context else {
              self.__needsRefresh = true
              return
            }
            let transaction = animated ? UITransaction.animation : nil
            if let n = self.__n0b {
                n.setRadius(self._focused ? 0 : 8, context, animation: transaction)
            }
            if let n = self.__n0c {
                n.setMaterial(self._focused ? .thick : .thin, context)
            }
          }
      }

      extension Card: ReactiveComponent {
      }
      """,
      macros: ["Component": ComponentMacro.self]
    )
  }
}
