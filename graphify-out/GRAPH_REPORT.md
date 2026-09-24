# Graph Report - MetalGraphics  (2026-09-24)

## Corpus Check
- 165 files · ~89,920 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 15 file(s) not represented in the graph (top: (none) 4, .plist 3, .resolved 2)

## Summary
- 2201 nodes · 5013 edges · 113 communities (105 shown, 8 thin omitted)
- Extraction: 92% EXTRACTED · 8% INFERRED · 0% AMBIGUOUS · INFERRED: 385 edges (avg confidence: 0.84)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `8a4789d7`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- TransitionElement
- Input
- Text
- Int
- BoundingBox2D
- DiagnosticsTests
- Utils.swift
- AnimatedProperty
- Ray-Marching Shader
- SIMD2
- CodeGen
- SVGParser
- GlyphSDF.metal
- MathLib.swift
- .invalidate
- IMView
- .expansion
- Alignment
- IMView
- BodyParser
- SDFPathBuilder
- Image
- WindowState
- Graphics2D
- String
- View
- Drag
- ModifierSpec
- ViewRenderer
- UIContext
- SDF.metal
- bakeVectorSDF
- TransitionState
- VectorBaker
- Kind
- MyMTKView
- LayoutDemo
- UIAnimation
- float3
- ListRows
- Metal Math Helpers
- BoundingBox3D
- Rect
- compute2D
- .expansion
- simd
- SceneData
- GraphicsGrid2D
- VList
- SVGIcon
- HStack
- VStack
- AnimationDemo
- MetalViewRepresentable
- HittableView
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
- ImageManager
- Comparable Clamp
- PathBuilder
- Macro Package Manifest
- EffectState
- Path
- Foundation
- SVGScanner
- BitmapTexture
- SingleChildElement
- VectorItem
- ViewItem
- MetalGraphicsLib
- UIElement
- EffectElement
- VectorItem
- VectorDemo
- float4
- ConditionalDemo
- SDF.swift
- Inset
- VectorCanvas
- UIElementWrapping
- MouseOver
- Hittable
- Background
- .texture
- Graphics2D.swift
- SVGPathCommand
- IMView
- FlexFrame
- Padding
- AppKit
- .drawData
- ReactiveUIDiagnostic
- Input.swift
- ExpandedFrame
- ShapeType2D
- float2
- Frame
- Line
- Square
- int2
- float2x2

## God Nodes (most connected - your core abstractions)
1. `UIContext` - 131 edges
2. `UIElement` - 98 edges
3. `UIAnimation` - 92 edges
4. `SIMD2` - 57 edges
5. `float4` - 53 edges
6. `Input` - 51 edges
7. `VectorShape` - 48 edges
8. `Graphics2D` - 46 edges
9. `simd` - 38 edges
10. `Inset` - 37 edges

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

## Communities (113 total, 8 thin omitted)

### Community 0 - "TransitionElement"
Cohesion: 0.14
Nodes (14): 1. The pieces, 2. What a component looks like, 3. What gets generated, 4. Rules that follow, 6. Composition, not helper methods, 9. Animation, Compile-time state in RetainedModeUI, Costs to know (+6 more)

### Community 1 - "Input"
Cohesion: 0.10
Nodes (14): Input, .mouseDown, .mouseMoved, .mousePressed, .mouseUp, Bool, Double, NSEvent (+6 more)

### Community 2 - "Text"
Cohesion: 0.08
Nodes (29): CGGlyph, CoreText, CTFont, Float, TextDemo, .body, Hashable, FontManager (+21 more)

### Community 3 - "Int"
Cohesion: 0.15
Nodes (11): AnyIterator, Int, Bool, ClosedRange, SparseSet, .count, .isEmpty, .storedKeys (+3 more)

### Community 4 - "BoundingBox2D"
Cohesion: 0.17
Nodes (12): BoundingBox2D, .bottom, .bottomRight, .height, .left, .right, .top, .topLeft (+4 more)

### Community 5 - "DiagnosticsTests"
Cohesion: 0.06
Nodes (17): CompilerPlugin, ReactiveUIMacrosPlugin, Macro, AnimationMacroTests, Macro, ComponentMacroTests, component(), DiagnosticsTests (+9 more)

### Community 6 - "Utils.swift"
Cohesion: 0.17
Nodes (13): DispatchQueue, DispatchWorkItem, Debouncer, forEachGridCell(), generateRandomArray(), iterateWithStep(), name(), ClosedRange (+5 more)

### Community 7 - "AnimatedProperty"
Cohesion: 0.06
Nodes (41): Apply, `withAnimation`, AnimatedProperty, center, color, cornerRadius, fontSize, inset (+33 more)

### Community 8 - "Ray-Marching Shader"
Cohesion: 0.08
Nodes (29): Camera, fov, position, rotation, compute(), distanceToScene(), GridArgBuffer, GridItem (+21 more)

### Community 9 - "SIMD2"
Cohesion: 0.17
Nodes (11): Float, .packed, SIMD2, .packed, SIMD4, .packed, Float, UIAnimatable (+3 more)

### Community 10 - "CodeGen"
Cohesion: 0.12
Nodes (15): CodeGen, .armedHandlers, Dependents, RowsMode, full, insert, remove, DeclSyntax (+7 more)

### Community 11 - "SVGParser"
Cohesion: 0.17
Nodes (16): Equatable, SVGDocument, SVGPaint, color, currentColor, none, SVGParser, SVGShape (+8 more)

### Community 12 - "GlyphSDF.metal"
Cohesion: 0.09
Nodes (34): bakeSDF(), lineWinding(), constant, float2, kernel, texture2d, uint, uint2 (+26 more)

### Community 13 - "MathLib.swift"
Cohesion: 0.18
Nodes (17): int3, dragDirection(), from1DTo3DArray(), from2DTo1DArray(), from3DTo1DArray(), fromPixelCoordToGridIndex(), fromWorldPositionToGridIndex(), lerp() (+9 more)

### Community 14 - ".invalidate"
Cohesion: 0.08
Nodes (18): Sliding layout, Text styling, Background, Circle, ExpandedFrame, Frame, HStack, Padding (+10 more)

### Community 15 - "IMView"
Cohesion: 0.13
Nodes (16): ExpandedFrame, FlexFrame, IMView, Background, Float, float2, Frame, HStack (+8 more)

### Community 16 - ".expansion"
Cohesion: 0.09
Nodes (16): AccessorDeclSyntax, AccessorMacro, DeclReferenceExprSyntax, DeclSyntaxProtocol, MemberAccessExprSyntax, PeerMacro, StateRewriter, ClosureExprSyntax (+8 more)

### Community 17 - "Alignment"
Cohesion: 0.27
Nodes (8): Alignment, .offset, HorizontalAlignment, IMView, Float, float2, Self, VerticalAlignment

### Community 18 - "IMView"
Cohesion: 0.24
Nodes (10): ExpandedFrame, FlexFrame, Frame, IMView, Alignment, Axis, Float, float2 (+2 more)

### Community 19 - "BodyParser"
Cohesion: 0.16
Nodes (12): CodeBlockItemListSyntax, IfExprSyntax, BodyParser, Bool, ClosureExprSyntax, ExprSyntax, FunctionCallExprSyntax, MemberBlockItemListSyntax (+4 more)

### Community 20 - "SDFPathBuilder"
Cohesion: 0.09
Nodes (34): CGPath, CoreGraphics, PathElement, PendingBake, SDFAtlas, SDFBakeParams, SDFBaker, SDFPathBuilder (+26 more)

### Community 21 - "Image"
Cohesion: 0.13
Nodes (13): Image, .naturalSize, Interpolation, high, low, medium, none, Float (+5 more)

### Community 22 - "WindowState"
Cohesion: 0.12
Nodes (16): CaseIterable, Repeat and keyframes, Application, Event, Inspector, Navigation, Global, Reload (+8 more)

### Community 23 - "Graphics2D"
Cohesion: 0.14
Nodes (17): Glyph, ImageQuad, Line, Graphics2D, .size, Float, float2, MTLBuffer (+9 more)

### Community 24 - "String"
Cohesion: 0.17
Nodes (6): String, .uint32, UInt32, Bool, FunctionCallExprSyntax, Naming

### Community 25 - "View"
Cohesion: 0.13
Nodes (15): Bool, View, Background, ExpandedFrame, FlexFrame, HStack, .isSpacer, MouseOver (+7 more)

### Community 26 - "Drag"
Cohesion: 0.20
Nodes (6): CustomStringConvertible, Drag, .description, Float, float2, Void

### Community 27 - "ModifierSpec"
Cohesion: 0.16
Nodes (19): Scopes, Owner, component, node, ArgCombine, float2, identity, labeled (+11 more)

### Community 28 - "ViewRenderer"
Cohesion: 0.12
Nodes (14): .body, MetalView, .body, CGSize, Double, Float, float2, MTKView (+6 more)

### Community 29 - "UIContext"
Cohesion: 0.09
Nodes (13): Invalidation, Bool, Double, float2, Frame, ObjectIdentifier, UInt8, Void (+5 more)

### Community 30 - "SDF.metal"
Cohesion: 0.15
Nodes (12): dot2(), float2, sdBox(), sdBoxSquared(), sdCircle(), sdCircleSquared(), sdOrientedBox(), sdRoundedBox() (+4 more)

### Community 31 - "bakeVectorSDF"
Cohesion: 0.09
Nodes (34): bakeVectorSDF(), closestOnLine(), closestOnQuadratic(), isInside(), lineCrossing(), constant, float2, kernel (+26 more)

### Community 32 - "TransitionState"
Cohesion: 0.07
Nodes (28): Any, KeyframeElement, KeyframeSegment, Float, float2, Self, V, UIKeyframe (+20 more)

### Community 33 - "VectorBaker"
Cohesion: 0.12
Nodes (20): BakedRegion, DynamicSDFAtlas, .maxTileSize, Mode, fillEvenOdd, fillNonZero, stroke, SDFSlot (+12 more)

### Community 34 - "Kind"
Cohesion: 0.19
Nodes (16): AnimationScope, BoundArg, BoundHandler, ChainLink, ElementIR, .innermost, .outermost, Kind (+8 more)

### Community 35 - "MyMTKView"
Cohesion: 0.19
Nodes (7): Modifier, MyMTKView, .acceptsFirstResponder, Bool, NSEvent, UInt, MTKView

### Community 36 - "LayoutDemo"
Cohesion: 0.20
Nodes (8): LayoutDemo, .body, Alignment, Axis, Float, float2, HorizontalAlignment, VerticalAlignment

### Community 37 - "UIAnimation"
Cohesion: 0.15
Nodes (13): Curve, easeIn, easeInOut, easeOut, keyframes, linear, spring, Bool (+5 more)

### Community 38 - "float3"
Cohesion: 0.18
Nodes (9): float3, .depth, .height, .width, .xy, Float, float2, Double (+1 more)

### Community 39 - "ListRows"
Cohesion: 0.15
Nodes (12): HStack, 5. Collections are just `@State` arrays, Mutation carries the operation, The plain setter still works, HList, Float, T, VerticalAlignment (+4 more)

### Community 40 - "Metal Math Helpers"
Cohesion: 0.21
Nodes (10): cross2d(), float2, ndot(), normalize(), remap(), rotation(), rotationX(), rotationY() (+2 more)

### Community 41 - "BoundingBox3D"
Cohesion: 0.14
Nodes (13): BoundingBox3D, .back, .bottom, .bottomRightBack, .depth, .front, .height, .left (+5 more)

### Community 42 - "Rect"
Cohesion: 0.16
Nodes (10): Rect, .center, .height, .maxX, .maxY, .minX, .minY, .width (+2 more)

### Community 43 - "compute2D"
Cohesion: 0.12
Nodes (13): compute2D(), constant, kernel, uint2, write, Square, color, depth (+5 more)

### Community 44 - ".expansion"
Cohesion: 0.09
Nodes (22): DeclGroupSyntax, ExtensionDeclSyntax, ExtensionMacro, MemberMacro, PatternBindingSyntax, .states, TypeSyntax, .arrayStates (+14 more)

### Community 45 - "simd"
Cohesion: 0.08
Nodes (18): .inspectorView, Number2Field, .body, T, Number3Field, .body, SIMD3, T (+10 more)

### Community 46 - "SceneData"
Cohesion: 0.29
Nodes (7): DebugData, drawGrid, showFilledCells, SceneData, debug, time, windowSize

### Community 47 - "GraphicsGrid2D"
Cohesion: 0.17
Nodes (12): Int32, GPUDevice, MTLDevice, GraphicsGrid2D, GridArgBuffer, GridCell, Shape, Float (+4 more)

### Community 48 - "VList"
Cohesion: 0.29
Nodes (6): Float, HorizontalAlignment, T, Void, VList, VStack

### Community 49 - "SVGIcon"
Cohesion: 0.21
Nodes (8): Layer, SVGIcon, Bool, Bundle, Data, Float, float2, Set

### Community 50 - "HStack"
Cohesion: 0.27
Nodes (5): HStack, .size, Float, float2, VerticalAlignment

### Community 51 - "VStack"
Cohesion: 0.27
Nodes (5): Float, float2, HorizontalAlignment, VStack, .size

### Community 52 - "AnimationDemo"
Cohesion: 0.23
Nodes (7): AnimatedItem, AnimationDemo, .body, Bool, Float, StressIndex, Identifiable

### Community 53 - "MetalViewRepresentable"
Cohesion: 0.29
Nodes (6): Context, MetalViewRepresentable, MTKView, NSView, NSViewType, ViewRepresentable

### Community 54 - "HittableView"
Cohesion: 0.24
Nodes (7): HittableView, .hitPosition, .hitSize, Bool, Float, float2, Void

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
Cohesion: 0.11
Nodes (32): ArraySlice, CGEventFlags, CGEventType, CGKeyCode, CGMouseButton, CGWindowID, 1. Build and launch, 2. Compile the driver (+24 more)

### Community 59 - "Axis"
Cohesion: 0.25
Nodes (7): Axis, .inverted, .size, IMView, Float, float2, Self

### Community 60 - "GPU Glyph Shape"
Cohesion: 0.25
Nodes (8): Glyph, color, depth, fontSize, position, size, uvMax, uvMin

### Community 61 - "Demo"
Cohesion: 0.13
Nodes (16): Demo, animation, conditional, .id, image, layout, list, text (+8 more)

### Community 62 - "float4x4"
Cohesion: 0.14
Nodes (12): matrix_double4x4, float3x3, Float, float4x4, .formated, .identity, .upperLeft, Bool (+4 more)

### Community 63 - "Array"
Cohesion: 0.33
Nodes (4): Array, .byteCount, Element, Void

### Community 65 - "Shaders/Shaders.metal"
Cohesion: 0.08
Nodes (31): metal_stdlib, Circle, color, depth, position, radius, ellipseAlong(), GridArgBuffer (+23 more)

### Community 66 - "ImageManager"
Cohesion: 0.18
Nodes (10): CGFloat, ImageManager, ImageQuad, .bounds, PendingUpload, MTLBuffer, MTLCommandBuffer, MTLDevice (+2 more)

### Community 67 - "Comparable Clamp"
Cohesion: 0.40
Nodes (3): Comparable, ClosedRange, Self

### Community 68 - "PathBuilder"
Cohesion: 0.24
Nodes (8): PathBuilder, Bool, Double, Float, float2, VectorSegment, VectorGeometry, .isEmpty

### Community 74 - "Path"
Cohesion: 0.13
Nodes (15): Path, .isClosed, .length, .localBounds, Source, builder, commands, Bool (+7 more)

### Community 75 - "Foundation"
Cohesion: 0.14
Nodes (8): Foundation, benchmark(), Bool, Void, SVGPathData, SVGTransform, .lengthScale, Double

### Community 76 - "SVGScanner"
Cohesion: 0.24
Nodes (6): SVGScanner, .isAtEnd, .peek, Bool, Character, UInt8

### Community 77 - "BitmapTexture"
Cohesion: 0.24
Nodes (9): CGContext, BitmapTexture, float2, MTLTexture, Void, Content, bitmap, missing (+1 more)

### Community 78 - "SingleChildElement"
Cohesion: 0.14
Nodes (5): EmptyElement, LeafElement, SingleChildElement, float2, Spacer

### Community 79 - "VectorItem"
Cohesion: 0.09
Nodes (23): ImageQuad, depth, flags, lod, position, size, textureIndex, tint (+15 more)

### Community 80 - "ViewItem"
Cohesion: 0.22
Nodes (11): HStack, .size, IMView, Float, HorizontalAlignment, Self, VerticalAlignment, Void (+3 more)

### Community 81 - "MetalGraphicsLib"
Cohesion: 0.13
Nodes (11): App, Combine, ContentView, GPURayMarchingApp, .body, MTKView, TestViewRenderer, MetalGraphicsLib (+3 more)

### Community 82 - "UIElement"
Cohesion: 0.09
Nodes (14): 7. Diagnostics, MultiChildElement, .liveChildrenCount, float2, Void, Void, Bool, float2 (+6 more)

### Community 83 - "EffectElement"
Cohesion: 0.27
Nodes (6): EffectElement, .hasEffect, .localEffect, Bool, Float, float2

### Community 84 - "VectorItem"
Cohesion: 0.19
Nodes (12): Kind, bakedFill, bakedStroke, ellipse, roundedBox, Float, float2, VectorItem (+4 more)

### Community 85 - "VectorDemo"
Cohesion: 0.21
Nodes (7): StressCell, .body, StressRow, .body, Bool, VectorDemo, .body

### Community 86 - "float4"
Cohesion: 0.06
Nodes (34): Float, float2, float4, .xyz, UInt8, uchar4, .a, .b (+26 more)

### Community 87 - "ConditionalDemo"
Cohesion: 0.39
Nodes (4): ConditionalDemo, .body, Bool, Float

### Community 88 - "SDF.swift"
Cohesion: 0.33
Nodes (12): closestPointToSDBox(), pointInAABBox(), pointInAABBoxTopLeftOrigin(), sdBox(), sdBoxTopLeft(), sdCircle(), sdfNormal(), sdRoundBox() (+4 more)

### Community 89 - "Inset"
Cohesion: 0.13
Nodes (13): IMView, Padding, Float, Self, Void, .packed, Padding, Inset (+5 more)

### Community 90 - "VectorCanvas"
Cohesion: 0.23
Nodes (6): Float, float2, Self, VectorCanvas, .children, VectorShapeList

### Community 91 - "UIElementWrapping"
Cohesion: 0.19
Nodes (6): Bool, Float, float2, Frame, Void, UIElementWrapping

### Community 92 - "MouseOver"
Cohesion: 0.35
Nodes (6): IMView, MouseOver, Bool, Float, Self, Void

### Community 93 - "Hittable"
Cohesion: 0.10
Nodes (18): AnyObject, IteratorProtocol, HittableGrid2D, HittableGridCell, HoveredView, Float, float2, ObjectIdentifier (+10 more)

### Community 94 - "Background"
Cohesion: 0.18
Nodes (7): IMView, Background, IMView, Float, Self, Void, IMGameView

### Community 95 - ".texture"
Cohesion: 0.25
Nodes (6): CGImage, Bundle, Float, NSImage, Bundle, NSImage

### Community 96 - "Graphics2D.swift"
Cohesion: 0.33
Nodes (6): DebugData, SceneData, ShapeArgBuffer, Bool, Int32, UInt64

### Community 97 - "SVGPathCommand"
Cohesion: 0.18
Nodes (8): SVGPathCommand, close, cubic, line, move, quad, PathMorph, .presentedCommands

### Community 98 - "IMView"
Cohesion: 0.39
Nodes (4): IMView, Spacer, Float, Void

### Community 99 - "FlexFrame"
Cohesion: 0.26
Nodes (6): clamp(), T, FlexFrame, Alignment, Float, float2

### Community 100 - "Padding"
Cohesion: 0.29
Nodes (3): Padding, Float, float2

### Community 101 - "AppKit"
Cohesion: 0.33
Nodes (4): AppKit, ContentMode, fill, fit

### Community 102 - ".drawData"
Cohesion: 0.22
Nodes (4): MTKView, Void, Circle2D, .bounds

### Community 103 - "ReactiveUIDiagnostic"
Cohesion: 0.24
Nodes (7): DiagnosticMessage, DiagnosticSeverity, FixItMessage, MessageID, ReactiveUIDiagnostic, ReactiveUIFixIt, SwiftDiagnostics

### Community 105 - "ExpandedFrame"
Cohesion: 0.39
Nodes (4): ExpandedFrame, Alignment, Axis, float2

### Community 106 - "ShapeType2D"
Cohesion: 0.29
Nodes (7): ShapeType2D, Circle, Glyph, Image, Line, Square, Vector

### Community 107 - "float2"
Cohesion: 0.18
Nodes (6): float2, .asInt2, .greatestComponent, .height, .width, Float

### Community 108 - "Frame"
Cohesion: 0.39
Nodes (4): Frame, Alignment, float2, Void

### Community 109 - "Line"
Cohesion: 0.33
Nodes (4): Line, .bounds, Float, float2

### Community 110 - "Square"
Cohesion: 0.33
Nodes (4): Square, .bounds, Float, float2

### Community 111 - "int2"
Cohesion: 0.40
Nodes (3): int2, float2, from1DTo2DArray()

## Knowledge Gaps
- **332 isolated node(s):** `conditional`, `list`, `text`, `layout`, `image` (+327 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 680 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **8 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `String` connect `String` to `Input`, `Text`, `DiagnosticsTests`, `Utils.swift`, `SIMD2`, `CodeGen`, `SVGParser`, `.invalidate`, `IMView`, `.expansion`, `IMView`, `BodyParser`, `SDFPathBuilder`, `Image`, `WindowState`, `Graphics2D`, `Drag`, `ModifierSpec`, `Kind`, `LayoutDemo`, `.expansion`, `simd`, `SVGIcon`, `HStack`, `VStack`, `AnimationDemo`, `ListDemo`, `Rectangle`, `main.swift`, `Demo`, `float4x4`, `ImageManager`, `Path`, `Foundation`, `SVGScanner`, `SingleChildElement`, `ViewItem`, `UIElement`, `EffectElement`, `Inset`, `VectorCanvas`, `MouseOver`, `Background`, `.texture`, `IMView`, `FlexFrame`, `Padding`, `ReactiveUIDiagnostic`, `ExpandedFrame`, `Frame`?**
  _High betweenness centrality (0.260) - this node is a cross-community bridge._
- **Why does `Input` connect `Input` to `TransitionState`, `MyMTKView`, `Input.swift`, `float2`, `UIContext`, `HittableView`, `float4`, `String`, `Drag`, `UIElementWrapping`, `ViewRenderer`, `Hittable`?**
  _High betweenness centrality (0.105) - this node is a cross-community bridge._
- **Why does `Int` connect `Int` to `Text`, `Utils.swift`, `AnimatedProperty`, `MathLib.swift`, `IMView`, `BodyParser`, `SDFPathBuilder`, `WindowState`, `Graphics2D`, `String`, `View`, `ModifierSpec`, `UIContext`, `VectorBaker`, `Kind`, `LayoutDemo`, `UIAnimation`, `ListRows`, `GraphicsGrid2D`, `VList`, `AnimationDemo`, `ListDemo`, `main.swift`, `Array`, `ImageManager`, `Path`, `BitmapTexture`, `ViewItem`, `UIElement`, `VectorDemo`, `ConditionalDemo`, `int2`?**
  _High betweenness centrality (0.103) - this node is a cross-community bridge._
- **Are the 5 inferred relationships involving `UIContext` (e.g. with `Effects and transitions` and `HittableGrid2D`) actually correct?**
  _`UIContext` has 5 INFERRED edges - model-reasoned connections that need verification._
- **Are the 4 inferred relationships involving `UIElement` (e.g. with `7. Diagnostics` and `.dropLeaving()`) actually correct?**
  _`UIElement` has 4 INFERRED edges - model-reasoned connections that need verification._
- **What connects `conditional`, `list`, `text` to the rest of the system?**
  _332 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `TransitionElement` be split into smaller, more focused modules?**
  _Cohesion score 0.1380952380952381 - nodes in this community are weakly interconnected._