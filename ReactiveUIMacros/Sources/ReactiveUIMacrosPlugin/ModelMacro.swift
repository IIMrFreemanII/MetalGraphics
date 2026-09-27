import SwiftSyntax
import SwiftSyntaxMacros

// `@Model final class AppModel { var count: Int = 0 }` becomes:
//
//   final class AppModel {
//     @ModelTracked var count: Int = 0 {
//       @storageRestrictions(initializes: _count)
//       init(initialValue) { _count = initialValue }
//       get { __lock.lock(); defer { __lock.unlock() }; return _count }
//       set { __lock.lock(); let changed = ModelObservers.changed(_count, newValue)
//             _count = newValue; __lock.unlock()
//             if changed { __observers_count.notify(also: __observers_any) } }
//       _modify { __lock.lock(); defer { __lock.unlock(); __observers_count.notify(…) }
//                 yield &_count }
//     }
//     private var _count: Int
//     private let __observers_count = ModelObservers()
//
//     private let __lock = ModelLock()
//     private let __observers_any = ModelObservers()
//     public func __observers(named name: String) -> ModelObservers { … }
//   }
//   extension AppModel: ReactiveModel, @unchecked Sendable {}
//
// Every window runs on a thread of its own, and reads and writes the model from there: the
// storage is behind the model's lock, which is recursive, so a `_modify` body can read the model
// it modifies. Readers are notified after the lock is released.
//
// `__observers(named:)` is how a component subscribes on mount: `@Component` knows only the
// property names its body reads, as written. A name that is not a tracked property — a
// computed one, a method — gets the list every write notifies.
public struct ModelMacro {}

extension ModelMacro: MemberMacro {
  public static func expansion(
    of node: AttributeSyntax,
    providingMembersOf declaration: some DeclGroupSyntax,
    conformingTo protocols: [TypeSyntax],
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    guard let classDecl = declaration.as(ClassDeclSyntax.self) else {
      context.error("F20", "@Model can only be applied to a class: components share one instance, by reference.", at: declaration)
      return []
    }
    if AttributeName.has("MainActor", in: classDecl.attributes) {
      context.error(
        "F20",
        "@Model is read and written by windows that each run on a thread of their own; remove '@MainActor'.",
        at: classDecl.name
      )
    }

    for member in classDecl.memberBlock.members {
      if let decl = member.decl.as(VariableDeclSyntax.self), TrackedProperty.declaresSeveral(decl) {
        context.error("F20", TrackedProperty.severalBindings, at: decl)
      }
    }

    let tracked = TrackedProperty.all(in: classDecl.memberBlock.members)
    let cases = tracked.map { "case \"\($0.name)\": return self.\(Naming.modelObservers($0.name))" }
    return [
      "private let \(raw: Naming.modelLock) = ModelLock()",
      "private let \(raw: Naming.modelObserversAny) = ModelObservers()",
      """
      public func __observers(named name: String) -> ModelObservers {
        switch name {
        \(raw: (cases + ["default: return self.\(Naming.modelObserversAny)"]).joined(separator: "\n  "))
        }
      }
      """,
    ]
  }
}

extension ModelMacro: MemberAttributeMacro {
  public static func expansion(
    of node: AttributeSyntax,
    attachedTo declaration: some DeclGroupSyntax,
    providingAttributesFor member: some DeclSyntaxProtocol,
    in context: some MacroExpansionContext
  ) throws -> [AttributeSyntax] {
    guard declaration.is(ClassDeclSyntax.self),
          let decl = member.as(VariableDeclSyntax.self), TrackedProperty.isTracked(decl)
    else { return [] }
    return ["@ModelTracked"]
  }
}

extension ModelMacro: ExtensionMacro {
  public static func expansion(
    of node: AttributeSyntax,
    attachedTo declaration: some DeclGroupSyntax,
    providingExtensionsOf type: some TypeSyntaxProtocol,
    conformingTo protocols: [TypeSyntax],
    in context: some MacroExpansionContext
  ) throws -> [ExtensionDeclSyntax] {
    guard declaration.is(ClassDeclSyntax.self) else { return [] }
    // Sendable by its lock: every access to tracked storage takes it.
    return [try ExtensionDeclSyntax("extension \(type.trimmed): \(raw: Naming.modelProtocol), @unchecked Sendable {}")]
  }
}

public struct ModelTrackedMacro {}

extension ModelTrackedMacro: AccessorMacro {
  public static func expansion(
    of node: AttributeSyntax,
    providingAccessorsOf declaration: some DeclSyntaxProtocol,
    in context: some MacroExpansionContext
  ) throws -> [AccessorDeclSyntax] {
    guard let decl = declaration.as(VariableDeclSyntax.self) else { return [] }
    let (property, error) = TrackedProperty.parse(decl)
    guard let property else {
      if let error { context.error("F20", error.message, at: error.node) }
      return []
    }

    let storage = Naming.storage(property.name)
    let lock = "self.\(Naming.modelLock)"
    let notify = "self.\(Naming.modelObservers(property.name)).notify(also: self.\(Naming.modelObserversAny))"
    return [
      """
      @storageRestrictions(initializes: \(raw: storage))
      init(initialValue) {
        \(raw: storage) = initialValue
      }
      """,
      """
      get {
        \(raw: lock).lock()
        defer {
          \(raw: lock).unlock()
        }
        return \(raw: storage)
      }
      """,
      // Writing the value it already has touches no window. `@State` does not skip: only its
      // own component reads it, while a model's readers can be anywhere. Readers are notified
      // outside the lock: the writer's own window updates them right away, and they read.
      """
      set {
        \(raw: lock).lock()
        let changed = ModelObservers.changed(\(raw: storage), newValue)
        \(raw: storage) = newValue
        \(raw: lock).unlock()
        if changed {
          \(raw: notify)
        }
      }
      """,
      // Held across the yield, so an append is one in place, and another window's write can't
      // land in the middle of it.
      """
      _modify {
        \(raw: lock).lock()
        defer {
          \(raw: lock).unlock()
          \(raw: notify)
        }
        yield &\(raw: storage)
      }
      """,
    ]
  }
}

extension ModelTrackedMacro: PeerMacro {
  public static func expansion(
    of node: AttributeSyntax,
    providingPeersOf declaration: some DeclSyntaxProtocol,
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    guard let decl = declaration.as(VariableDeclSyntax.self),
          let property = TrackedProperty.parse(decl).property
    else { return [] }   // the accessor expansion already diagnosed this
    return [
      "private var \(raw: Naming.storage(property.name)): \(property.type.trimmed)",
      "private let \(raw: Naming.modelObservers(property.name)) = ModelObservers()",
    ]
  }
}

public struct ModelIgnoredMacro: PeerMacro {
  public static func expansion(
    of node: AttributeSyntax,
    providingPeersOf declaration: some DeclSyntaxProtocol,
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    []
  }
}

// `@Bindable let model: AppModel = .shared` in a component. `@Component` reads the attribute to
// know which reads in `body` are a model's; this only declares what the body can spell.
public struct BindableMacro: PeerMacro {
  public static func expansion(
    of node: AttributeSyntax,
    providingPeersOf declaration: some DeclSyntaxProtocol,
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    guard let decl = declaration.as(VariableDeclSyntax.self) else {
      context.error("F21", "@Bindable can only be applied to a property.", at: declaration)
      return []
    }
    let (property, error) = ModelProperty.parse(decl)
    guard let property else {
      if let error { context.error("F21", error.message, at: error.node) }
      return []
    }
    return [
      // What `$model.count` spells. A `@Component` body never evaluates it; see `ModelBindings`.
      """
      var \(raw: Naming.binding(property.name)): ModelBindings<\(property.type.trimmed)> {
        ModelBindings(self.\(raw: property.name))
      }
      """,
      """
      private func \(raw: Naming.requiresComponent(property.name))() {
        let _: any \(raw: Naming.componentProtocol) = self
      }
      """,
    ]
  }
}
