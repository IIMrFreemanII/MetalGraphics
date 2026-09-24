# Graph Report - MetalGraphics  (2026-09-24)

## Corpus Check
- 165 files · ~92,447 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 15 file(s) not represented in the graph (top: (none) 4, .plist 3, .resolved 2)

## Summary
- 2206 nodes · 5040 edges · 118 communities (110 shown, 8 thin omitted)
- Extraction: 92% EXTRACTED · 8% INFERRED · 0% AMBIGUOUS · INFERRED: 388 edges (avg confidence: 0.84)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `c9f68c10`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- HittableView
- Input
- Text
- SparseSet
- BoundingBox2D
- DiagnosticsTests
- Hittable
- AnimatedProperty
- Ray-Marching Shader
- SIMD2
- CodeGen
- Int
- GlyphSDF.metal
- MathLib.swift
- UIContext
- IMView
- ReactiveUIDiagnostic
- Alignment
- IMView
- BodyParser
- VectorShape
- SDFPathBuilder
- WindowState
- Graphics2D
- String
- View
- Drag
- Arity
- ViewRenderer
- .update
- SDF.metal
- .expansion
- Sendable
- TransitionState
- Kind
- MyMTKView
- LayoutDemo
- VectorBaker
- SVGParser
- ListRows
- Metal Math Helpers
- BoundingBox3D
- bakeVectorSDF
- compute2D
- .expansion
- simd
- SceneData
- GraphicsGrid2D
- VList
- PathBuilder
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
- float3
- Array
- GPU Device
- Shaders/Shaders.metal
- .drawData
- Comparable Clamp
- UIElementWrapping
- Macro Package Manifest
- Line
- SVGScanner
- Inset
- TransitionElement
- Frame
- EmptyElement
- Square
- IMView
- MetalKit
- Image
- EffectElement
- UIElement
- float4
- uchar4
- ConditionalDemo
- SingleChildElement
- Path
- Float
- SVGIcon
- MouseOver
- StepIterator
- Background
- VectorItem
- Graphics2D.swift
- StateProperty
- IMView
- Background
- VectorCanvas
- ImageManager
- VectorItem
- BitmapTexture
- Input.swift
- ImageQuad
- ShapeType2D
- Alignment
- .texture
- SVGPathCommand
- VectorSegment
- Curve
- Padding
- Axis
- AppKit
- int2
- Circle
- .animation

## God Nodes (most connected - your core abstractions)
1. `UIContext` - 131 edges
2. `UIElement` - 99 edges
3. `UIAnimation` - 92 edges
4. `SIMD2` - 57 edges
5. `float4` - 53 edges
6. `Input` - 51 edges
7. `VectorShape` - 48 edges
8. `Graphics2D` - 46 edges
9. `Inset` - 41 edges
10. `simd` - 38 edges

## Surprising Connections (you probably didn't know these)
- `5. Collections are just `@State` arrays` --references--> `DemoItem`  [INFERRED]
  MetalGraphicsLib/docs/CompileTimeState.md → GPURayMarching/ListDemo.swift
- `Driving GPURayMarching` --references--> `MyMTKView`  [INFERRED]
  .claude/skills/drive-app/SKILL.md → MetalGraphicsLib/MyMTKView.swift
- `1. The pieces` --references--> `ElementCatalog`  [INFERRED]
  MetalGraphicsLib/docs/CompileTimeState.md → ReactiveUIMacros/Sources/ReactiveUIMacrosPlugin/ElementCatalog.swift
- `7. Diagnostics` --references--> `ElementCatalog`  [INFERRED]
  MetalGraphicsLib/docs/CompileTimeState.md → ReactiveUIMacros/Sources/ReactiveUIMacrosPlugin/ElementCatalog.swift
- `Scopes` --references--> `ElementCatalog`  [INFERRED]
  MetalGraphicsLib/docs/CompileTimeState.md → ReactiveUIMacros/Sources/ReactiveUIMacrosPlugin/ElementCatalog.swift

## Import Cycles
- None detected.

## Communities (118 total, 8 thin omitted)

### Community 0 - "HittableView"
Cohesion: 0.24
Nodes (7): HittableView, .hitPosition, .hitSize, Bool, Float, float2, Void

### Community 1 - "Input"
Cohesion: 0.10
Nodes (14): Input, .mouseDown, .mouseMoved, .mousePressed, .mouseUp, Bool, Double, NSEvent (+6 more)

### Community 2 - "Text"
Cohesion: 0.08
Nodes (29): CGGlyph, CoreText, CTFont, Float, TextDemo, .body, Hashable, FontManager (+21 more)

### Community 3 - "SparseSet"
Cohesion: 0.18
Nodes (8): AnyIterator, SparseSet, .count, .isEmpty, .storedKeys, .values, Bool, Element

### Community 4 - "BoundingBox2D"
Cohesion: 0.17
Nodes (12): BoundingBox2D, .bottom, .bottomRight, .height, .left, .right, .top, .topLeft (+4 more)

### Community 5 - "DiagnosticsTests"
Cohesion: 0.06
Nodes (17): CompilerPlugin, ReactiveUIMacrosPlugin, Macro, AnimationMacroTests, Macro, ComponentMacroTests, component(), DiagnosticsTests (+9 more)

### Community 6 - "Hittable"
Cohesion: 0.21
Nodes (10): HittableGrid2D, HittableGridCell, HoveredView, Float, float2, ObjectIdentifier, Hittable, .handlesEvents (+2 more)

### Community 7 - "AnimatedProperty"
Cohesion: 0.06
Nodes (40): Apply, `withAnimation`, AnimatedProperty, center, color, cornerRadius, fontSize, inset (+32 more)

### Community 8 - "Ray-Marching Shader"
Cohesion: 0.08
Nodes (29): Camera, fov, position, rotation, compute(), distanceToScene(), GridArgBuffer, GridItem (+21 more)

### Community 9 - "SIMD2"
Cohesion: 0.31
Nodes (8): Float, .packed, SIMD2, .packed, SIMD4, .packed, Float, UIAnimatable

### Community 10 - "CodeGen"
Cohesion: 0.14
Nodes (16): CodeGen, .armedHandlers, Dependents, RowsMode, full, insert, remove, Bool (+8 more)

### Community 11 - "Int"
Cohesion: 0.18
Nodes (10): StressCell, StressIndex, StressRow, .body, Bool, VectorDemo, .body, Int (+2 more)

### Community 12 - "GlyphSDF.metal"
Cohesion: 0.09
Nodes (34): bakeSDF(), lineWinding(), constant, float2, kernel, texture2d, uint, uint2 (+26 more)

### Community 13 - "MathLib.swift"
Cohesion: 0.18
Nodes (18): int3, dragDirection(), from1DTo3DArray(), from2DTo1DArray(), from3DTo1DArray(), fromPixelCoordToGridIndex(), fromWorldPositionToGridIndex(), lerp() (+10 more)

### Community 14 - "UIContext"
Cohesion: 0.09
Nodes (21): Sliding layout, UIAnimation, ObjectIdentifier, UIContext, Background, Circle, ExpandedFrame, Frame (+13 more)

### Community 15 - "IMView"
Cohesion: 0.12
Nodes (17): ExpandedFrame, FlexFrame, IMView, Background, Float, float2, Frame, HStack (+9 more)

### Community 16 - "ReactiveUIDiagnostic"
Cohesion: 0.20
Nodes (8): DiagnosticMessage, DiagnosticSeverity, FixItMessage, MessageID, ReactiveUIDiagnostic, ReactiveUIFixIt, SyntaxProtocol, SwiftDiagnostics

### Community 17 - "Alignment"
Cohesion: 0.27
Nodes (8): Alignment, .offset, HorizontalAlignment, IMView, Float, float2, Self, VerticalAlignment

### Community 18 - "IMView"
Cohesion: 0.13
Nodes (16): ExpandedFrame, FlexFrame, Frame, IMView, Alignment, Axis, Float, float2 (+8 more)

### Community 19 - "BodyParser"
Cohesion: 0.13
Nodes (20): IfExprSyntax, Scopes, BodyParser, Bool, ClosureExprSyntax, ExprSyntax, FunctionCallExprSyntax, Set (+12 more)

### Community 20 - "VectorShape"
Cohesion: 0.09
Nodes (24): Text styling, Capsule, Circle, .length, .localBounds, Ellipse, .length, .localBounds (+16 more)

### Community 21 - "SDFPathBuilder"
Cohesion: 0.09
Nodes (33): CGPath, PathElement, PendingBake, SDFAtlas, SDFBakeParams, SDFBaker, SDFPathBuilder, .isEmpty (+25 more)

### Community 22 - "WindowState"
Cohesion: 0.12
Nodes (16): CaseIterable, Repeat and keyframes, Application, Event, Inspector, Navigation, Global, Reload (+8 more)

### Community 23 - "Graphics2D"
Cohesion: 0.14
Nodes (17): Glyph, ImageQuad, Line, Graphics2D, .size, Float, float2, MTLBuffer (+9 more)

### Community 24 - "String"
Cohesion: 0.14
Nodes (5): String, .uint32, UInt32, FunctionCallExprSyntax, Naming

### Community 25 - "View"
Cohesion: 0.15
Nodes (13): Bool, View, Background, ExpandedFrame, FlexFrame, HStack, .isSpacer, MouseOver (+5 more)

### Community 26 - "Drag"
Cohesion: 0.20
Nodes (6): CustomStringConvertible, Drag, .description, Float, float2, Void

### Community 27 - "Arity"
Cohesion: 0.29
Nodes (7): Owner, component, node, Arity, leaf, multi, single

### Community 28 - "ViewRenderer"
Cohesion: 0.14
Nodes (13): MetalView, .body, CGSize, Double, Float, float2, MTKView, ViewRenderer (+5 more)

### Community 29 - ".update"
Cohesion: 0.08
Nodes (11): Invalidation, Bool, Double, float2, Frame, UInt8, Void, .needsRender (+3 more)

### Community 30 - "SDF.metal"
Cohesion: 0.14
Nodes (13): dot2(), float2, sdBox(), sdBoxSquared(), sdCircle(), sdCircleSquared(), sdOrientedBox(), sdRoundedBox() (+5 more)

### Community 31 - ".expansion"
Cohesion: 0.09
Nodes (16): AccessorDeclSyntax, AccessorMacro, DeclReferenceExprSyntax, DeclSyntaxProtocol, MemberAccessExprSyntax, PeerMacro, StateRewriter, ClosureExprSyntax (+8 more)

### Community 32 - "Sendable"
Cohesion: 0.25
Nodes (10): Any, KeyframeElement, KeyframeSegment, Float, float2, Self, V, UIKeyframe (+2 more)

### Community 33 - "TransitionState"
Cohesion: 0.23
Nodes (4): Float, float2, TransitionState, UITransition

### Community 34 - "Kind"
Cohesion: 0.19
Nodes (16): AnimationScope, BoundArg, BoundHandler, ChainLink, ElementIR, .innermost, .outermost, Kind (+8 more)

### Community 35 - "MyMTKView"
Cohesion: 0.10
Nodes (15): float2, .asInt2, .greatestComponent, .height, .width, Float, float2x2, Float (+7 more)

### Community 36 - "LayoutDemo"
Cohesion: 0.12
Nodes (11): LayoutDemo, .body, Alignment, Axis, Float, float2, HorizontalAlignment, VerticalAlignment (+3 more)

### Community 37 - "VectorBaker"
Cohesion: 0.11
Nodes (20): BakedRegion, DynamicSDFAtlas, .maxTileSize, Mode, fillEvenOdd, fillNonZero, stroke, SDFSlot (+12 more)

### Community 38 - "SVGParser"
Cohesion: 0.17
Nodes (16): Equatable, SVGDocument, SVGPaint, color, currentColor, none, SVGParser, SVGShape (+8 more)

### Community 39 - "ListRows"
Cohesion: 0.15
Nodes (12): HStack, 5. Collections are just `@State` arrays, Mutation carries the operation, The plain setter still works, HList, Float, T, VerticalAlignment (+4 more)

### Community 40 - "Metal Math Helpers"
Cohesion: 0.21
Nodes (10): cross2d(), float2, ndot(), normalize(), remap(), rotation(), rotationX(), rotationY() (+2 more)

### Community 41 - "BoundingBox3D"
Cohesion: 0.14
Nodes (13): BoundingBox3D, .back, .bottom, .bottomRightBack, .depth, .front, .height, .left (+5 more)

### Community 42 - "bakeVectorSDF"
Cohesion: 0.14
Nodes (25): bakeVectorSDF(), closestOnLine(), closestOnQuadratic(), isInside(), lineCrossing(), constant, float2, kernel (+17 more)

### Community 43 - "compute2D"
Cohesion: 0.12
Nodes (13): compute2D(), constant, kernel, uint2, write, Square, color, depth (+5 more)

### Community 44 - ".expansion"
Cohesion: 0.12
Nodes (14): CodeBlockItemListSyntax, DeclGroupSyntax, ExtensionDeclSyntax, ExtensionMacro, MemberMacro, MemberBlockItemListSyntax, TypeSyntax, VariableDeclSyntax (+6 more)

### Community 45 - "simd"
Cohesion: 0.08
Nodes (18): .inspectorView, Number2Field, .body, T, Number3Field, .body, SIMD3, T (+10 more)

### Community 46 - "SceneData"
Cohesion: 0.29
Nodes (7): DebugData, drawGrid, showFilledCells, SceneData, debug, time, windowSize

### Community 47 - "GraphicsGrid2D"
Cohesion: 0.19
Nodes (11): Int32, GPUDevice, MTLDevice, GraphicsGrid2D, GridArgBuffer, GridCell, Shape, Float (+3 more)

### Community 48 - "VList"
Cohesion: 0.29
Nodes (6): Float, HorizontalAlignment, T, Void, VList, VStack

### Community 49 - "PathBuilder"
Cohesion: 0.19
Nodes (9): PathBuilder, PathMorph, Bool, Double, Float, float2, VectorSegment, VectorGeometry (+1 more)

### Community 50 - "HStack"
Cohesion: 0.27
Nodes (5): HStack, .size, Float, float2, VerticalAlignment

### Community 51 - "VStack"
Cohesion: 0.27
Nodes (5): Float, float2, HorizontalAlignment, VStack, .size

### Community 52 - "AnimationDemo"
Cohesion: 0.14
Nodes (10): AnimatedItem, AnimationDemo, .body, Bool, Float, ImageDemo, .body, Bool (+2 more)

### Community 53 - "MetalViewRepresentable"
Cohesion: 0.29
Nodes (6): Context, MetalViewRepresentable, MTKView, NSView, NSViewType, ViewRepresentable

### Community 54 - "ExpandedFrame Element"
Cohesion: 0.33
Nodes (4): ExpandedFrame, Alignment, Axis, float2

### Community 55 - "ListDemo"
Cohesion: 0.21
Nodes (11): ChipView, .body, DemoItem, ListDemo, .body, RowView, .body, Bool (+3 more)

### Community 56 - "Float"
Cohesion: 0.28
Nodes (6): Float, .degrees, .isNegative, .radians, Bool, ClosedRange

### Community 58 - "main.swift"
Cohesion: 0.05
Nodes (50): ArraySlice, CGEventFlags, CGEventType, CGKeyCode, CGMouseButton, CGWindowID, 1. Build and launch, 2. Compile the driver (+42 more)

### Community 59 - "Axis"
Cohesion: 0.25
Nodes (7): Axis, .inverted, .size, IMView, Float, float2, Self

### Community 60 - "GPU Glyph Shape"
Cohesion: 0.25
Nodes (8): Glyph, color, depth, fontSize, position, size, uvMax, uvMin

### Community 61 - "Demo"
Cohesion: 0.15
Nodes (14): Demo, animation, conditional, .id, image, layout, list, text (+6 more)

### Community 62 - "float3"
Cohesion: 0.05
Nodes (42): matrix_double4x4, float3, .depth, .height, .width, .xy, Float, float2 (+34 more)

### Community 63 - "Array"
Cohesion: 0.33
Nodes (4): Array, .byteCount, Element, Void

### Community 65 - "Shaders/Shaders.metal"
Cohesion: 0.10
Nodes (25): metal_stdlib, ellipseAlong(), GridArgBuffer, GridCell, count, startIndex, Line, color (+17 more)

### Community 66 - ".drawData"
Cohesion: 0.16
Nodes (6): MTKView, Void, Circle2D, .bounds, Float, float2

### Community 67 - "Comparable Clamp"
Cohesion: 0.40
Nodes (3): Comparable, ClosedRange, Self

### Community 68 - "UIElementWrapping"
Cohesion: 0.15
Nodes (8): AnyObject, Bool, Float, float2, Frame, Void, UIElementWrapping, ReactiveComponent

### Community 73 - "Line"
Cohesion: 0.33
Nodes (4): Line, .bounds, Float, float2

### Community 74 - "SVGScanner"
Cohesion: 0.17
Nodes (10): SVGPathData, SVGScanner, .isAtEnd, .peek, SVGTransform, .lengthScale, Bool, Character (+2 more)

### Community 75 - "Inset"
Cohesion: 0.13
Nodes (13): IMView, Padding, Float, Self, Void, .packed, Padding, Inset (+5 more)

### Community 76 - "TransitionElement"
Cohesion: 0.16
Nodes (12): 1. The pieces, 2. What a component looks like, 3. What gets generated, 4. Rules that follow, 6. Composition, not helper methods, 9. Animation, Compile-time state in RetainedModeUI, Effects and transitions (+4 more)

### Community 77 - "Frame"
Cohesion: 0.33
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

### Community 81 - "MetalKit"
Cohesion: 0.11
Nodes (14): App, Combine, ContentView, .body, GPURayMarchingApp, .body, MTKView, TestViewRenderer (+6 more)

### Community 82 - "Image"
Cohesion: 0.13
Nodes (13): Image, .naturalSize, Interpolation, high, low, medium, none, Float (+5 more)

### Community 83 - "EffectElement"
Cohesion: 0.24
Nodes (6): EffectElement, .hasEffect, .localEffect, Bool, Float, float2

### Community 84 - "UIElement"
Cohesion: 0.09
Nodes (13): 7. Diagnostics, MultiChildElement, .liveChildrenCount, float2, Void, Bool, float2, Void (+5 more)

### Community 85 - "float4"
Cohesion: 0.40
Nodes (3): float4, .xyz, Background

### Community 86 - "uchar4"
Cohesion: 0.25
Nodes (6): UInt8, uchar4, .a, .b, .g, .r

### Community 87 - "ConditionalDemo"
Cohesion: 0.43
Nodes (4): ConditionalDemo, .body, Bool, Float

### Community 88 - "SingleChildElement"
Cohesion: 0.25
Nodes (3): SingleChildElement, float2, Void

### Community 89 - "Path"
Cohesion: 0.15
Nodes (15): Path, .isClosed, .length, .localBounds, Source, builder, commands, Bool (+7 more)

### Community 90 - "Float"
Cohesion: 0.22
Nodes (5): Costs to know, The runtime, Bool, Float, Int32

### Community 91 - "SVGIcon"
Cohesion: 0.21
Nodes (8): Layer, SVGIcon, Bool, Bundle, Data, Float, float2, Set

### Community 92 - "MouseOver"
Cohesion: 0.35
Nodes (6): IMView, MouseOver, Bool, Float, Self, Void

### Community 93 - "StepIterator"
Cohesion: 0.27
Nodes (6): IteratorProtocol, StepIterator, StepSequence, Bool, Float, Sequence

### Community 94 - "Background"
Cohesion: 0.20
Nodes (7): IMView, Background, IMView, Float, Self, Void, IMGameView

### Community 95 - "VectorItem"
Cohesion: 0.19
Nodes (12): Kind, bakedFill, bakedStroke, ellipse, roundedBox, Float, float2, VectorItem (+4 more)

### Community 96 - "Graphics2D.swift"
Cohesion: 0.33
Nodes (6): DebugData, SceneData, ShapeArgBuffer, Bool, Int32, UInt64

### Community 97 - "StateProperty"
Cohesion: 0.18
Nodes (11): PatternBindingSyntax, .states, .reactiveNames, .stateNames, StateProperty, AttributeSyntax, Bool, MemberBlockItemListSyntax (+3 more)

### Community 98 - "IMView"
Cohesion: 0.39
Nodes (4): IMView, Spacer, Float, Void

### Community 99 - "Background"
Cohesion: 0.31
Nodes (3): Background, Float, float2

### Community 100 - "VectorCanvas"
Cohesion: 0.21
Nodes (7): .body, Float, float2, Self, VectorCanvas, .children, VectorShapeList

### Community 101 - "ImageManager"
Cohesion: 0.18
Nodes (10): CGFloat, ImageManager, ImageQuad, .bounds, PendingUpload, MTLBuffer, MTLCommandBuffer, MTLDevice (+2 more)

### Community 102 - "VectorItem"
Cohesion: 0.17
Nodes (12): VectorItem, clip, color, flags, kind, padding0, padding1, params0 (+4 more)

### Community 103 - "BitmapTexture"
Cohesion: 0.24
Nodes (9): CGContext, BitmapTexture, float2, MTLTexture, Void, Content, bitmap, missing (+1 more)

### Community 105 - "ImageQuad"
Cohesion: 0.18
Nodes (11): ImageQuad, depth, flags, lod, position, size, textureIndex, tint (+3 more)

### Community 106 - "ShapeType2D"
Cohesion: 0.29
Nodes (7): ShapeType2D, Circle, Glyph, Image, Line, Square, Vector

### Community 107 - "Alignment"
Cohesion: 0.31
Nodes (7): Alignment, .offset, HorizontalAlignment, Float, float2, Self, VerticalAlignment

### Community 108 - ".texture"
Cohesion: 0.25
Nodes (6): CGImage, Bundle, Float, NSImage, Bundle, NSImage

### Community 109 - "SVGPathCommand"
Cohesion: 0.22
Nodes (7): SVGPathCommand, close, cubic, line, move, quad, .presentedCommands

### Community 110 - "VectorSegment"
Cohesion: 0.22
Nodes (9): VectorSegment, a, b, boxMax, boxMin, c, isLine, padding (+1 more)

### Community 111 - "Curve"
Cohesion: 0.25
Nodes (7): Curve, easeIn, easeInOut, easeOut, keyframes, linear, spring

### Community 112 - "Padding"
Cohesion: 0.29
Nodes (3): Padding, Float, float2

### Community 113 - "Axis"
Cohesion: 0.29
Nodes (6): Axis, .inverted, .size, Float, float2, Self

### Community 114 - "AppKit"
Cohesion: 0.33
Nodes (4): AppKit, ContentMode, fill, fit

### Community 115 - "int2"
Cohesion: 0.40
Nodes (3): int2, float2, from1DTo2DArray()

### Community 116 - "Circle"
Cohesion: 0.40
Nodes (5): Circle, color, depth, position, radius

## Knowledge Gaps
- **331 isolated node(s):** `conditional`, `list`, `text`, `layout`, `image` (+326 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 681 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **8 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `String` connect `String` to `Input`, `Text`, `DiagnosticsTests`, `CodeGen`, `UIContext`, `IMView`, `ReactiveUIDiagnostic`, `IMView`, `BodyParser`, `SDFPathBuilder`, `WindowState`, `Graphics2D`, `Drag`, `Arity`, `.expansion`, `Kind`, `LayoutDemo`, `SVGParser`, `.expansion`, `simd`, `HStack`, `VStack`, `AnimationDemo`, `ExpandedFrame Element`, `ListDemo`, `main.swift`, `Demo`, `float3`, `SVGScanner`, `Inset`, `Frame`, `IMView`, `Image`, `EffectElement`, `UIElement`, `ConditionalDemo`, `SingleChildElement`, `Path`, `SVGIcon`, `MouseOver`, `Background`, `StateProperty`, `IMView`, `Background`, `VectorCanvas`, `ImageManager`, `.texture`, `Padding`?**
  _High betweenness centrality (0.271) - this node is a cross-community bridge._
- **Why does `Int` connect `Int` to `Text`, `SparseSet`, `AnimatedProperty`, `MathLib.swift`, `UIContext`, `IMView`, `BodyParser`, `SDFPathBuilder`, `WindowState`, `Graphics2D`, `String`, `View`, `.update`, `Kind`, `LayoutDemo`, `VectorBaker`, `ListRows`, `GraphicsGrid2D`, `VList`, `PathBuilder`, `AnimationDemo`, `ListDemo`, `main.swift`, `Array`, `UIElement`, `ConditionalDemo`, `Float`, `ImageManager`, `BitmapTexture`, `int2`?**
  _High betweenness centrality (0.110) - this node is a cross-community bridge._
- **Why does `Input` connect `Input` to `Sendable`, `HittableView`, `MyMTKView`, `UIElementWrapping`, `Hittable`, `Input.swift`, `VectorShape`, `String`, `Drag`, `ViewRenderer`, `.update`?**
  _High betweenness centrality (0.099) - this node is a cross-community bridge._
- **Are the 5 inferred relationships involving `UIContext` (e.g. with `Effects and transitions` and `HittableGrid2D`) actually correct?**
  _`UIContext` has 5 INFERRED edges - model-reasoned connections that need verification._
- **Are the 4 inferred relationships involving `UIElement` (e.g. with `7. Diagnostics` and `.dropLeaving()`) actually correct?**
  _`UIElement` has 4 INFERRED edges - model-reasoned connections that need verification._
- **What connects `conditional`, `list`, `text` to the rest of the system?**
  _331 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Input` be split into smaller, more focused modules?**
  _Cohesion score 0.10344827586206896 - nodes in this community are weakly interconnected._