import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacros
import SwiftSyntaxMacrosGenericTestSupport
import Testing

/// `assertMacroExpansion` for Swift Testing.
///
/// The XCTest flavour from `SwiftSyntaxMacrosTestSupport` reports through `XCTFail`, which a
/// Swift Testing `@Test` only records as a warning ("An API was misused") — so a wrong expansion
/// used to pass. This routes the same checks to `Issue.record`, which fails the test.
func assertMacroExpansion(
  _ originalSource: String,
  expandedSource expectedExpandedSource: String,
  diagnostics: [DiagnosticSpec] = [],
  macros: [String: Macro.Type],
  applyFixIts: [String]? = nil,
  fixedSource expectedFixedSource: String? = nil,
  sourceLocation: Testing.SourceLocation = #_sourceLocation
) {
  SwiftSyntaxMacrosGenericTestSupport.assertMacroExpansion(
    originalSource,
    expandedSource: expectedExpandedSource,
    diagnostics: diagnostics,
    macroSpecs: macros.mapValues { MacroSpec(type: $0) },
    applyFixIts: applyFixIts,
    fixedSource: expectedFixedSource,
    failureHandler: { failure in
      Issue.record(Comment(rawValue: failure.message), sourceLocation: sourceLocation)
    }
  )
}
