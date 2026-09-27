import SwiftSyntaxMacros
import SwiftSyntaxMacrosGenericTestSupport
import Testing

@testable import ReactiveUIMacrosPlugin

// Drag and drop. `.draggable` binds its payload like any reactive argument, so a row carries its
// current value, and takes its preview as content through `replaceContent`. `.dropDestination`
// has two handlers — the drop, and `isTargeted:` written as a further trailing closure — both
// taken out of the chain and armed on mount. `.onMove(perform:)` is armed the same way, and the
// array it reorders gets a `move…(fromOffsets:toOffset:)` mutation.
@Suite("Drag and drop")
struct DragDropMacroTests {
  @Test("draggable with a preview, a drop destination with two handlers, and a reorderable list")
  func dragAndDrop() {
    assertMacroExpansion(
      """
      @Component
      final class Board: SingleChildElement {
        @State var chip: Chip = Chip()
        @State var targeted: Bool = false
        @State var rows: [Row] = []

        @UIElementBuilder var body: [UIElement] {
          VStack {
            Rectangle(.red)
              .draggable(self.chip) {
                Text("Moving")
              }
            Rectangle(.blue)
              .dropDestination(for: Chip.self) { items, location in
                self.drop(items)
                return true
              } isTargeted: { over in
                self.targeted = over
              }
            VList(items: self.rows) { row in
              RowView(row: row)
            }
            .onMove(perform: { from, to in
              self.moveRows(fromOffsets: from, toOffset: to)
            })
          }
        }
      }
      """,
      expandedSource: """

      final class Board: SingleChildElement {
        var chip: Chip {
            @storageRestrictions(initializes: _chip)
            init(initialValue) {
              _chip = initialValue
            }
            get {
              _chip
            }
            set {
              _chip = newValue
              self.__update_chip()
            }
            _modify {
              yield &_chip
              self.__update_chip()
            }
        }

        private var _chip: Chip

        var $chip: Binding<Chip> {
          Binding(unowned: self, \\.chip)
        }

        private func __requiresComponent_chip() {
          let _: any ReactiveComponent = self
        }
        var targeted: Bool {
            @storageRestrictions(initializes: _targeted)
            init(initialValue) {
              _targeted = initialValue
            }
            get {
              _targeted
            }
            set {
              _targeted = newValue
              self.__update_targeted()
            }
            _modify {
              yield &_targeted
              self.__update_targeted()
            }
        }

        private var _targeted: Bool

        var $targeted: Binding<Bool> {
          Binding(unowned: self, \\.targeted)
        }

        private func __requiresComponent_targeted() {
          let _: any ReactiveComponent = self
        }
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
          VStack {
            Rectangle(.red)
              .draggable(self.chip) {
                Text("Moving")
              }
            Rectangle(.blue)
              .dropDestination(for: Chip.self) { items, location in
                self.drop(items)
                return true
              } isTargeted: { over in
                self.targeted = over
              }
            VList(items: self.rows) { row in
              RowView(row: row)
            }
            .onMove(perform: { from, to in
              self.moveRows(fromOffsets: from, toOffset: to)
            })
          }
        }

          private var __context: UIContext? = nil

          private var __needsRefresh: Bool = false

          private var __built: Bool = false

          private var __n0a: VStack? = nil

          private var __n0_0a: Rectangle? = nil

          private var __n0_0b: DraggableElement? = nil

          private var __n0_0o1_0a: Text? = nil

          private var __n0_1a: Rectangle? = nil

          private var __n0_1b: DropDestinationElement<Chip>? = nil

          private var __n0_2a: VList<Row>? = nil

          private var __n0_2b: ReorderElement? = nil

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
            self.__update_chip(false)
            self.__update_targeted(false)
            self.__update_rows(false)
          }

          private func __build(_ context: UIContext) -> UIElement {
            let n0a = VStack ()
            self.__n0a = n0a
            let n0_0a = Rectangle(.red)
            self.__n0_0a = n0_0a
            let n0_0b = n0_0a.draggable(self._chip)
            self.__n0_0b = n0_0b
            let n0_0o1_0a = Text("Moving")
            self.__n0_0o1_0a = n0_0o1_0a
            self.__applyChildren0_0o1(context, animation: nil)
            let n0_1a = Rectangle(.blue)
            self.__n0_1a = n0_1a
            let n0_1b = n0_1a.dropDestination(for: Chip.self) { _, _ in
                false
            }
            self.__n0_1b = n0_1b
            let n0_2a = VList(items: self._rows) { row in
                  RowView(row: row)
                }
            self.__n0_2a = n0_2a
            let n0_2b = n0_2a.onMove { _, _ in
            }
            self.__n0_2b = n0_2b
            self.__applyChildren0(context, animation: nil)
            var root: [UIElement] = []
            if let e = self.__n0a {
                root.append(e)
            }
            return root.first ?? EmptyElement()
          }

          private func __armHandlers() {
            self.__n0_1b?.action = { items, location in
                    self.drop(items)
                    return true
                  }
            self.__n0_1b?.isTargeted = { over in
                    self.targeted = over
                  }
            self.__n0_2b?.action = { from, to in
                  self.moveRows(fromOffsets: from, toOffset: to)
                }
          }

          private func __disarmHandlers() {
            self.__n0_1b?.action = nil
            self.__n0_1b?.isTargeted = nil
            self.__n0_2b?.action = nil
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
            if let e = self.__n0_1b {
                children.append(e)
            }
            if let e = self.__n0_2b {
                children.append(e)
            }
            if let owner = self.__n0a {
                owner.replaceChildren(children, context, animation: animation)
            }
          }

          private func __applyChildren0_0o1(_ context: UIContext, animation: UIAnimation?) {
            var children: [UIElement] = []
            if let e = self.__n0_0o1_0a {
                children.append(e)
            }
            if let owner = self.__n0_0b {
                owner.replaceContent(children, context, animation: animation)
            }
          }

          private func __update_chip(_ animated: Bool = true) {
            guard let context = self.__context else {
              self.__needsRefresh = true
              return
            }
            if let n = self.__n0_0b {
                n.setDragPayload(self._chip, context)
            }
          }

          private func __update_targeted(_ animated: Bool = true) {
            if self.__context == nil {
              self.__needsRefresh = true
            }
          }

          private func __update_rows(_ animated: Bool = true) {
            guard let context = self.__context else {
              self.__needsRefresh = true
              return
            }
            let transaction = animated ? UITransaction.animation : nil
            if let n = self.__n0_2a {
                n.setItems(self._rows, context, animation: transaction)
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

          public func moveRows(fromOffsets source: IndexSet, toOffset destination: Int) {
            self._rows.moveElements(fromOffsets: source, toOffset: destination)
            self.__update_rows()
          }

          private func __rows_didInsert(_ element: Row, at index: Int, _ animated: Bool = true) {
            guard let context = self.__context else {
              self.__needsRefresh = true
              return
            }
            let transaction = animated ? UITransaction.animation : nil
            if let n = self.__n0_2a {
                n.insertRow(element, at: index, context, animation: transaction)
            }
          }

          private func __rows_didRemove(_ element: Row, at index: Int, _ animated: Bool = true) {
            guard let context = self.__context else {
              self.__needsRefresh = true
              return
            }
            let transaction = animated ? UITransaction.animation : nil
            if let n = self.__n0_2a {
                n.removeRow(element, at: index, context, animation: transaction)
            }
          }
      }

      extension Board: ReactiveComponent {
      }
      """,
      macros: ["Component": ComponentMacro.self, "State": StateMacro.self]
    )
  }
}
