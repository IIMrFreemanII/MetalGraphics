# Graph Report - MetalGraphics  (2026-09-24)

## Corpus Check
- 140 files · ~63,112 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 15 file(s) not represented in the graph (top: (none) 4, .plist 3, .resolved 2)

## Summary
- 1714 nodes · 3759 edges · 116 communities (102 shown, 14 thin omitted)
- Extraction: 92% EXTRACTED · 8% INFERRED · 0% AMBIGUOUS · INFERRED: 296 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `d0229746`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- Text
- Input
- float2
- Int
- BoundingBox2D
- DiagnosticsTests
- Foundation
- Animator
- Ray-Marching Shader
- SIMD2
- CodeGen
- .isBetween
- GlyphSDF.metal
- MathLib.swift
- .invalidate
- IMView
- .expansion
- Alignment
- IMView
- BodyParser
- float2x2
- UIAnimation
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
- ListRows
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
- AnimationDemo
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
- TextDemo
- 1. The pieces
- Frame
- EmptyElement
- Square
- IMView
- SwiftUI
- UIElement
- EffectElement
- MultiChildElement
- MetalGraphicsLib
- uchar4
- ConditionalDemo
- SingleChildElement
- Inset
- HittableView
- .offset
- MouseOver
- StepIterator
- Background
- int2
- MetalKit
- TextStyle
- IMView
- Background
- Padding
- AnimationGroup
- FontManager
- Line
- Input.swift
- IMGameView
- ShapeType2D
- GridCell
- .init
- .expansion
- SDFFont
- float4
- RowView
- 5. Collections are just `@State` arrays
- .render

## God Nodes (most connected - your core abstractions)
1. `UIContext` - 97 edges
2. `UIElement` - 94 edges
3. `UIAnimation` - 70 edges
4. `Input` - 45 edges
5. `SIMD2` - 43 edges
6. `Graphics2D` - 37 edges
7. `CodeGen` - 36 edges
8. `Inset` - 35 edges
9. `float4` - 33 edges
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

## Communities (116 total, 14 thin omitted)

### Community 0 - "Text"
Cohesion: 0.14
Nodes (10): float2, Self, Text, .displayedColor, .displayedFontSize, .fontScale, .resolvedColor, .resolvedFace (+2 more)

### Community 1 - "Input"
Cohesion: 0.12
Nodes (12): Input, .mouseDown, .mouseMoved, .mousePressed, .mouseUp, Bool, Double, NSEvent (+4 more)

### Community 2 - "float2"
Cohesion: 0.16
Nodes (15): CGPath, GlyphBakeParams, GlyphMetrics, PathElement, PendingBake, SubPath, UInt32, UInt8 (+7 more)

### Community 3 - "Int"
Cohesion: 0.17
Nodes (9): AnyIterator, Int, SparseSet, .count, .isEmpty, .storedKeys, .values, Bool (+1 more)

### Community 4 - "BoundingBox2D"
Cohesion: 0.17
Nodes (12): BoundingBox2D, .bottom, .bottomRight, .height, .left, .right, .top, .topLeft (+4 more)

### Community 5 - "DiagnosticsTests"
Cohesion: 0.06
Nodes (17): CompilerPlugin, ReactiveUIMacrosPlugin, Macro, AnimationMacroTests, Macro, ComponentMacroTests, component(), DiagnosticsTests (+9 more)

### Community 6 - "Foundation"
Cohesion: 0.09
Nodes (17): DispatchQueue, DispatchWorkItem, Foundation, benchmark(), Bool, Void, Debouncer, forEachGridCell() (+9 more)

### Community 7 - "Animator"
Cohesion: 0.12
Nodes (23): Apply, AnimatedProperty, color, fontSize, inset, keyframes, offset, opacity (+15 more)

### Community 8 - "Ray-Marching Shader"
Cohesion: 0.08
Nodes (29): Camera, fov, position, rotation, compute(), distanceToScene(), GridArgBuffer, GridItem (+21 more)

### Community 9 - "SIMD2"
Cohesion: 0.31
Nodes (8): Float, .packed, SIMD2, .packed, SIMD4, .packed, Float, UIAnimatable

### Community 10 - "CodeGen"
Cohesion: 0.13
Nodes (15): CodeGen, .armedHandlers, Dependents, RowsMode, full, insert, remove, Bool (+7 more)

### Community 12 - "GlyphSDF.metal"
Cohesion: 0.11
Nodes (28): bakeGlyphSDF(), GlyphBakeParams, emPerTexel, emTopLeft, origin, pathElementCount, size, subPathEnd (+20 more)

### Community 13 - "MathLib.swift"
Cohesion: 0.22
Nodes (17): dragDirection(), from1DTo3DArray(), from2DTo1DArray(), from3DTo1DArray(), fromPixelCoordToGridIndex(), fromWorldPositionToGridIndex(), lerp(), mix() (+9 more)

### Community 14 - ".invalidate"
Cohesion: 0.12
Nodes (14): Background, ExpandedFrame, Frame, HStack, Padding, Alignment, Axis, Float (+6 more)

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

### Community 21 - "UIAnimation"
Cohesion: 0.16
Nodes (12): Curve, easeIn, easeInOut, easeOut, keyframes, linear, spring, Bool (+4 more)

### Community 22 - "WindowState"
Cohesion: 0.15
Nodes (13): CaseIterable, Application, Event, Inspector, Navigation, Global, Reload, Bool (+5 more)

### Community 23 - "Graphics2D"
Cohesion: 0.14
Nodes (16): Circle, Glyph, Line, Graphics2D, .size, Float, float2, MTKView (+8 more)

### Community 24 - "String"
Cohesion: 0.21
Nodes (4): String, .uint32, UInt32, Naming

### Community 25 - "View"
Cohesion: 0.11
Nodes (20): Bool, View, Background, ExpandedFrame, FlexFrame, Frame, HStack, .isSpacer (+12 more)

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
Cohesion: 0.12
Nodes (13): Invalidation, Bool, Double, float2, Frame, ObjectIdentifier, UInt8, Void (+5 more)

### Community 30 - "SDF.metal"
Cohesion: 0.15
Nodes (10): dot2(), float2, sdBox(), sdBoxSquared(), sdCircle(), sdCircleSquared(), sdOrientedBox(), sdRoundedBox() (+2 more)

### Community 31 - ".scan"
Cohesion: 0.26
Nodes (8): DeclReferenceExprSyntax, MemberAccessExprSyntax, StateRewriter, ClosureExprSyntax, ExprSyntax, Set, SyntaxProtocol, SyntaxRewriter

### Community 32 - "Sendable"
Cohesion: 0.09
Nodes (25): Any, KeyframeElement, KeyframeSegment, Float, float2, Self, V, UIKeyframe (+17 more)

### Community 33 - "TransitionState"
Cohesion: 0.14
Nodes (10): Equatable, Effects and transitions, Float, Void, TransitionElement, .currentState, Float, float2 (+2 more)

### Community 34 - "Kind"
Cohesion: 0.16
Nodes (18): Void, AnimationScope, BoundArg, BoundHandler, BranchIR, ChainLink, ElementIR, .innermost (+10 more)

### Community 35 - "MyMTKView"
Cohesion: 0.18
Nodes (7): Modifier, MyMTKView, .acceptsFirstResponder, Bool, NSEvent, UInt, MTKView

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
Cohesion: 0.10
Nodes (15): .inspectorView, Number2Field, .body, T, Number3Field, .body, SIMD3, T (+7 more)

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
Cohesion: 0.24
Nodes (6): AnimatedItem, AnimationDemo, .body, Bool, Float, Identifiable

### Community 53 - "MetalViewRepresentable"
Cohesion: 0.29
Nodes (6): Context, MetalViewRepresentable, MTKView, NSView, NSViewType, ViewRepresentable

### Community 54 - "ExpandedFrame Element"
Cohesion: 0.33
Nodes (4): ExpandedFrame, Alignment, Axis, float2

### Community 55 - "ListDemo"
Cohesion: 0.35
Nodes (4): DemoItem, ListDemo, .body, Float

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
Cohesion: 0.14
Nodes (15): Demo, animation, conditional, .id, layout, list, text, .title (+7 more)

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

### Community 75 - "TextDemo"
Cohesion: 0.53
Nodes (3): Float, TextDemo, .body

### Community 76 - "1. The pieces"
Cohesion: 0.18
Nodes (9): 1. The pieces, 2. What a component looks like, 3. What gets generated, 4. Rules that follow, 6. Composition, not helper methods, 8. How it lands on screen, Compile-time state in RetainedModeUI, Bool (+1 more)

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

### Community 81 - "SwiftUI"
Cohesion: 0.12
Nodes (13): App, Combine, ContentView, .body, GPURayMarchingApp, .body, MTKView, TestViewRenderer (+5 more)

### Community 82 - "UIElement"
Cohesion: 0.12
Nodes (9): 7. Diagnostics, Bool, float2, Void, UIElement, .hasEffect, .localEffect, .transitionOnSpine (+1 more)

### Community 83 - "EffectElement"
Cohesion: 0.20
Nodes (7): EffectElement, .hasEffect, .localEffect, EffectState, Bool, Float, float2

### Community 84 - "MultiChildElement"
Cohesion: 0.22
Nodes (5): Sliding layout, MultiChildElement, .liveChildrenCount, float2, Void

### Community 86 - "uchar4"
Cohesion: 0.29
Nodes (6): UInt8, uchar4, .a, .b, .g, .r

### Community 87 - "ConditionalDemo"
Cohesion: 0.39
Nodes (4): ConditionalDemo, .body, Bool, Float

### Community 88 - "SingleChildElement"
Cohesion: 0.29
Nodes (3): SingleChildElement, float2, Void

### Community 89 - "Inset"
Cohesion: 0.13
Nodes (13): IMView, Padding, Float, Self, Void, .packed, Padding, Inset (+5 more)

### Community 90 - "HittableView"
Cohesion: 0.15
Nodes (11): HittableGrid2D, HittableGridCell, HoveredView, Float, float2, ObjectIdentifier, HittableView, Bool (+3 more)

### Community 91 - ".offset"
Cohesion: 0.29
Nodes (4): Scopes, Float, float2, Frame

### Community 92 - "MouseOver"
Cohesion: 0.35
Nodes (6): IMView, MouseOver, Bool, Float, Self, Void

### Community 93 - "StepIterator"
Cohesion: 0.27
Nodes (6): IteratorProtocol, StepIterator, StepSequence, Bool, Float, Sequence

### Community 94 - "Background"
Cohesion: 0.35
Nodes (5): Background, IMView, Float, Self, Void

### Community 95 - "int2"
Cohesion: 0.40
Nodes (3): int2, float2, from1DTo2DArray()

### Community 96 - "MetalKit"
Cohesion: 0.18
Nodes (9): GPUDevice, MTLDevice, DebugData, SceneData, ShapeArgBuffer, Bool, Int32, UInt64 (+1 more)

### Community 97 - "TextStyle"
Cohesion: 0.42
Nodes (9): CoreText, layoutText(), measureText(), PlacedGlyph, Float, float2, TextLayout, TextLine (+1 more)

### Community 98 - "IMView"
Cohesion: 0.39
Nodes (4): IMView, Spacer, Float, Void

### Community 99 - "Background"
Cohesion: 0.31
Nodes (3): Background, Float, float2

### Community 100 - "Padding"
Cohesion: 0.29
Nodes (3): Padding, Float, float2

### Community 101 - "AnimationGroup"
Cohesion: 0.21
Nodes (10): 9. Animation, Costs to know, Repeat and keyframes, The runtime, `withAnimation`, AnimationGroup, Void, UITransaction (+2 more)

### Community 102 - "FontManager"
Cohesion: 0.22
Nodes (9): CGGlyph, Hashable, FontManager, .atlasTexture, GlyphKey, SDFAtlas, MTLComputePipelineState, MTLDevice (+1 more)

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

### Community 111 - "SDFFont"
Cohesion: 0.31
Nodes (6): CTFont, Text styling, SDFFont, Float, Float, TextFont

### Community 112 - "float4"
Cohesion: 0.22
Nodes (5): float4, .xyz, Double, Float, Background

### Community 113 - "RowView"
Cohesion: 0.50
Nodes (4): RowView, .body, Bool, Void

### Community 114 - "5. Collections are just `@State` arrays"
Cohesion: 0.67
Nodes (3): 5. Collections are just `@State` arrays, Mutation carries the operation, The plain setter still works

## Knowledge Gaps
- **220 isolated node(s):** `conditional`, `list`, `toggle`, `text`, `layout` (+215 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 529 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **14 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `String` connect `String` to `Text`, `Input`, `float2`, `Int`, `DiagnosticsTests`, `Foundation`, `CodeGen`, `.invalidate`, `IMView`, `.expansion`, `IMView`, `BodyParser`, `WindowState`, `Graphics2D`, `Drag`, `ModifierSpec`, `.scan`, `Kind`, `LayoutDemo`, `StateProperty`, `simd`, `HStack`, `VStack`, `AnimationDemo`, `ExpandedFrame Element`, `ListDemo`, `Rectangle`, `main.swift`, `Demo`, `float4x4`, `FlexFrame`, `TextDemo`, `Frame`, `IMView`, `SwiftUI`, `UIElement`, `EffectElement`, `MultiChildElement`, `SingleChildElement`, `Inset`, `MouseOver`, `Background`, `TextStyle`, `IMView`, `Background`, `Padding`, `FontManager`, `SDFFont`?**
  _High betweenness centrality (0.321) - this node is a cross-community bridge._
- **Why does `Int` connect `Int` to `Foundation`, `Animator`, `.isBetween`, `MathLib.swift`, `IMView`, `BodyParser`, `UIAnimation`, `WindowState`, `Graphics2D`, `String`, `View`, `ModifierSpec`, `UIContext`, `Kind`, `LayoutDemo`, `ListRows`, `HList`, `GraphicsGrid2D`, `VList`, `AnimationDemo`, `ListDemo`, `main.swift`, `Array`, `TextDemo`, `MultiChildElement`, `ConditionalDemo`, `int2`, `FontManager`?**
  _High betweenness centrality (0.140) - this node is a cross-community bridge._
- **Why does `Input` connect `Input` to `Sendable`, `Drag`, `MyMTKView`, `Input.swift`, `.scrollWheel`, `1. The pieces`, `String`, `HittableView`, `ViewRenderer`, `UIContext`?**
  _High betweenness centrality (0.086) - this node is a cross-community bridge._
- **Are the 5 inferred relationships involving `UIContext` (e.g. with `Effects and transitions` and `HittableGrid2D`) actually correct?**
  _`UIContext` has 5 INFERRED edges - model-reasoned connections that need verification._
- **Are the 4 inferred relationships involving `UIElement` (e.g. with `7. Diagnostics` and `.dropLeaving()`) actually correct?**
  _`UIElement` has 4 INFERRED edges - model-reasoned connections that need verification._
- **What connects `conditional`, `list`, `toggle` to the rest of the system?**
  _220 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Text` be split into smaller, more focused modules?**
  _Cohesion score 0.13725490196078433 - nodes in this community are weakly interconnected._