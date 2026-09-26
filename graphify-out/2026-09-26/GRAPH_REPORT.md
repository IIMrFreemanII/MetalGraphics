# Graph Report - MetalGraphics  (2026-09-26)

## Corpus Check
- 241 files · ~206,460 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 16 file(s) not represented in the graph (top: (none) 4, .plist 3, .resolved 2)

## Summary
- 4350 nodes · 12053 edges · 200 communities (185 shown, 15 thin omitted)
- Extraction: 90% EXTRACTED · 10% INFERRED · 0% AMBIGUOUS · INFERRED: 1219 edges (avg confidence: 0.83)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `e2951072`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- UIElementWrapping
- Input
- Text
- Float
- DragAndDropTests
- DiagnosticsTests
- UIHarness
- AnimatedProperty
- GPURayMarching/Shaders.metal
- ViewItem
- CodeGen
- IMView
- GlyphSDF.metal
- MathLib.swift
- UIAnimation
- IMView
- MyMTKView
- Alignment
- Grid
- ColorPicker
- VectorShape
- TextFont
- WindowState
- Equatable
- .expansion
- View
- Background
- ScrollView
- ViewRenderer
- KeyPress
- SDF.metal
- DragDropDemo
- UIKeyframe
- Inset
- ElementIR
- .content
- LayoutDemo
- VectorBaker
- SVGParser
- Graphics2D
- Math.metal
- BoundingBox3D
- bakeVectorSDF
- Shaders/Shaders.metal
- StateProperty
- String
- SceneData
- ImageManager
- Rect
- Hittable
- HStack
- IDElement
- AnimationDemo
- MetalViewRepresentable
- Table
- ListDemo
- Float
- DropDestinationBase
- uidrive/main.swift
- SDF.swift
- Glyph
- Demo
- float4x4
- Array
- UIStorage
- Glass
- GeometryChangeElement
- Comparable Clamp
- ClipRect
- Macro Package Manifest
- BorderElement
- OverlayElement
- UIContext
- Picker
- Frame
- Int
- LayoutView
- IMView
- StackElement
- VectorCanvas
- BoundingBox2D
- UIElement
- .draw
- Divider
- .system
- Sendable
- Performance in MetalGraphics
- MetalKit
- SVGIcon
- MouseOver
- Hot reload
- simd
- VectorItem
- .encodeFrame
- LazyGridElement
- IMView
- assertSnapshot
- TransitionState
- float3
- VectorItem
- LazyStack
- HittableView
- float2
- GraphicsGrid2D
- Utils.swift
- Rectangle
- SVGPathCommand
- Image
- UIElement+ReactiveSetters.swift
- VList
- uchar4
- TextEnvironment
- SDFBaker.swift
- TextStyleElement
- PathBuilder
- Axis
- .expansion
- Toggle
- ListRows
- TransitionElement
- float2
- TextLayout.swift
- FormControl
- ProposedSize
- FontManager
- SwiftSyntaxMacros
- oracle.swift
- VectorDemo
- Set
- StepIterator
- SDFPathBuilder
- FlexFrame
- Padding
- AnimationMacroTests
- DatePicker
- TextTests
- TextField
- Path
- LayoutMacroTests
- FieldBox
- Drag
- Section
- BodyParser
- Stepper
- compute2D
- GlassPass
- Float
- ConditionalDemo
- FileWatcher
- SingleChildElement
- expand
- TableColumn
- ZStack
- TableDemo
- MultiChildElement
- Form
- .scan
- Button
- .init
- ComponentMacroTests
- KeyboardDemo
- UIShape
- .step
- .body
- post
- .init
- Line
- expand
- Foundation
- Spacer
- FormGraphic
- ViewThatFits
- Kind
- ButtonFace
- TableColumnLayout
- HotReload
- ClipElement
- .snapshot
- Square
- GridCell
- .setGridCell
- .restyleLayout
- .readExactly
- Driving GPURayMarching
- int2
- .setChild
- .setAlignment
- VStack
- TextDemo
- Void
- Phases
- .sizeThatFits
- .init
- .setLayout
- float2x2
- float2

## God Nodes (most connected - your core abstractions)
1. `UIContext` - 408 edges
2. `UIElement` - 280 edges
3. `UIAnimation` - 239 edges
4. `ProposedSize` - 171 edges
5. `Graphics2D` - 122 edges
6. `TextStyleElement` - 88 edges
7. `UIHarness` - 88 edges
8. `simd` - 87 edges
9. `TextEnvironment` - 72 edges
10. `Inset` - 66 edges

## Surprising Connections (you probably didn't know these)
- `7. Measure, don't guess` --references--> `ScrollDemo`  [INFERRED]
  .claude/skills/performance/SKILL.md → GPURayMarching/ScrollDemo.swift
- `6. Lists and scrolling` --references--> `ListRows`  [INFERRED]
  .claude/skills/performance/SKILL.md → MetalGraphicsLib/RetainedModeUI/Layout/ListRows.swift
- `Scopes` --references--> `ElementCatalog`  [INFERRED]
  MetalGraphicsLib/docs/CompileTimeState.md → ReactiveUIMacros/Sources/ReactiveUIMacrosPlugin/ElementCatalog.swift
- `Hot reload` --references--> `Demos`  [INFERRED]
  MetalGraphicsLib/docs/HotReload.md → GPURayMarching/Demos.swift
- `5. Collections are just `@State` arrays` --references--> `DemoItem`  [INFERRED]
  MetalGraphicsLib/docs/CompileTimeState.md → GPURayMarching/ListDemo.swift

## Import Cycles
- None detected.

## Communities (200 total, 15 thin omitted)

### Community 0 - "UIElementWrapping"
Cohesion: 0.14
Nodes (8): Bool, Float, float2, HorizontalAlignment, Self, VerticalAlignment, Void, UIElementWrapping

### Community 1 - "Input"
Cohesion: 0.11
Nodes (13): Input, .mouseDown, .mouseMoved, .mousePressed, .mouseUp, Bool, Double, NSEvent (+5 more)

### Community 2 - "Text"
Cohesion: 0.08
Nodes (22): Case, F, DateStyle, Any, Bool, Date, Float, float2 (+14 more)

### Community 3 - "Float"
Cohesion: 0.15
Nodes (10): Curve, easeIn, easeInOut, easeOut, keyframes, linear, spring, Bool (+2 more)

### Community 4 - "DragAndDropTests"
Cohesion: 0.31
Nodes (5): Chip, DragAndDropTests, Log, Bool, float2

### Community 5 - "DiagnosticsTests"
Cohesion: 0.28
Nodes (3): component(), DiagnosticsTests, stubsOnly()

### Community 6 - "UIHarness"
Cohesion: 0.15
Nodes (10): InteractionTests, Bool, Float, float2, MTLTexture, NSEvent, UIHarness, .context (+2 more)

### Community 7 - "AnimatedProperty"
Cohesion: 0.05
Nodes (51): Apply, 9. Animation, Costs to know, Repeat and keyframes, Scopes, The runtime, `withAnimation`, AnimatedProperty (+43 more)

### Community 8 - "GPURayMarching/Shaders.metal"
Cohesion: 0.08
Nodes (30): Camera, fov, position, rotation, compute(), distanceToScene(), GridArgBuffer, GridItem (+22 more)

### Community 9 - "ViewItem"
Cohesion: 0.28
Nodes (7): Background, IMView, Float, float4, Self, Void, ViewItem

### Community 10 - "CodeGen"
Cohesion: 0.25
Nodes (7): CodeGen, Dependents, RowsMode, full, insert, remove, DeclSyntax

### Community 11 - "IMView"
Cohesion: 0.23
Nodes (9): ExpandedFrame, FlexFrame, Frame, IMView, Alignment, Float, float2, Self (+1 more)

### Community 12 - "GlyphSDF.metal"
Cohesion: 0.08
Nodes (35): What needs a relaunch, bakeSDF(), lineWinding(), constant, float2, kernel, texture2d, uint (+27 more)

### Community 13 - "MathLib.swift"
Cohesion: 0.18
Nodes (17): int3, dragDirection(), from1DTo3DArray(), from2DTo1DArray(), from3DTo1DArray(), fromPixelCoordToGridIndex(), fromWorldPositionToGridIndex(), lerp() (+9 more)

### Community 14 - "UIAnimation"
Cohesion: 0.05
Nodes (16): UIAnimation, Background, Circle, FlexFrame, Frame, Alignment, Bool, Float (+8 more)

### Community 15 - "IMView"
Cohesion: 0.08
Nodes (28): ExpandedFrame, IMView, Background, Bool, FlexFrame, Float, float2, Frame (+20 more)

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
Cohesion: 0.07
Nodes (31): Member, Binding, .wrappedValue, Value, Void, WritableKeyPath, ColorPicker, ColorSwatch (+23 more)

### Community 20 - "VectorShape"
Cohesion: 0.09
Nodes (26): Text styling, Capsule, Circle, .length, .localBounds, Ellipse, .length, .localBounds (+18 more)

### Community 21 - "TextFont"
Cohesion: 0.04
Nodes (50): Theme, dark, light, system, Hashable, Design, `default`, monospaced (+42 more)

### Community 22 - "WindowState"
Cohesion: 0.15
Nodes (13): CaseIterable, Application, Event, Inspector, Navigation, Global, Reload, Bool (+5 more)

### Community 23 - "Equatable"
Cohesion: 0.16
Nodes (9): Equatable, ImageQuad, GPUClip, float2, float4, Int32, UInt32, VectorItem (+1 more)

### Community 24 - ".expansion"
Cohesion: 0.12
Nodes (13): CodeBlockItemListSyntax, DeclGroupSyntax, ExtensionDeclSyntax, ExtensionMacro, IfExprSyntax, MemberMacro, MemberBlockItemListSyntax, VariableDeclSyntax (+5 more)

### Community 25 - "View"
Cohesion: 0.09
Nodes (23): .inspectorView, Inspector, .body, Navigation, .body, ToggleView, .body, Number2Field (+15 more)

### Community 26 - "Background"
Cohesion: 0.18
Nodes (6): Background, GlassBackground, GlassMaterial, Float, float2, float4

### Community 27 - "ScrollView"
Cohesion: 0.09
Nodes (17): ScrollIndicator, .visibility, ScrollIndicatorVisibility, automatic, hidden, never, visible, ScrollView (+9 more)

### Community 28 - "ViewRenderer"
Cohesion: 0.12
Nodes (15): .body, MetalView, .body, CGSize, Double, Float, float2, MTKView (+7 more)

### Community 29 - "KeyPress"
Cohesion: 0.22
Nodes (11): CharacterSet, ExpressibleByExtendedGraphemeClusterLiteral, KeyEquivalent, KeyPress, KeyPressElement, Result, handled, ignored (+3 more)

### Community 30 - "SDF.metal"
Cohesion: 0.15
Nodes (15): dot2(), float2, float4, sdBox(), sdBoxSquared(), sdCircle(), sdCircleSquared(), sdOrientedBox() (+7 more)

### Community 31 - "DragDropDemo"
Cohesion: 0.40
Nodes (5): DragChip, DragDropDemo, .body, Bool, float4

### Community 32 - "UIKeyframe"
Cohesion: 0.21
Nodes (10): KeyframeElement, KeyframeSegment, Any, Float, float2, Self, V, UIKeyframe (+2 more)

### Community 33 - "Inset"
Cohesion: 0.10
Nodes (22): IMView, Padding, Float, Self, Void, Float, .packed, .packed (+14 more)

### Community 34 - "ElementIR"
Cohesion: 0.10
Nodes (26): .armedHandlers, Owner, component, node, Void, Arity, leaf, multi (+18 more)

### Community 35 - ".content"
Cohesion: 0.15
Nodes (11): EffectElement, .hasEffect, .localEffect, ShadowState, .margin, Bool, Float, float2 (+3 more)

### Community 36 - "LayoutDemo"
Cohesion: 0.22
Nodes (7): LayoutDemo, .body, Alignment, Float, float2, HorizontalAlignment, VerticalAlignment

### Community 37 - "VectorBaker"
Cohesion: 0.12
Nodes (20): BakedRegion, DynamicSDFAtlas, .maxTileSize, Mode, fillEvenOdd, fillNonZero, stroke, SDFSlot (+12 more)

### Community 38 - "SVGParser"
Cohesion: 0.18
Nodes (15): SVGDocument, SVGPaint, color, currentColor, none, SVGParser, SVGShape, SVGStyle (+7 more)

### Community 39 - "Graphics2D"
Cohesion: 0.09
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

### Community 43 - "Shaders/Shaders.metal"
Cohesion: 0.07
Nodes (36): metal_stdlib, Circle, color, depth, position, radius, ellipseAlong(), GridArgBuffer (+28 more)

### Community 44 - "StateProperty"
Cohesion: 0.14
Nodes (13): PatternBindingSyntax, .states, TypeSyntax, .arrayStates, .reactiveNames, .stateNames, StateProperty, AttributeSyntax (+5 more)

### Community 45 - "String"
Cohesion: 0.13
Nodes (4): String, .uint32, UInt32, Naming

### Community 46 - "SceneData"
Cohesion: 0.29
Nodes (7): DebugData, drawGrid, showFilledCells, SceneData, debug, time, windowSize

### Community 47 - "ImageManager"
Cohesion: 0.12
Nodes (19): CGContext, 4. GPU and Metal (`Graphics2D.swift`, `Shaders/Shaders.metal`), BitmapTexture, ImageManager, ImageQuad, .bounds, PendingUpload, Bundle (+11 more)

### Community 48 - "Rect"
Cohesion: 0.16
Nodes (10): Rect, .center, .height, .maxX, .maxY, .minX, .minY, .width (+2 more)

### Community 49 - "Hittable"
Cohesion: 0.14
Nodes (13): AnyObject, HittableGrid2D, HittableGridCell, HoveredView, Bool, Float, float2, ObjectIdentifier (+5 more)

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
Cohesion: 0.29
Nodes (6): Context, MetalViewRepresentable, MTKView, NSView, NSViewType, ViewRepresentable

### Community 54 - "Table"
Cohesion: 0.19
Nodes (8): Bool, float2, KeyPathComparator, T, Text, Table, .clipRect, .items

### Community 55 - "ListDemo"
Cohesion: 0.20
Nodes (12): ChipView, .body, DemoItem, ListDemo, .body, RowView, .body, Bool (+4 more)

### Community 56 - "Float"
Cohesion: 0.28
Nodes (6): Float, .degrees, .isNegative, .radians, Bool, ClosedRange

### Community 57 - "DropDestinationBase"
Cohesion: 0.07
Nodes (23): HStack, DraggableElement, DragPreviewLayer, .hasEffect, .localEffect, DragSession, DropDestinationBase, DropDestinationElement (+15 more)

### Community 58 - "uidrive/main.swift"
Cohesion: 0.20
Nodes (17): CGKeyCode, CGWindowID, CoreGraphics, fail(), findWindow(), keyCode(), modifierFlags(), postKey() (+9 more)

### Community 59 - "SDF.swift"
Cohesion: 0.24
Nodes (15): clamp(), T, closestPointToSDBox(), pointInAABBox(), pointInAABBoxTopLeftOrigin(), sdBox(), sdBoxTopLeft(), sdCircle() (+7 more)

### Community 60 - "Glyph"
Cohesion: 0.22
Nodes (9): Glyph, blur, color, depth, fontSize, position, size, uvMax (+1 more)

### Community 61 - "Demo"
Cohesion: 0.08
Nodes (24): Demo, animation, conditional, containers, dragDrop, form, glass, grids (+16 more)

### Community 62 - "float4x4"
Cohesion: 0.14
Nodes (12): matrix_double4x4, float3x3, Float, float4x4, .formated, .identity, .upperLeft, Bool (+4 more)

### Community 63 - "Array"
Cohesion: 0.25
Nodes (5): Array, .byteCount, Element, IndexSet, Void

### Community 64 - "UIStorage"
Cohesion: 0.22
Nodes (6): graphify, Hot reload, Performance, UI tests, T, UIStorage

### Community 65 - "Glass"
Cohesion: 0.15
Nodes (13): Glass, depth, noise, opacity, padding, pointsPerTexel, radii, rect (+5 more)

### Community 66 - "GeometryChangeElement"
Cohesion: 0.14
Nodes (11): CoordinateSpace, global, local, GeometryChangeElement, GeometryProxy, GeometryReader, Float, float2 (+3 more)

### Community 67 - "Comparable Clamp"
Cohesion: 0.40
Nodes (3): Comparable, ClosedRange, Self

### Community 68 - "ClipRect"
Cohesion: 0.11
Nodes (17): Cache, ClipRect, .isEmpty, HStackLayout, Layout, LayoutSubviews, .endIndex, .startIndex (+9 more)

### Community 73 - "BorderElement"
Cohesion: 0.19
Nodes (9): BorderElement, .color, .lineWidth, .shape, BorderLayer, Float, float2, float4 (+1 more)

### Community 74 - "OverlayElement"
Cohesion: 0.15
Nodes (9): Alignment, FlexFrame, Frame, OverlayElement, .alignment, Alignment, Bool, float2 (+1 more)

### Community 75 - "UIContext"
Cohesion: 0.04
Nodes (11): Float, float4, ObjectIdentifier, UIContext, .isDragging, LayoutPass, Any, UInt32 (+3 more)

### Community 76 - "Picker"
Cohesion: 0.08
Nodes (23): Kind, check, menuItem, segment, Picker, .selectedTitle, PickerMark, PickerStyle (+15 more)

### Community 77 - "Frame"
Cohesion: 0.26
Nodes (6): Frame, .size, Alignment, Float, float2, Void

### Community 78 - "Int"
Cohesion: 0.14
Nodes (12): AnyIterator, Int, Bool, ClosedRange, RunText, SparseSet, .count, .isEmpty (+4 more)

### Community 79 - "LayoutView"
Cohesion: 0.17
Nodes (8): AnyLayout, AnyLayoutBox, LayoutBox, LayoutView, Alignment, float2, L, UInt32

### Community 80 - "IMView"
Cohesion: 0.23
Nodes (10): HStack, .size, IMView, Float, HorizontalAlignment, Self, VerticalAlignment, Void (+2 more)

### Community 81 - "StackElement"
Cohesion: 0.23
Nodes (8): origin, StackElement, .crossKey, .size, Bool, Float, float2, Void

### Community 82 - "VectorCanvas"
Cohesion: 0.16
Nodes (9): GlassDemo, .body, Bool, Float, float2, Self, VectorCanvas, .children (+1 more)

### Community 83 - "BoundingBox2D"
Cohesion: 0.17
Nodes (12): BoundingBox2D, .bottom, .bottomRight, .height, .left, .right, .top, .topLeft (+4 more)

### Community 84 - "UIElement"
Cohesion: 0.07
Nodes (27): 7. Diagnostics, LayoutTraits, Alignment, AnyHashable, Bool, Float, float2, float4 (+19 more)

### Community 85 - ".draw"
Cohesion: 0.20
Nodes (3): EffectState, float4, TextStyle

### Community 86 - "Divider"
Cohesion: 0.16
Nodes (8): GridsDemo, .body, Bool, GridItem, Divider, Float, float2, float4

### Community 87 - ".system"
Cohesion: 0.18
Nodes (15): LazyRowCounter, makeScrollToDemo(), ScrollDemo, .body, ScrollRow, .name, ScrollRowView, .body (+7 more)

### Community 88 - "Sendable"
Cohesion: 0.08
Nodes (31): Alignment, .offset, .xOffset, .yOffset, AlignmentID, AlignmentKey, .isFraction, HorizontalAlignment (+23 more)

### Community 89 - "Performance in MetalGraphics"
Cohesion: 0.29
Nodes (6): 2. Invalidation — name the narrowest effect, 5. Layout and text, 6. Lists and scrolling, 7. Measure, don't guess, 8. Before finishing, Performance in MetalGraphics

### Community 90 - "MetalKit"
Cohesion: 0.19
Nodes (8): App, Combine, ContentView, GPURayMarchingApp, .body, MetalKit, Scene, SwiftUI

### Community 91 - "SVGIcon"
Cohesion: 0.16
Nodes (12): Layer, SVGIcon, Bool, Bundle, Data, Float, float2, float4 (+4 more)

### Community 92 - "MouseOver"
Cohesion: 0.19
Nodes (9): IMView, IMGameView, float4, IMView, MouseOver, Bool, Float, Self (+1 more)

### Community 93 - "Hot reload"
Cohesion: 0.13
Nodes (10): Hot reload, How it fits the frame loop, Quirks, Date, Int32, URL, MacroReloader, URL (+2 more)

### Community 94 - "simd"
Cohesion: 0.11
Nodes (14): AppKit, ContainersDemo, .body, Alignment, Bool, Float, ImageDemo, .body (+6 more)

### Community 95 - "VectorItem"
Cohesion: 0.19
Nodes (12): Kind, bakedFill, bakedStroke, ellipse, roundedBox, Float, float2, VectorItem (+4 more)

### Community 96 - ".encodeFrame"
Cohesion: 0.21
Nodes (8): DebugData, GlassPass, SceneData, ShapeArgBuffer, Bool, MTLComputePipelineState, UInt64, MTLComputeCommandEncoder

### Community 97 - "LazyGridElement"
Cohesion: 0.14
Nodes (20): GridItem, LazyGridElement, .defaultCellAlignment, .trackAlignment, LazyHGrid, .defaultCellAlignment, .trackAlignment, LazyVGrid (+12 more)

### Community 98 - "IMView"
Cohesion: 0.39
Nodes (4): IMView, Spacer, Float, Void

### Community 99 - "assertSnapshot"
Cohesion: 0.17
Nodes (17): ImageIO, SnapshotTests, assertSnapshot(), failureURL(), loadPNG(), rgba(), rgbaImage(), CGImage (+9 more)

### Community 100 - "TransitionState"
Cohesion: 0.23
Nodes (4): Float, float2, TransitionState, UITransition

### Community 101 - "float3"
Cohesion: 0.14
Nodes (11): float3, .depth, .height, .width, .xy, Float, float2, float4 (+3 more)

### Community 102 - "VectorItem"
Cohesion: 0.06
Nodes (31): Clip, blur, bounds, padding1, padding2, radii, rect, rounded (+23 more)

### Community 103 - "LazyStack"
Cohesion: 0.12
Nodes (20): LazyHStack, .crossAlignment, LazyStack, .crossAlignment, .defaultLength, .estimatedLength, .initialExtent, .overscan (+12 more)

### Community 104 - "HittableView"
Cohesion: 0.24
Nodes (7): HittableView, .hitPosition, .hitSize, Bool, Float, float2, Void

### Community 105 - "float2"
Cohesion: 0.15
Nodes (8): AspectRatioElement, FixedSizeElement, PositionElement, Float, float2, ContentMode, fill, fit

### Community 106 - "GraphicsGrid2D"
Cohesion: 0.12
Nodes (19): Int32, GPUDevice, MTLDevice, GraphicsGrid2D, GridArgBuffer, GridCell, Shape, ShapeType2D (+11 more)

### Community 107 - "Utils.swift"
Cohesion: 0.17
Nodes (13): DispatchWorkItem, Debouncer, forEachGridCell(), generateRandomArray(), iterateWithStep(), name(), ClosedRange, DispatchQueue (+5 more)

### Community 108 - "Rectangle"
Cohesion: 0.18
Nodes (6): Rectangle, Float, Row, IndexSet, Void, LayoutTests

### Community 109 - "SVGPathCommand"
Cohesion: 0.12
Nodes (16): SVGPathCommand, close, cubic, line, move, quad, SVGPathData, SVGScanner (+8 more)

### Community 110 - "Image"
Cohesion: 0.11
Nodes (16): Image, .naturalSize, Interpolation, high, low, medium, none, Bundle (+8 more)

### Community 111 - "UIElement+ReactiveSetters.swift"
Cohesion: 0.06
Nodes (24): 1. The frame, 3. Hot paths — per frame, or per element per frame, 8. How it lands on screen, Effects and transitions, BlurElement, ShadowElement, Invalidation, Any (+16 more)

### Community 112 - "VList"
Cohesion: 0.29
Nodes (6): Float, HorizontalAlignment, T, Void, VList, VStack

### Community 113 - "uchar4"
Cohesion: 0.29
Nodes (6): UInt8, uchar4, .a, .b, .g, .r

### Community 114 - "TextEnvironment"
Cohesion: 0.08
Nodes (22): .design, RunStyle, Bool, Float, float4, Void, TextCase, lowercase (+14 more)

### Community 115 - "SDFBaker.swift"
Cohesion: 0.14
Nodes (21): PendingBake, SDFAtlas, SDFBakeParams, SDFBaker, SDFRegion, SDFShape, SDFShapeGeometry, SDFShapeMode (+13 more)

### Community 116 - "TextStyleElement"
Cohesion: 0.14
Nodes (7): Bool, Float, float4, Self, TextStyleElement, .displayedForeground, UIElementWrapping

### Community 117 - "PathBuilder"
Cohesion: 0.18
Nodes (10): PathBuilder, PathMorph, Bool, Double, Float, float2, VectorSegment, VectorGeometry (+2 more)

### Community 118 - "Axis"
Cohesion: 0.09
Nodes (18): ExpressibleByArrayLiteral, FlexFrame, Axis, .inverted, .size, IMView, Float, float2 (+10 more)

### Community 119 - ".expansion"
Cohesion: 0.08
Nodes (17): AccessorDeclSyntax, AccessorMacro, DeclSyntaxProtocol, DiagnosticMessage, DiagnosticSeverity, FixItMessage, MessageID, PeerMacro (+9 more)

### Community 120 - "Toggle"
Cohesion: 0.26
Nodes (7): Bool, Float, float2, Text, Void, Toggle, ToggleSwitch

### Community 121 - "ListRows"
Cohesion: 0.14
Nodes (14): 1. The pieces, 2. What a component looks like, 3. What gets generated, 4. Rules that follow, 5. Collections are just `@State` arrays, 6. Composition, not helper methods, Bindings are lowered, not passed, Compile-time state in RetainedModeUI (+6 more)

### Community 122 - "TransitionElement"
Cohesion: 0.26
Nodes (4): Float, Void, TransitionElement, .currentState

### Community 123 - "float2"
Cohesion: 0.15
Nodes (7): Bool, float2, TableCell, .clipRect, TableCells, TableColumnDivider, TableHeader

### Community 124 - "TextLayout.swift"
Cohesion: 0.13
Nodes (31): CTLine, CTRun, CTTypesetter, caretOffsets(), layoutText(), measureText(), ParagraphShaper, .baseHeight (+23 more)

### Community 125 - "FormControl"
Cohesion: 0.21
Nodes (5): FormControl, .isInteracting, Bool, Self, Void

### Community 126 - "ProposedSize"
Cohesion: 0.14
Nodes (9): MeasureCache, ProposedSize, Float, float2, UInt32, UInt8, LayoutSubview, .priority (+1 more)

### Community 127 - "FontManager"
Cohesion: 0.12
Nodes (19): CGGlyph, CoreText, FontManager, GlyphKey, GlyphMetrics, SDFFont, Bool, CGFloat (+11 more)

### Community 128 - "SwiftSyntaxMacros"
Cohesion: 0.16
Nodes (8): DragDropMacroTests, ListMacroTests, StateMacroTests, ReactiveUIMacrosPlugin, SwiftSyntaxMacroExpansion, SwiftSyntaxMacros, SwiftSyntaxMacrosGenericTestSupport, Testing

### Community 129 - "oracle.swift"
Cohesion: 0.29
Nodes (6): Probe, .body, render(), CGSize, V, View

### Community 130 - "VectorDemo"
Cohesion: 0.13
Nodes (13): StressCell, .body, StressIndex, StressRow, .body, Bool, VectorDemo, .body (+5 more)

### Community 131 - "Set"
Cohesion: 0.12
Nodes (19): Set, UInt8, Bool, ClosureExprSyntax, ExprSyntax, FunctionCallExprSyntax, ArgCombine, construct (+11 more)

### Community 132 - "StepIterator"
Cohesion: 0.24
Nodes (6): IteratorProtocol, StepIterator, StepSequence, Bool, Float, Sequence

### Community 133 - "SDFPathBuilder"
Cohesion: 0.21
Nodes (12): CGPath, PathElement, SDFPathBuilder, .isEmpty, Bool, float2, UInt8, CGRect (+4 more)

### Community 134 - "FlexFrame"
Cohesion: 0.30
Nodes (4): FlexFrame, Alignment, Float, float2

### Community 135 - "Padding"
Cohesion: 0.23
Nodes (4): Padding, Float, float2, float2

### Community 137 - "DatePicker"
Cohesion: 0.06
Nodes (24): PopoverFill, PopoverHandle, .isPresented, PopoverLayer, Bool, Float, float2, HorizontalAlignment (+16 more)

### Community 138 - "TextTests"
Cohesion: 0.12
Nodes (4): .style, Int32, Void, TextTests

### Community 139 - "TextField"
Cohesion: 0.17
Nodes (10): EditKind, deleting, other, typing, Snapshot, Character, Range, Self (+2 more)

### Community 140 - "Path"
Cohesion: 0.13
Nodes (16): Path, .isClosed, .length, .localBounds, Source, builder, commands, Bool (+8 more)

### Community 142 - "FieldBox"
Cohesion: 0.33
Nodes (4): FieldBox, .clipRect, Float, float2

### Community 143 - "Drag"
Cohesion: 0.15
Nodes (7): Carbon.HIToolbox, GameController, Drag, .description, Float, float2, Void

### Community 144 - "Section"
Cohesion: 0.17
Nodes (12): CaptionSlot, .isEmpty, RowLayout, RowSeparators, RowStack, .inset, Section, .inset (+4 more)

### Community 145 - "BodyParser"
Cohesion: 0.20
Nodes (10): BodyParser, ChainLink, Concatenation, failed, lowered, none, Bool, ExprSyntax (+2 more)

### Community 146 - "Stepper"
Cohesion: 0.22
Nodes (9): Stepper, StepperGlyph, Bool, ClosedRange, Double, float2, Text, V (+1 more)

### Community 147 - "compute2D"
Cohesion: 0.35
Nodes (11): backdrop2D(), compute2D(), glassBlur(), constant, kernel, texture2d, uint2, write (+3 more)

### Community 148 - "GlassPass"
Cohesion: 0.22
Nodes (9): GlassPass, atlasOrigin, direction, maxDepth, padding, pointsPerTexel, sceneOrigin, sigma (+1 more)

### Community 149 - "Float"
Cohesion: 0.10
Nodes (15): How it works (when the harness itself needs changing), GlassItem, Float, float2, MTLTexture, UInt8, Float, MTKView (+7 more)

### Community 150 - "ConditionalDemo"
Cohesion: 0.36
Nodes (5): ConditionalDemo, .body, Bool, Float, float4

### Community 151 - "FileWatcher"
Cohesion: 0.28
Nodes (6): FSEventStreamRef, FileWatcher, ArraySlice, DispatchQueue, URL, Void

### Community 152 - "SingleChildElement"
Cohesion: 0.16
Nodes (5): EmptyElement, SingleChildElement, Float, float2, Void

### Community 153 - "expand"
Cohesion: 0.26
Nodes (3): component(), expand(), TextMacroTests

### Community 154 - "TableColumn"
Cohesion: 0.24
Nodes (8): KeyPath, MainActor, HorizontalAlignment, KeyPathComparator, T, V, TableColumn, TableColumnBuilder

### Community 155 - "ZStack"
Cohesion: 0.23
Nodes (6): Alignment, Bool, Float, float2, Void, ZStack

### Community 156 - "TableDemo"
Cohesion: 0.40
Nodes (5): Person, float4, KeyPathComparator, TableDemo, .body

### Community 157 - "MultiChildElement"
Cohesion: 0.22
Nodes (4): MultiChildElement, .liveChildrenCount, float2, Void

### Community 158 - "Form"
Cohesion: 0.27
Nodes (5): Form, Bool, ObjectIdentifier, Void, VStack

### Community 159 - ".scan"
Cohesion: 0.14
Nodes (9): DeclReferenceExprSyntax, MemberAccessExprSyntax, Bool, FunctionCallExprSyntax, StateRewriter, ClosureExprSyntax, ExprSyntax, SyntaxProtocol (+1 more)

### Community 160 - "Button"
Cohesion: 0.24
Nodes (5): Button, HStack, ButtonTests, float2, T

### Community 161 - ".init"
Cohesion: 0.25
Nodes (7): DisclosureChevron, DisclosureGroup, Bool, Float, float2, Text, Void

### Community 163 - "KeyboardDemo"
Cohesion: 0.38
Nodes (5): KeyboardDemo, .body, Bool, Float, float2

### Community 164 - "UIShape"
Cohesion: 0.14
Nodes (11): Background, float4, Kind, capsule, circle, rect, Bool, Float (+3 more)

### Community 165 - ".step"
Cohesion: 0.21
Nodes (3): Rules, AnimationTests, Double

### Community 166 - ".body"
Cohesion: 0.17
Nodes (10): AudioSettings, FormDemo, .body, Bool, Date, Double, float4, LabeledContent (+2 more)

### Community 167 - "post"
Cohesion: 0.25
Nodes (14): CGEventFlags, CGEventType, CGMouseButton, Int64, click(), drag(), holdModifiers(), post() (+6 more)

### Community 168 - ".init"
Cohesion: 0.20
Nodes (4): SecureField, Bool, Text, Void

### Community 169 - "Line"
Cohesion: 0.29
Nodes (5): Line, .bounds, Float, float2, float4

### Community 170 - "expand"
Cohesion: 0.26
Nodes (5): BindingMacroTests, component(), expand(), NamedContentTests, SwiftParser

### Community 171 - "Foundation"
Cohesion: 0.15
Nodes (5): CoreServices, Foundation, benchmark(), Bool, Void

### Community 172 - "Spacer"
Cohesion: 0.31
Nodes (4): LeafElement, Spacer, Float, float2

### Community 173 - "FormGraphic"
Cohesion: 0.17
Nodes (8): FormGraphic, FormMetrics, mix(), Float, float2, float4, V, UIElementWrapping

### Community 174 - "ViewThatFits"
Cohesion: 0.26
Nodes (4): Float, float2, Void, ViewThatFits

### Community 175 - "Kind"
Cohesion: 0.21
Nodes (11): BoundArg, BoundHandler, Kind, condition, constructor, modifier, optional, passThrough (+3 more)

### Community 176 - "ButtonFace"
Cohesion: 0.11
Nodes (18): ButtonFace, .inset, ButtonRole, cancel, destructive, ButtonStyle, automatic, bordered (+10 more)

### Community 177 - "TableColumnLayout"
Cohesion: 0.32
Nodes (5): Bool, Float, TableColumnLayout, .count, TableColumnWidth

### Community 178 - "HotReload"
Cohesion: 0.21
Nodes (6): Duration, HotReload, Bool, Never, Void, Task

### Community 179 - "ClipElement"
Cohesion: 0.18
Nodes (5): ClipElement, .clipCornerRadii, .clipRect, Bool, float4

### Community 180 - ".snapshot"
Cohesion: 0.15
Nodes (9): Headless UI tests, Run, Snapshots, When to launch the app instead (drive-app skill), Write a test, makeImage(), CGImage, UInt8 (+1 more)

### Community 181 - "Square"
Cohesion: 0.29
Nodes (5): Square, .bounds, Float, float2, float4

### Community 182 - "GridCell"
Cohesion: 0.20
Nodes (6): GridCell, count, startIndex, from2DTo1DArray(), isBetween(), thread

### Community 184 - ".restyleLayout"
Cohesion: 0.25
Nodes (4): V, Void, WritableKeyPath, .runs

### Community 185 - ".readExactly"
Cohesion: 0.17
Nodes (9): CompilerPlugin, PluginMain, ReactiveUIMacrosPlugin, Macro, StdinFilter, Bool, Int32, UInt8 (+1 more)

### Community 186 - "Driving GPURayMarching"
Cohesion: 0.33
Nodes (5): 1. Build and launch, 2. Compile the driver, 3. Drive and look, Driving GPURayMarching, Notes

### Community 188 - "int2"
Cohesion: 0.40
Nodes (3): int2, float2, from1DTo2DArray()

### Community 191 - "VStack"
Cohesion: 0.33
Nodes (4): Float, HorizontalAlignment, VStack, .crossKey

### Community 192 - "TextDemo"
Cohesion: 0.48
Nodes (4): Bool, Float, TextDemo, .body

### Community 194 - "Phases"
Cohesion: 0.67
Nodes (3): Phases, UInt8, OptionSet

### Community 196 - ".init"
Cohesion: 0.25
Nodes (4): Background, HorizontalAlignment, T, TableRowHighlight

### Community 203 - "float2"
Cohesion: 0.20
Nodes (6): float2, .asInt2, .greatestComponent, .height, .width, Float

## Knowledge Gaps
- **555 isolated node(s):** `conditional`, `list`, `text`, `layout`, `image` (+550 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 1062 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **15 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `String` connect `String` to `Input`, `Text`, `DragAndDropTests`, `DiagnosticsTests`, `UIHarness`, `ViewItem`, `CodeGen`, `IMView`, `UIAnimation`, `IMView`, `ColorPicker`, `TextFont`, `WindowState`, `.expansion`, `View`, `Background`, `ScrollView`, `KeyPress`, `DragDropDemo`, `Inset`, `ElementIR`, `LayoutDemo`, `SVGParser`, `Graphics2D`, `StateProperty`, `ImageManager`, `HStack`, `IDElement`, `AnimationDemo`, `Table`, `ListDemo`, `uidrive/main.swift`, `Demo`, `float4x4`, `UIStorage`, `BorderElement`, `OverlayElement`, `UIContext`, `Picker`, `Frame`, `Int`, `IMView`, `VectorCanvas`, `UIElement`, `.draw`, `Divider`, `.system`, `SVGIcon`, `MouseOver`, `Hot reload`, `simd`, `IMView`, `assertSnapshot`, `Utils.swift`, `Rectangle`, `SVGPathCommand`, `Image`, `SDFBaker.swift`, `.expansion`, `Toggle`, `TextLayout.swift`, `FontManager`, `oracle.swift`, `VectorDemo`, `Set`, `FlexFrame`, `Padding`, `AnimationMacroTests`, `DatePicker`, `TextTests`, `TextField`, `Path`, `Drag`, `Section`, `BodyParser`, `Stepper`, `ConditionalDemo`, `FileWatcher`, `SingleChildElement`, `expand`, `TableColumn`, `ZStack`, `TableDemo`, `MultiChildElement`, `.scan`, `.init`, `KeyboardDemo`, `.body`, `.init`, `expand`, `Foundation`, `Kind`, `ButtonFace`, `.init`, `VStack`, `TextDemo`?**
  _High betweenness centrality (0.232) - this node is a cross-community bridge._
- **Why does `UIContext` connect `UIContext` to `VectorDemo`, `UIHarness`, `AnimatedProperty`, `DatePicker`, `TextTests`, `Path`, `UIAnimation`, `Stepper`, `ColorPicker`, `Background`, `ScrollView`, `ViewRenderer`, `MultiChildElement`, `KeyPress`, `Form`, `.init`, `.content`, `Graphics2D`, `.init`, `ViewThatFits`, `Hittable`, `IDElement`, `AnimationDemo`, `Table`, `.setGridCell`, `.restyleLayout`, `DropDestinationBase`, `int2`, `.setChild`, `.setAlignment`, `GeometryChangeElement`, `ClipRect`, `.setLayout`, `Picker`, `Int`, `VectorCanvas`, `UIElement`, `.draw`, `Divider`, `LazyStack`, `UIElement+ReactiveSetters.swift`, `VList`, `TextEnvironment`, `TextStyleElement`, `Toggle`, `ListRows`, `TransitionElement`, `float2`, `FormControl`?**
  _High betweenness centrality (0.180) - this node is a cross-community bridge._
- **Why does `UIElement` connect `UIElement` to `UIElementWrapping`, `DragAndDropTests`, `UIHarness`, `AnimatedProperty`, `GlyphSDF.metal`, `UIAnimation`, `Grid`, `VectorShape`, `Background`, `ScrollView`, `KeyPress`, `DragDropDemo`, `UIKeyframe`, `Inset`, `.content`, `LayoutDemo`, `HStack`, `IDElement`, `AnimationDemo`, `Table`, `ListDemo`, `DropDestinationBase`, `Demo`, `GeometryChangeElement`, `ClipRect`, `BorderElement`, `OverlayElement`, `UIContext`, `Picker`, `Frame`, `Int`, `LayoutView`, `StackElement`, `VectorCanvas`, `.draw`, `Divider`, `.system`, `Sendable`, `simd`, `LazyGridElement`, `assertSnapshot`, `TransitionState`, `LazyStack`, `HittableView`, `float2`, `Rectangle`, `UIElement+ReactiveSetters.swift`, `VList`, `Axis`, `ListRows`, `TransitionElement`, `FormControl`, `ProposedSize`, `VectorDemo`, `FlexFrame`, `Padding`, `DatePicker`, `Section`, `ConditionalDemo`, `SingleChildElement`, `TableColumn`, `ZStack`, `TableDemo`, `MultiChildElement`, `Form`, `.init`, `KeyboardDemo`, `UIShape`, `.body`, `Spacer`, `FormGraphic`, `ViewThatFits`, `ButtonFace`, `ClipElement`, `.snapshot`, `.setGridCell`, `.init`, `.setChild`, `VStack`, `TextDemo`, `Void`, `.init`?**
  _High betweenness centrality (0.175) - this node is a cross-community bridge._
- **Are the 6 inferred relationships involving `UIContext` (e.g. with `Effects and transitions` and `HittableGrid2D`) actually correct?**
  _`UIContext` has 6 INFERRED edges - model-reasoned connections that need verification._
- **Are the 23 inferred relationships involving `UIElement` (e.g. with `7. Diagnostics` and `What needs a relaunch`) actually correct?**
  _`UIElement` has 23 INFERRED edges - model-reasoned connections that need verification._
- **What connects `conditional`, `list`, `text` to the rest of the system?**
  _555 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `UIElementWrapping` be split into smaller, more focused modules?**
  _Cohesion score 0.14461538461538462 - nodes in this community are weakly interconnected._