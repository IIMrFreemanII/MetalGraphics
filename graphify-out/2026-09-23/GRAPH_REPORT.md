# Graph Report - MetalGraphics  (2026-09-23)

## Corpus Check
- 136 files · ~54,571 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 15 file(s) not represented in the graph (top: (none) 4, .plist 3, .resolved 2)

## Summary
- 1586 nodes · 3409 edges · 88 communities (80 shown, 8 thin omitted)
- Extraction: 92% EXTRACTED · 8% INFERRED · 0% AMBIGUOUS · INFERRED: 265 edges (avg confidence: 0.84)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `d0229746`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- TextStyle
- Input
- FontManager
- Int
- BoundingBox2D
- SwiftSyntaxMacros
- Foundation
- Animator
- Ray-Marching Shader
- Inset
- CodeGen
- Naming
- GlyphSDF.metal
- MathLib.swift
- UIContext
- IMView
- SwiftSyntax
- Alignment
- SIMD2
- BodyParser
- simd
- UIAnimation
- WindowState
- Graphics2D
- String
- View
- Drag
- ModifierSpec
- ViewRenderer
- .update
- SDF Shape Operators
- StateRewriter
- HittableView
- TransitionState
- Kind
- MyMTKView
- LayoutDemo
- ListRows
- float3
- HList
- Metal Math Helpers
- BoundingBox3D
- Rect
- 2D Compute Kernel
- StateProperty
- NumberField
- Shaders/Shaders.metal
- GraphicsGrid2D
- VList
- SDF.swift
- HStack
- VStack
- AnimationDemo
- MetalViewRepresentable
- ExpandedFrame Element
- ListDemo
- Float
- Rectangle
- Circle
- Axis
- GPU Glyph Shape
- Demo
- float4x4
- Array
- GPU Device
- Line
- Circle
- Comparable Clamp
- Reactive Component Protocol
- Macro Package Manifest
- Line
- FlexFrame
- TextDemo
- Compile-time state in RetainedModeUI
- Frame
- EmptyElement
- Square
- MetalKit
- UIElement
- Number2Field
- MetalGraphicsLib
- float4
- ConditionalDemo
- SingleChildElement
- Number3Field

## God Nodes (most connected - your core abstractions)
1. `UIContext` - 86 edges
2. `UIElement` - 84 edges
3. `UIAnimation` - 47 edges
4. `Input` - 45 edges
5. `SIMD2` - 43 edges
6. `Graphics2D` - 37 edges
7. `CodeGen` - 36 edges
8. `Inset` - 35 edges
9. `float4` - 30 edges
10. `ViewRenderer` - 30 edges

## Surprising Connections (you probably didn't know these)
- `5. Collections are just `@State` arrays` --references--> `DemoItem`  [INFERRED]
  MetalGraphicsLib/docs/CompileTimeState.md → GPURayMarching/ListDemo.swift
- `8. How it lands on screen` --references--> `TestViewRenderer`  [INFERRED]
  MetalGraphicsLib/docs/CompileTimeState.md → GPURayMarching/TestViewRenderer.swift
- `1. The pieces` --references--> `ElementCatalog`  [INFERRED]
  MetalGraphicsLib/docs/CompileTimeState.md → ReactiveUIMacros/Sources/ReactiveUIMacrosPlugin/ElementCatalog.swift
- `7. Diagnostics` --references--> `ElementCatalog`  [INFERRED]
  MetalGraphicsLib/docs/CompileTimeState.md → ReactiveUIMacros/Sources/ReactiveUIMacrosPlugin/ElementCatalog.swift
- `Scopes` --references--> `ElementCatalog`  [INFERRED]
  MetalGraphicsLib/docs/CompileTimeState.md → ReactiveUIMacros/Sources/ReactiveUIMacrosPlugin/ElementCatalog.swift

## Import Cycles
- None detected.

## Communities (88 total, 8 thin omitted)

### Community 0 - "TextStyle"
Cohesion: 0.19
Nodes (13): layoutText(), measureText(), PlacedGlyph, Float, float2, TextLayout, TextLine, TextStyle (+5 more)

### Community 1 - "Input"
Cohesion: 0.12
Nodes (12): GCKeyCode, Input, .mouseDown, .mouseMoved, .mousePressed, .mouseUp, Bool, Double (+4 more)

### Community 2 - "FontManager"
Cohesion: 0.09
Nodes (28): CGGlyph, CGPath, CoreText, CTFont, Hashable, FontManager, .atlasTexture, GlyphBakeParams (+20 more)

### Community 3 - "Int"
Cohesion: 0.13
Nodes (13): AnyIterator, Int, Bool, ClosedRange, from1DTo2DArray(), from2DTo1DArray(), SparseSet, .count (+5 more)

### Community 4 - "BoundingBox2D"
Cohesion: 0.17
Nodes (12): BoundingBox2D, .bottom, .bottomRight, .height, .left, .right, .top, .topLeft (+4 more)

### Community 5 - "SwiftSyntaxMacros"
Cohesion: 0.06
Nodes (20): AccessorMacro, CompilerPlugin, PeerMacro, ReactiveUIMacrosPlugin, Macro, StateMacro, AnimationMacroTests, Macro (+12 more)

### Community 6 - "Foundation"
Cohesion: 0.09
Nodes (17): DispatchQueue, DispatchWorkItem, Foundation, benchmark(), Bool, Void, Debouncer, forEachGridCell() (+9 more)

### Community 7 - "Animator"
Cohesion: 0.13
Nodes (21): Apply, AnimatedProperty, color, inset, offset, opacity, size, spacing (+13 more)

### Community 8 - "Ray-Marching Shader"
Cohesion: 0.08
Nodes (29): Camera, fov, position, rotation, compute(), distanceToScene(), GridArgBuffer, GridItem (+21 more)

### Community 9 - "Inset"
Cohesion: 0.06
Nodes (29): Equatable, IMView, Padding, Float, Self, Void, Double, Float (+21 more)

### Community 10 - "CodeGen"
Cohesion: 0.15
Nodes (15): CodeGen, .armedHandlers, Dependents, RowsMode, full, insert, remove, DeclSyntax (+7 more)

### Community 11 - "Naming"
Cohesion: 0.09
Nodes (14): AccessorDeclSyntax, DeclGroupSyntax, DeclSyntaxProtocol, ExtensionDeclSyntax, ExtensionMacro, MemberMacro, ComponentMacro, AttributeSyntax (+6 more)

### Community 12 - "GlyphSDF.metal"
Cohesion: 0.11
Nodes (28): bakeGlyphSDF(), GlyphBakeParams, emPerTexel, emTopLeft, origin, pathElementCount, size, subPathEnd (+20 more)

### Community 13 - "MathLib.swift"
Cohesion: 0.24
Nodes (16): dragDirection(), from1DTo3DArray(), from3DTo1DArray(), fromPixelCoordToGridIndex(), fromWorldPositionToGridIndex(), lerp(), mix(), normalize() (+8 more)

### Community 14 - "UIContext"
Cohesion: 0.10
Nodes (17): float2, ObjectIdentifier, UIContext, Background, ExpandedFrame, Frame, HStack, Padding (+9 more)

### Community 15 - "IMView"
Cohesion: 0.12
Nodes (16): ExpandedFrame, FlexFrame, IMView, Background, Float, float2, Frame, HStack (+8 more)

### Community 16 - "SwiftSyntax"
Cohesion: 0.15
Nodes (8): DiagnosticMessage, DiagnosticSeverity, FixItMessage, MessageID, ReactiveUIDiagnostic, ReactiveUIFixIt, SwiftDiagnostics, SwiftSyntax

### Community 17 - "Alignment"
Cohesion: 0.27
Nodes (8): Alignment, .offset, HorizontalAlignment, IMView, Float, float2, Self, VerticalAlignment

### Community 18 - "SIMD2"
Cohesion: 0.06
Nodes (39): IMView, Background, IMView, Float, Self, Void, ExpandedFrame, FlexFrame (+31 more)

### Community 19 - "BodyParser"
Cohesion: 0.16
Nodes (12): CodeBlockItemListSyntax, IfExprSyntax, BodyParser, Bool, ClosureExprSyntax, ExprSyntax, FunctionCallExprSyntax, MemberBlockItemListSyntax (+4 more)

### Community 20 - "simd"
Cohesion: 0.18
Nodes (3): float2x2, Float, simd

### Community 21 - "UIAnimation"
Cohesion: 0.18
Nodes (9): 1. The pieces, Bool, Float, UIAnimation, UITransaction, withAnimation(), Self, V (+1 more)

### Community 22 - "WindowState"
Cohesion: 0.15
Nodes (13): CaseIterable, CGPoint, Application, Event, Inspector, Navigation, Global, Reload (+5 more)

### Community 23 - "Graphics2D"
Cohesion: 0.06
Nodes (37): Circle, Glyph, Line, 9. Animation, Costs to know, Effects and transitions, Scopes, The runtime (+29 more)

### Community 24 - "String"
Cohesion: 0.22
Nodes (5): String, .uint32, UInt32, Bool, FunctionCallExprSyntax

### Community 25 - "View"
Cohesion: 0.12
Nodes (19): Bool, View, Background, ExpandedFrame, FlexFrame, HStack, .isSpacer, MouseOver (+11 more)

### Community 26 - "Drag"
Cohesion: 0.14
Nodes (8): CustomStringConvertible, GameController, Drag, .description, Float, float2, UInt32, Void

### Community 27 - "ModifierSpec"
Cohesion: 0.17
Nodes (16): Owner, component, node, ArgCombine, float2, identity, ArgSpec, Arity (+8 more)

### Community 28 - "ViewRenderer"
Cohesion: 0.16
Nodes (11): MetalView, .body, CGSize, Double, Float, float2, MTKView, ViewRenderer (+3 more)

### Community 29 - ".update"
Cohesion: 0.13
Nodes (10): Invalidation, Bool, Double, Frame, UInt8, Void, .needsRender, float2 (+2 more)

### Community 30 - "SDF Shape Operators"
Cohesion: 0.15
Nodes (10): dot2(), float2, sdBoxSquared(), sdCircle(), sdCircleSquared(), sdOrientedBox(), sdRoundedBox(), sdRoundedBoxSquared() (+2 more)

### Community 31 - "StateRewriter"
Cohesion: 0.26
Nodes (8): DeclReferenceExprSyntax, MemberAccessExprSyntax, StateRewriter, ClosureExprSyntax, ExprSyntax, Set, SyntaxProtocol, SyntaxRewriter

### Community 32 - "HittableView"
Cohesion: 0.24
Nodes (5): HittableView, Bool, Float, float2, Void

### Community 33 - "TransitionState"
Cohesion: 0.06
Nodes (28): Float, Void, TransitionElement, .currentState, Curve, easeIn, easeInOut, easeOut (+20 more)

### Community 34 - "Kind"
Cohesion: 0.19
Nodes (16): AnimationScope, BoundArg, BoundHandler, ChainLink, ElementIR, .innermost, .outermost, Kind (+8 more)

### Community 35 - "MyMTKView"
Cohesion: 0.20
Nodes (5): MyMTKView, .acceptsFirstResponder, Bool, NSEvent, MTKView

### Community 36 - "LayoutDemo"
Cohesion: 0.20
Nodes (8): LayoutDemo, .body, Alignment, Axis, Float, float2, HorizontalAlignment, VerticalAlignment

### Community 37 - "ListRows"
Cohesion: 0.44
Nodes (3): ListRows, T, Void

### Community 38 - "float3"
Cohesion: 0.18
Nodes (8): float3, .depth, .height, .width, .xy, Float, float2, int3

### Community 39 - "HList"
Cohesion: 0.29
Nodes (6): HStack, HList, Float, T, VerticalAlignment, Void

### Community 40 - "Metal Math Helpers"
Cohesion: 0.21
Nodes (9): cross2d(), float2, ndot(), remap(), rotation(), rotationX(), rotationY(), rotationZ() (+1 more)

### Community 41 - "BoundingBox3D"
Cohesion: 0.15
Nodes (13): BoundingBox3D, .back, .bottom, .bottomRightBack, .depth, .front, .height, .left (+5 more)

### Community 42 - "Rect"
Cohesion: 0.16
Nodes (10): Rect, .center, .height, .maxX, .maxY, .minX, .minY, .width (+2 more)

### Community 43 - "2D Compute Kernel"
Cohesion: 0.17
Nodes (9): sdBox(), compute2D(), constant, kernel, texture2d, uint2, write, from2DTo1DArray() (+1 more)

### Community 44 - "StateProperty"
Cohesion: 0.14
Nodes (13): PatternBindingSyntax, .states, TypeSyntax, .arrayStates, .reactiveNames, .stateNames, StateProperty, AttributeSyntax (+5 more)

### Community 45 - "NumberField"
Cohesion: 0.24
Nodes (8): Number4Field, .body, T, NumberField, .body, stringToSIMDScalar(), Bool, T

### Community 46 - "Shaders/Shaders.metal"
Cohesion: 0.14
Nodes (14): metal_stdlib, DebugData, drawGrid, showFilledCells, GridCell, count, startIndex, SceneData (+6 more)

### Community 47 - "GraphicsGrid2D"
Cohesion: 0.06
Nodes (30): Int32, IteratorProtocol, GPUDevice, MTLDevice, GraphicsGrid2D, GridArgBuffer, GridCell, Shape (+22 more)

### Community 48 - "VList"
Cohesion: 0.29
Nodes (6): Float, HorizontalAlignment, T, Void, VList, VStack

### Community 49 - "SDF.swift"
Cohesion: 0.33
Nodes (12): closestPointToSDBox(), pointInAABBox(), pointInAABBoxTopLeftOrigin(), sdBox(), sdBoxTopLeft(), sdCircle(), sdfNormal(), sdRoundBox() (+4 more)

### Community 50 - "HStack"
Cohesion: 0.27
Nodes (5): HStack, .size, Float, float2, VerticalAlignment

### Community 51 - "VStack"
Cohesion: 0.27
Nodes (5): Float, float2, HorizontalAlignment, VStack, .size

### Community 52 - "AnimationDemo"
Cohesion: 0.33
Nodes (6): AnimatedItem, AnimationDemo, .body, Bool, Float, Identifiable

### Community 53 - "MetalViewRepresentable"
Cohesion: 0.29
Nodes (6): Context, MetalViewRepresentable, MTKView, NSView, NSViewType, ViewRepresentable

### Community 54 - "ExpandedFrame Element"
Cohesion: 0.33
Nodes (4): ExpandedFrame, Alignment, Axis, float2

### Community 55 - "ListDemo"
Cohesion: 0.24
Nodes (8): DemoItem, ListDemo, .body, RowView, .body, Bool, Float, Void

### Community 56 - "Float"
Cohesion: 0.28
Nodes (6): Float, .degrees, .isNegative, .radians, Bool, ClosedRange

### Community 57 - "Rectangle"
Cohesion: 0.31
Nodes (3): Rectangle, Float, float2

### Community 58 - "Circle"
Cohesion: 0.40
Nodes (5): Circle, color, depth, position, radius

### Community 59 - "Axis"
Cohesion: 0.25
Nodes (7): Axis, .inverted, .size, IMView, Float, float2, Self

### Community 60 - "GPU Glyph Shape"
Cohesion: 0.25
Nodes (8): Glyph, color, depth, fontSize, position, size, uvMax, uvMin

### Community 61 - "Demo"
Cohesion: 0.14
Nodes (15): Demo, animation, conditional, .id, layout, list, text, .title (+7 more)

### Community 62 - "float4x4"
Cohesion: 0.15
Nodes (11): matrix_double4x4, float3x3, Float, float4x4, .formated, .identity, .upperLeft, Bool (+3 more)

### Community 63 - "Array"
Cohesion: 0.33
Nodes (4): Array, .byteCount, Element, Void

### Community 65 - "Line"
Cohesion: 0.12
Nodes (16): GridArgBuffer, Line, color, depth, end, start, thickness, device (+8 more)

### Community 66 - "Circle"
Cohesion: 0.33
Nodes (4): Circle, .bounds, Float, float2

### Community 67 - "Comparable Clamp"
Cohesion: 0.40
Nodes (3): Comparable, ClosedRange, Self

### Community 73 - "Line"
Cohesion: 0.33
Nodes (4): Line, .bounds, Float, float2

### Community 74 - "FlexFrame"
Cohesion: 0.26
Nodes (6): clamp(), T, FlexFrame, Alignment, Float, float2

### Community 75 - "TextDemo"
Cohesion: 0.70
Nodes (3): Float, TextDemo, .body

### Community 76 - "Compile-time state in RetainedModeUI"
Cohesion: 0.15
Nodes (11): 2. What a component looks like, 3. What gets generated, 4. Rules that follow, 5. Collections are just `@State` arrays, 6. Composition, not helper methods, 8. How it lands on screen, Compile-time state in RetainedModeUI, Mutation carries the operation (+3 more)

### Community 77 - "Frame"
Cohesion: 0.39
Nodes (4): Frame, Alignment, float2, Void

### Community 78 - "EmptyElement"
Cohesion: 0.22
Nodes (3): EmptyElement, LeafElement, Spacer

### Community 79 - "Square"
Cohesion: 0.33
Nodes (4): Square, .bounds, Float, float2

### Community 81 - "MetalKit"
Cohesion: 0.12
Nodes (11): App, Combine, ContentView, .body, GPURayMarchingApp, .body, MTKView, TestViewRenderer (+3 more)

### Community 82 - "UIElement"
Cohesion: 0.11
Nodes (9): 7. Diagnostics, MultiChildElement, .liveChildrenCount, Void, Void, Void, UIElement, .transitionOnSpine (+1 more)

### Community 83 - "Number2Field"
Cohesion: 0.40
Nodes (4): .inspectorView, Number2Field, .body, T

### Community 86 - "float4"
Cohesion: 0.15
Nodes (9): float4, .xyz, UInt8, uchar4, .a, .b, .g, .r (+1 more)

### Community 87 - "ConditionalDemo"
Cohesion: 0.39
Nodes (4): ConditionalDemo, .body, Bool, Float

### Community 89 - "Number3Field"
Cohesion: 0.40
Nodes (4): Number3Field, .body, SIMD3, T

## Knowledge Gaps
- **204 isolated node(s):** `conditional`, `list`, `toggle`, `text`, `layout` (+199 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 497 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **8 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `String` connect `String` to `TextStyle`, `Input`, `FontManager`, `SwiftSyntaxMacros`, `Foundation`, `Inset`, `CodeGen`, `Naming`, `UIContext`, `IMView`, `SwiftSyntax`, `SIMD2`, `BodyParser`, `WindowState`, `Graphics2D`, `Drag`, `ModifierSpec`, `StateRewriter`, `Kind`, `LayoutDemo`, `StateProperty`, `NumberField`, `HStack`, `VStack`, `AnimationDemo`, `ExpandedFrame Element`, `ListDemo`, `Rectangle`, `Demo`, `float4x4`, `FlexFrame`, `Frame`, `UIElement`, `Number2Field`, `SingleChildElement`, `Number3Field`?**
  _High betweenness centrality (0.327) - this node is a cross-community bridge._
- **Why does `Int` connect `Int` to `FontManager`, `Foundation`, `Animator`, `Naming`, `MathLib.swift`, `UIContext`, `IMView`, `SIMD2`, `BodyParser`, `WindowState`, `Graphics2D`, `View`, `ModifierSpec`, `.update`, `Kind`, `LayoutDemo`, `ListRows`, `HList`, `GraphicsGrid2D`, `VList`, `AnimationDemo`, `ListDemo`, `Array`, `TextDemo`, `UIElement`, `ConditionalDemo`?**
  _High betweenness centrality (0.163) - this node is a cross-community bridge._
- **Why does `UIElement` connect `UIElement` to `Animator`, `Inset`, `simd`, `UIAnimation`, `Graphics2D`, `.update`, `HittableView`, `TransitionState`, `LayoutDemo`, `ListRows`, `HList`, `VList`, `HStack`, `VStack`, `AnimationDemo`, `ExpandedFrame Element`, `ListDemo`, `Rectangle`, `Demo`, `TextDemo`, `Compile-time state in RetainedModeUI`, `Frame`, `EmptyElement`, `float4`, `ConditionalDemo`, `SingleChildElement`?**
  _High betweenness centrality (0.100) - this node is a cross-community bridge._
- **Are the 4 inferred relationships involving `UIContext` (e.g. with `Effects and transitions` and `HittableGrid2D`) actually correct?**
  _`UIContext` has 4 INFERRED edges - model-reasoned connections that need verification._
- **Are the 4 inferred relationships involving `UIElement` (e.g. with `7. Diagnostics` and `.dropLeaving()`) actually correct?**
  _`UIElement` has 4 INFERRED edges - model-reasoned connections that need verification._
- **What connects `conditional`, `list`, `toggle` to the rest of the system?**
  _204 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Input` be split into smaller, more focused modules?**
  _Cohesion score 0.12333333333333334 - nodes in this community are weakly interconnected._