# Graph Report - MetalGraphics  (2026-09-25)

## Corpus Check
- 222 files · ~169,418 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 15 file(s) not represented in the graph (top: (none) 4, .plist 3, .resolved 2)

## Summary
- 3707 nodes · 9815 edges · 198 communities (181 shown, 17 thin omitted)
- Extraction: 91% EXTRACTED · 9% INFERRED · 0% AMBIGUOUS · INFERRED: 853 edges (avg confidence: 0.83)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `fa00f9f7`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- UIElementWrapping
- Input
- Text
- UIAnimation
- IMView
- DiagnosticsTests
- .gpuClip
- AnimatedProperty
- GPURayMarching/Shaders.metal
- ViewItem
- CodeGen
- SingleChildElement
- GlyphSDF.metal
- MathLib.swift
- .invalidate
- IMView
- MyMTKView
- Alignment
- Grid
- ColorPicker
- VectorShape
- LayoutSubviews
- WindowState
- Float
- Naming
- View
- BorderElement
- ScrollView
- ViewRenderer
- KeyPress
- SDF.metal
- StateRewriter
- Sendable
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
- String
- SceneData
- ImageManager
- Rect
- ClipRect
- HStack
- IDElement
- AnimationDemo
- MetalViewRepresentable
- Table
- ListDemo
- Float
- StackElement
- uidrive/main.swift
- SDF.swift
- Glyph
- Demo
- float4x4
- Array
- UIStorage
- Shaders/Shaders.metal
- GeometryChangeElement
- Comparable Clamp
- LayoutView
- Macro Package Manifest
- UIElement+ReactiveSetters.swift
- OverlayElement
- UIContext
- Picker
- Frame
- Int
- Square
- SIMD2
- Slider
- VectorCanvas
- BoundingBox2D
- UIElement
- BitmapTexture
- Divider
- .system
- AlignmentKey
- Performance in MetalGraphics
- FocusableElement
- SVGIcon
- MouseOver
- HotReload
- MetalGraphicsLib
- VectorItem
- Graphics2D.swift
- HList
- IMView
- GlassMaterial
- Interpolation
- float3
- VectorItem
- LazyStack
- HittableView
- .content
- GraphicsGrid2D
- Utils.swift
- Rectangle
- SVGPathCommand
- Image
- Void
- LazyGridElement
- uchar4
- Padding
- SDFBaker.swift
- ArgSpec
- PathBuilder
- Axis
- SwiftSyntax
- layoutText
- MultiChildElement
- Content
- float2
- Animator
- SDFFont
- ProposedSize
- .init
- SwiftSyntaxMacros
- oracle.swift
- VectorDemo
- BodyParser
- StepIterator
- SDFPathBuilder
- FlexFrame
- Glass
- AnimationMacroTests
- DatePicker
- VList
- TextField
- Path
- LayoutMacroTests
- FieldBox
- Plugin.swift
- Section
- AnimationGroup
- Stepper
- GridCell
- GlassPass
- .drawData
- float2
- FileWatcher
- .body
- ViewThatFits
- TableColumn
- ZStack
- TableDemo
- TransitionElement
- Padding
- View
- Form
- .init
- ComponentMacroTests
- Toggle
- int2
- TableCell
- layoutchecks/main.swift
- UIShape
- Binding
- ScrollIndicator
- expand
- simd
- Spacer
- FormControl
- GeometryReader
- .replacingUnspecified
- Button
- TableColumnLayout
- LayoutBox
- Compile-time state in RetainedModeUI
- TextDemo
- ListMacroTests
- StateMacroTests
- Phases
- TemplateRenderingMode
- .readExactly
- .init
- VStack
- IMGameView
- 9. Animation
- .pressed
- .init
- .init
- .setAlignment
- ContentMode
- .sizeThatFits
- Result
- .setLayout

## God Nodes (most connected - your core abstractions)
1. `UIContext` - 330 edges
2. `UIElement` - 255 edges
3. `UIAnimation` - 192 edges
4. `ProposedSize` - 162 edges
5. `Graphics2D` - 111 edges
6. `simd` - 75 edges
7. `Inset` - 63 edges
8. `SingleChildElement` - 61 edges
9. `Input` - 57 edges
10. `SIMD2` - 57 edges

## Surprising Connections (you probably didn't know these)
- `6. Lists and scrolling` --references--> `ListRows`  [INFERRED]
  .claude/skills/performance/SKILL.md → MetalGraphicsLib/RetainedModeUI/Layout/ListRows.swift
- `Scopes` --references--> `ElementCatalog`  [INFERRED]
  MetalGraphicsLib/docs/CompileTimeState.md → ReactiveUIMacros/Sources/ReactiveUIMacrosPlugin/ElementCatalog.swift
- `Hot reload` --references--> `Demos`  [INFERRED]
  MetalGraphicsLib/docs/HotReload.md → GPURayMarching/Demos.swift
- `5. Collections are just `@State` arrays` --references--> `DemoItem`  [INFERRED]
  MetalGraphicsLib/docs/CompileTimeState.md → GPURayMarching/ListDemo.swift
- `7. Measure, don't guess` --references--> `ScrollDemo`  [INFERRED]
  .claude/skills/performance/SKILL.md → GPURayMarching/ScrollDemo.swift

## Import Cycles
- None detected.

## Communities (198 total, 17 thin omitted)

### Community 0 - "UIElementWrapping"
Cohesion: 0.10
Nodes (13): AnyObject, Alignment, Background, FlexFrame, Float, float2, float4, Frame (+5 more)

### Community 1 - "Input"
Cohesion: 0.07
Nodes (20): Carbon.HIToolbox, GameController, Drag, .description, Input, .mouseDown, .mouseMoved, .mousePressed (+12 more)

### Community 2 - "Text"
Cohesion: 0.17
Nodes (9): Float, float2, float4, Self, Text, .displayedColor, .displayedFontSize, .fontScale (+1 more)

### Community 3 - "UIAnimation"
Cohesion: 0.08
Nodes (14): Curve, easeIn, easeInOut, easeOut, keyframes, linear, spring, Bool (+6 more)

### Community 4 - "IMView"
Cohesion: 0.25
Nodes (9): ExpandedFrame, FlexFrame, Frame, IMView, Alignment, Float, float2, Self (+1 more)

### Community 5 - "DiagnosticsTests"
Cohesion: 0.26
Nodes (3): component(), DiagnosticsTests, stubsOnly()

### Community 7 - "AnimatedProperty"
Cohesion: 0.07
Nodes (29): AnimatedProperty, center, color, cornerRadius, fontSize, height, inset, keyframes (+21 more)

### Community 8 - "GPURayMarching/Shaders.metal"
Cohesion: 0.08
Nodes (30): Camera, fov, position, rotation, compute(), distanceToScene(), GridArgBuffer, GridItem (+22 more)

### Community 9 - "ViewItem"
Cohesion: 0.28
Nodes (7): Background, IMView, Float, float4, Self, Void, ViewItem

### Community 10 - "CodeGen"
Cohesion: 0.15
Nodes (15): CodeGen, .armedHandlers, Dependents, RowsMode, full, insert, remove, DeclSyntax (+7 more)

### Community 11 - "SingleChildElement"
Cohesion: 0.16
Nodes (5): EmptyElement, SingleChildElement, Float, float2, Void

### Community 12 - "GlyphSDF.metal"
Cohesion: 0.08
Nodes (35): What needs a relaunch, bakeSDF(), lineWinding(), constant, float2, kernel, texture2d, uint (+27 more)

### Community 13 - "MathLib.swift"
Cohesion: 0.22
Nodes (17): dragDirection(), from1DTo3DArray(), from2DTo1DArray(), from3DTo1DArray(), fromPixelCoordToGridIndex(), fromWorldPositionToGridIndex(), lerp(), mix() (+9 more)

### Community 14 - ".invalidate"
Cohesion: 0.07
Nodes (10): Circle, FlexFrame, Frame, Alignment, Bool, Float, float2, GridItem (+2 more)

### Community 15 - "IMView"
Cohesion: 0.12
Nodes (17): ExpandedFrame, IMView, Background, FlexFrame, Float, float2, Frame, HStack (+9 more)

### Community 16 - "MyMTKView"
Cohesion: 0.17
Nodes (8): Modifier, MyMTKView, .acceptsFirstResponder, Bool, NSEvent, UInt, UInt16, MTKView

### Community 17 - "Alignment"
Cohesion: 0.27
Nodes (8): Alignment, .offset, HorizontalAlignment, IMView, Float, float2, Self, VerticalAlignment

### Community 18 - "Grid"
Cohesion: 0.18
Nodes (9): Grid, GridCellOptions, GridRow, Alignment, Bool, Float, float2, HorizontalAlignment (+1 more)

### Community 19 - "ColorPicker"
Cohesion: 0.20
Nodes (12): ColorPicker, ColorSwatch, ColorWell, drawCheckerboard(), hsbFromRGB(), rgbFromHSB(), Bool, Float (+4 more)

### Community 20 - "VectorShape"
Cohesion: 0.08
Nodes (28): Text styling, float2x2, Float, Capsule, Circle, .length, .localBounds, Ellipse (+20 more)

### Community 21 - "LayoutSubviews"
Cohesion: 0.15
Nodes (13): HStackLayout, LayoutSubview, .priority, LayoutSubviews, .endIndex, .startIndex, Float, HorizontalAlignment (+5 more)

### Community 22 - "WindowState"
Cohesion: 0.15
Nodes (13): CaseIterable, Application, Event, Inspector, Navigation, Global, Reload, Bool (+5 more)

### Community 23 - "Float"
Cohesion: 0.16
Nodes (10): ImageQuad, GlassItem, GlassPass, GPUClip, Float, float2, float4, Int32 (+2 more)

### Community 24 - "Naming"
Cohesion: 0.12
Nodes (11): AccessorDeclSyntax, DeclGroupSyntax, DeclSyntaxProtocol, ExtensionDeclSyntax, AttributeSyntax, DeclSyntax, TypeSyntax, Naming (+3 more)

### Community 25 - "View"
Cohesion: 0.07
Nodes (30): App, Combine, ContentView, GPURayMarchingApp, .body, .inspectorView, Inspector, .body (+22 more)

### Community 26 - "BorderElement"
Cohesion: 0.16
Nodes (9): BorderElement, .color, .lineWidth, .shape, BorderLayer, Float, float2, float4 (+1 more)

### Community 27 - "ScrollView"
Cohesion: 0.16
Nodes (6): ScrollView, .clipRect, .contentOrigin, Alignment, float2, Void

### Community 28 - "ViewRenderer"
Cohesion: 0.12
Nodes (15): .body, MetalView, .body, CGSize, Double, Float, float2, MTKView (+7 more)

### Community 29 - "KeyPress"
Cohesion: 0.13
Nodes (13): CharacterSet, ExpressibleByExtendedGraphemeClusterLiteral, KeyboardDemo, .body, Bool, Float, float2, KeyEquivalent (+5 more)

### Community 30 - "SDF.metal"
Cohesion: 0.15
Nodes (15): dot2(), float2, float4, sdBox(), sdBoxSquared(), sdCircle(), sdCircleSquared(), sdOrientedBox() (+7 more)

### Community 31 - "StateRewriter"
Cohesion: 0.22
Nodes (7): DeclReferenceExprSyntax, MemberAccessExprSyntax, StateRewriter, ClosureExprSyntax, ExprSyntax, SyntaxProtocol, SyntaxRewriter

### Community 32 - "Sendable"
Cohesion: 0.10
Nodes (15): Any, KeyframeElement, KeyframeSegment, Float, float2, Self, V, UIKeyframe (+7 more)

### Community 33 - "Inset"
Cohesion: 0.12
Nodes (17): .body, Float, .packed, .packed, .packed, SIMD4, .packed, Float (+9 more)

### Community 34 - "Set"
Cohesion: 0.13
Nodes (23): Set, UInt8, Owner, component, node, AnimationScope, BoundArg, BoundHandler (+15 more)

### Community 35 - "EffectElement"
Cohesion: 0.16
Nodes (10): EffectElement, .hasEffect, .localEffect, ShadowState, .margin, Bool, Float, float2 (+2 more)

### Community 36 - "LayoutDemo"
Cohesion: 0.22
Nodes (7): LayoutDemo, .body, Alignment, Float, float2, HorizontalAlignment, VerticalAlignment

### Community 37 - "VectorBaker"
Cohesion: 0.12
Nodes (19): BakedRegion, DynamicSDFAtlas, .maxTileSize, Mode, fillEvenOdd, fillNonZero, stroke, Double (+11 more)

### Community 38 - "SVGParser"
Cohesion: 0.18
Nodes (15): SVGDocument, SVGPaint, color, currentColor, none, SVGParser, SVGShape, SVGStyle (+7 more)

### Community 39 - "Graphics2D"
Cohesion: 0.10
Nodes (19): CustomStringConvertible, Error, Glyph, Line, Graphics2D, .glassAtlasWidth, .size, PipelineError (+11 more)

### Community 40 - "Math.metal"
Cohesion: 0.14
Nodes (15): Default arguments, Macro plugin: the zero-length message, Setup, Why the Debug settings are what they are, cross2d(), float2, float4, ndot() (+7 more)

### Community 41 - "BoundingBox3D"
Cohesion: 0.14
Nodes (13): BoundingBox3D, .back, .bottom, .bottomRightBack, .depth, .front, .height, .left (+5 more)

### Community 42 - "bakeVectorSDF"
Cohesion: 0.09
Nodes (34): bakeVectorSDF(), closestOnLine(), closestOnQuadratic(), isInside(), lineCrossing(), constant, float2, kernel (+26 more)

### Community 43 - "compute2D"
Cohesion: 0.35
Nodes (11): backdrop2D(), compute2D(), glassBlur(), constant, kernel, texture2d, uint2, write (+3 more)

### Community 44 - "StateProperty"
Cohesion: 0.14
Nodes (13): PatternBindingSyntax, .states, TypeSyntax, .arrayStates, .reactiveNames, .stateNames, StateProperty, AttributeSyntax (+5 more)

### Community 45 - "String"
Cohesion: 0.12
Nodes (11): DiagnosticMessage, DiagnosticSeverity, FixItMessage, MessageID, String, .uint32, UInt32, Bool (+3 more)

### Community 46 - "SceneData"
Cohesion: 0.29
Nodes (7): DebugData, drawGrid, showFilledCells, SceneData, debug, time, windowSize

### Community 47 - "ImageManager"
Cohesion: 0.20
Nodes (9): ImageManager, ImageQuad, .bounds, PendingUpload, CGFloat, MTLBuffer, MTLCommandBuffer, MTLDevice (+1 more)

### Community 48 - "Rect"
Cohesion: 0.16
Nodes (10): Rect, .center, .height, .maxX, .maxY, .minX, .minY, .width (+2 more)

### Community 49 - "ClipRect"
Cohesion: 0.15
Nodes (14): HittableGrid2D, HittableGridCell, HoveredView, Bool, Float, float2, ObjectIdentifier, ClipRect (+6 more)

### Community 50 - "HStack"
Cohesion: 0.33
Nodes (4): HStack, .crossKey, Float, VerticalAlignment

### Community 51 - "IDElement"
Cohesion: 0.15
Nodes (9): ID, IDElement, ScrollViewProxy, ScrollViewReader, Alignment, AnyHashable, float2, Void (+1 more)

### Community 52 - "AnimationDemo"
Cohesion: 0.29
Nodes (6): AnimatedItem, AnimationDemo, .body, Bool, Float, float4

### Community 53 - "MetalViewRepresentable"
Cohesion: 0.26
Nodes (6): Context, MetalViewRepresentable, MTKView, NSView, NSViewType, ViewRepresentable

### Community 54 - "Table"
Cohesion: 0.17
Nodes (9): Bool, float2, KeyPathComparator, T, Text, Void, Table, .clipRect (+1 more)

### Community 55 - "ListDemo"
Cohesion: 0.22
Nodes (11): ChipView, DemoItem, ListDemo, .body, RowView, .body, Bool, Float (+3 more)

### Community 56 - "Float"
Cohesion: 0.28
Nodes (6): Float, .degrees, .isNegative, .radians, Bool, ClosedRange

### Community 57 - "StackElement"
Cohesion: 0.25
Nodes (8): origin, StackElement, .crossKey, .size, Bool, Float, float2, Void

### Community 58 - "uidrive/main.swift"
Cohesion: 0.11
Nodes (36): CGEventFlags, CGEventType, CGKeyCode, CGMouseButton, CGWindowID, 1. Build and launch, 2. Compile the driver, 3. Drive and look (+28 more)

### Community 59 - "SDF.swift"
Cohesion: 0.24
Nodes (15): clamp(), T, closestPointToSDBox(), pointInAABBox(), pointInAABBoxTopLeftOrigin(), sdBox(), sdBoxTopLeft(), sdCircle() (+7 more)

### Community 60 - "Glyph"
Cohesion: 0.22
Nodes (9): Glyph, blur, color, depth, fontSize, position, size, uvMax (+1 more)

### Community 61 - "Demo"
Cohesion: 0.08
Nodes (24): Demo, animation, conditional, containers, form, glass, grids, .id (+16 more)

### Community 62 - "float4x4"
Cohesion: 0.15
Nodes (11): matrix_double4x4, float3x3, Float, float4x4, .formated, .identity, .upperLeft, Bool (+3 more)

### Community 63 - "Array"
Cohesion: 0.33
Nodes (4): Array, .byteCount, Element, Void

### Community 64 - "UIStorage"
Cohesion: 0.33
Nodes (4): graphify, Hot reload, Performance, UIStorage

### Community 65 - "Shaders/Shaders.metal"
Cohesion: 0.07
Nodes (36): metal_stdlib, Circle, color, depth, position, radius, ellipseAlong(), GridArgBuffer (+28 more)

### Community 66 - "GeometryChangeElement"
Cohesion: 0.21
Nodes (8): CoordinateSpace, global, local, GeometryChangeElement, GeometryProxy, Value, Void, UIElementWrapping

### Community 67 - "Comparable Clamp"
Cohesion: 0.40
Nodes (3): Comparable, ClosedRange, Self

### Community 68 - "LayoutView"
Cohesion: 0.15
Nodes (8): Cache, AnyLayout, Layout, LayoutView, Alignment, float2, Void, ZStackLayout

### Community 73 - "UIElement+ReactiveSetters.swift"
Cohesion: 0.10
Nodes (10): Effects and transitions, Sliding layout, BlurElement, ShadowElement, Background, ExpandedFrame, Padding, Spacer (+2 more)

### Community 74 - "OverlayElement"
Cohesion: 0.23
Nodes (6): OverlayElement, .alignment, Alignment, Bool, float2, Void

### Community 75 - "UIContext"
Cohesion: 0.07
Nodes (6): Float, float4, ObjectIdentifier, UIContext, HorizontalAlignment, VStack

### Community 76 - "Picker"
Cohesion: 0.09
Nodes (23): Kind, check, menuItem, segment, Picker, .selectedTitle, PickerMark, PickerStyle (+15 more)

### Community 77 - "Frame"
Cohesion: 0.26
Nodes (6): Frame, .size, Alignment, Float, float2, Void

### Community 78 - "Int"
Cohesion: 0.12
Nodes (12): AnyIterator, Int, Bool, ClosedRange, SDFSlot, SparseSet, .count, .isEmpty (+4 more)

### Community 79 - "Square"
Cohesion: 0.29
Nodes (5): Square, .bounds, Float, float2, float4

### Community 80 - "SIMD2"
Cohesion: 0.23
Nodes (11): HStack, .size, IMView, Float, HorizontalAlignment, Self, VerticalAlignment, Void (+3 more)

### Community 81 - "Slider"
Cohesion: 0.17
Nodes (12): ProgressView, .fraction, Slider, SliderTrack, ClosedRange, Double, Float, float2 (+4 more)

### Community 82 - "VectorCanvas"
Cohesion: 0.17
Nodes (9): GlassDemo, .body, Bool, Float, float2, Self, VectorCanvas, .children (+1 more)

### Community 83 - "BoundingBox2D"
Cohesion: 0.12
Nodes (15): BoundingBox2D, .bottom, .bottomRight, .height, .left, .right, .top, .topLeft (+7 more)

### Community 84 - "UIElement"
Cohesion: 0.07
Nodes (26): LayoutPass, LayoutTraits, AnyHashable, Float, float2, float4, UInt32, Void (+18 more)

### Community 85 - "BitmapTexture"
Cohesion: 0.23
Nodes (9): CGContext, CGImage, BitmapTexture, Bundle, Float, float2, MTLTexture, NSImage (+1 more)

### Community 86 - "Divider"
Cohesion: 0.27
Nodes (4): Divider, Float, float2, float4

### Community 87 - ".system"
Cohesion: 0.15
Nodes (18): 7. Measure, don't guess, GridsDemo, .body, Bool, GridItem, LazyRowCounter, makeScrollToDemo(), ScrollDemo (+10 more)

### Community 88 - "AlignmentKey"
Cohesion: 0.08
Nodes (34): Equatable, Theme, dark, light, system, Hashable, Hasher, Alignment (+26 more)

### Community 89 - "Performance in MetalGraphics"
Cohesion: 0.25
Nodes (7): 1. The frame, 2. Invalidation — name the narrowest effect, 4. GPU and Metal (`Graphics2D.swift`, `Shaders/Shaders.metal`), 5. Layout and text, 6. Lists and scrolling, 8. Before finishing, Performance in MetalGraphics

### Community 90 - "FocusableElement"
Cohesion: 0.17
Nodes (6): FocusableElement, Bool, float2, Self, Void, UIElementWrapping

### Community 91 - "SVGIcon"
Cohesion: 0.23
Nodes (8): Layer, SVGIcon, Bool, Bundle, Data, Float, float2, float4

### Community 92 - "MouseOver"
Cohesion: 0.35
Nodes (6): IMView, MouseOver, Bool, Float, Self, Void

### Community 93 - "HotReload"
Cohesion: 0.09
Nodes (16): Duration, Hot reload, How it fits the frame loop, Quirks, HotReload, Bool, Date, Int32 (+8 more)

### Community 94 - "MetalGraphicsLib"
Cohesion: 0.13
Nodes (11): AppKit, ContainersDemo, .body, Alignment, Bool, Float, ImageDemo, .body (+3 more)

### Community 95 - "VectorItem"
Cohesion: 0.19
Nodes (12): Kind, bakedFill, bakedStroke, ellipse, roundedBox, Float, float2, VectorItem (+4 more)

### Community 96 - "Graphics2D.swift"
Cohesion: 0.40
Nodes (5): DebugData, SceneData, ShapeArgBuffer, Bool, UInt64

### Community 97 - "HList"
Cohesion: 0.29
Nodes (6): HStack, HList, Float, T, VerticalAlignment, Void

### Community 98 - "IMView"
Cohesion: 0.39
Nodes (4): IMView, Spacer, Float, Void

### Community 99 - "GlassMaterial"
Cohesion: 0.39
Nodes (4): GlassBackground, GlassMaterial, Float, float4

### Community 100 - "Interpolation"
Cohesion: 0.33
Nodes (5): Interpolation, high, low, medium, none

### Community 101 - "float3"
Cohesion: 0.18
Nodes (8): float3, .depth, .height, .width, .xy, Float, float2, int3

### Community 102 - "VectorItem"
Cohesion: 0.06
Nodes (31): Clip, blur, bounds, padding1, padding2, radii, rect, rounded (+23 more)

### Community 103 - "LazyStack"
Cohesion: 0.10
Nodes (21): LazyHStack, .crossAlignment, LazyStack, .crossAlignment, .defaultLength, .estimatedLength, .initialExtent, .overscan (+13 more)

### Community 104 - "HittableView"
Cohesion: 0.16
Nodes (9): Bool, Void, HittableView, .hitPosition, .hitSize, Bool, Float, float2 (+1 more)

### Community 105 - ".content"
Cohesion: 0.10
Nodes (11): .content, AspectRatioElement, ClipElement, .clipCornerRadii, .clipRect, FixedSizeElement, PositionElement, Bool (+3 more)

### Community 106 - "GraphicsGrid2D"
Cohesion: 0.10
Nodes (20): Int32, GPUDevice, MTLDevice, GraphicsGrid2D, GridArgBuffer, GridCell, Shape, ShapeType2D (+12 more)

### Community 107 - "Utils.swift"
Cohesion: 0.17
Nodes (13): DispatchWorkItem, Debouncer, forEachGridCell(), generateRandomArray(), iterateWithStep(), name(), ClosedRange, DispatchQueue (+5 more)

### Community 108 - "Rectangle"
Cohesion: 0.16
Nodes (8): ConditionalDemo, .body, Bool, Float, float4, Rectangle, Float, float2

### Community 109 - "SVGPathCommand"
Cohesion: 0.12
Nodes (16): SVGPathCommand, close, cubic, line, move, quad, SVGPathData, SVGScanner (+8 more)

### Community 110 - "Image"
Cohesion: 0.23
Nodes (6): Image, .naturalSize, Float, float2, float4, Self

### Community 111 - "Void"
Cohesion: 0.14
Nodes (11): 3. Hot paths — per frame, or per element per frame, 8. How it lands on screen, Invalidation, Bool, Double, float2, Frame, UInt8 (+3 more)

### Community 112 - "LazyGridElement"
Cohesion: 0.14
Nodes (20): GridItem, LazyGridElement, .defaultCellAlignment, .trackAlignment, LazyHGrid, .defaultCellAlignment, .trackAlignment, LazyVGrid (+12 more)

### Community 113 - "uchar4"
Cohesion: 0.14
Nodes (10): float4, .xyz, Double, Float, UInt8, uchar4, .a, .b (+2 more)

### Community 114 - "Padding"
Cohesion: 0.27
Nodes (4): Padding, Float, float2, float2

### Community 115 - "SDFBaker.swift"
Cohesion: 0.14
Nodes (21): PendingBake, SDFAtlas, SDFBakeParams, SDFBaker, SDFRegion, SDFShape, SDFShapeGeometry, SDFShapeMode (+13 more)

### Community 116 - "ArgSpec"
Cohesion: 0.15
Nodes (16): ArgCombine, construct, float2, identity, labeled, ArgSpec, Arity, leaf (+8 more)

### Community 117 - "PathBuilder"
Cohesion: 0.18
Nodes (10): PathBuilder, PathMorph, Bool, Double, Float, float2, VectorSegment, VectorGeometry (+2 more)

### Community 118 - "Axis"
Cohesion: 0.11
Nodes (14): ExpressibleByArrayLiteral, Axis, .inverted, .size, IMView, Float, float2, Self (+6 more)

### Community 119 - "SwiftSyntax"
Cohesion: 0.14
Nodes (8): AccessorMacro, ExtensionMacro, MemberMacro, PeerMacro, ComponentMacro, StateMacro, SwiftDiagnostics, SwiftSyntax

### Community 120 - "layoutText"
Cohesion: 0.26
Nodes (14): CoreText, caretOffsets(), Glyph, .bounds, layoutText(), measureText(), PlacedGlyph, Bool (+6 more)

### Community 121 - "MultiChildElement"
Cohesion: 0.16
Nodes (7): MultiChildElement, .liveChildrenCount, float2, Void, ListRows, T, Void

### Community 122 - "Content"
Cohesion: 0.50
Nodes (4): Content, bitmap, missing, svg

### Community 123 - "float2"
Cohesion: 0.19
Nodes (5): Bool, float2, TableCells, TableColumnDivider, TableHeader

### Community 124 - "Animator"
Cohesion: 0.25
Nodes (11): Apply, Animator, .isIdle, Key, Running, Bool, Double, Float (+3 more)

### Community 125 - "SDFFont"
Cohesion: 0.33
Nodes (7): CGGlyph, CTFont, FontManager, GlyphKey, GlyphMetrics, SDFFont, Float

### Community 126 - "ProposedSize"
Cohesion: 0.22
Nodes (7): MeasureCache, ProposedSize, Float, float2, UInt32, UInt8, AnyLayoutBox

### Community 127 - ".init"
Cohesion: 0.20
Nodes (3): Bool, Text, Void

### Community 128 - "SwiftSyntaxMacros"
Cohesion: 0.49
Nodes (4): ReactiveUIMacrosPlugin, SwiftSyntaxMacros, SwiftSyntaxMacrosGenericTestSupport, Testing

### Community 129 - "oracle.swift"
Cohesion: 0.25
Nodes (7): HorizontalAlignment, Probe, .body, render(), CGSize, V, View

### Community 130 - "VectorDemo"
Cohesion: 0.17
Nodes (10): StressCell, .body, StressIndex, StressRow, .body, Bool, VectorDemo, .body (+2 more)

### Community 131 - "BodyParser"
Cohesion: 0.14
Nodes (13): CodeBlockItemListSyntax, IfExprSyntax, BodyParser, Bool, ClosureExprSyntax, ExprSyntax, FunctionCallExprSyntax, MemberBlockItemListSyntax (+5 more)

### Community 132 - "StepIterator"
Cohesion: 0.27
Nodes (6): IteratorProtocol, StepIterator, StepSequence, Bool, Float, Sequence

### Community 133 - "SDFPathBuilder"
Cohesion: 0.21
Nodes (12): CGPath, PathElement, SDFPathBuilder, .isEmpty, Bool, float2, UInt8, CGRect (+4 more)

### Community 134 - "FlexFrame"
Cohesion: 0.30
Nodes (4): FlexFrame, Alignment, Float, float2

### Community 135 - "Glass"
Cohesion: 0.15
Nodes (13): Glass, depth, noise, opacity, padding, pointsPerTexel, radii, rect (+5 more)

### Community 137 - "DatePicker"
Cohesion: 0.06
Nodes (24): PopoverFill, PopoverHandle, .isPresented, PopoverLayer, Bool, Float, float2, HorizontalAlignment (+16 more)

### Community 138 - "VList"
Cohesion: 0.19
Nodes (10): 5. Collections are just `@State` arrays, Bindings are lowered, not passed, Mutation carries the operation, Named content closures, The plain setter still works, Float, HorizontalAlignment, T (+2 more)

### Community 139 - "TextField"
Cohesion: 0.20
Nodes (10): EditKind, deleting, other, typing, SecureField, Snapshot, Range, Self (+2 more)

### Community 140 - "Path"
Cohesion: 0.13
Nodes (16): Path, .isClosed, .length, .localBounds, Source, builder, commands, Bool (+8 more)

### Community 142 - "FieldBox"
Cohesion: 0.27
Nodes (4): FieldBox, .clipRect, Float, float2

### Community 143 - "Plugin.swift"
Cohesion: 0.29
Nodes (5): CompilerPlugin, PluginMain, ReactiveUIMacrosPlugin, Macro, SwiftCompilerPlugin

### Community 144 - "Section"
Cohesion: 0.12
Nodes (14): CaptionSlot, .isEmpty, RowLayout, RowSeparators, RowStack, .inset, Section, .inset (+6 more)

### Community 145 - "AnimationGroup"
Cohesion: 0.33
Nodes (5): `withAnimation`, AnimationGroup, Void, UITransaction, withAnimation()

### Community 146 - "Stepper"
Cohesion: 0.19
Nodes (10): Stepper, StepperGlyph, Bool, ClosedRange, Double, Float, float2, Text (+2 more)

### Community 147 - "GridCell"
Cohesion: 0.20
Nodes (6): GridCell, count, startIndex, from2DTo1DArray(), isBetween(), thread

### Community 148 - "GlassPass"
Cohesion: 0.22
Nodes (9): GlassPass, atlasOrigin, direction, maxDepth, padding, pointsPerTexel, sceneOrigin, sigma (+1 more)

### Community 149 - ".drawData"
Cohesion: 0.15
Nodes (9): MTKView, MTLComputePipelineState, Void, Circle2D, .bounds, Float, float2, float4 (+1 more)

### Community 150 - "float2"
Cohesion: 0.22
Nodes (7): float2, .asInt2, .greatestComponent, .height, .width, Float, .text

### Community 151 - "FileWatcher"
Cohesion: 0.22
Nodes (7): CoreServices, FSEventStreamRef, FileWatcher, ArraySlice, DispatchQueue, URL, Void

### Community 152 - ".body"
Cohesion: 0.18
Nodes (10): AudioSettings, FormDemo, .body, Bool, Date, Double, float4, LabeledContent (+2 more)

### Community 153 - "ViewThatFits"
Cohesion: 0.26
Nodes (4): Float, float2, Void, ViewThatFits

### Community 154 - "TableColumn"
Cohesion: 0.24
Nodes (8): KeyPath, MainActor, HorizontalAlignment, KeyPathComparator, T, V, TableColumn, TableColumnBuilder

### Community 155 - "ZStack"
Cohesion: 0.25
Nodes (6): Alignment, Bool, Float, float2, Void, ZStack

### Community 156 - "TableDemo"
Cohesion: 0.40
Nodes (5): Person, float4, KeyPathComparator, TableDemo, .body

### Community 157 - "TransitionElement"
Cohesion: 0.33
Nodes (5): 1. The pieces, Float, Void, TransitionElement, .currentState

### Community 158 - "Padding"
Cohesion: 0.31
Nodes (5): IMView, Padding, Float, Self, Void

### Community 159 - "View"
Cohesion: 0.18
Nodes (11): Bool, View, Background, ExpandedFrame, FlexFrame, HStack, .isSpacer, MouseOver (+3 more)

### Community 160 - "Form"
Cohesion: 0.29
Nodes (4): Form, Bool, ObjectIdentifier, VStack

### Community 161 - ".init"
Cohesion: 0.25
Nodes (7): DisclosureChevron, DisclosureGroup, Bool, Float, float2, Text, Void

### Community 163 - "Toggle"
Cohesion: 0.26
Nodes (7): Bool, Float, float2, Text, Void, Toggle, ToggleSwitch

### Community 164 - "int2"
Cohesion: 0.40
Nodes (3): int2, float2, from1DTo2DArray()

### Community 165 - "TableCell"
Cohesion: 0.16
Nodes (8): Background, Float, HorizontalAlignment, T, TableCell, .clipRect, TableMetrics, TableRowHighlight

### Community 166 - "layoutchecks/main.swift"
Cohesion: 0.29
Nodes (5): check(), HorizontalAlignment, Mid, Float, float2

### Community 167 - "UIShape"
Cohesion: 0.20
Nodes (9): Kind, capsule, circle, rect, Bool, Float, float4, UIShape (+1 more)

### Community 168 - "Binding"
Cohesion: 0.23
Nodes (8): Member, Binding, .wrappedValue, Value, Void, ReferenceWritableKeyPath, Root, WritableKeyPath

### Community 169 - "ScrollIndicator"
Cohesion: 0.20
Nodes (8): ScrollIndicator, .visibility, ScrollIndicatorVisibility, automatic, hidden, never, visible, Float

### Community 170 - "expand"
Cohesion: 0.28
Nodes (6): BindingMacroTests, component(), expand(), NamedContentTests, SwiftParser, SwiftSyntaxMacroExpansion

### Community 171 - "simd"
Cohesion: 0.11
Nodes (6): Foundation, benchmark(), Bool, Void, QuartzCore, simd

### Community 172 - "Spacer"
Cohesion: 0.31
Nodes (4): LeafElement, Spacer, Float, float2

### Community 173 - "FormControl"
Cohesion: 0.10
Nodes (12): FormControl, .isInteracting, FormGraphic, mix(), Bool, Float, float2, float4 (+4 more)

### Community 174 - "GeometryReader"
Cohesion: 0.31
Nodes (3): GeometryReader, Float, float2

### Community 176 - "Button"
Cohesion: 0.33
Nodes (6): Button, ButtonRole, cancel, destructive, Text, Void

### Community 177 - "TableColumnLayout"
Cohesion: 0.32
Nodes (5): Bool, Float, TableColumnLayout, .count, TableColumnWidth

### Community 178 - "LayoutBox"
Cohesion: 0.43
Nodes (3): LayoutBox, L, UInt32

### Community 179 - "Compile-time state in RetainedModeUI"
Cohesion: 0.29
Nodes (6): 2. What a component looks like, 3. What gets generated, 4. Rules that follow, 6. Composition, not helper methods, 7. Diagnostics, Compile-time state in RetainedModeUI

### Community 180 - "TextDemo"
Cohesion: 0.36
Nodes (4): Float, TextDemo, .body, FormMetrics

### Community 183 - "Phases"
Cohesion: 0.67
Nodes (3): Phases, UInt8, OptionSet

### Community 184 - "TemplateRenderingMode"
Cohesion: 0.50
Nodes (3): TemplateRenderingMode, original, template

### Community 185 - ".readExactly"
Cohesion: 0.39
Nodes (4): StdinFilter, Bool, Int32, UInt8

### Community 186 - ".init"
Cohesion: 0.38
Nodes (4): FlexFrame, ExpandedFrame, .axis, Alignment

### Community 187 - "VStack"
Cohesion: 0.33
Nodes (4): Float, HorizontalAlignment, VStack, .crossKey

### Community 188 - "IMGameView"
Cohesion: 0.33
Nodes (3): IMView, IMGameView, float4

### Community 189 - "9. Animation"
Cohesion: 0.47
Nodes (5): 9. Animation, Costs to know, Repeat and keyframes, Scopes, The runtime

### Community 194 - "ContentMode"
Cohesion: 0.50
Nodes (3): ContentMode, fill, fit

### Community 196 - "Result"
Cohesion: 0.67
Nodes (3): Result, handled, ignored

## Knowledge Gaps
- **478 isolated node(s):** `conditional`, `list`, `text`, `layout`, `image` (+473 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 940 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **17 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `String` connect `String` to `Input`, `Text`, `UIAnimation`, `IMView`, `DiagnosticsTests`, `ViewItem`, `CodeGen`, `SingleChildElement`, `.invalidate`, `IMView`, `ColorPicker`, `WindowState`, `Naming`, `View`, `BorderElement`, `ScrollView`, `KeyPress`, `StateRewriter`, `Set`, `LayoutDemo`, `SVGParser`, `Graphics2D`, `StateProperty`, `ImageManager`, `HStack`, `IDElement`, `AnimationDemo`, `Table`, `ListDemo`, `uidrive/main.swift`, `Demo`, `float4x4`, `UIElement+ReactiveSetters.swift`, `OverlayElement`, `Picker`, `Frame`, `SIMD2`, `Slider`, `VectorCanvas`, `UIElement`, `BitmapTexture`, `.system`, `SVGIcon`, `MouseOver`, `HotReload`, `MetalGraphicsLib`, `IMView`, `Utils.swift`, `Rectangle`, `SVGPathCommand`, `Image`, `Padding`, `SDFBaker.swift`, `ArgSpec`, `layoutText`, `MultiChildElement`, `SDFFont`, `.init`, `oracle.swift`, `BodyParser`, `FlexFrame`, `AnimationMacroTests`, `DatePicker`, `TextField`, `Path`, `Section`, `Stepper`, `float2`, `FileWatcher`, `.body`, `TableColumn`, `ZStack`, `TableDemo`, `Padding`, `.init`, `Toggle`, `layoutchecks/main.swift`, `expand`, `simd`, `.replacingUnspecified`, `Button`, `TextDemo`, `VStack`, `.pressed`, `.init`?**
  _High betweenness centrality (0.244) - this node is a cross-community bridge._
- **Why does `UIContext` connect `UIContext` to `VectorDemo`, `UIAnimation`, `.gpuClip`, `DatePicker`, `VList`, `.invalidate`, `AnimationGroup`, `Stepper`, `ColorPicker`, `ViewThatFits`, `BorderElement`, `ScrollView`, `ViewRenderer`, `TransitionElement`, `KeyPress`, `Sendable`, `.init`, `EffectElement`, `int2`, `Toggle`, `Graphics2D`, `ScrollIndicator`, `simd`, `FormControl`, `Button`, `ClipRect`, `IDElement`, `AnimationDemo`, `Table`, `.setAlignment`, `GeometryChangeElement`, `.setLayout`, `UIElement+ReactiveSetters.swift`, `Picker`, `Int`, `Slider`, `VectorCanvas`, `UIElement`, `Divider`, `FocusableElement`, `HList`, `LazyStack`, `Void`, `MultiChildElement`, `float2`, `Animator`, `.init`?**
  _High betweenness centrality (0.175) - this node is a cross-community bridge._
- **Why does `Int` connect `Int` to `UIElementWrapping`, `VectorDemo`, `UIAnimation`, `BodyParser`, `SDFPathBuilder`, `.gpuClip`, `FlexFrame`, `ViewItem`, `DatePicker`, `TextField`, `Path`, `MathLib.swift`, `FieldBox`, `IMView`, `VList`, `CodeGen`, `Grid`, `ColorPicker`, `.drawData`, `WindowState`, `LayoutSubviews`, `.body`, `Naming`, `ZStack`, `TableDemo`, `View`, `Set`, `LayoutDemo`, `VectorBaker`, `int2`, `Graphics2D`, `String`, `ImageManager`, `TableColumnLayout`, `AnimationDemo`, `TextDemo`, `Table`, `ListDemo`, `StackElement`, `.readExactly`, `uidrive/main.swift`, `.pressed`, `Array`, `LayoutView`, `UIContext`, `Picker`, `UIElement`, `BitmapTexture`, `.system`, `AlignmentKey`, `HotReload`, `MetalGraphicsLib`, `HList`, `LazyStack`, `GraphicsGrid2D`, `Utils.swift`, `Rectangle`, `Void`, `LazyGridElement`, `SDFBaker.swift`, `ArgSpec`, `MultiChildElement`, `Animator`, `ProposedSize`, `.init`?**
  _High betweenness centrality (0.173) - this node is a cross-community bridge._
- **Are the 5 inferred relationships involving `UIContext` (e.g. with `Effects and transitions` and `HittableGrid2D`) actually correct?**
  _`UIContext` has 5 INFERRED edges - model-reasoned connections that need verification._
- **Are the 23 inferred relationships involving `UIElement` (e.g. with `7. Diagnostics` and `What needs a relaunch`) actually correct?**
  _`UIElement` has 23 INFERRED edges - model-reasoned connections that need verification._
- **What connects `conditional`, `list`, `text` to the rest of the system?**
  _478 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `UIElementWrapping` be split into smaller, more focused modules?**
  _Cohesion score 0.10037878787878787 - nodes in this community are weakly interconnected._