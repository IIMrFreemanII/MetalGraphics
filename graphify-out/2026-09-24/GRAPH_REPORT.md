# Graph Report - MetalGraphics  (2026-09-24)

## Corpus Check
- 191 files · ~137,383 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 15 file(s) not represented in the graph (top: (none) 4, .plist 3, .resolved 2)

## Summary
- 2977 nodes · 7619 edges · 160 communities (144 shown, 16 thin omitted)
- Extraction: 91% EXTRACTED · 9% INFERRED · 0% AMBIGUOUS · INFERRED: 657 edges (avg confidence: 0.84)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `fa00f9f7`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- UIElementWrapping
- Input
- Text
- SparseSet
- IMView
- DiagnosticsTests
- Hittable
- AnimatedProperty
- Ray-Marching Shader
- SIMD2
- CodeGen
- SingleChildElement
- GlyphSDF.metal
- MathLib.swift
- UIAnimation
- IMView
- MyMTKView
- Alignment
- Axis
- ModifierSpec
- VectorShape
- LayoutSubviews
- WindowState
- .draw
- String
- View
- BorderElement
- ScrollView
- ViewRenderer
- UIContext
- SDF.metal
- .expansion
- Float
- Inset
- Set
- EffectElement
- LayoutDemo
- VectorBaker
- SVGParser
- Graphics2D
- Math.metal
- BoundingBox3D
- bakeVectorSDF
- compute2D
- StateProperty
- simd
- SceneData
- SDFPathBuilder
- Rect
- PathBuilder
- HStack
- IDElement
- AnimationDemo
- MetalViewRepresentable
- Image
- ListDemo
- Float
- StackElement
- uidrive/main.swift
- SDF.swift
- Glyph
- Demo
- float4x4
- Array
- CLAUDE.md
- Shaders/Shaders.metal
- GeometryChangeElement
- Comparable Clamp
- ClipRect
- Macro Package Manifest
- Line
- OverlayElement
- Padding
- TransitionElement
- Frame
- Int
- Square
- IMView
- MetalGraphicsLib
- VectorCanvas
- BoundingBox2D
- UIElement
- UIShape
- Divider
- ScrollRow
- AlignmentKey
- Path
- layoutchecks/main.swift
- SVGIcon
- MouseOver
- VectorSegment
- ViewItem
- VectorItem
- Graphics2D.swift
- HList
- IMView
- Background
- View
- float3
- VectorItem
- LazyStack
- HittableView
- float2
- GraphicsGrid2D
- T
- Rectangle
- SVGPathCommand
- ImageManager
- Void
- LazyGridElement
- float4
- Grid
- SDFBaker.swift
- LayoutView
- LayoutSubview
- TransitionState
- Naming
- ProposedSize
- MultiChildElement
- UIElement+ReactiveSetters.swift
- Clip
- .system
- ZStack
- MetalKit
- ContentMode
- SwiftSyntaxMacros
- oracle.swift
- Drag
- ConditionalDemo
- StepIterator
- BodyParser
- FlexFrame
- Glass
- AnimationMacroTests
- Spacer
- VList
- ComponentMacroTests
- ReactiveUIDiagnostic
- LayoutMacroTests
- StateMacroTests
- Plugin.swift
- TextDemo
- Input.swift
- .setLayout
- GridCell
- GlassPass
- Float
- ListMacroTests
- .addClip
- Performance in MetalGraphics
- ClipElement
- Line
- .init
- Interpolation
- Circle
- Shape
- content

## God Nodes (most connected - your core abstractions)
1. `UIContext` - 227 edges
2. `UIElement` - 208 edges
3. `UIAnimation` - 144 edges
4. `ProposedSize` - 126 edges
5. `float4` - 89 edges
6. `Graphics2D` - 86 edges
7. `SIMD2` - 57 edges
8. `simd` - 56 edges
9. `Inset` - 53 edges
10. `Input` - 52 edges

## Surprising Connections (you probably didn't know these)
- `7. Measure, don't guess` --references--> `ScrollDemo`  [INFERRED]
  .claude/skills/performance/SKILL.md → GPURayMarching/ScrollDemo.swift
- `6. Lists and scrolling` --references--> `ListRows`  [INFERRED]
  .claude/skills/performance/SKILL.md → MetalGraphicsLib/RetainedModeUI/Layout/ListRows.swift
- `Scopes` --references--> `ElementCatalog`  [INFERRED]
  MetalGraphicsLib/docs/CompileTimeState.md → ReactiveUIMacros/Sources/ReactiveUIMacrosPlugin/ElementCatalog.swift
- `5. Collections are just `@State` arrays` --references--> `DemoItem`  [INFERRED]
  MetalGraphicsLib/docs/CompileTimeState.md → GPURayMarching/ListDemo.swift
- `8. How it lands on screen` --references--> `TestViewRenderer`  [INFERRED]
  MetalGraphicsLib/docs/CompileTimeState.md → GPURayMarching/TestViewRenderer.swift

## Import Cycles
- None detected.

## Communities (160 total, 16 thin omitted)

### Community 0 - "UIElementWrapping"
Cohesion: 0.16
Nodes (6): Float, float2, HorizontalAlignment, Self, VerticalAlignment, UIElementWrapping

### Community 1 - "Input"
Cohesion: 0.10
Nodes (12): Input, .mouseDown, .mouseMoved, .mousePressed, .mouseUp, Bool, Double, NSEvent (+4 more)

### Community 2 - "Text"
Cohesion: 0.07
Nodes (34): CGGlyph, CoreText, CTFont, FontManager, GlyphKey, GlyphMetrics, SDFFont, Float (+26 more)

### Community 3 - "SparseSet"
Cohesion: 0.18
Nodes (8): AnyIterator, SparseSet, .count, .isEmpty, .storedKeys, .values, Bool, Element

### Community 4 - "IMView"
Cohesion: 0.25
Nodes (9): ExpandedFrame, FlexFrame, Frame, IMView, Alignment, Float, float2, Self (+1 more)

### Community 5 - "DiagnosticsTests"
Cohesion: 0.26
Nodes (3): component(), DiagnosticsTests, stubsOnly()

### Community 6 - "Hittable"
Cohesion: 0.07
Nodes (29): AnyObject, DispatchQueue, DispatchWorkItem, HittableGrid2D, HittableGridCell, HoveredView, Bool, Float (+21 more)

### Community 7 - "AnimatedProperty"
Cohesion: 0.05
Nodes (50): Apply, 9. Animation, Costs to know, Repeat and keyframes, Scopes, The runtime, `withAnimation`, AnimatedProperty (+42 more)

### Community 8 - "Ray-Marching Shader"
Cohesion: 0.08
Nodes (29): Camera, fov, position, rotation, compute(), distanceToScene(), GridArgBuffer, GridItem (+21 more)

### Community 9 - "SIMD2"
Cohesion: 0.31
Nodes (8): Float, .packed, SIMD2, .packed, SIMD4, .packed, Float, UIAnimatable

### Community 10 - "CodeGen"
Cohesion: 0.15
Nodes (15): CodeGen, .armedHandlers, Dependents, RowsMode, full, insert, remove, Bool (+7 more)

### Community 11 - "SingleChildElement"
Cohesion: 0.17
Nodes (5): EmptyElement, SingleChildElement, Float, float2, Void

### Community 12 - "GlyphSDF.metal"
Cohesion: 0.09
Nodes (34): bakeSDF(), lineWinding(), constant, float2, kernel, texture2d, uint, uint2 (+26 more)

### Community 13 - "MathLib.swift"
Cohesion: 0.18
Nodes (17): int3, dragDirection(), from1DTo3DArray(), from2DTo1DArray(), from3DTo1DArray(), fromPixelCoordToGridIndex(), fromWorldPositionToGridIndex(), lerp() (+9 more)

### Community 14 - "UIAnimation"
Cohesion: 0.07
Nodes (13): UIAnimation, FlexFrame, Frame, HStack, Alignment, Float, float2, GridItem (+5 more)

### Community 15 - "IMView"
Cohesion: 0.12
Nodes (17): ExpandedFrame, IMView, Background, FlexFrame, Float, float2, Frame, HStack (+9 more)

### Community 16 - "MyMTKView"
Cohesion: 0.18
Nodes (7): Modifier, MyMTKView, .acceptsFirstResponder, Bool, NSEvent, UInt, MTKView

### Community 17 - "Alignment"
Cohesion: 0.27
Nodes (8): Alignment, .offset, HorizontalAlignment, IMView, Float, float2, Self, VerticalAlignment

### Community 18 - "Axis"
Cohesion: 0.07
Nodes (22): ExpressibleByArrayLiteral, FlexFrame, Axis, .inverted, .size, IMView, Float, float2 (+14 more)

### Community 19 - "ModifierSpec"
Cohesion: 0.18
Nodes (15): ArgCombine, construct, float2, identity, labeled, ArgSpec, Arity, leaf (+7 more)

### Community 20 - "VectorShape"
Cohesion: 0.09
Nodes (24): Text styling, Capsule, Circle, .length, .localBounds, Ellipse, .length, .localBounds (+16 more)

### Community 21 - "LayoutSubviews"
Cohesion: 0.16
Nodes (11): Cache, AnyLayoutBox, Layout, LayoutBox, LayoutSubviews, .endIndex, .startIndex, L (+3 more)

### Community 22 - "WindowState"
Cohesion: 0.15
Nodes (13): CaseIterable, Application, Event, Inspector, Navigation, Global, Reload, Bool (+5 more)

### Community 23 - ".draw"
Cohesion: 0.25
Nodes (6): ImageQuad, GlassPass, float2, Int32, UInt32, VectorItem

### Community 24 - "String"
Cohesion: 0.18
Nodes (4): String, .uint32, UInt32, FunctionCallExprSyntax

### Community 25 - "View"
Cohesion: 0.18
Nodes (11): .inspectorView, Inspector, .body, Navigation, .body, ToggleView, .body, Number2Field (+3 more)

### Community 26 - "BorderElement"
Cohesion: 0.16
Nodes (8): BorderElement, .color, .lineWidth, .shape, BorderLayer, Float, float2, Void

### Community 27 - "ScrollView"
Cohesion: 0.08
Nodes (18): Bool, LazyStackViewport, ScrollIndicator, .visibility, ScrollIndicatorVisibility, automatic, hidden, never (+10 more)

### Community 28 - "ViewRenderer"
Cohesion: 0.13
Nodes (14): MetalView, .body, CGSize, Double, Float, float2, MTKView, View (+6 more)

### Community 29 - "UIContext"
Cohesion: 0.09
Nodes (4): Float, ObjectIdentifier, UIContext, Void

### Community 30 - "SDF.metal"
Cohesion: 0.14
Nodes (12): dot2(), float2, sdBox(), sdBoxSquared(), sdCircle(), sdCircleSquared(), sdOrientedBox(), sdRoundedBoxSquared() (+4 more)

### Community 31 - ".expansion"
Cohesion: 0.09
Nodes (15): AccessorDeclSyntax, AccessorMacro, DeclReferenceExprSyntax, DeclSyntaxProtocol, MemberAccessExprSyntax, PeerMacro, StateRewriter, ClosureExprSyntax (+7 more)

### Community 32 - "Float"
Cohesion: 0.09
Nodes (20): Any, Curve, easeIn, easeInOut, easeOut, keyframes, linear, spring (+12 more)

### Community 33 - "Inset"
Cohesion: 0.12
Nodes (14): IMView, Padding, Float, Self, Void, .packed, Padding, Edge (+6 more)

### Community 34 - "Set"
Cohesion: 0.11
Nodes (27): Set, UInt8, OptionSet, Owner, component, node, AnimationScope, Attach (+19 more)

### Community 35 - "EffectElement"
Cohesion: 0.16
Nodes (10): BlurElement, EffectElement, .hasEffect, .localEffect, ShadowState, .margin, Bool, Float (+2 more)

### Community 36 - "LayoutDemo"
Cohesion: 0.22
Nodes (7): LayoutDemo, .body, Alignment, Float, float2, HorizontalAlignment, VerticalAlignment

### Community 37 - "VectorBaker"
Cohesion: 0.11
Nodes (20): BakedRegion, DynamicSDFAtlas, .maxTileSize, Mode, fillEvenOdd, fillNonZero, stroke, SDFSlot (+12 more)

### Community 38 - "SVGParser"
Cohesion: 0.17
Nodes (14): SVGDocument, SVGPaint, color, currentColor, none, SVGParser, SVGShape, SVGStyle (+6 more)

### Community 39 - "Graphics2D"
Cohesion: 0.12
Nodes (16): Glyph, Line, Graphics2D, .glassAtlasWidth, .size, MTKView, MTLBuffer, MTLComputePipelineState (+8 more)

### Community 40 - "Math.metal"
Cohesion: 0.21
Nodes (10): cross2d(), float2, ndot(), normalize(), remap(), rotation(), rotationX(), rotationY() (+2 more)

### Community 41 - "BoundingBox3D"
Cohesion: 0.15
Nodes (13): BoundingBox3D, .back, .bottom, .bottomRightBack, .depth, .front, .height, .left (+5 more)

### Community 42 - "bakeVectorSDF"
Cohesion: 0.14
Nodes (25): bakeVectorSDF(), closestOnLine(), closestOnQuadratic(), isInside(), lineCrossing(), constant, float2, kernel (+17 more)

### Community 43 - "compute2D"
Cohesion: 0.35
Nodes (11): backdrop2D(), compute2D(), glassBlur(), constant, kernel, texture2d, uint2, write (+3 more)

### Community 44 - "StateProperty"
Cohesion: 0.18
Nodes (11): PatternBindingSyntax, .states, .reactiveNames, .stateNames, StateProperty, AttributeSyntax, Bool, MemberBlockItemListSyntax (+3 more)

### Community 45 - "simd"
Cohesion: 0.09
Nodes (14): Number3Field, .body, SIMD3, T, Number4Field, .body, T, NumberField (+6 more)

### Community 46 - "SceneData"
Cohesion: 0.29
Nodes (7): DebugData, drawGrid, showFilledCells, SceneData, debug, time, windowSize

### Community 47 - "SDFPathBuilder"
Cohesion: 0.21
Nodes (12): CGPath, PathElement, SDFPathBuilder, .isEmpty, Bool, float2, UInt8, CGRect (+4 more)

### Community 48 - "Rect"
Cohesion: 0.16
Nodes (10): Rect, .center, .height, .maxX, .maxY, .minX, .minY, .width (+2 more)

### Community 49 - "PathBuilder"
Cohesion: 0.17
Nodes (10): PathBuilder, PathMorph, Bool, Double, Float, float2, VectorSegment, VectorGeometry (+2 more)

### Community 50 - "HStack"
Cohesion: 0.33
Nodes (4): HStack, .crossKey, Float, VerticalAlignment

### Community 51 - "IDElement"
Cohesion: 0.11
Nodes (13): AnyHashable, ID, IDElement, ScrollViewProxy, ScrollViewReader, Alignment, float2, Void (+5 more)

### Community 52 - "AnimationDemo"
Cohesion: 0.24
Nodes (7): AnimatedItem, AnimationDemo, .body, Bool, Float, Identifiable, Row

### Community 53 - "MetalViewRepresentable"
Cohesion: 0.29
Nodes (6): Context, MetalViewRepresentable, MTKView, NSView, NSViewType, ViewRepresentable

### Community 54 - "Image"
Cohesion: 0.18
Nodes (8): Image, .naturalSize, Float, float2, Self, TemplateRenderingMode, original, template

### Community 55 - "ListDemo"
Cohesion: 0.21
Nodes (11): ChipView, .body, DemoItem, ListDemo, .body, RowView, .body, Bool (+3 more)

### Community 56 - "Float"
Cohesion: 0.28
Nodes (6): Float, .degrees, .isNegative, .radians, Bool, ClosedRange

### Community 57 - "StackElement"
Cohesion: 0.25
Nodes (8): origin, StackElement, .crossKey, .size, Bool, Float, float2, Void

### Community 58 - "uidrive/main.swift"
Cohesion: 0.10
Nodes (35): ArraySlice, CGEventFlags, CGEventType, CGKeyCode, CGMouseButton, CGWindowID, 1. Build and launch, 2. Compile the driver (+27 more)

### Community 59 - "SDF.swift"
Cohesion: 0.27
Nodes (14): clamp(), T, closestPointToSDBox(), pointInAABBox(), pointInAABBoxTopLeftOrigin(), sdBox(), sdBoxTopLeft(), sdCircle() (+6 more)

### Community 60 - "Glyph"
Cohesion: 0.22
Nodes (9): Glyph, blur, color, depth, fontSize, position, size, uvMax (+1 more)

### Community 61 - "Demo"
Cohesion: 0.12
Nodes (18): Demo, animation, conditional, containers, glass, grids, .id, image (+10 more)

### Community 62 - "float4x4"
Cohesion: 0.14
Nodes (12): matrix_double4x4, float3x3, Float, float4x4, .formated, .identity, .upperLeft, Bool (+4 more)

### Community 63 - "Array"
Cohesion: 0.33
Nodes (4): Array, .byteCount, Element, Void

### Community 65 - "Shaders/Shaders.metal"
Cohesion: 0.16
Nodes (21): metal_stdlib, sdRoundedBox(), ellipseAlong(), GridArgBuffer, hash12(), device, float2, roundedBoxAlong() (+13 more)

### Community 66 - "GeometryChangeElement"
Cohesion: 0.13
Nodes (11): CoordinateSpace, global, local, GeometryChangeElement, GeometryProxy, GeometryReader, Float, float2 (+3 more)

### Community 67 - "Comparable Clamp"
Cohesion: 0.40
Nodes (3): Comparable, ClosedRange, Self

### Community 68 - "ClipRect"
Cohesion: 0.18
Nodes (5): EffectState, ClipRect, .isEmpty, .scrollableSize, Void

### Community 73 - "Line"
Cohesion: 0.33
Nodes (4): Line, .bounds, Float, float2

### Community 74 - "OverlayElement"
Cohesion: 0.14
Nodes (10): Alignment, Background, FlexFrame, Frame, OverlayElement, .alignment, Alignment, Bool (+2 more)

### Community 75 - "Padding"
Cohesion: 0.24
Nodes (4): Padding, Float, float2, float2

### Community 76 - "TransitionElement"
Cohesion: 0.29
Nodes (6): 1. The pieces, Effects and transitions, Float, Void, TransitionElement, .currentState

### Community 77 - "Frame"
Cohesion: 0.29
Nodes (6): Frame, .size, Alignment, Float, float2, Void

### Community 78 - "Int"
Cohesion: 0.17
Nodes (11): StressCell, .body, StressIndex, StressRow, .body, Bool, VectorDemo, .body (+3 more)

### Community 79 - "Square"
Cohesion: 0.33
Nodes (4): Square, .bounds, Float, float2

### Community 80 - "IMView"
Cohesion: 0.23
Nodes (10): HStack, .size, IMView, Float, HorizontalAlignment, Self, VerticalAlignment, Void (+2 more)

### Community 82 - "VectorCanvas"
Cohesion: 0.24
Nodes (6): Float, float2, Self, VectorCanvas, .children, VectorShapeList

### Community 83 - "BoundingBox2D"
Cohesion: 0.15
Nodes (12): BoundingBox2D, .bottom, .bottomRight, .height, .left, .right, .top, .topLeft (+4 more)

### Community 84 - "UIElement"
Cohesion: 0.07
Nodes (24): 7. Diagnostics, LayoutPass, LayoutTraits, Alignment, Bool, Float, float2, UInt32 (+16 more)

### Community 85 - "UIShape"
Cohesion: 0.20
Nodes (8): Kind, capsule, circle, rect, Bool, Float, UIShape, .isPlainRect

### Community 86 - "Divider"
Cohesion: 0.39
Nodes (3): Divider, Float, float2

### Community 87 - "ScrollRow"
Cohesion: 0.32
Nodes (9): LazyRowCounter, makeScrollToDemo(), ScrollDemo, .body, ScrollRow, .name, ScrollRowView, .body (+1 more)

### Community 88 - "AlignmentKey"
Cohesion: 0.09
Nodes (30): Equatable, Hashable, Hasher, Alignment, .offset, .xOffset, .yOffset, AlignmentID (+22 more)

### Community 89 - "Path"
Cohesion: 0.14
Nodes (15): Path, .isClosed, .length, .localBounds, Source, builder, commands, Bool (+7 more)

### Community 90 - "layoutchecks/main.swift"
Cohesion: 0.25
Nodes (6): check(), HorizontalAlignment, layout(), Mid, Float, float2

### Community 91 - "SVGIcon"
Cohesion: 0.18
Nodes (11): Layer, SVGIcon, Bool, Bundle, Data, Float, float2, Content (+3 more)

### Community 92 - "MouseOver"
Cohesion: 0.21
Nodes (8): IMView, IMGameView, IMView, MouseOver, Bool, Float, Self, Void

### Community 93 - "VectorSegment"
Cohesion: 0.22
Nodes (9): VectorSegment, a, b, boxMax, boxMin, c, isLine, padding (+1 more)

### Community 94 - "ViewItem"
Cohesion: 0.30
Nodes (6): Background, IMView, Float, Self, Void, ViewItem

### Community 95 - "VectorItem"
Cohesion: 0.19
Nodes (12): Kind, bakedFill, bakedStroke, ellipse, roundedBox, Float, float2, VectorItem (+4 more)

### Community 96 - "Graphics2D.swift"
Cohesion: 0.40
Nodes (5): DebugData, SceneData, ShapeArgBuffer, Bool, UInt64

### Community 97 - "HList"
Cohesion: 0.21
Nodes (9): HStack, 5. Collections are just `@State` arrays, Mutation carries the operation, The plain setter still works, HList, Float, T, VerticalAlignment (+1 more)

### Community 98 - "IMView"
Cohesion: 0.39
Nodes (4): IMView, Spacer, Float, Void

### Community 99 - "Background"
Cohesion: 0.23
Nodes (5): Background, GlassBackground, GlassMaterial, Float, float2

### Community 100 - "View"
Cohesion: 0.18
Nodes (11): Bool, View, Background, ExpandedFrame, FlexFrame, HStack, .isSpacer, MouseOver (+3 more)

### Community 101 - "float3"
Cohesion: 0.18
Nodes (9): float3, .depth, .height, .width, .xy, Float, float2, Double (+1 more)

### Community 102 - "VectorItem"
Cohesion: 0.09
Nodes (23): ImageQuad, depth, flags, lod, position, size, textureIndex, tint (+15 more)

### Community 103 - "LazyStack"
Cohesion: 0.17
Nodes (11): LazyStack, .crossAlignment, .defaultLength, .estimatedLength, .initialExtent, .overscan, Bool, ClosedRange (+3 more)

### Community 104 - "HittableView"
Cohesion: 0.16
Nodes (9): Bool, Void, HittableView, .hitPosition, .hitSize, Bool, Float, float2 (+1 more)

### Community 105 - "float2"
Cohesion: 0.18
Nodes (6): AspectRatioElement, FixedSizeElement, PositionElement, Bool, Float, float2

### Community 106 - "GraphicsGrid2D"
Cohesion: 0.12
Nodes (19): Int32, GPUDevice, MTLDevice, GraphicsGrid2D, GridArgBuffer, GridCell, Shape, ShapeType2D (+11 more)

### Community 107 - "T"
Cohesion: 0.20
Nodes (9): LazyHStack, .crossAlignment, LazyVStack, .crossAlignment, Float, HorizontalAlignment, T, VerticalAlignment (+1 more)

### Community 108 - "Rectangle"
Cohesion: 0.29
Nodes (3): Rectangle, Float, float2

### Community 109 - "SVGPathCommand"
Cohesion: 0.09
Nodes (17): Foundation, SVGPathCommand, close, cubic, line, move, quad, SVGPathData (+9 more)

### Community 110 - "ImageManager"
Cohesion: 0.12
Nodes (19): CGContext, CGImage, 4. GPU and Metal (`Graphics2D.swift`, `Shaders/Shaders.metal`), BitmapTexture, ImageManager, ImageQuad, .bounds, PendingUpload (+11 more)

### Community 111 - "Void"
Cohesion: 0.10
Nodes (18): 1. The frame, 3. Hot paths — per frame, or per element per frame, 2. What a component looks like, 3. What gets generated, 4. Rules that follow, 6. Composition, not helper methods, 8. How it lands on screen, Compile-time state in RetainedModeUI (+10 more)

### Community 112 - "LazyGridElement"
Cohesion: 0.14
Nodes (20): GridItem, LazyGridElement, .defaultCellAlignment, .trackAlignment, LazyHGrid, .defaultCellAlignment, .trackAlignment, LazyVGrid (+12 more)

### Community 113 - "float4"
Cohesion: 0.14
Nodes (10): Float, float2, float4, .xyz, UInt8, uchar4, .a, .b (+2 more)

### Community 114 - "Grid"
Cohesion: 0.18
Nodes (9): Grid, GridCellOptions, GridRow, Alignment, Bool, Float, float2, HorizontalAlignment (+1 more)

### Community 115 - "SDFBaker.swift"
Cohesion: 0.14
Nodes (21): PendingBake, SDFAtlas, SDFBakeParams, SDFBaker, SDFRegion, SDFShape, SDFShapeGeometry, SDFShapeMode (+13 more)

### Community 116 - "LayoutView"
Cohesion: 0.18
Nodes (5): AnyLayout, LayoutView, Alignment, float2, Void

### Community 117 - "LayoutSubview"
Cohesion: 0.16
Nodes (9): HStackLayout, LayoutSubview, .priority, Float, HorizontalAlignment, HStack, VerticalAlignment, VStack (+1 more)

### Community 118 - "TransitionState"
Cohesion: 0.23
Nodes (4): Float, float2, TransitionState, UITransition

### Community 119 - "Naming"
Cohesion: 0.13
Nodes (10): DeclGroupSyntax, ExtensionDeclSyntax, ExtensionMacro, MemberMacro, ComponentMacro, AttributeSyntax, DeclSyntax, TypeSyntax (+2 more)

### Community 120 - "ProposedSize"
Cohesion: 0.18
Nodes (11): benchmark(), Bool, Void, MeasureCache, ProposedSize, Float, float2, UInt32 (+3 more)

### Community 121 - "MultiChildElement"
Cohesion: 0.16
Nodes (7): MultiChildElement, .liveChildrenCount, float2, Void, ListRows, T, Void

### Community 122 - "UIElement+ReactiveSetters.swift"
Cohesion: 0.17
Nodes (7): Sliding layout, Background, Circle, ExpandedFrame, Padding, Spacer, Text

### Community 123 - "Clip"
Cohesion: 0.25
Nodes (8): Clip, blur, bounds, padding1, padding2, radii, rect, rounded

### Community 124 - ".system"
Cohesion: 0.13
Nodes (18): ContainersDemo, .body, Alignment, Bool, Float, GlassDemo, .body, Bool (+10 more)

### Community 125 - "ZStack"
Cohesion: 0.23
Nodes (6): Alignment, Bool, Float, float2, Void, ZStack

### Community 126 - "MetalKit"
Cohesion: 0.13
Nodes (11): App, Combine, ContentView, .body, GPURayMarchingApp, .body, MTKView, TestViewRenderer (+3 more)

### Community 127 - "ContentMode"
Cohesion: 0.33
Nodes (4): AppKit, ContentMode, fill, fit

### Community 128 - "SwiftSyntaxMacros"
Cohesion: 0.42
Nodes (5): ReactiveUIMacrosPlugin, SwiftSyntaxMacroExpansion, SwiftSyntaxMacros, SwiftSyntaxMacrosGenericTestSupport, Testing

### Community 129 - "oracle.swift"
Cohesion: 0.25
Nodes (7): HorizontalAlignment, Probe, .body, render(), CGSize, V, View

### Community 130 - "Drag"
Cohesion: 0.16
Nodes (7): CustomStringConvertible, Drag, .description, Float, float2, UInt32, Void

### Community 131 - "ConditionalDemo"
Cohesion: 0.43
Nodes (4): ConditionalDemo, .body, Bool, Float

### Community 132 - "StepIterator"
Cohesion: 0.24
Nodes (6): IteratorProtocol, StepIterator, StepSequence, Bool, Float, Sequence

### Community 133 - "BodyParser"
Cohesion: 0.14
Nodes (13): CodeBlockItemListSyntax, IfExprSyntax, BodyParser, Bool, ClosureExprSyntax, ExprSyntax, FunctionCallExprSyntax, MemberBlockItemListSyntax (+5 more)

### Community 134 - "FlexFrame"
Cohesion: 0.34
Nodes (4): FlexFrame, Alignment, Float, float2

### Community 135 - "Glass"
Cohesion: 0.15
Nodes (13): Glass, depth, noise, opacity, padding, pointsPerTexel, radii, rect (+5 more)

### Community 137 - "Spacer"
Cohesion: 0.31
Nodes (4): LeafElement, Spacer, Float, float2

### Community 138 - "VList"
Cohesion: 0.29
Nodes (6): Float, HorizontalAlignment, T, Void, VList, VStack

### Community 140 - "ReactiveUIDiagnostic"
Cohesion: 0.24
Nodes (7): DiagnosticMessage, DiagnosticSeverity, FixItMessage, MessageID, ReactiveUIDiagnostic, ReactiveUIFixIt, SwiftDiagnostics

### Community 143 - "Plugin.swift"
Cohesion: 0.40
Nodes (4): CompilerPlugin, ReactiveUIMacrosPlugin, Macro, SwiftCompilerPlugin

### Community 144 - "TextDemo"
Cohesion: 0.53
Nodes (3): Float, TextDemo, .body

### Community 147 - "GridCell"
Cohesion: 0.20
Nodes (6): GridCell, count, startIndex, from2DTo1DArray(), isBetween(), thread

### Community 148 - "GlassPass"
Cohesion: 0.22
Nodes (9): GlassPass, atlasOrigin, direction, maxDepth, padding, pointsPerTexel, sceneOrigin, sigma (+1 more)

### Community 149 - "Float"
Cohesion: 0.24
Nodes (5): GlassItem, GPUClip, Float, Circle2D, .bounds

### Community 152 - "Performance in MetalGraphics"
Cohesion: 0.29
Nodes (6): 2. Invalidation — name the narrowest effect, 5. Layout and text, 6. Lists and scrolling, 7. Measure, don't guess, 8. Before finishing, Performance in MetalGraphics

### Community 153 - "ClipElement"
Cohesion: 0.33
Nodes (3): ClipElement, .clipCornerRadii, .clipRect

### Community 154 - "Line"
Cohesion: 0.33
Nodes (6): Line, color, depth, end, start, thickness

### Community 156 - "Interpolation"
Cohesion: 0.40
Nodes (5): Interpolation, high, low, medium, none

### Community 157 - "Circle"
Cohesion: 0.40
Nodes (5): Circle, color, depth, position, radius

### Community 158 - "Shape"
Cohesion: 0.40
Nodes (5): Shape, clip, depth, index, shapeType

## Knowledge Gaps
- **438 isolated node(s):** `conditional`, `list`, `text`, `layout`, `image` (+433 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 832 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **16 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `String` connect `String` to `Input`, `Text`, `ConditionalDemo`, `IMView`, `Drag`, `FlexFrame`, `Hittable`, `BodyParser`, `AnimationMacroTests`, `CodeGen`, `SingleChildElement`, `ReactiveUIDiagnostic`, `DiagnosticsTests`, `UIAnimation`, `IMView`, `TextDemo`, `oracle.swift`, `ModifierSpec`, `WindowState`, `.draw`, `View`, `BorderElement`, `.init`, `ScrollView`, `.expansion`, `Inset`, `Set`, `LayoutDemo`, `SVGParser`, `Graphics2D`, `StateProperty`, `simd`, `HStack`, `IDElement`, `AnimationDemo`, `Image`, `ListDemo`, `uidrive/main.swift`, `Demo`, `float4x4`, `OverlayElement`, `Padding`, `Frame`, `IMView`, `VectorCanvas`, `UIElement`, `ScrollRow`, `Path`, `layoutchecks/main.swift`, `SVGIcon`, `MouseOver`, `ViewItem`, `IMView`, `Background`, `Rectangle`, `SVGPathCommand`, `ImageManager`, `SDFBaker.swift`, `Naming`, `ProposedSize`, `MultiChildElement`, `UIElement+ReactiveSetters.swift`, `.system`, `ZStack`?**
  _High betweenness centrality (0.259) - this node is a cross-community bridge._
- **Why does `Int` connect `Int` to `UIElementWrapping`, `ConditionalDemo`, `SparseSet`, `BodyParser`, `Hittable`, `AnimatedProperty`, `FlexFrame`, `VList`, `MathLib.swift`, `UIAnimation`, `IMView`, `TextDemo`, `ModifierSpec`, `Float`, `WindowState`, `.addClip`, `LayoutSubviews`, `UIContext`, `Float`, `Set`, `LayoutDemo`, `VectorBaker`, `Graphics2D`, `SDFPathBuilder`, `PathBuilder`, `AnimationDemo`, `ListDemo`, `StackElement`, `uidrive/main.swift`, `Array`, `UIElement`, `ScrollRow`, `AlignmentKey`, `ViewItem`, `HList`, `View`, `LazyStack`, `GraphicsGrid2D`, `T`, `ImageManager`, `Void`, `LazyGridElement`, `Grid`, `SDFBaker.swift`, `LayoutView`, `LayoutSubview`, `Naming`, `ProposedSize`, `MultiChildElement`, `.system`, `ZStack`?**
  _High betweenness centrality (0.148) - this node is a cross-community bridge._
- **Why does `UIContext` connect `UIContext` to `Hittable`, `AnimatedProperty`, `VList`, `UIAnimation`, `.setLayout`, `Axis`, `.addClip`, `BorderElement`, `ScrollView`, `ViewRenderer`, `EffectElement`, `VectorBaker`, `simd`, `IDElement`, `AnimationDemo`, `GeometryChangeElement`, `ClipRect`, `TransitionElement`, `Int`, `UIElement`, `HList`, `LazyStack`, `T`, `Void`, `float4`, `MultiChildElement`, `UIElement+ReactiveSetters.swift`, `.system`?**
  _High betweenness centrality (0.130) - this node is a cross-community bridge._
- **Are the 5 inferred relationships involving `UIContext` (e.g. with `Effects and transitions` and `HittableGrid2D`) actually correct?**
  _`UIContext` has 5 INFERRED edges - model-reasoned connections that need verification._
- **Are the 18 inferred relationships involving `UIElement` (e.g. with `7. Diagnostics` and `.dropLeaving()`) actually correct?**
  _`UIElement` has 18 INFERRED edges - model-reasoned connections that need verification._
- **What connects `conditional`, `list`, `text` to the rest of the system?**
  _438 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Input` be split into smaller, more focused modules?**
  _Cohesion score 0.10344827586206896 - nodes in this community are weakly interconnected._