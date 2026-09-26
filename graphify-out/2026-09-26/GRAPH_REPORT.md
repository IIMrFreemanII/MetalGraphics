# Graph Report - MetalGraphics  (2026-09-26)

## Corpus Check
- 234 files · ~182,511 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 16 file(s) not represented in the graph (top: (none) 4, .plist 3, .resolved 2)

## Summary
- 3923 nodes · 10598 edges · 191 communities (177 shown, 14 thin omitted)
- Extraction: 90% EXTRACTED · 10% INFERRED · 0% AMBIGUOUS · INFERRED: 1060 edges (avg confidence: 0.84)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `bd52fb10`
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
- Background
- CodeGen
- .body
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
- NumberField
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
- VList
- MetalViewRepresentable
- Table
- ListDemo
- Float
- StackElement
- post
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
- uidrive/main.swift
- IMView
- Slider
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
- Hot reload
- simd
- VectorItem
- Graphics2D.swift
- HList
- ViewItem
- assertSnapshot
- TransitionElement
- float3
- VectorItem
- LazyStack
- HittableView
- ProposedSize
- GraphicsGrid2D
- Utils.swift
- Rectangle
- SVGPathCommand
- Image
- Void
- .init
- uchar4
- GameController
- SDFBaker.swift
- Float
- PathBuilder
- Axis
- .expansion
- Toggle
- ListRows
- View
- float2
- Animator
- FormControl
- .replacingUnspecified
- Write a test
- SwiftSyntaxMacros
- SwiftUI
- SingleChildElement
- ModifierSpec
- StepIterator
- SDFPathBuilder
- FlexFrame
- Padding
- AnimationMacroTests
- DatePicker
- ViewThatFits
- TextField
- Path
- LayoutMacroTests
- FieldBox
- HotReload
- Section
- AnimationGroup
- Stepper
- Effects and transitions
- GlassPass
- .init
- ConditionalDemo
- FileWatcher
- EmptyElement
- ReactiveUIDiagnostic
- TableColumn
- ZStack
- TableDemo
- MultiChildElement
- Form
- View
- T
- .init
- ComponentMacroTests
- KeyboardDemo
- UIShape
- TableCell
- float2
- .texture
- Binding
- T
- expand
- Foundation
- Spacer
- FormGraphic
- layoutchecks/main.swift
- Shape
- Button
- TableColumnLayout
- Interpolation
- Square
- Headless UI tests
- Number2Field
- Animator.swift
- Phases
- ReactiveUIMacrosPlugin
- .readExactly
- IMGameView
- 9. Animation
- .pressed
- .sizeThatFits
- .setLayout

## God Nodes (most connected - your core abstractions)
1. `UIContext` - 356 edges
2. `UIElement` - 275 edges
3. `UIAnimation` - 193 edges
4. `ProposedSize` - 164 edges
5. `Graphics2D` - 119 edges
6. `simd` - 83 edges
7. `Inset` - 65 edges
8. `SingleChildElement` - 64 edges
9. `UIHarness` - 64 edges
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

## Communities (191 total, 14 thin omitted)

### Community 0 - "UIElementWrapping"
Cohesion: 0.16
Nodes (6): Bool, HorizontalAlignment, Self, VerticalAlignment, Void, UIElementWrapping

### Community 1 - "Input"
Cohesion: 0.08
Nodes (18): Drag, .description, Input, .mouseDown, .mouseMoved, .mousePressed, .mouseUp, Bool (+10 more)

### Community 2 - "Text"
Cohesion: 0.06
Nodes (39): CGGlyph, CoreText, CTFont, FontManager, GlyphKey, GlyphMetrics, SDFFont, Float (+31 more)

### Community 3 - "Float"
Cohesion: 0.13
Nodes (11): Curve, easeIn, easeInOut, easeOut, keyframes, linear, spring, Bool (+3 more)

### Community 4 - "DragAndDropTests"
Cohesion: 0.31
Nodes (5): Chip, DragAndDropTests, Log, Bool, float2

### Community 5 - "DiagnosticsTests"
Cohesion: 0.25
Nodes (3): component(), DiagnosticsTests, stubsOnly()

### Community 6 - "UIHarness"
Cohesion: 0.13
Nodes (14): Rules, AnimationTests, InteractionTests, Bool, Double, Float, float2, MTLTexture (+6 more)

### Community 7 - "AnimatedProperty"
Cohesion: 0.07
Nodes (29): AnimatedProperty, center, color, cornerRadius, fontSize, height, inset, keyframes (+21 more)

### Community 8 - "GPURayMarching/Shaders.metal"
Cohesion: 0.08
Nodes (30): Camera, fov, position, rotation, compute(), distanceToScene(), GridArgBuffer, GridItem (+22 more)

### Community 9 - "Background"
Cohesion: 0.32
Nodes (6): Background, IMView, Float, float4, Self, Void

### Community 10 - "CodeGen"
Cohesion: 0.14
Nodes (16): CodeGen, .armedHandlers, Dependents, RowsMode, full, insert, remove, Bool (+8 more)

### Community 11 - ".body"
Cohesion: 0.13
Nodes (15): AudioSettings, FormDemo, .body, Bool, Date, Double, float4, Theme (+7 more)

### Community 12 - "GlyphSDF.metal"
Cohesion: 0.09
Nodes (34): bakeSDF(), lineWinding(), constant, float2, kernel, texture2d, uint, uint2 (+26 more)

### Community 13 - "MathLib.swift"
Cohesion: 0.22
Nodes (17): dragDirection(), from1DTo3DArray(), from2DTo1DArray(), from3DTo1DArray(), fromPixelCoordToGridIndex(), fromWorldPositionToGridIndex(), lerp(), mix() (+9 more)

### Community 14 - "UIAnimation"
Cohesion: 0.06
Nodes (17): UIAnimation, Background, Circle, FlexFrame, Frame, HStack, Alignment, Float (+9 more)

### Community 15 - "IMView"
Cohesion: 0.11
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
Cohesion: 0.05
Nodes (49): Text styling, ExpandedFrame, Padding, Spacer, GridItem, LazyGridElement, .defaultCellAlignment, .trackAlignment (+41 more)

### Community 21 - "FocusableElement"
Cohesion: 0.19
Nodes (6): FocusableElement, Bool, float2, Self, Void, UIElementWrapping

### Community 22 - "WindowState"
Cohesion: 0.15
Nodes (13): CaseIterable, Application, Event, Inspector, Navigation, Global, Reload, Bool (+5 more)

### Community 23 - "Float"
Cohesion: 0.16
Nodes (10): ImageQuad, GlassItem, GlassPass, GPUClip, Float, float2, float4, Int32 (+2 more)

### Community 24 - "BodyParser"
Cohesion: 0.16
Nodes (11): CodeBlockItemListSyntax, IfExprSyntax, BodyParser, Bool, ClosureExprSyntax, ExprSyntax, FunctionCallExprSyntax, MemberBlockItemListSyntax (+3 more)

### Community 25 - "NumberField"
Cohesion: 0.24
Nodes (8): Number4Field, .body, T, NumberField, .body, stringToSIMDScalar(), Bool, T

### Community 26 - "Background"
Cohesion: 0.18
Nodes (6): Background, GlassBackground, GlassMaterial, Float, float2, float4

### Community 27 - "ScrollView"
Cohesion: 0.08
Nodes (17): Bool, ScrollIndicator, .visibility, ScrollIndicatorVisibility, automatic, hidden, never, visible (+9 more)

### Community 28 - "ViewRenderer"
Cohesion: 0.14
Nodes (12): MetalView, .body, CGSize, Double, Float, float2, MTKView, View (+4 more)

### Community 29 - "KeyPress"
Cohesion: 0.22
Nodes (11): CharacterSet, ExpressibleByExtendedGraphemeClusterLiteral, KeyEquivalent, KeyPress, KeyPressElement, Result, handled, ignored (+3 more)

### Community 30 - "SDF.metal"
Cohesion: 0.15
Nodes (15): dot2(), float2, float4, sdBox(), sdBoxSquared(), sdCircle(), sdCircleSquared(), sdOrientedBox() (+7 more)

### Community 31 - "Equatable"
Cohesion: 0.16
Nodes (10): Equatable, DragChip, DragDropDemo, .body, Bool, float4, GlassDemo, .body (+2 more)

### Community 32 - "Sendable"
Cohesion: 0.19
Nodes (11): KeyframeElement, KeyframeSegment, Any, Float, float2, Self, V, UIKeyframe (+3 more)

### Community 33 - "Inset"
Cohesion: 0.10
Nodes (22): IMView, Padding, Float, Self, Void, Float, .packed, .packed (+14 more)

### Community 34 - "Set"
Cohesion: 0.11
Nodes (26): Set, UInt8, Owner, component, node, AnimationScope, Attach, arity (+18 more)

### Community 35 - "EffectElement"
Cohesion: 0.12
Nodes (12): BlurElement, EffectElement, .hasEffect, .localEffect, ShadowState, .margin, Bool, Float (+4 more)

### Community 36 - "LayoutDemo"
Cohesion: 0.22
Nodes (7): LayoutDemo, .body, Alignment, Float, float2, HorizontalAlignment, VerticalAlignment

### Community 37 - "VectorBaker"
Cohesion: 0.11
Nodes (20): BakedRegion, DynamicSDFAtlas, .maxTileSize, Mode, fillEvenOdd, fillNonZero, stroke, SDFSlot (+12 more)

### Community 38 - "SVGParser"
Cohesion: 0.17
Nodes (15): SVGDocument, SVGPaint, color, currentColor, none, SVGParser, SVGShape, SVGStyle (+7 more)

### Community 39 - "Graphics2D"
Cohesion: 0.10
Nodes (22): How it works (when the harness itself needs changing), CustomStringConvertible, Error, Glyph, Graphics2D, .glassAtlasWidth, .size, PipelineError (+14 more)

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
Cohesion: 0.13
Nodes (5): String, .uint32, UInt32, FunctionCallExprSyntax, Naming

### Community 46 - "SceneData"
Cohesion: 0.29
Nodes (7): DebugData, drawGrid, showFilledCells, SceneData, debug, time, windowSize

### Community 47 - "ImageManager"
Cohesion: 0.16
Nodes (14): CGContext, BitmapTexture, ImageManager, ImageQuad, .bounds, PendingUpload, CGFloat, float2 (+6 more)

### Community 48 - "Rect"
Cohesion: 0.16
Nodes (10): Rect, .center, .height, .maxX, .maxY, .minX, .minY, .width (+2 more)

### Community 49 - "ClipRect"
Cohesion: 0.13
Nodes (16): AnyObject, HittableGrid2D, HittableGridCell, HoveredView, Bool, Float, float2, ObjectIdentifier (+8 more)

### Community 50 - "HStack"
Cohesion: 0.33
Nodes (4): HStack, .crossKey, Float, VerticalAlignment

### Community 51 - "IDElement"
Cohesion: 0.11
Nodes (13): ID, IDElement, ScrollViewProxy, ScrollViewReader, Alignment, AnyHashable, float2, Void (+5 more)

### Community 52 - "VList"
Cohesion: 0.14
Nodes (11): AnimatedItem, AnimationDemo, .body, Bool, Float, float4, Float, HorizontalAlignment (+3 more)

### Community 53 - "MetalViewRepresentable"
Cohesion: 0.29
Nodes (6): Context, MetalViewRepresentable, MTKView, NSView, NSViewType, ViewRepresentable

### Community 54 - "Table"
Cohesion: 0.15
Nodes (10): Background, Bool, float2, KeyPathComparator, Text, Table, .clipRect, .items (+2 more)

### Community 55 - "ListDemo"
Cohesion: 0.20
Nodes (12): ChipView, .body, DemoItem, ListDemo, .body, RowView, .body, Bool (+4 more)

### Community 56 - "Float"
Cohesion: 0.28
Nodes (6): Float, .degrees, .isNegative, .radians, Bool, ClosedRange

### Community 57 - "StackElement"
Cohesion: 0.07
Nodes (25): origin, DraggableElement, DragPreviewLayer, .hasEffect, .localEffect, DragSession, DropDestinationBase, DropDestinationElement (+17 more)

### Community 58 - "post"
Cohesion: 0.23
Nodes (16): CGEventFlags, CGEventType, CGKeyCode, CGMouseButton, Int64, click(), drag(), holdModifiers() (+8 more)

### Community 59 - "SDF.swift"
Cohesion: 0.24
Nodes (15): clamp(), T, closestPointToSDBox(), pointInAABBox(), pointInAABBoxTopLeftOrigin(), sdBox(), sdBoxTopLeft(), sdCircle() (+7 more)

### Community 60 - "Glyph"
Cohesion: 0.22
Nodes (9): Glyph, blur, color, depth, fontSize, position, size, uvMax (+1 more)

### Community 61 - "Demo"
Cohesion: 0.07
Nodes (25): Demo, animation, conditional, containers, dragDrop, form, glass, grids (+17 more)

### Community 62 - "float4x4"
Cohesion: 0.15
Nodes (11): matrix_double4x4, float3x3, Float, float4x4, .formated, .identity, .upperLeft, Bool (+3 more)

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
Cohesion: 0.08
Nodes (25): Cache, AnyLayout, AnyLayoutBox, HStackLayout, Layout, LayoutBox, LayoutSubview, .priority (+17 more)

### Community 73 - "BorderElement"
Cohesion: 0.16
Nodes (9): BorderElement, .color, .lineWidth, .shape, BorderLayer, Float, float2, float4 (+1 more)

### Community 74 - "OverlayElement"
Cohesion: 0.23
Nodes (6): OverlayElement, .alignment, Alignment, Bool, float2, Void

### Community 75 - "UIContext"
Cohesion: 0.05
Nodes (9): Sliding layout, Float, float4, ObjectIdentifier, UIContext, .isDragging, Any, Void (+1 more)

### Community 76 - "Picker"
Cohesion: 0.09
Nodes (22): Kind, check, menuItem, segment, Picker, .selectedTitle, PickerMark, PickerStyle (+14 more)

### Community 77 - "Frame"
Cohesion: 0.26
Nodes (6): Frame, .size, Alignment, Float, float2, Void

### Community 78 - "Int"
Cohesion: 0.15
Nodes (11): AnyIterator, Int, Bool, ClosedRange, SparseSet, .count, .isEmpty, .storedKeys (+3 more)

### Community 79 - "uidrive/main.swift"
Cohesion: 0.22
Nodes (15): CGWindowID, CoreGraphics, fail(), findWindow(), keyCode(), modifierFlags(), run(), screenPoint() (+7 more)

### Community 80 - "IMView"
Cohesion: 0.23
Nodes (10): HStack, .size, IMView, Float, HorizontalAlignment, Self, VerticalAlignment, Void (+2 more)

### Community 81 - "Slider"
Cohesion: 0.18
Nodes (12): ProgressView, .fraction, Slider, SliderTrack, ClosedRange, Double, Float, float2 (+4 more)

### Community 82 - "VectorCanvas"
Cohesion: 0.24
Nodes (6): Float, float2, Self, VectorCanvas, .children, VectorShapeList

### Community 83 - "BoundingBox2D"
Cohesion: 0.08
Nodes (20): BoundingBox2D, .bottom, .bottomRight, .height, .left, .right, .top, .topLeft (+12 more)

### Community 84 - "UIElement"
Cohesion: 0.07
Nodes (24): 7. Diagnostics, LayoutPass, LayoutTraits, AnyHashable, float4, UInt32, Void, UIElement (+16 more)

### Community 85 - ".draw"
Cohesion: 0.15
Nodes (6): Line, EffectState, float4, .scrollableSize, Void, Square

### Community 86 - "Divider"
Cohesion: 0.27
Nodes (4): Divider, Float, float2, float4

### Community 87 - ".system"
Cohesion: 0.15
Nodes (17): GridsDemo, .body, Bool, GridItem, LazyRowCounter, makeScrollToDemo(), ScrollDemo, .body (+9 more)

### Community 88 - "AlignmentKey"
Cohesion: 0.09
Nodes (28): Hasher, Alignment, .offset, .xOffset, .yOffset, AlignmentID, AlignmentKey, .isFraction (+20 more)

### Community 89 - "Performance in MetalGraphics"
Cohesion: 0.25
Nodes (7): 2. Invalidation — name the narrowest effect, 4. GPU and Metal (`Graphics2D.swift`, `Shaders/Shaders.metal`), 5. Layout and text, 6. Lists and scrolling, 7. Measure, don't guess, 8. Before finishing, Performance in MetalGraphics

### Community 90 - "MetalKit"
Cohesion: 0.25
Nodes (6): App, Combine, GPURayMarchingApp, .body, MetalKit, Scene

### Community 91 - "SVGIcon"
Cohesion: 0.16
Nodes (12): Layer, SVGIcon, Bool, Bundle, Data, Float, float2, float4 (+4 more)

### Community 92 - "MouseOver"
Cohesion: 0.35
Nodes (6): IMView, MouseOver, Bool, Float, Self, Void

### Community 93 - "Hot reload"
Cohesion: 0.13
Nodes (11): Hot reload, How it fits the frame loop, Quirks, What needs a relaunch, Date, Int32, URL, MacroReloader (+3 more)

### Community 94 - "simd"
Cohesion: 0.09
Nodes (17): AppKit, ContainersDemo, .body, Alignment, Bool, Float, ImageDemo, .body (+9 more)

### Community 95 - "VectorItem"
Cohesion: 0.19
Nodes (12): Kind, bakedFill, bakedStroke, ellipse, roundedBox, Float, float2, VectorItem (+4 more)

### Community 96 - "Graphics2D.swift"
Cohesion: 0.40
Nodes (5): DebugData, SceneData, ShapeArgBuffer, Bool, UInt64

### Community 97 - "HList"
Cohesion: 0.29
Nodes (6): HStack, HList, Float, T, VerticalAlignment, Void

### Community 98 - "ViewItem"
Cohesion: 0.33
Nodes (5): IMView, Spacer, Float, Void, ViewItem

### Community 99 - "assertSnapshot"
Cohesion: 0.23
Nodes (15): ImageIO, assertSnapshot(), failureURL(), loadPNG(), rgba(), rgbaImage(), CGImage, Double (+7 more)

### Community 100 - "TransitionElement"
Cohesion: 0.15
Nodes (8): Float, Void, TransitionElement, .currentState, Float, float2, TransitionState, UITransition

### Community 101 - "float3"
Cohesion: 0.18
Nodes (8): float3, .depth, .height, .width, .xy, Float, float2, int3

### Community 102 - "VectorItem"
Cohesion: 0.09
Nodes (23): ImageQuad, depth, flags, lod, position, size, textureIndex, tint (+15 more)

### Community 103 - "LazyStack"
Cohesion: 0.11
Nodes (19): LazyHStack, .crossAlignment, LazyStack, .crossAlignment, .defaultLength, .estimatedLength, .initialExtent, .overscan (+11 more)

### Community 104 - "HittableView"
Cohesion: 0.23
Nodes (7): HittableView, .hitPosition, .hitSize, Bool, Float, float2, Void

### Community 105 - "ProposedSize"
Cohesion: 0.13
Nodes (13): ProposedSize, Float, .content, AspectRatioElement, ClipElement, .clipCornerRadii, .clipRect, FixedSizeElement (+5 more)

### Community 106 - "GraphicsGrid2D"
Cohesion: 0.09
Nodes (22): Int32, GPUDevice, MTLDevice, GraphicsGrid2D, GridArgBuffer, GridCell, Shape, ShapeType2D (+14 more)

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
Cohesion: 0.15
Nodes (12): ContentMode, fill, fit, Image, .naturalSize, Float, float2, float4 (+4 more)

### Community 111 - "Void"
Cohesion: 0.09
Nodes (14): 1. The frame, 3. Hot paths — per frame, or per element per frame, 8. How it lands on screen, ShadowElement, Invalidation, Any, Bool, Double (+6 more)

### Community 112 - ".init"
Cohesion: 0.20
Nodes (4): SecureField, Bool, Text, Void

### Community 113 - "uchar4"
Cohesion: 0.14
Nodes (10): float4, .xyz, Double, Float, UInt8, uchar4, .a, .b (+2 more)

### Community 115 - "SDFBaker.swift"
Cohesion: 0.14
Nodes (21): PendingBake, SDFAtlas, SDFBakeParams, SDFBaker, SDFRegion, SDFShape, SDFShapeGeometry, SDFShapeMode (+13 more)

### Community 116 - "Float"
Cohesion: 0.16
Nodes (7): Alignment, Background, FlexFrame, Float, float2, float4, Frame

### Community 117 - "PathBuilder"
Cohesion: 0.17
Nodes (10): PathBuilder, PathMorph, Bool, Double, Float, float2, VectorSegment, VectorGeometry (+2 more)

### Community 118 - "Axis"
Cohesion: 0.08
Nodes (27): ExpressibleByArrayLiteral, FlexFrame, Axis, .inverted, .size, IMView, Float, float2 (+19 more)

### Community 119 - ".expansion"
Cohesion: 0.09
Nodes (15): AccessorDeclSyntax, AccessorMacro, DeclReferenceExprSyntax, DeclSyntaxProtocol, MemberAccessExprSyntax, PeerMacro, StateRewriter, ClosureExprSyntax (+7 more)

### Community 120 - "Toggle"
Cohesion: 0.26
Nodes (7): Bool, Float, float2, Text, Void, Toggle, ToggleSwitch

### Community 121 - "ListRows"
Cohesion: 0.14
Nodes (14): 1. The pieces, 2. What a component looks like, 3. What gets generated, 4. Rules that follow, 5. Collections are just `@State` arrays, 6. Composition, not helper methods, Bindings are lowered, not passed, Compile-time state in RetainedModeUI (+6 more)

### Community 122 - "View"
Cohesion: 0.19
Nodes (11): ContentView, .body, Editor, .body, Inspector, .body, Navigation, .body (+3 more)

### Community 123 - "float2"
Cohesion: 0.19
Nodes (7): Bool, Float, float2, TableCells, TableColumnDivider, TableHeader, TableMetrics

### Community 124 - "Animator"
Cohesion: 0.25
Nodes (11): Apply, Animator, .isIdle, Key, Running, Bool, Double, Float (+3 more)

### Community 125 - "FormControl"
Cohesion: 0.23
Nodes (4): FormControl, .isInteracting, Bool, Void

### Community 126 - ".replacingUnspecified"
Cohesion: 0.16
Nodes (5): MeasureCache, float2, UInt32, UInt8, float2

### Community 127 - "Write a test"
Cohesion: 0.20
Nodes (8): Write a test, Float, float2, MTLTexture, UInt8, makeImage(), CGImage, UInt8

### Community 128 - "SwiftSyntaxMacros"
Cohesion: 0.14
Nodes (9): DragDropMacroTests, ListMacroTests, StateMacroTests, ReactiveUIMacrosPlugin, SwiftCompilerPlugin, SwiftSyntaxMacroExpansion, SwiftSyntaxMacros, SwiftSyntaxMacrosGenericTestSupport (+1 more)

### Community 129 - "SwiftUI"
Cohesion: 0.14
Nodes (12): Number3Field, .body, SIMD3, T, SwiftUI, HorizontalAlignment, Probe, .body (+4 more)

### Community 130 - "SingleChildElement"
Cohesion: 0.13
Nodes (11): StressCell, .body, StressIndex, StressRow, .body, Bool, VectorDemo, .body (+3 more)

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
Cohesion: 0.24
Nodes (4): Padding, Float, float2, float2

### Community 137 - "DatePicker"
Cohesion: 0.07
Nodes (24): PopoverFill, PopoverHandle, .isPresented, PopoverLayer, Bool, Float, float2, HorizontalAlignment (+16 more)

### Community 138 - "ViewThatFits"
Cohesion: 0.26
Nodes (4): Float, float2, Void, ViewThatFits

### Community 139 - "TextField"
Cohesion: 0.21
Nodes (9): EditKind, deleting, other, typing, Snapshot, Range, Self, TextField (+1 more)

### Community 140 - "Path"
Cohesion: 0.14
Nodes (16): Path, .isClosed, .length, .localBounds, Source, builder, commands, Bool (+8 more)

### Community 142 - "FieldBox"
Cohesion: 0.30
Nodes (4): FieldBox, .clipRect, Float, float2

### Community 143 - "HotReload"
Cohesion: 0.21
Nodes (6): Duration, HotReload, Bool, Never, Void, Task

### Community 144 - "Section"
Cohesion: 0.12
Nodes (14): CaptionSlot, .isEmpty, RowLayout, RowSeparators, RowStack, .inset, Section, .inset (+6 more)

### Community 145 - "AnimationGroup"
Cohesion: 0.33
Nodes (5): `withAnimation`, AnimationGroup, Void, UITransaction, withAnimation()

### Community 146 - "Stepper"
Cohesion: 0.19
Nodes (10): Stepper, StepperGlyph, Bool, ClosedRange, Double, Float, float2, Text (+2 more)

### Community 147 - "Effects and transitions"
Cohesion: 0.19
Nodes (13): Effects and transitions, backdrop2D(), compute2D(), glassBlur(), constant, kernel, texture2d, uint2 (+5 more)

### Community 148 - "GlassPass"
Cohesion: 0.22
Nodes (9): GlassPass, atlasOrigin, direction, maxDepth, padding, pointsPerTexel, sceneOrigin, sigma (+1 more)

### Community 149 - ".init"
Cohesion: 0.50
Nodes (3): Float, float2, float4

### Community 150 - "ConditionalDemo"
Cohesion: 0.31
Nodes (5): ConditionalDemo, .body, Bool, Float, float4

### Community 151 - "FileWatcher"
Cohesion: 0.22
Nodes (7): CoreServices, FSEventStreamRef, FileWatcher, ArraySlice, DispatchQueue, URL, Void

### Community 152 - "EmptyElement"
Cohesion: 0.22
Nodes (3): EmptyElement, LeafElement, Void

### Community 153 - "ReactiveUIDiagnostic"
Cohesion: 0.24
Nodes (7): DiagnosticMessage, DiagnosticSeverity, FixItMessage, MessageID, ReactiveUIDiagnostic, ReactiveUIFixIt, SwiftDiagnostics

### Community 154 - "TableColumn"
Cohesion: 0.23
Nodes (8): KeyPath, MainActor, HorizontalAlignment, KeyPathComparator, T, V, TableColumn, TableColumnBuilder

### Community 155 - "ZStack"
Cohesion: 0.23
Nodes (6): Alignment, Bool, Float, float2, Void, ZStack

### Community 156 - "TableDemo"
Cohesion: 0.30
Nodes (7): Person, float4, KeyPathComparator, TableDemo, .body, Identifiable, Row

### Community 157 - "MultiChildElement"
Cohesion: 0.22
Nodes (4): MultiChildElement, .liveChildrenCount, float2, Void

### Community 158 - "Form"
Cohesion: 0.27
Nodes (5): Form, Bool, ObjectIdentifier, Void, VStack

### Community 159 - "View"
Cohesion: 0.18
Nodes (11): Bool, View, Background, ExpandedFrame, FlexFrame, HStack, .isSpacer, MouseOver (+3 more)

### Community 161 - ".init"
Cohesion: 0.25
Nodes (7): DisclosureChevron, DisclosureGroup, Bool, Float, float2, Text, Void

### Community 163 - "KeyboardDemo"
Cohesion: 0.38
Nodes (5): KeyboardDemo, .body, Bool, Float, float2

### Community 164 - "UIShape"
Cohesion: 0.24
Nodes (8): Kind, capsule, circle, rect, Bool, float4, UIShape, .isPlainRect

### Community 165 - "TableCell"
Cohesion: 0.33
Nodes (3): HorizontalAlignment, TableCell, .clipRect

### Community 166 - "float2"
Cohesion: 0.29
Nodes (4): Alignment, Float, float2, float2

### Community 167 - ".texture"
Cohesion: 0.25
Nodes (6): Bundle, CGImage, Float, NSImage, Bundle, NSImage

### Community 168 - "Binding"
Cohesion: 0.23
Nodes (8): Member, Binding, .wrappedValue, Value, Void, ReferenceWritableKeyPath, Root, WritableKeyPath

### Community 170 - "expand"
Cohesion: 0.30
Nodes (5): BindingMacroTests, component(), expand(), NamedContentTests, SwiftParser

### Community 171 - "Foundation"
Cohesion: 0.18
Nodes (4): Foundation, benchmark(), Bool, Void

### Community 172 - "Spacer"
Cohesion: 0.43
Nodes (3): Spacer, Float, float2

### Community 173 - "FormGraphic"
Cohesion: 0.17
Nodes (8): FormGraphic, mix(), Float, float2, float4, Self, V, UIElementWrapping

### Community 174 - "layoutchecks/main.swift"
Cohesion: 0.40
Nodes (4): check(), HorizontalAlignment, layout(), float2

### Community 175 - "Shape"
Cohesion: 0.40
Nodes (5): Shape, clip, depth, index, shapeType

### Community 176 - "Button"
Cohesion: 0.21
Nodes (8): Button, ButtonRole, cancel, destructive, Text, Void, SnapshotTests, XCTestCase

### Community 177 - "TableColumnLayout"
Cohesion: 0.28
Nodes (5): Bool, Float, TableColumnLayout, .count, TableColumnWidth

### Community 178 - "Interpolation"
Cohesion: 0.33
Nodes (5): Interpolation, high, low, medium, none

### Community 179 - "Square"
Cohesion: 0.33
Nodes (6): Square, color, depth, position, rotation, size

### Community 180 - "Headless UI tests"
Cohesion: 0.40
Nodes (4): Headless UI tests, Run, Snapshots, When to launch the app instead (drive-app skill)

### Community 181 - "Number2Field"
Cohesion: 0.40
Nodes (4): .inspectorView, Number2Field, .body, T

### Community 183 - "Phases"
Cohesion: 0.67
Nodes (3): Phases, UInt8, OptionSet

### Community 184 - "ReactiveUIMacrosPlugin"
Cohesion: 0.67
Nodes (3): CompilerPlugin, ReactiveUIMacrosPlugin, Macro

### Community 185 - ".readExactly"
Cohesion: 0.29
Nodes (5): PluginMain, StdinFilter, Bool, Int32, UInt8

### Community 188 - "IMGameView"
Cohesion: 0.33
Nodes (3): IMView, IMGameView, float4

### Community 189 - "9. Animation"
Cohesion: 0.47
Nodes (5): 9. Animation, Costs to know, Repeat and keyframes, Scopes, The runtime

## Knowledge Gaps
- **493 isolated node(s):** `conditional`, `list`, `text`, `layout`, `image` (+488 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 972 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **14 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `String` connect `String` to `Input`, `Text`, `DragAndDropTests`, `DiagnosticsTests`, `UIHarness`, `Background`, `CodeGen`, `.body`, `UIAnimation`, `IMView`, `ColorPicker`, `WindowState`, `BodyParser`, `NumberField`, `Background`, `ScrollView`, `KeyPress`, `Equatable`, `Inset`, `Set`, `LayoutDemo`, `SVGParser`, `Graphics2D`, `.expansion`, `ImageManager`, `HStack`, `IDElement`, `VList`, `Table`, `ListDemo`, `post`, `Demo`, `float4x4`, `BorderElement`, `OverlayElement`, `UIContext`, `Picker`, `Frame`, `uidrive/main.swift`, `IMView`, `Slider`, `VectorCanvas`, `UIElement`, `.draw`, `.system`, `SVGIcon`, `MouseOver`, `Hot reload`, `simd`, `ViewItem`, `assertSnapshot`, `Utils.swift`, `Rectangle`, `SVGPathCommand`, `Image`, `.init`, `SDFBaker.swift`, `Axis`, `.expansion`, `Toggle`, `SwiftUI`, `SingleChildElement`, `ModifierSpec`, `FlexFrame`, `Padding`, `AnimationMacroTests`, `DatePicker`, `TextField`, `Path`, `Section`, `Stepper`, `ConditionalDemo`, `FileWatcher`, `ReactiveUIDiagnostic`, `TableColumn`, `ZStack`, `TableDemo`, `MultiChildElement`, `.init`, `KeyboardDemo`, `.texture`, `expand`, `Foundation`, `layoutchecks/main.swift`, `Button`, `Number2Field`, `.pressed`?**
  _High betweenness centrality (0.240) - this node is a cross-community bridge._
- **Why does `UIElement` connect `UIElement` to `UIElementWrapping`, `SingleChildElement`, `DragAndDropTests`, `FlexFrame`, `Padding`, `TableColumn`, `DatePicker`, `ViewThatFits`, `.body`, `ZStack`, `UIHarness`, `UIAnimation`, `Section`, `Grid`, `KeyPress`, `VectorShape`, `FocusableElement`, `ConditionalDemo`, `EmptyElement`, `Background`, `ScrollView`, `TableDemo`, `MultiChildElement`, `Form`, `Equatable`, `Sendable`, `Inset`, `.init`, `KeyboardDemo`, `LayoutDemo`, `EffectElement`, `float2`, `TableCell`, `FormGraphic`, `layoutchecks/main.swift`, `Button`, `ClipRect`, `HStack`, `IDElement`, `VList`, `Table`, `ListDemo`, `StackElement`, `Demo`, `GeometryChangeElement`, `LayoutSubviews`, `BorderElement`, `OverlayElement`, `UIContext`, `Picker`, `Frame`, `Int`, `VectorCanvas`, `.draw`, `.system`, `AlignmentKey`, `Hot reload`, `simd`, `HList`, `TransitionElement`, `LazyStack`, `HittableView`, `ProposedSize`, `Rectangle`, `Void`, `Float`, `Axis`, `ListRows`, `Animator`, `FormControl`, `.replacingUnspecified`?**
  _High betweenness centrality (0.175) - this node is a cross-community bridge._
- **Why does `Int` connect `Int` to `UIElementWrapping`, `SingleChildElement`, `Float`, `DragAndDropTests`, `SDFPathBuilder`, `FlexFrame`, `UIHarness`, `ModifierSpec`, `DatePicker`, `CodeGen`, `.body`, `TextField`, `MathLib.swift`, `UIAnimation`, `IMView`, `FieldBox`, `Grid`, `ColorPicker`, `VectorShape`, `ConditionalDemo`, `WindowState`, `BodyParser`, `ZStack`, `TableDemo`, `MultiChildElement`, `Equatable`, `View`, `T`, `Set`, `EffectElement`, `LayoutDemo`, `VectorBaker`, `Graphics2D`, `T`, `String`, `ImageManager`, `TableColumnLayout`, `VList`, `Table`, `ListDemo`, `StackElement`, `.readExactly`, `post`, `.pressed`, `Array`, `LayoutSubviews`, `UIContext`, `Picker`, `UIElement`, `.draw`, `.system`, `AlignmentKey`, `Hot reload`, `simd`, `HList`, `ViewItem`, `assertSnapshot`, `LazyStack`, `ProposedSize`, `GraphicsGrid2D`, `Utils.swift`, `Rectangle`, `Void`, `.init`, `SDFBaker.swift`, `PathBuilder`, `ListRows`, `Animator`, `Write a test`?**
  _High betweenness centrality (0.162) - this node is a cross-community bridge._
- **Are the 5 inferred relationships involving `UIContext` (e.g. with `Effects and transitions` and `HittableGrid2D`) actually correct?**
  _`UIContext` has 5 INFERRED edges - model-reasoned connections that need verification._
- **Are the 23 inferred relationships involving `UIElement` (e.g. with `7. Diagnostics` and `What needs a relaunch`) actually correct?**
  _`UIElement` has 23 INFERRED edges - model-reasoned connections that need verification._
- **What connects `conditional`, `list`, `text` to the rest of the system?**
  _493 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Input` be split into smaller, more focused modules?**
  _Cohesion score 0.07682926829268293 - nodes in this community are weakly interconnected._