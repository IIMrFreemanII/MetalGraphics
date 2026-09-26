# Graph Report - MetalGraphics  (2026-09-26)

## Corpus Check
- 235 files · ~185,341 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 16 file(s) not represented in the graph (top: (none) 4, .plist 3, .resolved 2)

## Summary
- 3973 nodes · 10771 edges · 205 communities (184 shown, 21 thin omitted)
- Extraction: 90% EXTRACTED · 10% INFERRED · 0% AMBIGUOUS · INFERRED: 1114 edges (avg confidence: 0.83)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `61249e43`
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
- FocusableElement
- WindowState
- Float
- BodyParser
- View
- Background
- ScrollView
- ViewRenderer
- KeyPress
- SDF.metal
- Equatable
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
- Shaders/Shaders.metal
- .expansion
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
- LayoutSubviews
- Macro Package Manifest
- BorderElement
- OverlayElement
- UIContext
- Picker
- Frame
- Int
- LayoutView
- SIMD2
- StackElement
- VectorCanvas
- BoundingBox2D
- UIElement
- .draw
- Divider
- .system
- AlignmentKey
- Performance in MetalGraphics
- MetalKit
- SVGIcon
- MouseOver
- HotReload
- simd
- VectorItem
- Graphics2D.swift
- LazyHGrid
- IMView
- assertSnapshot
- TransitionState
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
- VList
- uchar4
- GameController
- SDFBaker.swift
- .frame
- PathBuilder
- Axis
- .expansion
- Toggle
- ListRows
- TransitionElement
- float2
- Animator
- FormControl
- ProposedSize
- Padding
- SwiftSyntaxMacros
- oracle.swift
- VectorDemo
- ModifierSpec
- StepIterator
- SDFPathBuilder
- FlexFrame
- Padding
- AnimationMacroTests
- DatePicker
- LazyGridElement
- TextField
- Path
- LayoutMacroTests
- FieldBox
- Drag
- Section
- AnimationGroup
- Stepper
- Effects and transitions
- GlassPass
- Circle2D
- ConditionalDemo
- FileWatcher
- SingleChildElement
- ReactiveUIDiagnostic
- TableColumn
- ZStack
- TableDemo
- MultiChildElement
- Form
- View
- ButtonTests
- .init
- ComponentMacroTests
- KeyboardDemo
- UIShape
- LayoutBox
- 1. The pieces
- .init
- Binding
- Line
- expand
- Foundation
- Spacer
- FormGraphic
- float2
- Shape
- Button
- TableColumnLayout
- Interpolation
- Square
- Headless UI tests
- Square
- Animator.swift
- .replacingUnspecified
- Plugin.swift
- .readExactly
- PopoverLayer
- CaptionSlot
- IMGameView
- 9. Animation
- .pressed
- VStack
- TextDemo
- Void
- StateMacroTests
- .sizeThatFits
- TableRowHighlight
- .setLayout
- float2x2
- Content
- ListMacroTests
- HorizontalAlignment
- AnyObject
- Result

## God Nodes (most connected - your core abstractions)
1. `UIContext` - 362 edges
2. `UIElement` - 279 edges
3. `UIAnimation` - 196 edges
4. `ProposedSize` - 166 edges
5. `Graphics2D` - 120 edges
6. `simd` - 84 edges
7. `UIHarness` - 72 edges
8. `Inset` - 66 edges
9. `SingleChildElement` - 64 edges
10. `Input` - 63 edges

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

## Communities (205 total, 21 thin omitted)

### Community 0 - "UIElementWrapping"
Cohesion: 0.15
Nodes (8): Bool, Float, float2, HorizontalAlignment, Self, VerticalAlignment, Void, UIElementWrapping

### Community 1 - "Input"
Cohesion: 0.11
Nodes (13): Input, .mouseDown, .mouseMoved, .mousePressed, .mouseUp, Bool, Double, NSEvent (+5 more)

### Community 2 - "Text"
Cohesion: 0.07
Nodes (35): CGGlyph, CoreText, CTFont, FontManager, GlyphKey, GlyphMetrics, SDFFont, Float (+27 more)

### Community 3 - "Float"
Cohesion: 0.15
Nodes (10): Curve, easeIn, easeInOut, easeOut, keyframes, linear, spring, Bool (+2 more)

### Community 4 - "DragAndDropTests"
Cohesion: 0.31
Nodes (5): Chip, DragAndDropTests, Log, Bool, float2

### Community 5 - "DiagnosticsTests"
Cohesion: 0.25
Nodes (3): component(), DiagnosticsTests, stubsOnly()

### Community 6 - "UIHarness"
Cohesion: 0.11
Nodes (17): Rules, Write a test, AnimationTests, InteractionTests, makeImage(), Bool, CGImage, Double (+9 more)

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
Cohesion: 0.18
Nodes (10): CodeGen, .armedHandlers, Dependents, RowsMode, full, insert, remove, DeclSyntax (+2 more)

### Community 11 - "IMView"
Cohesion: 0.25
Nodes (9): ExpandedFrame, FlexFrame, Frame, IMView, Alignment, Float, float2, Self (+1 more)

### Community 12 - "GlyphSDF.metal"
Cohesion: 0.09
Nodes (34): bakeSDF(), lineWinding(), constant, float2, kernel, texture2d, uint, uint2 (+26 more)

### Community 13 - "MathLib.swift"
Cohesion: 0.18
Nodes (17): int3, dragDirection(), from1DTo3DArray(), from2DTo1DArray(), from3DTo1DArray(), fromPixelCoordToGridIndex(), fromWorldPositionToGridIndex(), lerp() (+9 more)

### Community 14 - "UIAnimation"
Cohesion: 0.06
Nodes (21): Sliding layout, UIAnimation, Background, Circle, ExpandedFrame, FlexFrame, Frame, HStack (+13 more)

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
Cohesion: 0.06
Nodes (38): AudioSettings, FormDemo, .body, Bool, Date, Double, float4, Theme (+30 more)

### Community 20 - "VectorShape"
Cohesion: 0.09
Nodes (26): Text styling, Capsule, Circle, .length, .localBounds, Ellipse, .length, .localBounds (+18 more)

### Community 21 - "FocusableElement"
Cohesion: 0.16
Nodes (6): FocusableElement, Bool, float2, Self, Void, UIElementWrapping

### Community 22 - "WindowState"
Cohesion: 0.15
Nodes (13): CaseIterable, Application, Event, Inspector, Navigation, Global, Reload, Bool (+5 more)

### Community 23 - "Float"
Cohesion: 0.12
Nodes (12): table, ImageQuad, GlassItem, GlassPass, GPUClip, Float, float2, float4 (+4 more)

### Community 24 - "BodyParser"
Cohesion: 0.16
Nodes (11): CodeBlockItemListSyntax, IfExprSyntax, BodyParser, Bool, ClosureExprSyntax, ExprSyntax, FunctionCallExprSyntax, MemberBlockItemListSyntax (+3 more)

### Community 25 - "View"
Cohesion: 0.11
Nodes (19): Inspector, .body, Navigation, .body, ToggleView, .body, Number3Field, .body (+11 more)

### Community 26 - "Background"
Cohesion: 0.18
Nodes (6): Background, GlassBackground, GlassMaterial, Float, float2, float4

### Community 27 - "ScrollView"
Cohesion: 0.08
Nodes (18): Bool, ScrollIndicator, .visibility, ScrollIndicatorVisibility, automatic, hidden, never, visible (+10 more)

### Community 28 - "ViewRenderer"
Cohesion: 0.13
Nodes (14): MetalView, .body, CGSize, Double, Float, float2, MTKView, View (+6 more)

### Community 29 - "KeyPress"
Cohesion: 0.17
Nodes (10): CharacterSet, ExpressibleByExtendedGraphemeClusterLiteral, KeyEquivalent, KeyPress, Phases, Character, NSEvent, UInt8 (+2 more)

### Community 30 - "SDF.metal"
Cohesion: 0.15
Nodes (15): dot2(), float2, float4, sdBox(), sdBoxSquared(), sdCircle(), sdCircleSquared(), sdOrientedBox() (+7 more)

### Community 31 - "Equatable"
Cohesion: 0.27
Nodes (7): Equatable, DragChip, DragDropDemo, .body, Bool, float4, Float

### Community 32 - "Sendable"
Cohesion: 0.18
Nodes (11): KeyframeElement, KeyframeSegment, Any, Float, float2, Self, V, UIKeyframe (+3 more)

### Community 33 - "Inset"
Cohesion: 0.12
Nodes (18): .body, .body, Float, .packed, .packed, .packed, SIMD4, .packed (+10 more)

### Community 34 - "Set"
Cohesion: 0.09
Nodes (31): Set, UInt8, Owner, component, node, AnimationScope, Attach, arity (+23 more)

### Community 35 - "EffectElement"
Cohesion: 0.15
Nodes (11): BlurElement, EffectElement, .hasEffect, .localEffect, ShadowState, .margin, Bool, Float (+3 more)

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
Cohesion: 0.08
Nodes (27): How it works (when the harness itself needs changing), CustomStringConvertible, Error, Glyph, Line, Graphics2D, .glassAtlasWidth, .size (+19 more)

### Community 40 - "Math.metal"
Cohesion: 0.15
Nodes (14): Default arguments, Macro plugin: the zero-length message, Setup, Why the Debug settings are what they are, cross2d(), float2, float4, ndot() (+6 more)

### Community 41 - "BoundingBox3D"
Cohesion: 0.14
Nodes (13): BoundingBox3D, .back, .bottom, .bottomRightBack, .depth, .front, .height, .left (+5 more)

### Community 42 - "bakeVectorSDF"
Cohesion: 0.09
Nodes (35): normalize(), bakeVectorSDF(), closestOnLine(), closestOnQuadratic(), isInside(), lineCrossing(), constant, float2 (+27 more)

### Community 43 - "Shaders/Shaders.metal"
Cohesion: 0.12
Nodes (23): metal_stdlib, ellipseAlong(), GridArgBuffer, GridCell, count, startIndex, hash12(), Line (+15 more)

### Community 44 - ".expansion"
Cohesion: 0.09
Nodes (22): DeclGroupSyntax, ExtensionDeclSyntax, ExtensionMacro, MemberMacro, PatternBindingSyntax, .states, TypeSyntax, .arrayStates (+14 more)

### Community 45 - "String"
Cohesion: 0.12
Nodes (6): String, .uint32, UInt32, Bool, FunctionCallExprSyntax, Naming

### Community 46 - "SceneData"
Cohesion: 0.29
Nodes (7): DebugData, drawGrid, showFilledCells, SceneData, debug, time, windowSize

### Community 47 - "ImageManager"
Cohesion: 0.12
Nodes (18): CGContext, BitmapTexture, ImageManager, ImageQuad, .bounds, PendingUpload, Bundle, CGFloat (+10 more)

### Community 48 - "Rect"
Cohesion: 0.16
Nodes (10): Rect, .center, .height, .maxX, .maxY, .minX, .minY, .width (+2 more)

### Community 49 - "ClipRect"
Cohesion: 0.14
Nodes (15): HittableGrid2D, HittableGridCell, HoveredView, Bool, Float, float2, ObjectIdentifier, ClipRect (+7 more)

### Community 50 - "HStack"
Cohesion: 0.33
Nodes (4): HStack, .crossKey, Float, VerticalAlignment

### Community 51 - "IDElement"
Cohesion: 0.15
Nodes (9): ID, IDElement, ScrollViewProxy, ScrollViewReader, Alignment, AnyHashable, float2, Void (+1 more)

### Community 52 - "AnimationDemo"
Cohesion: 0.23
Nodes (8): AnimatedItem, AnimationDemo, .body, Bool, Float, float4, Identifiable, Row

### Community 53 - "MetalViewRepresentable"
Cohesion: 0.29
Nodes (6): Context, MetalViewRepresentable, MTKView, NSView, NSViewType, ViewRepresentable

### Community 54 - "Table"
Cohesion: 0.17
Nodes (9): Bool, float2, KeyPathComparator, T, Text, Void, Table, .clipRect (+1 more)

### Community 55 - "ListDemo"
Cohesion: 0.24
Nodes (10): ChipView, DemoItem, ListDemo, .body, RowView, Bool, Float, float4 (+2 more)

### Community 56 - "Float"
Cohesion: 0.28
Nodes (6): Float, .degrees, .isNegative, .radians, Bool, ClosedRange

### Community 57 - "DropDestinationBase"
Cohesion: 0.07
Nodes (23): HStack, DraggableElement, DragPreviewLayer, .hasEffect, .localEffect, DragSession, DropDestinationBase, DropDestinationElement (+15 more)

### Community 58 - "uidrive/main.swift"
Cohesion: 0.14
Nodes (30): CGEventFlags, CGEventType, CGKeyCode, CGMouseButton, CGWindowID, Int64, click(), drag() (+22 more)

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
Cohesion: 0.15
Nodes (10): graphify, Hot reload, Performance, 1. Build and launch, 2. Compile the driver, 3. Drive and look, Driving GPURayMarching, Notes (+2 more)

### Community 65 - "Glass"
Cohesion: 0.07
Nodes (28): Circle, color, depth, position, radius, Clip, blur, bounds (+20 more)

### Community 66 - "GeometryChangeElement"
Cohesion: 0.14
Nodes (11): CoordinateSpace, global, local, GeometryChangeElement, GeometryProxy, GeometryReader, Float, float2 (+3 more)

### Community 67 - "Comparable Clamp"
Cohesion: 0.40
Nodes (3): Comparable, ClosedRange, Self

### Community 68 - "LayoutSubviews"
Cohesion: 0.12
Nodes (15): Cache, HStackLayout, Layout, LayoutSubviews, .endIndex, .startIndex, Float, HorizontalAlignment (+7 more)

### Community 73 - "BorderElement"
Cohesion: 0.16
Nodes (9): BorderElement, .color, .lineWidth, .shape, BorderLayer, Float, float2, float4 (+1 more)

### Community 74 - "OverlayElement"
Cohesion: 0.23
Nodes (6): OverlayElement, .alignment, Alignment, Bool, float2, Void

### Community 75 - "UIContext"
Cohesion: 0.05
Nodes (11): Float, float4, ObjectIdentifier, UIContext, .isDragging, LayoutPass, Any, UInt32 (+3 more)

### Community 76 - "Picker"
Cohesion: 0.10
Nodes (22): Kind, check, menuItem, segment, Picker, .selectedTitle, PickerMark, PickerStyle (+14 more)

### Community 77 - "Frame"
Cohesion: 0.26
Nodes (6): Frame, .size, Alignment, Float, float2, Void

### Community 78 - "Int"
Cohesion: 0.15
Nodes (11): AnyIterator, Int, Bool, ClosedRange, SparseSet, .count, .isEmpty, .storedKeys (+3 more)

### Community 79 - "LayoutView"
Cohesion: 0.19
Nodes (7): AnyLayout, AnyLayoutBox, LayoutSubview, .priority, LayoutView, Alignment, float2

### Community 80 - "SIMD2"
Cohesion: 0.23
Nodes (11): HStack, .size, IMView, Float, HorizontalAlignment, Self, VerticalAlignment, Void (+3 more)

### Community 81 - "StackElement"
Cohesion: 0.23
Nodes (8): origin, StackElement, .crossKey, .size, Bool, Float, float2, Void

### Community 82 - "VectorCanvas"
Cohesion: 0.24
Nodes (6): Float, float2, Self, VectorCanvas, .children, VectorShapeList

### Community 83 - "BoundingBox2D"
Cohesion: 0.17
Nodes (12): BoundingBox2D, .bottom, .bottomRight, .height, .left, .right, .top, .topLeft (+4 more)

### Community 84 - "UIElement"
Cohesion: 0.07
Nodes (22): 7. Diagnostics, LayoutTraits, AnyHashable, float4, Void, UIElement, .clipCornerRadii, .clipRect (+14 more)

### Community 85 - ".draw"
Cohesion: 0.17
Nodes (4): EffectState, float4, Float, float4

### Community 86 - "Divider"
Cohesion: 0.27
Nodes (4): Divider, Float, float2, float4

### Community 87 - ".system"
Cohesion: 0.10
Nodes (25): ContainersDemo, .body, Alignment, Bool, Float, GridsDemo, .body, Bool (+17 more)

### Community 88 - "AlignmentKey"
Cohesion: 0.09
Nodes (27): Hasher, Alignment, Float, Alignment, .offset, .xOffset, .yOffset, AlignmentID (+19 more)

### Community 89 - "Performance in MetalGraphics"
Cohesion: 0.25
Nodes (7): 2. Invalidation — name the narrowest effect, 4. GPU and Metal (`Graphics2D.swift`, `Shaders/Shaders.metal`), 5. Layout and text, 6. Lists and scrolling, 7. Measure, don't guess, 8. Before finishing, Performance in MetalGraphics

### Community 90 - "MetalKit"
Cohesion: 0.12
Nodes (13): App, Combine, ContentView, .body, GPURayMarchingApp, .body, .inspectorView, Number2Field (+5 more)

### Community 91 - "SVGIcon"
Cohesion: 0.22
Nodes (8): Layer, SVGIcon, Bool, Bundle, Data, Float, float2, float4

### Community 92 - "MouseOver"
Cohesion: 0.35
Nodes (6): IMView, MouseOver, Bool, Float, Self, Void

### Community 93 - "HotReload"
Cohesion: 0.09
Nodes (17): Duration, Hot reload, How it fits the frame loop, Quirks, What needs a relaunch, HotReload, Bool, Date (+9 more)

### Community 94 - "simd"
Cohesion: 0.13
Nodes (9): AppKit, GlassDemo, .body, Bool, Metal, MetalGraphicsLib, ReactiveUI, simd (+1 more)

### Community 95 - "VectorItem"
Cohesion: 0.19
Nodes (12): Kind, bakedFill, bakedStroke, ellipse, roundedBox, Float, float2, VectorItem (+4 more)

### Community 96 - "Graphics2D.swift"
Cohesion: 0.40
Nodes (5): DebugData, SceneData, ShapeArgBuffer, Bool, UInt64

### Community 97 - "LazyHGrid"
Cohesion: 0.19
Nodes (15): GridItem, LazyHGrid, .defaultCellAlignment, .trackAlignment, LazyVGrid, .defaultCellAlignment, .trackAlignment, Size (+7 more)

### Community 98 - "IMView"
Cohesion: 0.39
Nodes (4): IMView, Spacer, Float, Void

### Community 99 - "assertSnapshot"
Cohesion: 0.21
Nodes (15): ImageIO, assertSnapshot(), failureURL(), loadPNG(), rgba(), rgbaImage(), CGImage, Double (+7 more)

### Community 100 - "TransitionState"
Cohesion: 0.27
Nodes (4): Float, float2, TransitionState, UITransition

### Community 101 - "float3"
Cohesion: 0.14
Nodes (11): float3, .depth, .height, .width, .xy, Float, float2, float4 (+3 more)

### Community 102 - "VectorItem"
Cohesion: 0.09
Nodes (23): ImageQuad, depth, flags, lod, position, size, textureIndex, tint (+15 more)

### Community 103 - "LazyStack"
Cohesion: 0.12
Nodes (19): LazyHStack, .crossAlignment, LazyStack, .crossAlignment, .defaultLength, .estimatedLength, .initialExtent, .overscan (+11 more)

### Community 104 - "HittableView"
Cohesion: 0.23
Nodes (7): HittableView, .hitPosition, .hitSize, Bool, Float, float2, Void

### Community 105 - ".content"
Cohesion: 0.11
Nodes (14): .content, AspectRatioElement, ClipElement, .clipCornerRadii, .clipRect, FixedSizeElement, PositionElement, Bool (+6 more)

### Community 106 - "GraphicsGrid2D"
Cohesion: 0.09
Nodes (22): Int32, GPUDevice, MTLDevice, GraphicsGrid2D, GridArgBuffer, GridCell, Shape, ShapeType2D (+14 more)

### Community 107 - "Utils.swift"
Cohesion: 0.17
Nodes (13): DispatchWorkItem, Debouncer, forEachGridCell(), generateRandomArray(), iterateWithStep(), name(), ClosedRange, DispatchQueue (+5 more)

### Community 108 - "Rectangle"
Cohesion: 0.16
Nodes (7): Rectangle, Float, IndexSet, Void, LayoutTests, SnapshotTests, XCTestCase

### Community 109 - "SVGPathCommand"
Cohesion: 0.12
Nodes (16): SVGPathCommand, close, cubic, line, move, quad, SVGPathData, SVGScanner (+8 more)

### Community 110 - "Image"
Cohesion: 0.17
Nodes (9): Image, .naturalSize, Float, float2, float4, Self, TemplateRenderingMode, original (+1 more)

### Community 111 - "Void"
Cohesion: 0.09
Nodes (15): 1. The frame, 3. Hot paths — per frame, or per element per frame, 8. How it lands on screen, ShadowElement, Invalidation, Any, Bool, Double (+7 more)

### Community 112 - "VList"
Cohesion: 0.19
Nodes (10): 5. Collections are just `@State` arrays, Bindings are lowered, not passed, Mutation carries the operation, Named content closures, The plain setter still works, Float, HorizontalAlignment, T (+2 more)

### Community 113 - "uchar4"
Cohesion: 0.29
Nodes (6): UInt8, uchar4, .a, .b, .g, .r

### Community 115 - "SDFBaker.swift"
Cohesion: 0.13
Nodes (22): CoreGraphics, PendingBake, SDFAtlas, SDFBakeParams, SDFBaker, SDFRegion, SDFShape, SDFShapeGeometry (+14 more)

### Community 116 - ".frame"
Cohesion: 0.40
Nodes (3): Alignment, FlexFrame, Frame

### Community 117 - "PathBuilder"
Cohesion: 0.17
Nodes (10): PathBuilder, PathMorph, Bool, Double, Float, float2, VectorSegment, VectorGeometry (+2 more)

### Community 118 - "Axis"
Cohesion: 0.07
Nodes (22): ExpressibleByArrayLiteral, FlexFrame, Axis, .inverted, .size, IMView, Float, float2 (+14 more)

### Community 119 - ".expansion"
Cohesion: 0.09
Nodes (15): AccessorDeclSyntax, AccessorMacro, DeclReferenceExprSyntax, DeclSyntaxProtocol, MemberAccessExprSyntax, PeerMacro, StateRewriter, ClosureExprSyntax (+7 more)

### Community 120 - "Toggle"
Cohesion: 0.26
Nodes (7): Bool, Float, float2, Text, Void, Toggle, ToggleSwitch

### Community 121 - "ListRows"
Cohesion: 0.44
Nodes (3): ListRows, T, Void

### Community 122 - "TransitionElement"
Cohesion: 0.26
Nodes (4): Float, Void, TransitionElement, .currentState

### Community 123 - "float2"
Cohesion: 0.13
Nodes (10): Bool, Float, float2, HorizontalAlignment, TableCell, .clipRect, TableCells, TableColumnDivider (+2 more)

### Community 124 - "Animator"
Cohesion: 0.25
Nodes (11): Apply, Animator, .isIdle, Key, Running, Bool, Double, Float (+3 more)

### Community 125 - "FormControl"
Cohesion: 0.21
Nodes (5): FormControl, .isInteracting, Bool, Self, Void

### Community 126 - "ProposedSize"
Cohesion: 0.20
Nodes (9): benchmark(), Bool, Void, MeasureCache, ProposedSize, Float, float2, UInt32 (+1 more)

### Community 127 - "Padding"
Cohesion: 0.31
Nodes (5): IMView, Padding, Float, Self, Void

### Community 128 - "SwiftSyntaxMacros"
Cohesion: 0.29
Nodes (6): DragDropMacroTests, ReactiveUIMacrosPlugin, SwiftSyntaxMacroExpansion, SwiftSyntaxMacros, SwiftSyntaxMacrosGenericTestSupport, Testing

### Community 129 - "oracle.swift"
Cohesion: 0.29
Nodes (6): Probe, .body, render(), CGSize, V, View

### Community 130 - "VectorDemo"
Cohesion: 0.21
Nodes (8): StressCell, .body, StressIndex, StressRow, .body, Bool, VectorDemo, .body

### Community 131 - "ModifierSpec"
Cohesion: 0.17
Nodes (16): ArgCombine, construct, float2, identity, labeled, ArgSpec, Arity, leaf (+8 more)

### Community 132 - "StepIterator"
Cohesion: 0.27
Nodes (6): IteratorProtocol, StepIterator, StepSequence, Bool, Float, Sequence

### Community 133 - "SDFPathBuilder"
Cohesion: 0.21
Nodes (12): CGPath, PathElement, SDFPathBuilder, .isEmpty, Bool, float2, UInt8, CGRect (+4 more)

### Community 134 - "FlexFrame"
Cohesion: 0.30
Nodes (4): FlexFrame, Alignment, Float, float2

### Community 135 - "Padding"
Cohesion: 0.22
Nodes (4): Padding, Float, float2, float2

### Community 137 - "DatePicker"
Cohesion: 0.10
Nodes (15): CalendarView, Components, DatePicker, DatePickerStyle, compact, graphical, DayCell, Bool (+7 more)

### Community 138 - "LazyGridElement"
Cohesion: 0.35
Nodes (5): LazyGridElement, .defaultCellAlignment, .trackAlignment, Bool, float2

### Community 139 - "TextField"
Cohesion: 0.19
Nodes (10): EditKind, deleting, other, typing, Snapshot, Range, Self, Void (+2 more)

### Community 140 - "Path"
Cohesion: 0.13
Nodes (16): Path, .isClosed, .length, .localBounds, Source, builder, commands, Bool (+8 more)

### Community 142 - "FieldBox"
Cohesion: 0.26
Nodes (4): FieldBox, .clipRect, Float, float2

### Community 143 - "Drag"
Cohesion: 0.24
Nodes (5): Drag, .description, Float, float2, Void

### Community 144 - "Section"
Cohesion: 0.19
Nodes (9): RowLayout, RowSeparators, RowStack, .inset, Section, .inset, SectionCard, Float (+1 more)

### Community 145 - "AnimationGroup"
Cohesion: 0.36
Nodes (4): AnimationGroup, Void, UITransaction, withAnimation()

### Community 146 - "Stepper"
Cohesion: 0.22
Nodes (9): Stepper, StepperGlyph, Bool, ClosedRange, Double, float2, Text, V (+1 more)

### Community 147 - "Effects and transitions"
Cohesion: 0.19
Nodes (13): Effects and transitions, backdrop2D(), compute2D(), glassBlur(), constant, kernel, texture2d, uint2 (+5 more)

### Community 148 - "GlassPass"
Cohesion: 0.22
Nodes (9): GlassPass, atlasOrigin, direction, maxDepth, padding, pointsPerTexel, sceneOrigin, sigma (+1 more)

### Community 149 - "Circle2D"
Cohesion: 0.29
Nodes (5): Circle2D, .bounds, Float, float2, float4

### Community 150 - "ConditionalDemo"
Cohesion: 0.31
Nodes (5): ConditionalDemo, .body, Bool, Float, float4

### Community 151 - "FileWatcher"
Cohesion: 0.28
Nodes (6): FSEventStreamRef, FileWatcher, ArraySlice, DispatchQueue, URL, Void

### Community 152 - "SingleChildElement"
Cohesion: 0.16
Nodes (5): EmptyElement, SingleChildElement, Float, float2, Void

### Community 153 - "ReactiveUIDiagnostic"
Cohesion: 0.24
Nodes (7): DiagnosticMessage, DiagnosticSeverity, FixItMessage, MessageID, ReactiveUIDiagnostic, ReactiveUIFixIt, SwiftDiagnostics

### Community 154 - "TableColumn"
Cohesion: 0.24
Nodes (8): KeyPath, MainActor, HorizontalAlignment, KeyPathComparator, T, V, TableColumn, TableColumnBuilder

### Community 155 - "ZStack"
Cohesion: 0.25
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

### Community 159 - "View"
Cohesion: 0.18
Nodes (11): Bool, View, Background, ExpandedFrame, FlexFrame, HStack, .isSpacer, MouseOver (+3 more)

### Community 160 - "ButtonTests"
Cohesion: 0.27
Nodes (3): ButtonTests, float2, T

### Community 161 - ".init"
Cohesion: 0.25
Nodes (7): DisclosureChevron, DisclosureGroup, Bool, Float, float2, Text, Void

### Community 163 - "KeyboardDemo"
Cohesion: 0.38
Nodes (5): KeyboardDemo, .body, Bool, Float, float2

### Community 164 - "UIShape"
Cohesion: 0.16
Nodes (10): Background, float4, Kind, capsule, circle, rect, Bool, float4 (+2 more)

### Community 165 - "LayoutBox"
Cohesion: 0.43
Nodes (3): LayoutBox, L, UInt32

### Community 166 - "1. The pieces"
Cohesion: 0.29
Nodes (6): 1. The pieces, 2. What a component looks like, 3. What gets generated, 4. Rules that follow, 6. Composition, not helper methods, Compile-time state in RetainedModeUI

### Community 168 - "Binding"
Cohesion: 0.16
Nodes (10): Member, Binding, .wrappedValue, Value, Void, SecureField, Text, ReferenceWritableKeyPath (+2 more)

### Community 169 - "Line"
Cohesion: 0.29
Nodes (5): Line, .bounds, Float, float2, float4

### Community 170 - "expand"
Cohesion: 0.26
Nodes (5): BindingMacroTests, component(), expand(), NamedContentTests, SwiftParser

### Community 172 - "Spacer"
Cohesion: 0.31
Nodes (4): LeafElement, Spacer, Float, float2

### Community 173 - "FormGraphic"
Cohesion: 0.16
Nodes (8): FormGraphic, FormMetrics, mix(), Float, float2, float4, V, UIElementWrapping

### Community 174 - "float2"
Cohesion: 0.15
Nodes (8): float2, check(), HorizontalAlignment, layout(), Mid, Row, Float, float2

### Community 175 - "Shape"
Cohesion: 0.40
Nodes (5): Shape, clip, depth, index, shapeType

### Community 176 - "Button"
Cohesion: 0.09
Nodes (23): Button, .labelColor, ButtonFace, .inset, ButtonRole, cancel, destructive, ButtonStyle (+15 more)

### Community 177 - "TableColumnLayout"
Cohesion: 0.32
Nodes (5): Bool, Float, TableColumnLayout, .count, TableColumnWidth

### Community 178 - "Interpolation"
Cohesion: 0.40
Nodes (5): Interpolation, high, low, medium, none

### Community 179 - "Square"
Cohesion: 0.33
Nodes (6): Square, color, depth, position, rotation, size

### Community 180 - "Headless UI tests"
Cohesion: 0.40
Nodes (4): Headless UI tests, Run, Snapshots, When to launch the app instead (drive-app skill)

### Community 181 - "Square"
Cohesion: 0.29
Nodes (5): Square, .bounds, Float, float2, float4

### Community 184 - "Plugin.swift"
Cohesion: 0.29
Nodes (5): CompilerPlugin, PluginMain, ReactiveUIMacrosPlugin, Macro, SwiftCompilerPlugin

### Community 185 - ".readExactly"
Cohesion: 0.39
Nodes (4): StdinFilter, Bool, Int32, UInt8

### Community 186 - "PopoverLayer"
Cohesion: 0.17
Nodes (9): PopoverFill, PopoverHandle, .isPresented, PopoverLayer, Bool, Float, float2, HorizontalAlignment (+1 more)

### Community 187 - "CaptionSlot"
Cohesion: 0.29
Nodes (4): CaptionSlot, .isEmpty, Bool, VStack

### Community 188 - "IMGameView"
Cohesion: 0.33
Nodes (3): IMView, IMGameView, float4

### Community 189 - "9. Animation"
Cohesion: 0.43
Nodes (6): 9. Animation, Costs to know, Repeat and keyframes, Scopes, The runtime, `withAnimation`

### Community 191 - "VStack"
Cohesion: 0.33
Nodes (4): Float, HorizontalAlignment, VStack, .crossKey

### Community 192 - "TextDemo"
Cohesion: 0.53
Nodes (3): Float, TextDemo, .body

### Community 196 - "TableRowHighlight"
Cohesion: 0.67
Nodes (3): Background, T, TableRowHighlight

### Community 199 - "Content"
Cohesion: 0.50
Nodes (4): Content, bitmap, missing, svg

### Community 201 - "HorizontalAlignment"
Cohesion: 0.50
Nodes (3): HorizontalAlignment, Mid, CGFloat

### Community 204 - "Result"
Cohesion: 0.67
Nodes (3): Result, handled, ignored

## Knowledge Gaps
- **500 isolated node(s):** `conditional`, `list`, `text`, `layout`, `image` (+495 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 982 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **21 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `String` connect `String` to `Input`, `Text`, `DragAndDropTests`, `DiagnosticsTests`, `UIHarness`, `ViewItem`, `CodeGen`, `IMView`, `UIAnimation`, `IMView`, `ColorPicker`, `WindowState`, `BodyParser`, `View`, `Background`, `ScrollView`, `KeyPress`, `Equatable`, `Set`, `LayoutDemo`, `SVGParser`, `Graphics2D`, `.expansion`, `ImageManager`, `HStack`, `IDElement`, `AnimationDemo`, `Table`, `ListDemo`, `uidrive/main.swift`, `Demo`, `float4x4`, `BorderElement`, `OverlayElement`, `UIContext`, `Picker`, `Frame`, `SIMD2`, `VectorCanvas`, `UIElement`, `.draw`, `.system`, `MetalKit`, `SVGIcon`, `MouseOver`, `HotReload`, `IMView`, `assertSnapshot`, `Utils.swift`, `SVGPathCommand`, `Image`, `SDFBaker.swift`, `.expansion`, `Toggle`, `ProposedSize`, `Padding`, `oracle.swift`, `ModifierSpec`, `FlexFrame`, `Padding`, `AnimationMacroTests`, `DatePicker`, `TextField`, `Path`, `Drag`, `Section`, `Stepper`, `ConditionalDemo`, `FileWatcher`, `SingleChildElement`, `ReactiveUIDiagnostic`, `TableColumn`, `ZStack`, `TableDemo`, `MultiChildElement`, `.init`, `KeyboardDemo`, `.init`, `Binding`, `expand`, `Foundation`, `FormGraphic`, `float2`, `Button`, `CaptionSlot`, `.pressed`, `VStack`?**
  _High betweenness centrality (0.219) - this node is a cross-community bridge._
- **Why does `UIElement` connect `UIElement` to `UIElementWrapping`, `DragAndDropTests`, `UIHarness`, `UIAnimation`, `Grid`, `ColorPicker`, `VectorShape`, `FocusableElement`, `Background`, `ScrollView`, `KeyPress`, `Equatable`, `Sendable`, `Inset`, `EffectElement`, `LayoutDemo`, `ClipRect`, `HStack`, `IDElement`, `AnimationDemo`, `Table`, `ListDemo`, `DropDestinationBase`, `Demo`, `GeometryChangeElement`, `LayoutSubviews`, `BorderElement`, `OverlayElement`, `UIContext`, `Picker`, `Frame`, `Int`, `LayoutView`, `StackElement`, `VectorCanvas`, `.draw`, `.system`, `AlignmentKey`, `HotReload`, `simd`, `LazyHGrid`, `LazyStack`, `HittableView`, `.content`, `Rectangle`, `Void`, `VList`, `.frame`, `Axis`, `ListRows`, `TransitionElement`, `float2`, `Animator`, `FormControl`, `ProposedSize`, `VectorDemo`, `FlexFrame`, `Padding`, `LazyGridElement`, `Section`, `ConditionalDemo`, `SingleChildElement`, `TableColumn`, `ZStack`, `TableDemo`, `MultiChildElement`, `Form`, `.init`, `KeyboardDemo`, `UIShape`, `Spacer`, `FormGraphic`, `float2`, `Button`, `PopoverLayer`, `CaptionSlot`, `VStack`, `TextDemo`, `Void`, `TableRowHighlight`?**
  _High betweenness centrality (0.199) - this node is a cross-community bridge._
- **Why does `Int` connect `Int` to `UIElementWrapping`, `VectorDemo`, `Float`, `DragAndDropTests`, `SDFPathBuilder`, `FlexFrame`, `UIHarness`, `ModifierSpec`, `ViewItem`, `DatePicker`, `TextField`, `LazyGridElement`, `MathLib.swift`, `UIAnimation`, `IMView`, `FieldBox`, `Grid`, `ColorPicker`, `ConditionalDemo`, `WindowState`, `Float`, `BodyParser`, `ZStack`, `TableDemo`, `MultiChildElement`, `Equatable`, `View`, `Set`, `LayoutDemo`, `VectorBaker`, `Graphics2D`, `String`, `float2`, `ImageManager`, `TableColumnLayout`, `AnimationDemo`, `Table`, `ListDemo`, `DropDestinationBase`, `.readExactly`, `uidrive/main.swift`, `.pressed`, `Array`, `TextDemo`, `LayoutSubviews`, `UIContext`, `Picker`, `LayoutView`, `StackElement`, `UIElement`, `.system`, `AlignmentKey`, `HotReload`, `LazyHGrid`, `assertSnapshot`, `LazyStack`, `GraphicsGrid2D`, `Utils.swift`, `Rectangle`, `Void`, `VList`, `SDFBaker.swift`, `PathBuilder`, `ListRows`, `Animator`, `ProposedSize`?**
  _High betweenness centrality (0.167) - this node is a cross-community bridge._
- **Are the 5 inferred relationships involving `UIContext` (e.g. with `Effects and transitions` and `HittableGrid2D`) actually correct?**
  _`UIContext` has 5 INFERRED edges - model-reasoned connections that need verification._
- **Are the 23 inferred relationships involving `UIElement` (e.g. with `7. Diagnostics` and `What needs a relaunch`) actually correct?**
  _`UIElement` has 23 INFERRED edges - model-reasoned connections that need verification._
- **What connects `conditional`, `list`, `text` to the rest of the system?**
  _500 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Input` be split into smaller, more focused modules?**
  _Cohesion score 0.11396011396011396 - nodes in this community are weakly interconnected._