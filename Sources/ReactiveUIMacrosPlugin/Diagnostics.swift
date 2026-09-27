import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

struct ReactiveUIDiagnostic: DiagnosticMessage {
  let message: String
  let diagnosticID: MessageID
  let severity: DiagnosticSeverity

  init(_ id: String, _ message: String, severity: DiagnosticSeverity = .error) {
    self.message = message
    self.diagnosticID = MessageID(domain: "ReactiveUI", id: id)
    self.severity = severity
  }
}

struct ReactiveUIFixIt: FixItMessage {
  let message: String
  let fixItID: MessageID

  init(_ id: String, _ message: String) {
    self.message = message
    self.fixItID = MessageID(domain: "ReactiveUI", id: id)
  }
}

extension MacroExpansionContext {
  func error(_ id: String, _ message: String, at node: some SyntaxProtocol) {
    diagnose(Diagnostic(node: Syntax(node), message: ReactiveUIDiagnostic(id, message)))
  }

  func warning(_ id: String, _ message: String, at node: some SyntaxProtocol) {
    diagnose(Diagnostic(node: Syntax(node), message: ReactiveUIDiagnostic(id, message, severity: .warning)))
  }
}
