# Graph Report - MetalGraphics  (2026-09-24)

## Corpus Check
- 139 files · ~65,875 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 15 file(s) not represented in the graph (top: (none) 4, .plist 3, .resolved 2)

## Summary
- 1711 nodes · 3768 edges · 105 communities (91 shown, 14 thin omitted)
- Extraction: 92% EXTRACTED · 8% INFERRED · 0% AMBIGUOUS · INFERRED: 290 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `22ff373e`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- HittableView
- Input
- Text
- SparseSet
- BoundingBox2D
- DiagnosticsTests
- int2
- Animator
- Ray-Marching Shader
- SIMD2
- CodeGen
- Int
- GlyphSDF.metal
- MathLib.swift
- UIAnimation
- IMView
- SwiftSyntax
- Alignment
- IMView
- BodyParser
- float2x2
- ListRows
- WindowState
- Graphics2D
- Naming
- View
- Drag
- String
- ViewRenderer
- UIContext
- SDF.metal
- .expansion
- Sendable
- TransitionState
- Kind
- MyMTKView
- LayoutDemo
- simd
- float3
- HList
- Metal Math Helpers
- BoundingBox3D
- Rect
- compute2D
- .expansion
- NumberField
- SceneData
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
- EffectState
- main.swift
- Axis
- GPU Glyph Shape
- Demo
- float4x4
- Array
- GPU Device
- Shaders/Shaders.metal
- Circle
- Comparable Clamp
- Reactive Component Protocol
- Macro Package Manifest
- Line
- FlexFrame
- Inset
- 1. The pieces
- Frame
- EmptyElement
- Square
- IMView
- MetalGraphicsLib
- .update
- EffectElement
- UIElement
- float4
- uchar4
- ConditionalDemo
- SingleChildElement
- Padding
- Number2Field
- Number3Field
- MouseOver
- StepIterator
- Background
- MetalKit
- IMView
- Background
- Line
- Input.swift
- IMGameView
- ShapeType2D
- GridCell
- .init

## God Nodes (most connected - your core abstractions)
1. `UIContext` - 96 edges
2. `UIElement` - 94 edges
3. `UIAnimation` - 69 edges
4. `Input` - 45 edges
5. `SIMD2` - 43 edges
6. `Inset` - 39 edges
7. `Graphics2D` - 37 edges
8. `CodeGen` - 37 edges
9. `float4` - 32 edges
10. `ViewRenderer` - 30 edges

## Surprising Connections (you probably didn't know these)
- `5. Collections are just `@State` arrays` --references--> `DemoItem`  [INFERRED]
  MetalGraphicsLib/docs/CompileTimeState.md → GPURayMarching/ListDemo.swift
- `8. How it lands on screen` --references--> `TestViewRenderer`  [INFERRED]
  MetalGraphicsLib/docs/CompileTimeState.md → GPURayMarching/TestViewRenderer.swift
- `Driving GPURayMarching` --references--> `MyMTKView`  [INFERRED]
  .claude/skills/drive-app/SKILL.md → MetalGraphicsLib/MyMTKView.swift
- `1. The pieces` --references--> `ElementCatalog`  [INFERRED]
  MetalGraphicsLib/docs/CompileTimeState.md → ReactiveUIMacros/Sources/ReactiveUIMacrosPlugin/ElementCatalog.swift
- `7. Diagnostics` --references--> `ElementCatalog`  [INFERRED]
  MetalGraphicsLib/docs/CompileTimeState.md → ReactiveUIMacros/Sources/ReactiveUIMacrosPlugin/ElementCatalog.swift

## Import Cycles
- None detected.

## Communities (105 total, 14 thin omitted)

### Community 0 - "HittableView"
Cohesion: 0.18
Nodes (5): HittableView, Bool, Float, float2, Void

### Community 1 - "Input"
Cohesion: 0.12
Nodes (12): Input, .mouseDown, .mouseMoved, .mousePressed, .mouseUp, Bool, Double, NSEvent (+4 more)

### Community 2 - "Text"
Cohesion: 0.05
Nodes (48): CGGlyph, CGPath, CoreText, CTFont, Float, TextDemo, .body, Hashable (+40 more)

### Community 3 - "SparseSet"
Cohesion: 0.20
Nodes (8): AnyIterator, SparseSet, .count, .isEmpty, .storedKeys, .values, Bool, Element

### Community 4 - "BoundingBox2D"
Cohesion: 0.17
Nodes (12): BoundingBox2D, .bottom, .bottomRight, .height, .left, .right, .top, .topLeft (+4 more)

### Community 5 - "DiagnosticsTests"
Cohesion: 0.05
Nodes (20): AccessorMacro, CompilerPlugin, PeerMacro, ReactiveUIMacrosPlugin, Macro, StateMacro, AnimationMacroTests, Macro (+12 more)

### Community 6 - "int2"
Cohesion: 0.06
Nodes (26): DispatchQueue, DispatchWorkItem, Foundation, benchmark(), Bool, Void, HittableGrid2D, HittableGridCell (+18 more)

### Community 7 - "Animator"
Cohesion: 0.06
Nodes (38): Apply, 9. Animation, Costs to know, Repeat and keyframes, Scopes, The runtime, `withAnimation`, AnimatedProperty (+30 more)

### Community 8 - "Ray-Marching Shader"
Cohesion: 0.08
Nodes (29): Camera, fov, position, rotation, compute(), distanceToScene(), GridArgBuffer, GridItem (+21 more)

### Community 9 - "SIMD2"
Cohesion: 0.31
Nodes (8): Float, .packed, SIMD2, .packed, SIMD4, .packed, Float, UIAnimatable

### Community 10 - "CodeGen"
Cohesion: 0.14
Nodes (15): CodeGen, .armedHandlers, Dependents, RowsMode, full, insert, remove, Bool (+7 more)

### Community 11 - "Int"
Cohesion: 0.27
Nodes (3): Int, Bool, ClosedRange

### Community 12 - "GlyphSDF.metal"
Cohesion: 0.11
Nodes (28): bakeGlyphSDF(), GlyphBakeParams, emPerTexel, emTopLeft, origin, pathElementCount, size, subPathEnd (+20 more)

### Community 13 - "MathLib.swift"
Cohesion: 0.22
Nodes (17): dragDirection(), from1DTo3DArray(), from2DTo1DArray(), from3DTo1DArray(), fromPixelCoordToGridIndex(), fromWorldPositionToGridIndex(), lerp(), mix() (+9 more)

### Community 14 - "UIAnimation"
Cohesion: 0.13
Nodes (17): Text styling, UIAnimation, Background, ExpandedFrame, Frame, HStack, Padding, Alignment (+9 more)

### Community 15 - "IMView"
Cohesion: 0.12
Nodes (17): ExpandedFrame, FlexFrame, IMView, Background, Float, float2, Frame, HStack (+9 more)

### Community 16 - "SwiftSyntax"
Cohesion: 0.15
Nodes (8): DiagnosticMessage, DiagnosticSeverity, FixItMessage, MessageID, ReactiveUIDiagnostic, ReactiveUIFixIt, SwiftDiagnostics, SwiftSyntax

### Community 17 - "Alignment"
Cohesion: 0.27
Nodes (8): Alignment, .offset, HorizontalAlignment, IMView, Float, float2, Self, VerticalAlignment

### Community 18 - "IMView"
Cohesion: 0.24
Nodes (10): ExpandedFrame, FlexFrame, Frame, IMView, Alignment, Axis, Float, float2 (+2 more)

### Community 19 - "BodyParser"
Cohesion: 0.16
Nodes (12): CodeBlockItemListSyntax, IfExprSyntax, BodyParser, Bool, ClosureExprSyntax, ExprSyntax, FunctionCallExprSyntax, MemberBlockItemListSyntax (+4 more)

### Community 21 - "ListRows"
Cohesion: 0.44
Nodes (3): ListRows, T, Void

### Community 22 - "WindowState"
Cohesion: 0.15
Nodes (13): CaseIterable, Application, Event, Inspector, Navigation, Global, Reload, Bool (+5 more)

### Community 23 - "Graphics2D"
Cohesion: 0.14
Nodes (16): Circle, Glyph, Line, Graphics2D, .size, Float, float2, MTKView (+8 more)

### Community 25 - "View"
Cohesion: 0.12
Nodes (19): Bool, View, Background, ExpandedFrame, FlexFrame, HStack, .isSpacer, MouseOver (+11 more)

### Community 26 - "Drag"
Cohesion: 0.16
Nodes (7): CustomStringConvertible, Drag, .description, Float, float2, UInt32, Void

### Community 27 - "String"
Cohesion: 0.15
Nodes (20): String, .uint32, UInt32, Owner, component, node, ArgCombine, float2 (+12 more)

### Community 28 - "ViewRenderer"
Cohesion: 0.15
Nodes (11): MetalView, .body, CGSize, Double, Float, float2, MTKView, ViewRenderer (+3 more)

### Community 29 - "UIContext"
Cohesion: 0.11
Nodes (15): Effects and transitions, Float, Void, TransitionElement, .currentState, Invalidation, Bool, float2 (+7 more)

### Community 30 - "SDF.metal"
Cohesion: 0.15
Nodes (10): dot2(), float2, sdBox(), sdBoxSquared(), sdCircle(), sdCircleSquared(), sdOrientedBox(), sdRoundedBox() (+2 more)

### Community 31 - ".expansion"
Cohesion: 0.14
Nodes (12): AccessorDeclSyntax, DeclReferenceExprSyntax, DeclSyntaxProtocol, MemberAccessExprSyntax, StateRewriter, ClosureExprSyntax, ExprSyntax, Set (+4 more)

### Community 32 - "Sendable"
Cohesion: 0.06
Nodes (34): Any, Curve, easeIn, easeInOut, easeOut, keyframes, linear, spring (+26 more)

### Community 33 - "TransitionState"
Cohesion: 0.21
Nodes (5): Equatable, Float, float2, TransitionState, UITransition

### Community 34 - "Kind"
Cohesion: 0.15
Nodes (18): Void, AnimationScope, BoundArg, BoundHandler, BranchIR, ChainLink, ElementIR, .innermost (+10 more)

### Community 35 - "MyMTKView"
Cohesion: 0.18
Nodes (7): Modifier, MyMTKView, .acceptsFirstResponder, Bool, NSEvent, UInt, MTKView

### Community 36 - "LayoutDemo"
Cohesion: 0.12
Nodes (11): LayoutDemo, .body, Alignment, Axis, Float, float2, HorizontalAlignment, VerticalAlignment (+3 more)

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

### Community 43 - "compute2D"
Cohesion: 0.17
Nodes (9): sdSegment(), compute2D(), constant, kernel, texture2d, uint2, write, from2DTo1DArray() (+1 more)

### Community 44 - ".expansion"
Cohesion: 0.09
Nodes (22): DeclGroupSyntax, ExtensionDeclSyntax, ExtensionMacro, MemberMacro, PatternBindingSyntax, .states, TypeSyntax, .arrayStates (+14 more)

### Community 45 - "NumberField"
Cohesion: 0.24
Nodes (8): Number4Field, .body, T, NumberField, .body, stringToSIMDScalar(), Bool, T

### Community 46 - "SceneData"
Cohesion: 0.29
Nodes (7): DebugData, drawGrid, showFilledCells, SceneData, debug, time, windowSize

### Community 47 - "GraphicsGrid2D"
Cohesion: 0.21
Nodes (9): Int32, GraphicsGrid2D, GridArgBuffer, GridCell, Shape, Float, float2, MTLBuffer (+1 more)

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
Nodes (5): AnimatedItem, AnimationDemo, .body, Bool, Float

### Community 53 - "MetalViewRepresentable"
Cohesion: 0.29
Nodes (6): Context, MetalViewRepresentable, MTKView, NSView, NSViewType, ViewRepresentable

### Community 54 - "ExpandedFrame Element"
Cohesion: 0.33
Nodes (4): ExpandedFrame, Alignment, Axis, float2

### Community 55 - "ListDemo"
Cohesion: 0.25
Nodes (9): ChipView, DemoItem, ListDemo, .body, RowView, Bool, Float, HorizontalAlignment (+1 more)

### Community 56 - "Float"
Cohesion: 0.28
Nodes (6): Float, .degrees, .isNegative, .radians, Bool, ClosedRange

### Community 57 - "EffectState"
Cohesion: 0.31
Nodes (3): .localEffect, EffectState, Void

### Community 58 - "main.swift"
Cohesion: 0.10
Nodes (34): AppKit, ArraySlice, CGEventFlags, CGEventType, CGKeyCode, CGMouseButton, CGRect, CGWindowID (+26 more)

### Community 59 - "Axis"
Cohesion: 0.25
Nodes (7): Axis, .inverted, .size, IMView, Float, float2, Self

### Community 60 - "GPU Glyph Shape"
Cohesion: 0.25
Nodes (8): Glyph, color, depth, fontSize, position, size, uvMax, uvMin

### Community 61 - "Demo"
Cohesion: 0.17
Nodes (12): Demo, animation, conditional, .id, layout, list, text, .title (+4 more)

### Community 62 - "float4x4"
Cohesion: 0.15
Nodes (11): matrix_double4x4, float3x3, Float, float4x4, .formated, .identity, .upperLeft, Bool (+3 more)

### Community 63 - "Array"
Cohesion: 0.33
Nodes (4): Array, .byteCount, Element, Void

### Community 65 - "Shaders/Shaders.metal"
Cohesion: 0.11
Nodes (19): metal_stdlib, Circle, color, depth, position, radius, GridArgBuffer, device (+11 more)

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

### Community 75 - "Inset"
Cohesion: 0.11
Nodes (13): .body, .body, .packed, Padding, Padding, Float, float2, Inset (+5 more)

### Community 76 - "1. The pieces"
Cohesion: 0.14
Nodes (12): 1. The pieces, 2. What a component looks like, 3. What gets generated, 4. Rules that follow, 5. Collections are just `@State` arrays, 6. Composition, not helper methods, 8. How it lands on screen, Compile-time state in RetainedModeUI (+4 more)

### Community 77 - "Frame"
Cohesion: 0.39
Nodes (4): Frame, Alignment, float2, Void

### Community 78 - "EmptyElement"
Cohesion: 0.22
Nodes (3): EmptyElement, LeafElement, Spacer

### Community 79 - "Square"
Cohesion: 0.33
Nodes (4): Square, .bounds, Float, float2

### Community 80 - "IMView"
Cohesion: 0.23
Nodes (10): HStack, .size, IMView, Float, HorizontalAlignment, Self, VerticalAlignment, Void (+2 more)

### Community 81 - "MetalGraphicsLib"
Cohesion: 0.13
Nodes (12): App, Combine, ContentView, .body, GPURayMarchingApp, .body, MTKView, TestViewRenderer (+4 more)

### Community 82 - ".update"
Cohesion: 0.29
Nodes (4): Double, Frame, LayoutPass, float2

### Community 83 - "EffectElement"
Cohesion: 0.31
Nodes (5): EffectElement, .hasEffect, Bool, Float, float2

### Community 84 - "UIElement"
Cohesion: 0.09
Nodes (15): 7. Diagnostics, Sliding layout, MultiChildElement, .liveChildrenCount, float2, Void, Void, Self (+7 more)

### Community 85 - "float4"
Cohesion: 0.25
Nodes (5): float4, .xyz, Double, Float, Background

### Community 86 - "uchar4"
Cohesion: 0.25
Nodes (6): UInt8, uchar4, .a, .b, .g, .r

### Community 87 - "ConditionalDemo"
Cohesion: 0.43
Nodes (4): ConditionalDemo, .body, Bool, Float

### Community 89 - "Padding"
Cohesion: 0.31
Nodes (5): IMView, Padding, Float, Self, Void

### Community 90 - "Number2Field"
Cohesion: 0.40
Nodes (4): .inspectorView, Number2Field, .body, T

### Community 91 - "Number3Field"
Cohesion: 0.40
Nodes (4): Number3Field, .body, SIMD3, T

### Community 92 - "MouseOver"
Cohesion: 0.35
Nodes (6): IMView, MouseOver, Bool, Float, Self, Void

### Community 93 - "StepIterator"
Cohesion: 0.27
Nodes (6): IteratorProtocol, StepIterator, StepSequence, Bool, Float, Sequence

### Community 94 - "Background"
Cohesion: 0.35
Nodes (5): Background, IMView, Float, Self, Void

### Community 96 - "MetalKit"
Cohesion: 0.18
Nodes (9): GPUDevice, MTLDevice, DebugData, SceneData, ShapeArgBuffer, Bool, Int32, UInt64 (+1 more)

### Community 98 - "IMView"
Cohesion: 0.39
Nodes (4): IMView, Spacer, Float, Void

### Community 99 - "Background"
Cohesion: 0.31
Nodes (3): Background, Float, float2

### Community 103 - "Line"
Cohesion: 0.33
Nodes (6): Line, color, depth, end, start, thickness

### Community 106 - "ShapeType2D"
Cohesion: 0.40
Nodes (5): ShapeType2D, Circle, Glyph, Line, Square

### Community 108 - "GridCell"
Cohesion: 0.67
Nodes (3): GridCell, count, startIndex

## Knowledge Gaps
- **214 isolated node(s):** `conditional`, `list`, `text`, `layout`, `.id` (+209 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 525 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **14 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `String` connect `String` to `Input`, `Text`, `DiagnosticsTests`, `int2`, `CodeGen`, `Int`, `UIAnimation`, `IMView`, `SwiftSyntax`, `IMView`, `BodyParser`, `WindowState`, `Graphics2D`, `Naming`, `Drag`, `.expansion`, `Kind`, `LayoutDemo`, `.expansion`, `NumberField`, `HStack`, `VStack`, `AnimationDemo`, `ExpandedFrame Element`, `ListDemo`, `main.swift`, `Demo`, `float4x4`, `FlexFrame`, `Inset`, `Frame`, `IMView`, `EffectElement`, `UIElement`, `ConditionalDemo`, `SingleChildElement`, `Padding`, `Number2Field`, `Number3Field`, `MouseOver`, `Background`, `IMView`, `Background`?**
  _High betweenness centrality (0.307) - this node is a cross-community bridge._
- **Why does `Int` connect `Int` to `Text`, `SparseSet`, `int2`, `Animator`, `MathLib.swift`, `IMView`, `BodyParser`, `ListRows`, `WindowState`, `Graphics2D`, `Naming`, `View`, `String`, `UIContext`, `Sendable`, `Kind`, `LayoutDemo`, `HList`, `GraphicsGrid2D`, `VList`, `AnimationDemo`, `ListDemo`, `main.swift`, `Array`, `UIElement`, `ConditionalDemo`?**
  _High betweenness centrality (0.149) - this node is a cross-community bridge._
- **Why does `Input` connect `Input` to `Sendable`, `HittableView`, `MyMTKView`, `int2`, `Input.swift`, `.scrollWheel`, `1. The pieces`, `.update`, `Drag`, `String`, `ViewRenderer`?**
  _High betweenness centrality (0.091) - this node is a cross-community bridge._
- **Are the 5 inferred relationships involving `UIContext` (e.g. with `Effects and transitions` and `HittableGrid2D`) actually correct?**
  _`UIContext` has 5 INFERRED edges - model-reasoned connections that need verification._
- **Are the 4 inferred relationships involving `UIElement` (e.g. with `7. Diagnostics` and `.dropLeaving()`) actually correct?**
  _`UIElement` has 4 INFERRED edges - model-reasoned connections that need verification._
- **What connects `conditional`, `list`, `text` to the rest of the system?**
  _214 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Input` be split into smaller, more focused modules?**
  _Cohesion score 0.12333333333333334 - nodes in this community are weakly interconnected._