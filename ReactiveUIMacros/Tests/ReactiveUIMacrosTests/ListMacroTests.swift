import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import Testing

@testable import ReactiveUIMacrosPlugin

// A `@State` array is an ordinary state property: the scanner needs no special case to see
// `Float(self.rows.count)` or `if self.rows.isEmpty`. What `@Component` adds on top is a set of
// mutation methods, so that the *operation* survives the trip from the call site into the tree.
// An append becomes one `insertRow` per list; a plain assignment can only say "the array is
// different now", and rebuilds every row.
@Suite("@State arrays and lists")
struct ListMacroTests {

  // The anchor for the list path. Three things are worth reading for in the expansion:
  //
  //   * both lists get a node field specialised from the annotation \u{2014} `VList<Item>`,
  //     `HList<Item>` \u{2014} which is the only reason `setItems` can be called on them at all;
  //   * `__rows_didInsert` / `__rows_didRemove` are `__update_rows` with the list lines
  //     swapped for `insertRow` / `removeRow`. Everything else (the width bar's count read,
  //     the `isEmpty` branch) re-runs its ordinary expression, because those have no
  //     incremental form however the array changed;
  //   * `mount` registers nothing and `unmount` unregisters nothing. The wiring from `rows`
  //     to the two lists was decided here, at compile time.
  @Test("two lists, a count read and a branch over one @State array")
  func listComponent() {
    assertMacroExpansion(
      """
      @Component
      final class L: SingleChildElement {
        @State var rows: [Item] = []

        @UIElementBuilder var body: [UIElementNode] {
          VStack {
            Rectangle(.blue)
              .frame(width: Float(self.rows.count), height: 6)
            VList(items: self.rows) { item in
              RowView(item: item)
            }
            HList(items: self.rows) { item in
              RowView(item: item)
            }
            if self.rows.isEmpty {
              Rectangle(.green)
            }
          }
        }
      }
      """,
      expandedSource: """
      final class L: SingleChildElement {
        var rows: [Item] {
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

        private var _rows: [Item]

        private func __requiresComponent_rows() {
          let _: any ReactiveComponent = self
        }

        @UIElementBuilder var body: [UIElementNode] {
          VStack {
            Rectangle(.blue)
              .frame(width: Float(self.rows.count), height: 6)
            VList(items: self.rows) { item in
              RowView(item: item)
            }
            HList(items: self.rows) { item in
              RowView(item: item)
            }
            if self.rows.isEmpty {
              Rectangle(.green)
            }
          }
        }

          private var __context: UIContext? = nil

          private var __needsRefresh: Bool = false

          private var __built: Bool = false

          private var __n0a: VStack? = nil

          private var __n0_0a: Rectangle? = nil

          private var __n0_0b: Frame? = nil

          private var __n0_1a: VList<Item>? = nil

          private var __n0_2a: HList<Item>? = nil

          private var __n0_3_0_0a: Rectangle? = nil

          private var __tag0_3: Int = -1

          private var __slot0_3: [UIElement] = []

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
            self.__update_rows()
          }

          private func __build(_ context: UIContext) -> UIElement {
            let n0a = VStack ()
            self.__n0a = n0a
            let n0_0a = Rectangle(.blue)
            self.__n0_0a = n0_0a
            let n0_0b = n0_0a.frame(width: Float(self._rows.count), height: 6)
            self.__n0_0b = n0_0b
            let n0_1a = VList(items: self._rows) { item in
                  RowView(item: item)
                }
            self.__n0_1a = n0_1a
            let n0_2a = HList(items: self._rows) { item in
                  RowView(item: item)
                }
            self.__n0_2a = n0_2a
            self.__tag0_3 = self.__evalTag0_3()
            self.__slot0_3 = self.__enter0_3(self.__tag0_3, context)
            self.__applyChildren0(context)
            var root: [UIElement] = []
            if let e = self.__n0a {
                root.append(e)
            }
            return root.first ?? EmptyElement()
          }

          private func __applyChildrenRoot(_ context: UIContext) {
            var children: [UIElement] = []
            if let e = self.__n0a {
                children.append(e)
            }
            self.setChild(children.first ?? EmptyElement(), context)
          }

          private func __applyChildren0(_ context: UIContext) {
            var children: [UIElement] = []
            if let e = self.__n0_0b {
                children.append(e)
            }
            if let e = self.__n0_1a {
                children.append(e)
            }
            if let e = self.__n0_2a {
                children.append(e)
            }
            children.append(contentsOf: self.__slot0_3)
            if let owner = self.__n0a {
                owner.replaceChildren(children, context)
            }
          }

          private func __evalTag0_3() -> Int {
            (self._rows.isEmpty) ? 0 : 1
          }

          private func __enter0_3(_ tag: Int, _ context: UIContext) -> [UIElement] {
            switch tag {
            case 0:
              let n0_3_0_0a = Rectangle(.green)
              self.__n0_3_0_0a = n0_3_0_0a
              var elements: [UIElement] = []
              if let e = self.__n0_3_0_0a {
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

          private func __leave0_3(_ tag: Int) {
            switch tag {
            case 0:
              self.__n0_3_0_0a = nil
            case 1:
              break
            default:
              break
            }
          }

          private func __swap0_3(_ context: UIContext) {
            let tag = self.__evalTag0_3()
            guard tag != self.__tag0_3 else {
              return
            }
            let previous = self.__tag0_3
            self.__tag0_3 = tag
            self.__slot0_3 = self.__enter0_3(tag, context)
            self.__leave0_3(previous)
            self.__applyChildren0(context)
          }

          private func __update_rows() {
            guard let context = self.__context else {
              self.__needsRefresh = true
              return
            }
            if let n = self.__n0_0b {
                n.setSize(float2(Float(self._rows.count), 6), context)
            }
            if let n = self.__n0_1a {
                n.setItems(self._rows, context)
            }
            if let n = self.__n0_2a {
                n.setItems(self._rows, context)
            }
            self.__swap0_3(context)
          }

          public func appendRows(_ element: Item) {
            let index = self._rows.count
            self._rows.append(element)
            self.__rows_didInsert(element, at: index)
          }

          public func insertRows(_ element: Item, at position: Int) {
            let index = Swift.min(Swift.max(position, 0), self._rows.count)
            self._rows.insert(element, at: index)
            self.__rows_didInsert(element, at: index)
          }

          @discardableResult
          public func removeRows(at index: Int) -> Item? {
            guard self._rows.indices.contains(index) else {
                return nil
            }
            let removed = self._rows.remove(at: index)
            self.__rows_didRemove(removed, at: index)
            return removed
          }

          public func removeRows(where predicate: (Item) -> Bool) {
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

          public func replaceRows(_ newValue: [Item]) {
            self._rows = newValue
            self.__update_rows()
          }

          private func __rows_didInsert(_ element: Item, at index: Int) {
            guard let context = self.__context else {
              self.__needsRefresh = true
              return
            }
            if let n = self.__n0_0b {
                n.setSize(float2(Float(self._rows.count), 6), context)
            }
            if let n = self.__n0_1a {
                n.insertRow(element, at: index, context)
            }
            if let n = self.__n0_2a {
                n.insertRow(element, at: index, context)
            }
            self.__swap0_3(context)
          }

          private func __rows_didRemove(_ element: Item, at index: Int) {
            guard let context = self.__context else {
              self.__needsRefresh = true
              return
            }
            if let n = self.__n0_0b {
                n.setSize(float2(Float(self._rows.count), 6), context)
            }
            if let n = self.__n0_1a {
                n.removeRow(element, at: index, context)
            }
            if let n = self.__n0_2a {
                n.removeRow(element, at: index, context)
            }
            self.__swap0_3(context)
          }
      }

      extension L: ReactiveComponent {
      }
      """,
      macros: ["Component": ComponentMacro.self, "State": StateMacro.self]
    )
  }

  // An array that feeds no list still gets mutation methods, but there is nothing to apply
  // incrementally, so they fall through to the full update and no appliers are emitted. The
  // bindings an incremental call would have needed are omitted too rather than left unused:
  // generated code must not make the compiler warn at its user.
  @Test("an array that feeds no list gets mutation methods but no incremental appliers")
  func arrayWithoutList() {
    assertMacroExpansion(
      """
      @Component
      final class N: SingleChildElement {
        @State var tags: [String] = []

        @UIElementBuilder var body: [UIElementNode] {
          Rectangle(.blue)
            .frame(width: Float(self.tags.count), height: 6)
        }
      }
      """,
      expandedSource: """
      final class N: SingleChildElement {
        var tags: [String] {
            @storageRestrictions(initializes: _tags)
            init(initialValue) {
              _tags = initialValue
            }
            get {
              _tags
            }
            set {
              _tags = newValue
              self.__update_tags()
            }
            _modify {
              yield &_tags
              self.__update_tags()
            }
        }

        private var _tags: [String]

        private func __requiresComponent_tags() {
          let _: any ReactiveComponent = self
        }

        @UIElementBuilder var body: [UIElementNode] {
          Rectangle(.blue)
            .frame(width: Float(self.tags.count), height: 6)
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
            self.__update_tags()
          }

          private func __build(_ context: UIContext) -> UIElement {
            let n0a = Rectangle(.blue)
            self.__n0a = n0a
            let n0b = n0a.frame(width: Float(self._tags.count), height: 6)
            self.__n0b = n0b
            var root: [UIElement] = []
            if let e = self.__n0b {
                root.append(e)
            }
            return root.first ?? EmptyElement()
          }

          private func __applyChildrenRoot(_ context: UIContext) {
            var children: [UIElement] = []
            if let e = self.__n0b {
                children.append(e)
            }
            self.setChild(children.first ?? EmptyElement(), context)
          }

          private func __update_tags() {
            guard let context = self.__context else {
              self.__needsRefresh = true
              return
            }
            if let n = self.__n0b {
                n.setSize(float2(Float(self._tags.count), 6), context)
            }
          }

          public func appendTags(_ element: String) {
            self._tags.append(element)
            self.__update_tags()
          }

          public func insertTags(_ element: String, at position: Int) {
            let index = Swift.min(Swift.max(position, 0), self._tags.count)
            self._tags.insert(element, at: index)
            self.__update_tags()
          }

          @discardableResult
          public func removeTags(at index: Int) -> String? {
            guard self._tags.indices.contains(index) else {
                return nil
            }
            let removed = self._tags.remove(at: index)
            self.__update_tags()
            return removed
          }

          public func removeTags(where predicate: (String) -> Bool) {
            let matches = self._tags.indices.filter {
                predicate(self._tags[$0])
            }
            guard matches.count == 1, let index = matches.first else {
              guard !matches.isEmpty else {
                  return
              }
              self._tags.removeAll(where: predicate)
              self.__update_tags()
              return
            }
            self._tags.remove(at: index)
            self.__update_tags()
          }

          public func replaceTags(_ newValue: [String]) {
            self._tags = newValue
            self.__update_tags()
          }
      }

      extension N: ReactiveComponent {
      }
      """,
      macros: ["Component": ComponentMacro.self, "State": StateMacro.self]
    )
  }
}
