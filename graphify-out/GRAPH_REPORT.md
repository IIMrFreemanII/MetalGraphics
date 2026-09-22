# Graph Report - MetalGraphics  (2026-09-23)

## Corpus Check
- 126 files · ~43,632 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 15 file(s) not represented in the graph (top: (none) 4, .plist 3, .resolved 2)

## Summary
- 1396 nodes · 2918 edges · 91 communities (80 shown, 11 thin omitted)
- Extraction: 93% EXTRACTED · 7% INFERRED · 0% AMBIGUOUS · INFERRED: 210 edges (avg confidence: 0.84)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `3687ff7b`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- TextStyle
- Input
- FontManager
- Int
- BoundingBox2D
- Macro Plugin & Tests
- Utilities & Benchmarks
- Background
- Ray-Marching Shader
- Inset
- CodeGen
- String
- GlyphSDF.metal
- MathLib.swift
- .invalidate
- IMView
- .expansion
- Float
- IMView
- BodyParser
- simd
- UIElement
- WindowState
- Graphics2D
- IMView
- View
- Editor
- ModifierSpec
- ViewRenderer
- Invalidation
- SDF Shape Operators
- StateRewriter
- HittableView
- Axis
- Macro IR
- MouseOver
- LayoutDemo
- ListRows
- float3
- HList
- Metal Math Helpers
- HittableGrid2D
- Rect
- 2D Compute Kernel
- .expansion
- NumberField
- Shader Headers & Grid Cells
- GraphicsGrid2D
- VList
- SDF.swift
- HStack Element
- VStack Element
- Background
- MetalViewRepresentable
- ExpandedFrame Element
- ListDemo
- UIContext
- Rectangle
- GPU Circle Shape
- IM Axis
- GPU Glyph Shape
- Demo
- float4x4
- GPU Scene & Debug Data
- GPU Device
- GPU Line Shape
- GPU Square Shape
- Comparable Clamp
- Reactive Component Protocol
- Macro Package Manifest
- int2
- FlexFrame
- float4
- Compile-time state in RetainedModeUI
- Frame
- .setChild
- Graphics2D.swift
- ShapeType2D
- MetalKit
- Void
- SwiftUI
- IMView
- MetalGraphicsLib
- uchar4
- ConditionalDemo
- SingleChildElement
- Number3Field
- Number4Field

## God Nodes (most connected - your core abstractions)
1. `UIContext` - 63 edges
2. `UIElement` - 61 edges
3. `Input` - 45 edges
4. `Graphics2D` - 37 edges
5. `CodeGen` - 35 edges
6. `ViewRenderer` - 30 edges
7. `float4` - 28 edges
8. `Inset` - 26 edges
9. `IMView` - 25 edges
10. `HittableView` - 25 edges

## Surprising Connections (you probably didn't know these)
- `5. Collections are just `@State` arrays` --references--> `DemoItem`  [INFERRED]
  MetalGraphicsLib/docs/CompileTimeState.md → GPURayMarching/ListDemo.swift
- `1. The pieces` --references--> `ElementCatalog`  [INFERRED]
  MetalGraphicsLib/docs/CompileTimeState.md → ReactiveUIMacros/Sources/ReactiveUIMacrosPlugin/ElementCatalog.swift
- `7. Diagnostics` --references--> `ElementCatalog`  [INFERRED]
  MetalGraphicsLib/docs/CompileTimeState.md → ReactiveUIMacros/Sources/ReactiveUIMacrosPlugin/ElementCatalog.swift
- `The plain setter still works` --references--> `ListRows`  [INFERRED]
  MetalGraphicsLib/docs/CompileTimeState.md → MetalGraphicsLib/RetainedModeUI/Layout/ListRows.swift
- `ConditionalDemo` --calls--> `TextStyle`  [INFERRED]
  GPURayMarching/ConditionalDemo.swift → MetalGraphicsLib/Graphics/2D/Text/TextLayout.swift

## Import Cycles
- None detected.

## Communities (91 total, 11 thin omitted)

### Community 0 - "TextStyle"
Cohesion: 0.21
Nodes (10): layoutText(), measureText(), PlacedGlyph, float2, TextLayout, TextLine, TextStyle, float2 (+2 more)

### Community 1 - "Input"
Cohesion: 0.06
Nodes (24): CustomStringConvertible, GameController, GCKeyCode, Drag, .description, Input, .mouseDown, .mouseMoved (+16 more)

### Community 2 - "FontManager"
Cohesion: 0.09
Nodes (27): CGGlyph, CGPath, CoreText, CTFont, Hashable, FontManager, .atlasTexture, GlyphBakeParams (+19 more)

### Community 3 - "Int"
Cohesion: 0.09
Nodes (20): AnyIterator, Array, .byteCount, Element, Void, Int, Bool, ClosedRange (+12 more)

### Community 4 - "BoundingBox2D"
Cohesion: 0.05
Nodes (34): BoundingBox2D, .bottom, .bottomRight, .height, .left, .right, .top, .topLeft (+26 more)

### Community 5 - "Macro Plugin & Tests"
Cohesion: 0.07
Nodes (17): AccessorMacro, CompilerPlugin, Macro, PeerMacro, ReactiveUIMacrosPlugin, StateMacro, ComponentMacroTests, component() (+9 more)

### Community 6 - "Utilities & Benchmarks"
Cohesion: 0.09
Nodes (16): DispatchQueue, DispatchWorkItem, Foundation, benchmark(), Bool, Void, Debouncer, forEachGridCell() (+8 more)

### Community 7 - "Background"
Cohesion: 0.33
Nodes (6): Background, IMView, Self, SIMD2, SIMD4, Void

### Community 8 - "Ray-Marching Shader"
Cohesion: 0.08
Nodes (29): Camera, fov, position, rotation, compute(), distanceToScene(), GridArgBuffer, GridItem (+21 more)

### Community 9 - "Inset"
Cohesion: 0.10
Nodes (14): IMView, Padding, Self, SIMD2, Void, Padding, Padding, float2 (+6 more)

### Community 10 - "CodeGen"
Cohesion: 0.15
Nodes (14): CodeGen, .armedHandlers, RowsMode, full, insert, remove, DeclSyntax, Set (+6 more)

### Community 11 - "String"
Cohesion: 0.18
Nodes (4): String, .uint32, UInt32, Naming

### Community 12 - "GlyphSDF.metal"
Cohesion: 0.11
Nodes (28): bakeGlyphSDF(), GlyphBakeParams, emPerTexel, emTopLeft, origin, pathElementCount, size, subPathEnd (+20 more)

### Community 13 - "MathLib.swift"
Cohesion: 0.18
Nodes (14): int3, dragDirection(), from1DTo3DArray(), from3DTo1DArray(), fromWorldPositionToGridIndex(), lerp(), mix(), remap() (+6 more)

### Community 14 - ".invalidate"
Cohesion: 0.13
Nodes (13): Background, ExpandedFrame, Frame, HStack, Padding, Alignment, Axis, float2 (+5 more)

### Community 15 - "IMView"
Cohesion: 0.13
Nodes (14): ExpandedFrame, FlexFrame, IMView, Background, float2, Frame, HStack, Padding (+6 more)

### Community 16 - ".expansion"
Cohesion: 0.14
Nodes (13): AccessorDeclSyntax, DeclSyntaxProtocol, DiagnosticMessage, DiagnosticSeverity, FixItMessage, MessageID, MacroExpansionContext, ReactiveUIDiagnostic (+5 more)

### Community 17 - "Float"
Cohesion: 0.10
Nodes (18): IteratorProtocol, Float, .degrees, .isNegative, .radians, Bool, ClosedRange, Alignment (+10 more)

### Community 18 - "IMView"
Cohesion: 0.23
Nodes (10): ExpandedFrame, FlexFrame, Frame, IMView, Alignment, Axis, float2, Self (+2 more)

### Community 19 - "BodyParser"
Cohesion: 0.14
Nodes (13): CodeBlockItemListSyntax, IfExprSyntax, BodyParser, .states, Bool, ClosureExprSyntax, ExprSyntax, FunctionCallExprSyntax (+5 more)

### Community 21 - "UIElement"
Cohesion: 0.15
Nodes (5): Background, Frame, float2, UIElement, UIElementBuilder

### Community 22 - "WindowState"
Cohesion: 0.15
Nodes (13): CaseIterable, CGPoint, Application, Event, Inspector, Navigation, Global, Reload (+5 more)

### Community 23 - "Graphics2D"
Cohesion: 0.13
Nodes (15): Circle, Glyph, Line, Graphics2D, .size, float2, MTKView, MTLBuffer (+7 more)

### Community 24 - "IMView"
Cohesion: 0.21
Nodes (10): HStack, .size, IMView, HorizontalAlignment, Self, SIMD2, VerticalAlignment, Void (+2 more)

### Community 25 - "View"
Cohesion: 0.15
Nodes (13): Bool, View, Background, ExpandedFrame, FlexFrame, Frame, HStack, .isSpacer (+5 more)

### Community 26 - "Editor"
Cohesion: 0.22
Nodes (9): .body, Editor, .body, Inspector, .body, Navigation, .body, ToggleView (+1 more)

### Community 27 - "ModifierSpec"
Cohesion: 0.15
Nodes (16): Owner, component, node, ArgCombine, float2, identity, ArgSpec, Arity (+8 more)

### Community 28 - "ViewRenderer"
Cohesion: 0.16
Nodes (10): MetalView, .body, CGSize, Double, float2, MTKView, ViewRenderer, .navigationView (+2 more)

### Community 29 - "Invalidation"
Cohesion: 0.22
Nodes (8): 8. How it lands on screen, Invalidation, Frame, UInt8, Void, .needsRender, UIRenderableElement, OptionSet

### Community 30 - "SDF Shape Operators"
Cohesion: 0.15
Nodes (10): dot2(), float2, sdBoxSquared(), sdCircle(), sdCircleSquared(), sdOrientedBox(), sdRoundedBox(), sdRoundedBoxSquared() (+2 more)

### Community 31 - "StateRewriter"
Cohesion: 0.16
Nodes (10): DeclReferenceExprSyntax, MemberAccessExprSyntax, Bool, FunctionCallExprSyntax, StateRewriter, ClosureExprSyntax, ExprSyntax, Set (+2 more)

### Community 32 - "HittableView"
Cohesion: 0.15
Nodes (8): 4. Rules that follow, Bool, Void, HittableView, Bool, float2, SIMD2, Void

### Community 33 - "Axis"
Cohesion: 0.14
Nodes (12): Alignment, .offset, HorizontalAlignment, float2, Self, VerticalAlignment, Axis, .inverted (+4 more)

### Community 34 - "Macro IR"
Cohesion: 0.18
Nodes (15): BoundArg, BoundHandler, ChainLink, ElementIR, .innermost, .outermost, Kind, condition (+7 more)

### Community 35 - "MouseOver"
Cohesion: 0.21
Nodes (8): IMView, IMGameView, IMView, MouseOver, Bool, Self, SIMD2, Void

### Community 36 - "LayoutDemo"
Cohesion: 0.22
Nodes (7): LayoutDemo, .body, Alignment, Axis, float2, HorizontalAlignment, VerticalAlignment

### Community 37 - "ListRows"
Cohesion: 0.22
Nodes (6): 3. What gets generated, MultiChildElement, Void, ListRows, T, Void

### Community 38 - "float3"
Cohesion: 0.13
Nodes (11): matrix_double4x4, float3, .depth, .height, .width, .xy, float2, Double (+3 more)

### Community 39 - "HList"
Cohesion: 0.33
Nodes (5): HStack, HList, T, VerticalAlignment, Void

### Community 40 - "Metal Math Helpers"
Cohesion: 0.21
Nodes (9): cross2d(), float2, ndot(), remap(), rotation(), rotationX(), rotationY(), rotationZ() (+1 more)

### Community 41 - "HittableGrid2D"
Cohesion: 0.31
Nodes (5): HittableGrid2D, HittableGridCell, HoveredView, float2, ObjectIdentifier

### Community 42 - "Rect"
Cohesion: 0.17
Nodes (9): Rect, .center, .height, .maxX, .maxY, .minX, .minY, .width (+1 more)

### Community 43 - "2D Compute Kernel"
Cohesion: 0.17
Nodes (9): sdBox(), compute2D(), constant, kernel, texture2d, uint2, write, from2DTo1DArray() (+1 more)

### Community 44 - ".expansion"
Cohesion: 0.09
Nodes (20): DeclGroupSyntax, ExtensionDeclSyntax, ExtensionMacro, MemberMacro, PatternBindingSyntax, .reactiveNames, .stateNames, ComponentMacro (+12 more)

### Community 45 - "NumberField"
Cohesion: 0.21
Nodes (10): .inspectorView, Number2Field, .body, SIMD2, T, NumberField, .body, stringToSIMDScalar() (+2 more)

### Community 46 - "Shader Headers & Grid Cells"
Cohesion: 0.24
Nodes (7): metal_stdlib, GridCell, count, startIndex, Shape, index, shapeType

### Community 47 - "GraphicsGrid2D"
Cohesion: 0.21
Nodes (8): Int32, GraphicsGrid2D, GridArgBuffer, GridCell, Shape, float2, MTLBuffer, UInt64

### Community 48 - "VList"
Cohesion: 0.33
Nodes (5): HorizontalAlignment, T, Void, VList, VStack

### Community 49 - "SDF.swift"
Cohesion: 0.24
Nodes (13): clamp(), T, closestPointToSDBox(), pointInAABBox(), pointInAABBoxTopLeftOrigin(), sdBox(), sdBoxTopLeft(), sdCircle() (+5 more)

### Community 50 - "HStack Element"
Cohesion: 0.25
Nodes (5): HStack, .size, float2, SIMD2, VerticalAlignment

### Community 51 - "VStack Element"
Cohesion: 0.25
Nodes (5): float2, HorizontalAlignment, SIMD2, VStack, .size

### Community 52 - "Background"
Cohesion: 0.24
Nodes (4): Background, float2, SIMD2, SIMD4

### Community 53 - "MetalViewRepresentable"
Cohesion: 0.29
Nodes (6): Context, MetalViewRepresentable, MTKView, NSView, NSViewType, ViewRepresentable

### Community 54 - "ExpandedFrame Element"
Cohesion: 0.33
Nodes (4): ExpandedFrame, Alignment, Axis, float2

### Community 55 - "ListDemo"
Cohesion: 0.27
Nodes (7): DemoItem, ListDemo, .body, RowView, .body, Bool, Void

### Community 56 - "UIContext"
Cohesion: 0.22
Nodes (4): Bool, float2, ObjectIdentifier, UIContext

### Community 57 - "Rectangle"
Cohesion: 0.27
Nodes (4): Rectangle, float2, SIMD2, SIMD4

### Community 58 - "GPU Circle Shape"
Cohesion: 0.22
Nodes (9): Circle, color, depth, position, radius, GridArgBuffer, device, float2 (+1 more)

### Community 59 - "IM Axis"
Cohesion: 0.25
Nodes (6): Axis, .inverted, .size, IMView, float2, Self

### Community 60 - "GPU Glyph Shape"
Cohesion: 0.25
Nodes (8): Glyph, color, depth, fontSize, position, size, uvMax, uvMin

### Community 61 - "Demo"
Cohesion: 0.18
Nodes (12): Demo, conditional, .id, layout, list, text, .title, toggle (+4 more)

### Community 62 - "float4x4"
Cohesion: 0.22
Nodes (7): float3x3, float4x4, .formated, .identity, .upperLeft, modelFrom(), simd_float4

### Community 63 - "GPU Scene & Debug Data"
Cohesion: 0.29
Nodes (7): DebugData, drawGrid, showFilledCells, SceneData, debug, time, windowSize

### Community 65 - "GPU Line Shape"
Cohesion: 0.33
Nodes (6): Line, color, depth, end, start, thickness

### Community 66 - "GPU Square Shape"
Cohesion: 0.33
Nodes (6): Square, color, depth, position, rotation, size

### Community 67 - "Comparable Clamp"
Cohesion: 0.40
Nodes (3): Comparable, ClosedRange, Self

### Community 74 - "FlexFrame"
Cohesion: 0.36
Nodes (3): FlexFrame, Alignment, float2

### Community 75 - "float4"
Cohesion: 0.19
Nodes (7): TextDemo, .body, Bool, ToggleDemo, .body, float4, .xyz

### Community 76 - "Compile-time state in RetainedModeUI"
Cohesion: 0.25
Nodes (7): 1. The pieces, 2. What a component looks like, 5. Collections are just `@State` arrays, 6. Composition, not helper methods, Compile-time state in RetainedModeUI, Mutation carries the operation, The plain setter still works

### Community 77 - "Frame"
Cohesion: 0.39
Nodes (4): Frame, Alignment, float2, Void

### Community 78 - ".setChild"
Cohesion: 0.17
Nodes (4): EmptyElement, LeafElement, Void, Spacer

### Community 79 - "Graphics2D.swift"
Cohesion: 0.33
Nodes (6): DebugData, SceneData, ShapeArgBuffer, Bool, Int32, UInt64

### Community 80 - "ShapeType2D"
Cohesion: 0.29
Nodes (6): ShapeType2D, Circle, Glyph, Line, Square, Shape

### Community 81 - "MetalKit"
Cohesion: 0.18
Nodes (6): Combine, MTKView, TestViewRenderer, GPUDevice, MTLDevice, MetalKit

### Community 83 - "SwiftUI"
Cohesion: 0.25
Nodes (6): App, ContentView, GPURayMarchingApp, .body, Scene, SwiftUI

### Community 84 - "IMView"
Cohesion: 0.39
Nodes (4): IMView, Spacer, SIMD2, Void

### Community 86 - "uchar4"
Cohesion: 0.25
Nodes (6): UInt8, uchar4, .a, .b, .g, .r

### Community 87 - "ConditionalDemo"
Cohesion: 0.48
Nodes (3): ConditionalDemo, .body, Bool

### Community 89 - "Number3Field"
Cohesion: 0.40
Nodes (4): Number3Field, .body, SIMD3, T

### Community 90 - "Number4Field"
Cohesion: 0.40
Nodes (4): Number4Field, .body, SIMD4, T

## Knowledge Gaps
- **184 isolated node(s):** `conditional`, `list`, `toggle`, `text`, `layout` (+179 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 457 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **11 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `String` connect `String` to `TextStyle`, `Input`, `FontManager`, `Macro Plugin & Tests`, `Utilities & Benchmarks`, `Background`, `Inset`, `CodeGen`, `.invalidate`, `IMView`, `.expansion`, `Float`, `IMView`, `BodyParser`, `WindowState`, `Graphics2D`, `IMView`, `ModifierSpec`, `StateRewriter`, `Macro IR`, `MouseOver`, `LayoutDemo`, `ListRows`, `.expansion`, `NumberField`, `HStack Element`, `VStack Element`, `Background`, `ExpandedFrame Element`, `ListDemo`, `Rectangle`, `Demo`, `float4x4`, `FlexFrame`, `float4`, `Frame`, `Void`, `IMView`, `SingleChildElement`, `Number3Field`, `Number4Field`?**
  _High betweenness centrality (0.355) - this node is a cross-community bridge._
- **Why does `Float` connect `Float` to `TextStyle`, `Input`, `FontManager`, `Int`, `BoundingBox2D`, `Utilities & Benchmarks`, `Background`, `Inset`, `MathLib.swift`, `.invalidate`, `IMView`, `IMView`, `UIElement`, `Graphics2D`, `IMView`, `ViewRenderer`, `HittableView`, `Axis`, `MouseOver`, `LayoutDemo`, `float3`, `HList`, `HittableGrid2D`, `Rect`, `GraphicsGrid2D`, `VList`, `SDF.swift`, `HStack Element`, `VStack Element`, `Background`, `ListDemo`, `Rectangle`, `IM Axis`, `float4x4`, `FlexFrame`, `float4`, `ShapeType2D`, `IMView`, `ConditionalDemo`?**
  _High betweenness centrality (0.317) - this node is a cross-community bridge._
- **Why does `Int` connect `Int` to `FontManager`, `LayoutDemo`, `ListRows`, `Utilities & Benchmarks`, `HList`, `float4`, `String`, `MathLib.swift`, `GraphicsGrid2D`, `IMView`, `VList`, `Graphics2D`, `WindowState`, `ListDemo`, `ConditionalDemo`, `View`, `ModifierSpec`?**
  _High betweenness centrality (0.081) - this node is a cross-community bridge._
- **Are the 2 inferred relationships involving `UIContext` (e.g. with `HittableGrid2D` and `int2`) actually correct?**
  _`UIContext` has 2 INFERRED edges - model-reasoned connections that need verification._
- **What connects `conditional`, `list`, `toggle` to the rest of the system?**
  _184 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Input` be split into smaller, more focused modules?**
  _Cohesion score 0.05639097744360902 - nodes in this community are weakly interconnected._
- **Should `FontManager` be split into smaller, more focused modules?**
  _Cohesion score 0.09446693657219973 - nodes in this community are weakly interconnected._