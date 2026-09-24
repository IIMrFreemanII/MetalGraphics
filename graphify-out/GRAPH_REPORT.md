# Graph Report - MetalGraphics  (2026-09-24)

## Corpus Check
- 156 files · ~75,475 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 15 file(s) not represented in the graph (top: (none) 4, .plist 3, .resolved 2)

## Summary
- 1912 nodes · 4248 edges · 108 communities (99 shown, 9 thin omitted)
- Extraction: 92% EXTRACTED · 8% INFERRED · 0% AMBIGUOUS · INFERRED: 326 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `22ff373e`
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
- SVGParser
- GlyphSDF.metal
- MathLib.swift
- UIAnimation
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
- .scan
- Sendable
- TransitionState
- Kind
- MyMTKView
- LayoutDemo
- float4
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
- Reactive Component Protocol
- Macro Package Manifest
- .draw
- FontManager
- TextDemo
- 1. The pieces
- BitmapTexture
- EmptyElement
- ImageQuad
- ViewItem
- MetalKit
- UIElement
- EffectElement
- MultiChildElement
- ListRows
- uchar4
- ConditionalDemo
- SingleChildElement
- Inset
- SDFBakeParams
- .frame
- MouseOver
- StepIterator
- Background
- .texture
- Graphics2D.swift
- ContentView
- IMView
- Background
- Padding
- AppKit
- Square
- Input.swift
- ShapeType2D
- float2
- .init
- .expansion

## God Nodes (most connected - your core abstractions)
1. `UIContext` - 102 edges
2. `UIElement` - 94 edges
3. `UIAnimation` - 73 edges
4. `SIMD2` - 52 edges
5. `Input` - 45 edges
6. `Graphics2D` - 43 edges
7. `float4` - 42 edges
8. `Inset` - 36 edges
9. `CodeGen` - 36 edges
10. `Image` - 33 edges

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

## Communities (108 total, 9 thin omitted)

### Community 0 - "TransitionElement"
Cohesion: 0.33
Nodes (5): Effects and transitions, Float, Void, TransitionElement, .currentState

### Community 1 - "Input"
Cohesion: 0.11
Nodes (13): Input, .mouseDown, .mouseMoved, .mousePressed, .mouseUp, Bool, Double, NSEvent (+5 more)

### Community 2 - "Text"
Cohesion: 0.15
Nodes (10): SDFFont, Float, float2, Self, Text, .displayedColor, .displayedFontSize, .fontScale (+2 more)

### Community 3 - "Int"
Cohesion: 0.13
Nodes (13): AnyIterator, Int, Bool, ClosedRange, from1DTo2DArray(), from2DTo1DArray(), SparseSet, .count (+5 more)

### Community 4 - "BoundingBox2D"
Cohesion: 0.06
Nodes (26): BoundingBox2D, .bottom, .bottomRight, .height, .left, .right, .top, .topLeft (+18 more)

### Community 5 - "DiagnosticsTests"
Cohesion: 0.06
Nodes (17): CompilerPlugin, ReactiveUIMacrosPlugin, Macro, AnimationMacroTests, Macro, ComponentMacroTests, component(), DiagnosticsTests (+9 more)

### Community 6 - "int2"
Cohesion: 0.09
Nodes (21): DispatchQueue, DispatchWorkItem, HittableGrid2D, HittableGridCell, HoveredView, Float, float2, ObjectIdentifier (+13 more)

### Community 7 - "Animator"
Cohesion: 0.07
Nodes (35): Apply, 9. Animation, Costs to know, Repeat and keyframes, Scopes, The runtime, `withAnimation`, AnimatedProperty (+27 more)

### Community 8 - "Ray-Marching Shader"
Cohesion: 0.08
Nodes (29): Camera, fov, position, rotation, compute(), distanceToScene(), GridArgBuffer, GridItem (+21 more)

### Community 9 - "SIMD2"
Cohesion: 0.31
Nodes (8): Float, .packed, SIMD2, .packed, SIMD4, .packed, Float, UIAnimatable

### Community 10 - "CodeGen"
Cohesion: 0.15
Nodes (15): CodeGen, .armedHandlers, Dependents, RowsMode, full, insert, remove, DeclSyntax (+7 more)

### Community 11 - "SVGParser"
Cohesion: 0.06
Nodes (36): Equatable, Foundation, benchmark(), Bool, Void, SVGDocument, SVGPaint, color (+28 more)

### Community 12 - "GlyphSDF.metal"
Cohesion: 0.13
Nodes (24): bakeSDF(), lineWinding(), constant, float2, kernel, texture2d, uint, write (+16 more)

### Community 13 - "MathLib.swift"
Cohesion: 0.24
Nodes (16): dragDirection(), from1DTo3DArray(), from3DTo1DArray(), fromPixelCoordToGridIndex(), fromWorldPositionToGridIndex(), lerp(), mix(), normalize() (+8 more)

### Community 14 - "UIAnimation"
Cohesion: 0.12
Nodes (18): Text styling, UIAnimation, Background, ExpandedFrame, Frame, HStack, Padding, Alignment (+10 more)

### Community 15 - "IMView"
Cohesion: 0.12
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
Cohesion: 0.14
Nodes (12): CodeBlockItemListSyntax, IfExprSyntax, BodyParser, Bool, ClosureExprSyntax, ExprSyntax, FunctionCallExprSyntax, MemberBlockItemListSyntax (+4 more)

### Community 20 - "SDFPathBuilder"
Cohesion: 0.09
Nodes (32): CGPath, CoreGraphics, PathElement, PendingBake, SDFAtlas, SDFBakeParams, SDFBaker, SDFPathBuilder (+24 more)

### Community 21 - "Image"
Cohesion: 0.13
Nodes (13): Image, .naturalSize, Interpolation, high, low, medium, none, Float (+5 more)

### Community 22 - "WindowState"
Cohesion: 0.15
Nodes (13): CaseIterable, Application, Event, Inspector, Navigation, Global, Reload, Bool (+5 more)

### Community 23 - "Graphics2D"
Cohesion: 0.13
Nodes (14): Glyph, ImageQuad, Graphics2D, .size, MTKView, MTLBuffer, MTLComputePipelineState, MTLDevice (+6 more)

### Community 24 - "String"
Cohesion: 0.15
Nodes (6): String, .uint32, UInt32, Bool, FunctionCallExprSyntax, Naming

### Community 25 - "View"
Cohesion: 0.12
Nodes (19): Bool, View, Background, ExpandedFrame, FlexFrame, HStack, .isSpacer, MouseOver (+11 more)

### Community 26 - "Drag"
Cohesion: 0.20
Nodes (6): CustomStringConvertible, Drag, .description, Float, float2, Void

### Community 27 - "ModifierSpec"
Cohesion: 0.15
Nodes (18): Owner, component, node, ArgCombine, float2, identity, labeled, ArgSpec (+10 more)

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
Cohesion: 0.23
Nodes (8): DeclReferenceExprSyntax, MemberAccessExprSyntax, StateRewriter, ClosureExprSyntax, ExprSyntax, Set, SyntaxProtocol, SyntaxRewriter

### Community 32 - "Sendable"
Cohesion: 0.06
Nodes (34): Any, Curve, easeIn, easeInOut, easeOut, keyframes, linear, spring (+26 more)

### Community 33 - "TransitionState"
Cohesion: 0.23
Nodes (4): Float, float2, TransitionState, UITransition

### Community 34 - "Kind"
Cohesion: 0.19
Nodes (16): AnimationScope, BoundArg, BoundHandler, ChainLink, ElementIR, .innermost, .outermost, Kind (+8 more)

### Community 35 - "MyMTKView"
Cohesion: 0.19
Nodes (7): Modifier, MyMTKView, .acceptsFirstResponder, Bool, NSEvent, UInt, MTKView

### Community 36 - "LayoutDemo"
Cohesion: 0.20
Nodes (8): LayoutDemo, .body, Alignment, Axis, Float, float2, HorizontalAlignment, VerticalAlignment

### Community 37 - "float4"
Cohesion: 0.24
Nodes (12): CoreText, layoutText(), measureText(), PlacedGlyph, Float, float2, TextLayout, TextLine (+4 more)

### Community 38 - "float3"
Cohesion: 0.14
Nodes (10): float3, .depth, .height, .width, .xy, Float, float2, Double (+2 more)

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
Cohesion: 0.08
Nodes (28): clamp(), T, closestPointToSDBox(), pointInAABBox(), pointInAABBoxTopLeftOrigin(), sdBox(), sdBoxTopLeft(), sdCircle() (+20 more)

### Community 43 - "compute2D"
Cohesion: 0.14
Nodes (11): sdSegment(), compute2D(), constant, kernel, texture2d, uint2, write, TextureHandle (+3 more)

### Community 44 - "StateProperty"
Cohesion: 0.18
Nodes (11): PatternBindingSyntax, .states, .reactiveNames, .stateNames, StateProperty, AttributeSyntax, Bool, MemberBlockItemListSyntax (+3 more)

### Community 45 - "simd"
Cohesion: 0.06
Nodes (27): ExpandedFrame, Alignment, Axis, float2, Frame, Alignment, float2, Void (+19 more)

### Community 46 - "SceneData"
Cohesion: 0.29
Nodes (7): DebugData, drawGrid, showFilledCells, SceneData, debug, time, windowSize

### Community 47 - "GraphicsGrid2D"
Cohesion: 0.17
Nodes (11): Int32, GPUDevice, MTLDevice, GraphicsGrid2D, GridArgBuffer, GridCell, Shape, Float (+3 more)

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
Cohesion: 0.29
Nodes (6): AnimatedItem, AnimationDemo, .body, Bool, Float, Identifiable

### Community 53 - "MetalViewRepresentable"
Cohesion: 0.29
Nodes (6): Context, MetalViewRepresentable, MTKView, NSView, NSViewType, ViewRepresentable

### Community 54 - "HittableView"
Cohesion: 0.21
Nodes (5): HittableView, Bool, Float, float2, Void

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
Nodes (15): Demo, animation, conditional, .id, image, layout, list, text (+7 more)

### Community 62 - "float4x4"
Cohesion: 0.15
Nodes (11): matrix_double4x4, float3x3, Float, float4x4, .formated, .identity, .upperLeft, Bool (+3 more)

### Community 63 - "Array"
Cohesion: 0.33
Nodes (4): Array, .byteCount, Element, Void

### Community 65 - "Shaders/Shaders.metal"
Cohesion: 0.10
Nodes (22): metal_stdlib, Circle, color, depth, position, radius, GridArgBuffer, GridCell (+14 more)

### Community 66 - "ImageManager"
Cohesion: 0.18
Nodes (10): CGFloat, ImageManager, ImageQuad, .bounds, PendingUpload, MTLBuffer, MTLCommandBuffer, MTLDevice (+2 more)

### Community 67 - "Comparable Clamp"
Cohesion: 0.40
Nodes (3): Comparable, ClosedRange, Self

### Community 73 - ".draw"
Cohesion: 0.26
Nodes (5): Circle, Line, float2, EffectState, Square

### Community 74 - "FontManager"
Cohesion: 0.32
Nodes (7): CGGlyph, CTFont, Hashable, FontManager, GlyphKey, GlyphMetrics, Float

### Community 75 - "TextDemo"
Cohesion: 0.53
Nodes (3): Float, TextDemo, .body

### Community 76 - "1. The pieces"
Cohesion: 0.14
Nodes (12): 1. The pieces, 2. What a component looks like, 3. What gets generated, 4. Rules that follow, 5. Collections are just `@State` arrays, 6. Composition, not helper methods, 8. How it lands on screen, Compile-time state in RetainedModeUI (+4 more)

### Community 77 - "BitmapTexture"
Cohesion: 0.24
Nodes (9): CGContext, BitmapTexture, float2, MTLTexture, Void, Content, bitmap, missing (+1 more)

### Community 78 - "EmptyElement"
Cohesion: 0.25
Nodes (3): EmptyElement, LeafElement, Spacer

### Community 79 - "ImageQuad"
Cohesion: 0.18
Nodes (11): ImageQuad, depth, flags, lod, position, size, textureIndex, tint (+3 more)

### Community 80 - "ViewItem"
Cohesion: 0.22
Nodes (11): HStack, .size, IMView, Float, HorizontalAlignment, Self, VerticalAlignment, Void (+3 more)

### Community 81 - "MetalKit"
Cohesion: 0.18
Nodes (7): App, Combine, GPURayMarchingApp, MetalGraphicsLib, MetalKit, ReactiveUI, Scene

### Community 82 - "UIElement"
Cohesion: 0.12
Nodes (10): 7. Diagnostics, Self, Bool, float2, Void, UIElement, .hasEffect, .localEffect (+2 more)

### Community 83 - "EffectElement"
Cohesion: 0.24
Nodes (6): EffectElement, .hasEffect, .localEffect, Bool, Float, float2

### Community 84 - "MultiChildElement"
Cohesion: 0.26
Nodes (5): Sliding layout, MultiChildElement, .liveChildrenCount, float2, Void

### Community 85 - "ListRows"
Cohesion: 0.44
Nodes (3): ListRows, T, Void

### Community 86 - "uchar4"
Cohesion: 0.25
Nodes (6): UInt8, uchar4, .a, .b, .g, .r

### Community 87 - "ConditionalDemo"
Cohesion: 0.39
Nodes (4): ConditionalDemo, .body, Bool, Float

### Community 88 - "SingleChildElement"
Cohesion: 0.24
Nodes (3): SingleChildElement, float2, Void

### Community 89 - "Inset"
Cohesion: 0.13
Nodes (13): IMView, Padding, Float, Self, Void, .packed, Padding, Inset (+5 more)

### Community 90 - "SDFBakeParams"
Cohesion: 0.20
Nodes (10): uint2, SDFBakeParams, emPerTexel, emTopLeft, origin, pathElementCount, shapeEnd, shapeStart (+2 more)

### Community 92 - "MouseOver"
Cohesion: 0.35
Nodes (6): IMView, MouseOver, Bool, Float, Self, Void

### Community 93 - "StepIterator"
Cohesion: 0.27
Nodes (6): IteratorProtocol, StepIterator, StepSequence, Bool, Float, Sequence

### Community 94 - "Background"
Cohesion: 0.20
Nodes (7): IMView, Background, IMView, Float, Self, Void, IMGameView

### Community 95 - ".texture"
Cohesion: 0.25
Nodes (6): CGImage, Bundle, Float, NSImage, Bundle, NSImage

### Community 96 - "Graphics2D.swift"
Cohesion: 0.33
Nodes (6): DebugData, SceneData, ShapeArgBuffer, Bool, Int32, UInt64

### Community 97 - "ContentView"
Cohesion: 0.25
Nodes (5): ContentView, .body, .body, MTKView, TestViewRenderer

### Community 98 - "IMView"
Cohesion: 0.39
Nodes (4): IMView, Spacer, Float, Void

### Community 99 - "Background"
Cohesion: 0.31
Nodes (3): Background, Float, float2

### Community 100 - "Padding"
Cohesion: 0.29
Nodes (3): Padding, Float, float2

### Community 101 - "AppKit"
Cohesion: 0.33
Nodes (4): AppKit, ContentMode, fill, fit

### Community 102 - "Square"
Cohesion: 0.33
Nodes (6): Square, color, depth, position, rotation, size

### Community 106 - "ShapeType2D"
Cohesion: 0.22
Nodes (8): Float, ShapeType2D, Circle, Glyph, Image, Line, Square, Shape

### Community 107 - "float2"
Cohesion: 0.18
Nodes (6): float2, .asInt2, .greatestComponent, .height, .width, Float

### Community 110 - ".expansion"
Cohesion: 0.20
Nodes (9): DeclGroupSyntax, ExtensionDeclSyntax, ExtensionMacro, MemberMacro, ComponentMacro, AttributeSyntax, DeclSyntax, TypeSyntax (+1 more)

## Knowledge Gaps
- **258 isolated node(s):** `conditional`, `list`, `text`, `layout`, `image` (+253 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 597 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **9 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `String` connect `String` to `Input`, `Text`, `DiagnosticsTests`, `int2`, `CodeGen`, `SVGParser`, `UIAnimation`, `IMView`, `.expansion`, `IMView`, `BodyParser`, `SDFPathBuilder`, `Image`, `WindowState`, `Drag`, `ModifierSpec`, `.scan`, `Kind`, `LayoutDemo`, `float4`, `Rect`, `StateProperty`, `simd`, `SVGIcon`, `HStack`, `VStack`, `AnimationDemo`, `ListDemo`, `Rectangle`, `main.swift`, `Demo`, `float4x4`, `ImageManager`, `.draw`, `FontManager`, `TextDemo`, `ViewItem`, `UIElement`, `EffectElement`, `SingleChildElement`, `Inset`, `MouseOver`, `Background`, `.texture`, `IMView`, `Background`, `Padding`?**
  _High betweenness centrality (0.296) - this node is a cross-community bridge._
- **Why does `Int` connect `Int` to `int2`, `Animator`, `MathLib.swift`, `IMView`, `BodyParser`, `SDFPathBuilder`, `WindowState`, `Graphics2D`, `String`, `View`, `ModifierSpec`, `UIContext`, `Sendable`, `Kind`, `LayoutDemo`, `HList`, `GraphicsGrid2D`, `VList`, `AnimationDemo`, `ListDemo`, `main.swift`, `Array`, `ImageManager`, `TextDemo`, `BitmapTexture`, `ViewItem`, `MultiChildElement`, `ListRows`, `ConditionalDemo`?**
  _High betweenness centrality (0.143) - this node is a cross-community bridge._
- **Why does `float4` connect `float4` to `Text`, `BoundingBox2D`, `SVGParser`, `UIAnimation`, `Image`, `LayoutDemo`, `float3`, `Rect`, `SVGIcon`, `AnimationDemo`, `ListDemo`, `Demo`, `float4x4`, `ImageManager`, `.draw`, `TextDemo`, `uchar4`, `ConditionalDemo`, `Background`?**
  _High betweenness centrality (0.102) - this node is a cross-community bridge._
- **Are the 5 inferred relationships involving `UIContext` (e.g. with `Effects and transitions` and `HittableGrid2D`) actually correct?**
  _`UIContext` has 5 INFERRED edges - model-reasoned connections that need verification._
- **Are the 4 inferred relationships involving `UIElement` (e.g. with `7. Diagnostics` and `.dropLeaving()`) actually correct?**
  _`UIElement` has 4 INFERRED edges - model-reasoned connections that need verification._
- **What connects `conditional`, `list`, `text` to the rest of the system?**
  _258 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Input` be split into smaller, more focused modules?**
  _Cohesion score 0.11396011396011396 - nodes in this community are weakly interconnected._