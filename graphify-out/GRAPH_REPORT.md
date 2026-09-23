# Graph Report - MetalGraphics  (2026-09-24)

## Corpus Check
- 139 files · ~63,309 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 15 file(s) not represented in the graph (top: (none) 4, .plist 3, .resolved 2)

## Summary
- 1706 nodes · 3741 edges · 104 communities (92 shown, 12 thin omitted)
- Extraction: 92% EXTRACTED · 8% INFERRED · 0% AMBIGUOUS · INFERRED: 287 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `d0229746`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- TransitionElement
- Input
- Text
- Int
- BoundingBox2D
- DiagnosticsTests
- int2
- Animator
- Ray-Marching Shader
- SIMD2
- CodeGen
- .isBetween
- GlyphSDF.metal
- MathLib.swift
- UIAnimation
- IMView
- .expansion
- Alignment
- IMView
- BodyParser
- float2x2
- WindowState
- Graphics2D
- String
- View
- Drag
- ModifierSpec
- ViewRenderer
- UIContext
- SDF.metal
- .scan
- Sendable
- TransitionState
- Kind
- MyMTKView
- LayoutDemo
- float3
- HList
- Metal Math Helpers
- BoundingBox3D
- Rect
- compute2D
- StateProperty
- simd
- SceneData
- GraphicsGrid2D
- VList
- SDF.swift
- HStack
- VStack
- float4
- MetalViewRepresentable
- ExpandedFrame Element
- ListDemo
- Float
- Rectangle
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
- Compile-time state in RetainedModeUI
- Frame
- EmptyElement
- Square
- IMView
- MetalGraphicsLib
- .update
- EffectElement
- UIElement
- uchar4
- ConditionalDemo
- SingleChildElement
- Padding
- 9. Animation
- MouseOver
- StepIterator
- ViewItem
- Graphics2D.swift
- IMView
- Background
- Padding
- Event
- Line
- Input.swift
- IMGameView
- ShapeType2D
- GridCell
- .init
- .expansion

## God Nodes (most connected - your core abstractions)
1. `UIContext` - 96 edges
2. `UIElement` - 93 edges
3. `UIAnimation` - 69 edges
4. `Input` - 45 edges
5. `SIMD2` - 43 edges
6. `Graphics2D` - 37 edges
7. `CodeGen` - 36 edges
8. `Inset` - 35 edges
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

## Communities (104 total, 12 thin omitted)

### Community 0 - "TransitionElement"
Cohesion: 0.26
Nodes (5): Effects and transitions, Float, Void, TransitionElement, .currentState

### Community 1 - "Input"
Cohesion: 0.12
Nodes (12): Input, .mouseDown, .mouseMoved, .mousePressed, .mouseUp, Bool, Double, NSEvent (+4 more)

### Community 2 - "Text"
Cohesion: 0.06
Nodes (45): CGGlyph, CGPath, CoreText, CTFont, Hashable, FontManager, .atlasTexture, GlyphBakeParams (+37 more)

### Community 3 - "Int"
Cohesion: 0.17
Nodes (9): AnyIterator, Int, SparseSet, .count, .isEmpty, .storedKeys, .values, Bool (+1 more)

### Community 4 - "BoundingBox2D"
Cohesion: 0.17
Nodes (12): BoundingBox2D, .bottom, .bottomRight, .height, .left, .right, .top, .topLeft (+4 more)

### Community 5 - "DiagnosticsTests"
Cohesion: 0.06
Nodes (17): CompilerPlugin, ReactiveUIMacrosPlugin, Macro, AnimationMacroTests, Macro, ComponentMacroTests, component(), DiagnosticsTests (+9 more)

### Community 6 - "int2"
Cohesion: 0.06
Nodes (26): DispatchQueue, DispatchWorkItem, Foundation, benchmark(), Bool, Void, HittableGrid2D, HittableGridCell (+18 more)

### Community 7 - "Animator"
Cohesion: 0.09
Nodes (29): Apply, `withAnimation`, AnimatedProperty, color, fontSize, inset, keyframes, offset (+21 more)

### Community 8 - "Ray-Marching Shader"
Cohesion: 0.08
Nodes (29): Camera, fov, position, rotation, compute(), distanceToScene(), GridArgBuffer, GridItem (+21 more)

### Community 9 - "SIMD2"
Cohesion: 0.31
Nodes (8): Float, .packed, SIMD2, .packed, SIMD4, .packed, Float, UIAnimatable

### Community 10 - "CodeGen"
Cohesion: 0.12
Nodes (15): CodeGen, .armedHandlers, Dependents, RowsMode, full, insert, remove, Bool (+7 more)

### Community 12 - "GlyphSDF.metal"
Cohesion: 0.11
Nodes (28): bakeGlyphSDF(), GlyphBakeParams, emPerTexel, emTopLeft, origin, pathElementCount, size, subPathEnd (+20 more)

### Community 13 - "MathLib.swift"
Cohesion: 0.22
Nodes (17): dragDirection(), from1DTo3DArray(), from2DTo1DArray(), from3DTo1DArray(), fromPixelCoordToGridIndex(), fromWorldPositionToGridIndex(), lerp(), mix() (+9 more)

### Community 14 - "UIAnimation"
Cohesion: 0.11
Nodes (18): 1. The pieces, Text styling, UIAnimation, Background, ExpandedFrame, Frame, HStack, Padding (+10 more)

### Community 15 - "IMView"
Cohesion: 0.13
Nodes (16): ExpandedFrame, FlexFrame, IMView, Background, Float, float2, Frame, HStack (+8 more)

### Community 16 - ".expansion"
Cohesion: 0.09
Nodes (17): AccessorDeclSyntax, AccessorMacro, DeclSyntaxProtocol, DiagnosticMessage, DiagnosticSeverity, FixItMessage, MessageID, PeerMacro (+9 more)

### Community 17 - "Alignment"
Cohesion: 0.27
Nodes (8): Alignment, .offset, HorizontalAlignment, IMView, Float, float2, Self, VerticalAlignment

### Community 18 - "IMView"
Cohesion: 0.24
Nodes (10): ExpandedFrame, FlexFrame, Frame, IMView, Alignment, Axis, Float, float2 (+2 more)

### Community 19 - "BodyParser"
Cohesion: 0.16
Nodes (11): CodeBlockItemListSyntax, IfExprSyntax, BodyParser, Bool, ExprSyntax, FunctionCallExprSyntax, MemberBlockItemListSyntax, Set (+3 more)

### Community 22 - "WindowState"
Cohesion: 0.22
Nodes (8): Application, Global, Reload, Bool, CGPoint, CGSize, WindowState, ObservableObject

### Community 23 - "Graphics2D"
Cohesion: 0.14
Nodes (16): Circle, Glyph, Line, Graphics2D, .size, Float, float2, MTKView (+8 more)

### Community 24 - "String"
Cohesion: 0.20
Nodes (4): String, .uint32, UInt32, Naming

### Community 25 - "View"
Cohesion: 0.11
Nodes (20): .body, Bool, View, Background, ExpandedFrame, FlexFrame, HStack, .isSpacer (+12 more)

### Community 26 - "Drag"
Cohesion: 0.16
Nodes (7): CustomStringConvertible, Drag, .description, Float, float2, UInt32, Void

### Community 27 - "ModifierSpec"
Cohesion: 0.14
Nodes (18): ClosureExprSyntax, Owner, component, node, ArgCombine, float2, identity, labeled (+10 more)

### Community 28 - "ViewRenderer"
Cohesion: 0.15
Nodes (11): MetalView, .body, CGSize, Double, Float, float2, MTKView, ViewRenderer (+3 more)

### Community 29 - "UIContext"
Cohesion: 0.10
Nodes (15): Invalidation, Bool, float2, ObjectIdentifier, UInt8, Void, UIContext, .needsRender (+7 more)

### Community 30 - "SDF.metal"
Cohesion: 0.15
Nodes (10): dot2(), float2, sdBox(), sdBoxSquared(), sdCircle(), sdCircleSquared(), sdOrientedBox(), sdRoundedBox() (+2 more)

### Community 31 - ".scan"
Cohesion: 0.26
Nodes (8): DeclReferenceExprSyntax, MemberAccessExprSyntax, StateRewriter, ClosureExprSyntax, ExprSyntax, Set, SyntaxProtocol, SyntaxRewriter

### Community 32 - "Sendable"
Cohesion: 0.06
Nodes (35): Any, The runtime, Curve, easeIn, easeInOut, easeOut, keyframes, linear (+27 more)

### Community 33 - "TransitionState"
Cohesion: 0.25
Nodes (5): Equatable, Float, float2, TransitionState, UITransition

### Community 34 - "Kind"
Cohesion: 0.16
Nodes (18): Void, AnimationScope, BoundArg, BoundHandler, BranchIR, ChainLink, ElementIR, .innermost (+10 more)

### Community 35 - "MyMTKView"
Cohesion: 0.18
Nodes (7): Modifier, MyMTKView, .acceptsFirstResponder, Bool, NSEvent, UInt, MTKView

### Community 36 - "LayoutDemo"
Cohesion: 0.20
Nodes (8): LayoutDemo, .body, Alignment, Axis, Float, float2, HorizontalAlignment, VerticalAlignment

### Community 38 - "float3"
Cohesion: 0.18
Nodes (8): float3, .depth, .height, .width, .xy, Float, float2, int3

### Community 39 - "HList"
Cohesion: 0.43
Nodes (4): HStack, HList, T, Void

### Community 40 - "Metal Math Helpers"
Cohesion: 0.21
Nodes (9): cross2d(), float2, ndot(), remap(), rotation(), rotationX(), rotationY(), rotationZ() (+1 more)

### Community 41 - "BoundingBox3D"
Cohesion: 0.14
Nodes (13): BoundingBox3D, .back, .bottom, .bottomRightBack, .depth, .front, .height, .left (+5 more)

### Community 42 - "Rect"
Cohesion: 0.16
Nodes (10): Rect, .center, .height, .maxX, .maxY, .minX, .minY, .width (+2 more)

### Community 43 - "compute2D"
Cohesion: 0.17
Nodes (9): sdSegment(), compute2D(), constant, kernel, texture2d, uint2, write, from2DTo1DArray() (+1 more)

### Community 44 - "StateProperty"
Cohesion: 0.18
Nodes (11): PatternBindingSyntax, .states, .reactiveNames, .stateNames, StateProperty, AttributeSyntax, Bool, MemberBlockItemListSyntax (+3 more)

### Community 45 - "simd"
Cohesion: 0.09
Nodes (19): .inspectorView, Number2Field, .body, T, Number3Field, .body, SIMD3, T (+11 more)

### Community 46 - "SceneData"
Cohesion: 0.29
Nodes (7): DebugData, drawGrid, showFilledCells, SceneData, debug, time, windowSize

### Community 47 - "GraphicsGrid2D"
Cohesion: 0.17
Nodes (11): Int32, GPUDevice, MTLDevice, GraphicsGrid2D, GridArgBuffer, GridCell, Shape, Float (+3 more)

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

### Community 52 - "float4"
Cohesion: 0.15
Nodes (10): AnimatedItem, AnimationDemo, .body, Bool, Float, float4, .xyz, Double (+2 more)

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
Cohesion: 0.15
Nodes (10): Float, TextDemo, .body, .packed, Padding, Inset, .horizontal, .topLeft (+2 more)

### Community 76 - "Compile-time state in RetainedModeUI"
Cohesion: 0.15
Nodes (11): 2. What a component looks like, 3. What gets generated, 4. Rules that follow, 5. Collections are just `@State` arrays, 6. Composition, not helper methods, 8. How it lands on screen, Compile-time state in RetainedModeUI, Mutation carries the operation (+3 more)

### Community 77 - "Frame"
Cohesion: 0.39
Nodes (4): Frame, Alignment, float2, Void

### Community 78 - "EmptyElement"
Cohesion: 0.25
Nodes (3): EmptyElement, LeafElement, Spacer

### Community 79 - "Square"
Cohesion: 0.33
Nodes (4): Square, .bounds, Float, float2

### Community 80 - "IMView"
Cohesion: 0.23
Nodes (10): HStack, .size, IMView, Float, HorizontalAlignment, Self, VerticalAlignment, Void (+2 more)

### Community 81 - "MetalGraphicsLib"
Cohesion: 0.12
Nodes (11): App, Combine, ContentView, GPURayMarchingApp, .body, MTKView, TestViewRenderer, MetalGraphicsLib (+3 more)

### Community 82 - ".update"
Cohesion: 0.14
Nodes (6): 7. Diagnostics, Double, Frame, LayoutPass, float2, Void

### Community 83 - "EffectElement"
Cohesion: 0.17
Nodes (8): EffectElement, .hasEffect, .localEffect, EffectState, Bool, Float, float2, Void

### Community 84 - "UIElement"
Cohesion: 0.10
Nodes (16): MultiChildElement, .liveChildrenCount, float2, Void, Self, Bool, UIElement, .hasEffect (+8 more)

### Community 86 - "uchar4"
Cohesion: 0.25
Nodes (6): UInt8, uchar4, .a, .b, .g, .r

### Community 87 - "ConditionalDemo"
Cohesion: 0.39
Nodes (4): ConditionalDemo, .body, Bool, Float

### Community 88 - "SingleChildElement"
Cohesion: 0.27
Nodes (3): SingleChildElement, float2, Void

### Community 89 - "Padding"
Cohesion: 0.24
Nodes (6): IMView, Padding, Float, Self, Void, float2

### Community 91 - "9. Animation"
Cohesion: 0.27
Nodes (7): 9. Animation, Costs to know, Scopes, Sliding layout, Float, float2, Frame

### Community 92 - "MouseOver"
Cohesion: 0.35
Nodes (6): IMView, MouseOver, Bool, Float, Self, Void

### Community 93 - "StepIterator"
Cohesion: 0.27
Nodes (6): IteratorProtocol, StepIterator, StepSequence, Bool, Float, Sequence

### Community 94 - "ViewItem"
Cohesion: 0.27
Nodes (6): Background, IMView, Float, Self, Void, ViewItem

### Community 96 - "Graphics2D.swift"
Cohesion: 0.33
Nodes (6): DebugData, SceneData, ShapeArgBuffer, Bool, Int32, UInt64

### Community 98 - "IMView"
Cohesion: 0.39
Nodes (4): IMView, Spacer, Float, Void

### Community 99 - "Background"
Cohesion: 0.31
Nodes (3): Background, Float, float2

### Community 100 - "Padding"
Cohesion: 0.29
Nodes (3): Padding, Float, float2

### Community 101 - "Event"
Cohesion: 0.25
Nodes (6): CaseIterable, Repeat and keyframes, Event, Inspector, Navigation, Void

### Community 103 - "Line"
Cohesion: 0.33
Nodes (6): Line, color, depth, end, start, thickness

### Community 106 - "ShapeType2D"
Cohesion: 0.40
Nodes (5): ShapeType2D, Circle, Glyph, Line, Square

### Community 108 - "GridCell"
Cohesion: 0.67
Nodes (3): GridCell, count, startIndex

### Community 110 - ".expansion"
Cohesion: 0.20
Nodes (9): DeclGroupSyntax, ExtensionDeclSyntax, ExtensionMacro, MemberMacro, ComponentMacro, AttributeSyntax, DeclSyntax, TypeSyntax (+1 more)

## Knowledge Gaps
- **215 isolated node(s):** `conditional`, `list`, `text`, `layout`, `.id` (+210 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 524 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **12 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `String` connect `String` to `Input`, `Text`, `Int`, `DiagnosticsTests`, `int2`, `CodeGen`, `UIAnimation`, `IMView`, `.expansion`, `IMView`, `BodyParser`, `WindowState`, `Graphics2D`, `Drag`, `ModifierSpec`, `.scan`, `Kind`, `LayoutDemo`, `StateProperty`, `simd`, `HStack`, `VStack`, `float4`, `ExpandedFrame Element`, `ListDemo`, `Rectangle`, `main.swift`, `Demo`, `float4x4`, `FlexFrame`, `Inset`, `Frame`, `IMView`, `.update`, `EffectElement`, `SingleChildElement`, `Padding`, `MouseOver`, `ViewItem`, `IMView`, `Background`, `Padding`?**
  _High betweenness centrality (0.304) - this node is a cross-community bridge._
- **Why does `Int` connect `Int` to `Text`, `int2`, `Animator`, `.isBetween`, `MathLib.swift`, `IMView`, `BodyParser`, `Graphics2D`, `String`, `View`, `ModifierSpec`, `UIContext`, `Sendable`, `Kind`, `LayoutDemo`, `HList`, `GraphicsGrid2D`, `VList`, `float4`, `ListDemo`, `main.swift`, `Array`, `Inset`, `UIElement`, `ConditionalDemo`, `ViewItem`, `Event`?**
  _High betweenness centrality (0.158) - this node is a cross-community bridge._
- **Why does `UIContext` connect `UIContext` to `TransitionElement`, `Sendable`, `Int`, `int2`, `Animator`, `HList`, `simd`, `UIAnimation`, `VList`, `.update`, `EffectElement`, `float4`, `UIElement`, `SingleChildElement`, `ViewRenderer`?**
  _High betweenness centrality (0.086) - this node is a cross-community bridge._
- **Are the 5 inferred relationships involving `UIContext` (e.g. with `Effects and transitions` and `HittableGrid2D`) actually correct?**
  _`UIContext` has 5 INFERRED edges - model-reasoned connections that need verification._
- **Are the 4 inferred relationships involving `UIElement` (e.g. with `7. Diagnostics` and `.dropLeaving()`) actually correct?**
  _`UIElement` has 4 INFERRED edges - model-reasoned connections that need verification._
- **What connects `conditional`, `list`, `text` to the rest of the system?**
  _215 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Input` be split into smaller, more focused modules?**
  _Cohesion score 0.12333333333333334 - nodes in this community are weakly interconnected._