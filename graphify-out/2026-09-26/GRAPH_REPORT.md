# Graph Report - MetalGraphics  (2026-09-26)

## Corpus Check
- 230 files · ~174,677 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 16 file(s) not represented in the graph (top: (none) 4, .plist 3, .resolved 2)

## Summary
- 3803 nodes · 10105 edges · 191 communities (175 shown, 16 thin omitted)
- Extraction: 91% EXTRACTED · 9% INFERRED · 0% AMBIGUOUS · INFERRED: 949 edges (avg confidence: 0.84)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `c4a691df`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- UIElementWrapping
- Input
- Text
- Float
- IMView
- DiagnosticsTests
- UIHarness
- AnimatedProperty
- GPURayMarching/Shaders.metal
- ViewItem
- CodeGen
- SingleChildElement
- GlyphSDF.metal
- MathLib.swift
- UIAnimation
- IMView
- MyMTKView
- Alignment
- Grid
- ColorPicker
- VectorShape
- PopoverLayer
- WindowState
- .draw
- .expansion
- NumberField
- UIShape
- ScrollView
- ViewRenderer
- KeyPress
- SDF.metal
- StateRewriter
- UIKeyframe
- Inset
- ElementIR
- EffectElement
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
- float4
- GeometryChangeElement
- Comparable Clamp
- LayoutSubviews
- Macro Package Manifest
- UIElement+ReactiveSetters.swift
- OverlayElement
- UIContext
- Picker
- Frame
- Int
- Square
- IMView
- .setValue
- VectorCanvas
- BoundingBox2D
- UIElement
- EffectState
- Divider
- .system
- Sendable
- Performance in MetalGraphics
- MetalKit
- SVGIcon
- MouseOver
- HotReload
- simd
- VectorItem
- Graphics2D.swift
- .insertRow
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
- SVGScanner
- Image
- Void
- LazyGridElement
- uchar4
- Drag
- SDFBaker.swift
- SIMD2
- PathBuilder
- Axis
- .expansion
- ViewDimensions
- ListRows
- View
- float2
- Animator
- FormControl
- ProposedSize
- Write a test
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
- .step
- Section
- AnimationGroup
- Stepper
- GridCell
- GlassPass
- .endFrame
- ConditionalDemo
- FileWatcher
- EmptyElement
- ShapeType2D
- TableColumn
- ZStack
- TableDemo
- TransitionElement
- Padding
- View
- .removeRow
- .init
- ComponentMacroTests
- KeyboardDemo
- int2
- TableCell
- float2
- Line
- Binding
- .parseBranch
- expand
- Foundation
- Spacer
- FormGraphic
- Kind
- Shape
- Button
- TableColumnWidth
- SnapshotTests
- HorizontalAlignment
- TextDemo
- Animator.swift
- Set
- .readExactly
- IMGameView
- 9. Animation
- .init
- .sizeThatFits
- Result
- .setLayout

## God Nodes (most connected - your core abstractions)
1. `UIContext` - 332 edges
2. `UIElement` - 257 edges
3. `UIAnimation` - 192 edges
4. `ProposedSize` - 162 edges
5. `Graphics2D` - 118 edges
6. `simd` - 81 edges
7. `Inset` - 63 edges
8. `SingleChildElement` - 61 edges
9. `Input` - 59 edges
10. `SIMD2` - 57 edges

## Surprising Connections (you probably didn't know these)
- `7. Measure, don't guess` --references--> `ScrollDemo`  [INFERRED]
  .claude/skills/performance/SKILL.md → GPURayMarching/ScrollDemo.swift
- `6. Lists and scrolling` --references--> `ListRows`  [INFERRED]
  .claude/skills/performance/SKILL.md → MetalGraphicsLib/RetainedModeUI/Layout/ListRows.swift
- `Hot reload` --references--> `Demos`  [INFERRED]
  MetalGraphicsLib/docs/HotReload.md → GPURayMarching/Demos.swift
- `5. Collections are just `@State` arrays` --references--> `DemoItem`  [INFERRED]
  MetalGraphicsLib/docs/CompileTimeState.md → GPURayMarching/ListDemo.swift
- `8. How it lands on screen` --references--> `TestViewRenderer`  [INFERRED]
  MetalGraphicsLib/docs/CompileTimeState.md → GPURayMarching/TestViewRenderer.swift

## Import Cycles
- None detected.

## Communities (191 total, 16 thin omitted)

### Community 0 - "UIElementWrapping"
Cohesion: 0.13
Nodes (8): Bool, Float, float2, HorizontalAlignment, Self, VerticalAlignment, Void, UIElementWrapping

### Community 1 - "Input"
Cohesion: 0.11
Nodes (13): Input, .mouseDown, .mouseMoved, .mousePressed, .mouseUp, Bool, Double, NSEvent (+5 more)

### Community 2 - "Text"
Cohesion: 0.07
Nodes (36): CGGlyph, CoreText, CTFont, FontManager, GlyphKey, GlyphMetrics, SDFFont, Float (+28 more)

### Community 3 - "Float"
Cohesion: 0.15
Nodes (10): Curve, easeIn, easeInOut, easeOut, keyframes, linear, spring, Bool (+2 more)

### Community 4 - "IMView"
Cohesion: 0.23
Nodes (9): ExpandedFrame, FlexFrame, Frame, IMView, Alignment, Float, float2, Self (+1 more)

### Community 5 - "DiagnosticsTests"
Cohesion: 0.25
Nodes (3): component(), DiagnosticsTests, stubsOnly()

### Community 6 - "UIHarness"
Cohesion: 0.15
Nodes (11): InteractionTests, Bool, Float, float2, MTLTexture, NSEvent, T, UIHarness (+3 more)

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
Cohesion: 0.13
Nodes (14): CodeGen, .armedHandlers, Dependents, RowsMode, full, insert, remove, Bool (+6 more)

### Community 11 - "SingleChildElement"
Cohesion: 0.19
Nodes (6): SingleChildElement, Float, float2, LabeledContent, HStack, Text

### Community 12 - "GlyphSDF.metal"
Cohesion: 0.08
Nodes (35): What needs a relaunch, bakeSDF(), lineWinding(), constant, float2, kernel, texture2d, uint (+27 more)

### Community 13 - "MathLib.swift"
Cohesion: 0.18
Nodes (17): int3, dragDirection(), from1DTo3DArray(), from2DTo1DArray(), from3DTo1DArray(), fromPixelCoordToGridIndex(), fromWorldPositionToGridIndex(), lerp() (+9 more)

### Community 14 - "UIAnimation"
Cohesion: 0.07
Nodes (13): UIAnimation, FlexFrame, Frame, Alignment, Float, float2, float4, GridItem (+5 more)

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
Cohesion: 0.05
Nodes (43): AudioSettings, FormDemo, .body, Bool, Date, Double, float4, Theme (+35 more)

### Community 20 - "VectorShape"
Cohesion: 0.09
Nodes (26): Text styling, Capsule, Circle, .length, .localBounds, Ellipse, .length, .localBounds (+18 more)

### Community 21 - "PopoverLayer"
Cohesion: 0.18
Nodes (9): PopoverFill, PopoverHandle, .isPresented, PopoverLayer, Bool, Float, float2, HorizontalAlignment (+1 more)

### Community 22 - "WindowState"
Cohesion: 0.15
Nodes (13): CaseIterable, Application, Event, Inspector, Navigation, Global, Reload, Bool (+5 more)

### Community 23 - ".draw"
Cohesion: 0.24
Nodes (8): GlassPass, GPUClip, Float, float2, float4, Int32, UInt32, VectorItem

### Community 24 - ".expansion"
Cohesion: 0.14
Nodes (12): CodeBlockItemListSyntax, DeclGroupSyntax, ExtensionDeclSyntax, ExtensionMacro, MemberMacro, MemberBlockItemListSyntax, VariableDeclSyntax, ComponentMacro (+4 more)

### Community 25 - "NumberField"
Cohesion: 0.15
Nodes (12): .inspectorView, Number2Field, .body, T, Number4Field, .body, T, NumberField (+4 more)

### Community 26 - "UIShape"
Cohesion: 0.06
Nodes (28): ClipElement, .clipCornerRadii, .clipRect, float4, Background, GlassBackground, GlassMaterial, Float (+20 more)

### Community 27 - "ScrollView"
Cohesion: 0.07
Nodes (22): Bool, Form, Bool, ObjectIdentifier, Void, VStack, ScrollIndicator, .visibility (+14 more)

### Community 28 - "ViewRenderer"
Cohesion: 0.14
Nodes (13): MetalView, .body, CGSize, Double, Float, float2, MTKView, View (+5 more)

### Community 29 - "KeyPress"
Cohesion: 0.29
Nodes (8): CharacterSet, ExpressibleByExtendedGraphemeClusterLiteral, KeyEquivalent, KeyPress, KeyPressElement, Character, NSEvent, UIElementWrapping

### Community 30 - "SDF.metal"
Cohesion: 0.14
Nodes (11): dot2(), float2, float4, sdBoxSquared(), sdCircle(), sdCircleSquared(), sdOrientedBox(), sdRoundedBoxSquared() (+3 more)

### Community 31 - "StateRewriter"
Cohesion: 0.22
Nodes (7): DeclReferenceExprSyntax, MemberAccessExprSyntax, StateRewriter, ClosureExprSyntax, ExprSyntax, SyntaxProtocol, SyntaxRewriter

### Community 32 - "UIKeyframe"
Cohesion: 0.19
Nodes (10): Any, KeyframeElement, KeyframeSegment, Float, float2, Self, V, UIKeyframe (+2 more)

### Community 33 - "Inset"
Cohesion: 0.11
Nodes (14): .body, .packed, Padding, Padding, Float, float2, Edge, Float (+6 more)

### Community 34 - "ElementIR"
Cohesion: 0.10
Nodes (29): Owner, component, node, Arity, leaf, multi, single, AnimationScope (+21 more)

### Community 35 - "EffectElement"
Cohesion: 0.16
Nodes (10): EffectElement, .hasEffect, .localEffect, ShadowState, .margin, Bool, Float, float2 (+2 more)

### Community 36 - "LayoutDemo"
Cohesion: 0.22
Nodes (7): LayoutDemo, .body, Alignment, Float, float2, HorizontalAlignment, VerticalAlignment

### Community 37 - "VectorBaker"
Cohesion: 0.11
Nodes (20): BakedRegion, DynamicSDFAtlas, .maxTileSize, Mode, fillEvenOdd, fillNonZero, stroke, SDFSlot (+12 more)

### Community 38 - "SVGParser"
Cohesion: 0.18
Nodes (15): SVGDocument, SVGPaint, color, currentColor, none, SVGParser, SVGShape, SVGStyle (+7 more)

### Community 39 - "Graphics2D"
Cohesion: 0.09
Nodes (18): CustomStringConvertible, Error, Glyph, ImageQuad, Line, Graphics2D, .glassAtlasWidth, .size (+10 more)

### Community 40 - "Math.metal"
Cohesion: 0.19
Nodes (11): cross2d(), float2, float4, ndot(), normalize(), remap(), rotation(), rotationX() (+3 more)

### Community 41 - "BoundingBox3D"
Cohesion: 0.14
Nodes (13): BoundingBox3D, .back, .bottom, .bottomRightBack, .depth, .front, .height, .left (+5 more)

### Community 42 - "bakeVectorSDF"
Cohesion: 0.09
Nodes (34): bakeVectorSDF(), closestOnLine(), closestOnQuadratic(), isInside(), lineCrossing(), constant, float2, kernel (+26 more)

### Community 43 - "Shaders/Shaders.metal"
Cohesion: 0.15
Nodes (28): metal_stdlib, sdBox(), sdRoundedBox(), backdrop2D(), compute2D(), ellipseAlong(), glassBlur(), GridArgBuffer (+20 more)

### Community 44 - "StateProperty"
Cohesion: 0.14
Nodes (13): PatternBindingSyntax, .states, TypeSyntax, .arrayStates, .reactiveNames, .stateNames, StateProperty, AttributeSyntax (+5 more)

### Community 45 - "String"
Cohesion: 0.14
Nodes (4): String, .uint32, UInt32, Naming

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
Cohesion: 0.12
Nodes (17): AnyObject, HittableGrid2D, HittableGridCell, HoveredView, Bool, Float, float2, ObjectIdentifier (+9 more)

### Community 50 - "HStack"
Cohesion: 0.33
Nodes (4): HStack, .crossKey, Float, VerticalAlignment

### Community 51 - "IDElement"
Cohesion: 0.11
Nodes (13): ID, IDElement, ScrollViewProxy, ScrollViewReader, Alignment, AnyHashable, float2, Void (+5 more)

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
Cohesion: 0.22
Nodes (11): ChipView, DemoItem, ListDemo, .body, RowView, .body, Bool, Float (+3 more)

### Community 56 - "Float"
Cohesion: 0.28
Nodes (6): Float, .degrees, .isNegative, .radians, Bool, ClosedRange

### Community 57 - "StackElement"
Cohesion: 0.23
Nodes (8): origin, StackElement, .crossKey, .size, Bool, Float, float2, Void

### Community 58 - "uidrive/main.swift"
Cohesion: 0.14
Nodes (31): CGEventFlags, CGEventType, CGKeyCode, CGMouseButton, CGWindowID, CoreGraphics, Int64, click() (+23 more)

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
Cohesion: 0.14
Nodes (12): matrix_double4x4, float3x3, Float, float4x4, .formated, .identity, .upperLeft, Bool (+4 more)

### Community 63 - "Array"
Cohesion: 0.33
Nodes (4): Array, .byteCount, Element, Void

### Community 64 - "UIStorage"
Cohesion: 0.15
Nodes (10): graphify, Hot reload, Performance, 1. Build and launch, 2. Compile the driver, 3. Drive and look, Driving GPURayMarching, Notes (+2 more)

### Community 65 - "float4"
Cohesion: 0.07
Nodes (27): Circle, color, depth, position, radius, Clip, blur, bounds (+19 more)

### Community 66 - "GeometryChangeElement"
Cohesion: 0.15
Nodes (11): CoordinateSpace, global, local, GeometryChangeElement, GeometryProxy, GeometryReader, Float, float2 (+3 more)

### Community 67 - "Comparable Clamp"
Cohesion: 0.40
Nodes (3): Comparable, ClosedRange, Self

### Community 68 - "LayoutSubviews"
Cohesion: 0.08
Nodes (23): Cache, AnyLayout, AnyLayoutBox, HStackLayout, Layout, LayoutBox, LayoutSubviews, .endIndex (+15 more)

### Community 73 - "UIElement+ReactiveSetters.swift"
Cohesion: 0.15
Nodes (11): Effects and transitions, Sliding layout, BlurElement, ShadowElement, Background, Circle, ExpandedFrame, HStack (+3 more)

### Community 74 - "OverlayElement"
Cohesion: 0.11
Nodes (11): Alignment, Background, FlexFrame, float4, Frame, OverlayElement, .alignment, Alignment (+3 more)

### Community 75 - "UIContext"
Cohesion: 0.06
Nodes (8): Float, float4, ObjectIdentifier, UIContext, LayoutPass, UInt32, Void, Void

### Community 76 - "Picker"
Cohesion: 0.09
Nodes (23): Kind, check, menuItem, segment, Picker, .selectedTitle, PickerMark, PickerStyle (+15 more)

### Community 77 - "Frame"
Cohesion: 0.26
Nodes (6): Frame, .size, Alignment, Float, float2, Void

### Community 78 - "Int"
Cohesion: 0.13
Nodes (11): AnyIterator, Int, Bool, ClosedRange, SparseSet, .count, .isEmpty, .storedKeys (+3 more)

### Community 79 - "Square"
Cohesion: 0.29
Nodes (5): Square, .bounds, Float, float2, float4

### Community 80 - "IMView"
Cohesion: 0.23
Nodes (10): HStack, .size, IMView, Float, HorizontalAlignment, Self, VerticalAlignment, Void (+2 more)

### Community 82 - "VectorCanvas"
Cohesion: 0.16
Nodes (9): GlassDemo, .body, Bool, Float, float2, Self, VectorCanvas, .children (+1 more)

### Community 83 - "BoundingBox2D"
Cohesion: 0.12
Nodes (14): BoundingBox2D, .bottom, .bottomRight, .height, .left, .right, .top, .topLeft (+6 more)

### Community 84 - "UIElement"
Cohesion: 0.06
Nodes (25): 7. Diagnostics, MultiChildElement, .liveChildrenCount, float2, LayoutTraits, AnyHashable, float4, Void (+17 more)

### Community 85 - "EffectState"
Cohesion: 0.18
Nodes (3): EffectState, .scrollableSize, Void

### Community 86 - "Divider"
Cohesion: 0.27
Nodes (4): Divider, Float, float2, float4

### Community 87 - ".system"
Cohesion: 0.23
Nodes (13): LazyRowCounter, makeScrollToDemo(), ScrollDemo, .body, ScrollRow, .name, ScrollRowView, .body (+5 more)

### Community 88 - "Sendable"
Cohesion: 0.17
Nodes (16): Equatable, Hasher, Alignment, .offset, .xOffset, .yOffset, AlignmentID, AlignmentKey (+8 more)

### Community 89 - "Performance in MetalGraphics"
Cohesion: 0.25
Nodes (7): 2. Invalidation — name the narrowest effect, 4. GPU and Metal (`Graphics2D.swift`, `Shaders/Shaders.metal`), 5. Layout and text, 6. Lists and scrolling, 7. Measure, don't guess, 8. Before finishing, Performance in MetalGraphics

### Community 90 - "MetalKit"
Cohesion: 0.13
Nodes (11): App, Combine, GPURayMarchingApp, .body, Number3Field, .body, SIMD3, T (+3 more)

### Community 91 - "SVGIcon"
Cohesion: 0.13
Nodes (14): Layer, SVGIcon, Bool, Bundle, Data, Float, float2, float4 (+6 more)

### Community 92 - "MouseOver"
Cohesion: 0.35
Nodes (6): IMView, MouseOver, Bool, Float, Self, Void

### Community 93 - "HotReload"
Cohesion: 0.08
Nodes (20): Duration, Default arguments, Hot reload, How it fits the frame loop, Macro plugin: the zero-length message, Quirks, Setup, Why the Debug settings are what they are (+12 more)

### Community 94 - "simd"
Cohesion: 0.09
Nodes (18): AppKit, ContainersDemo, .body, Alignment, Bool, Float, GridsDemo, .body (+10 more)

### Community 95 - "VectorItem"
Cohesion: 0.19
Nodes (12): Kind, bakedFill, bakedStroke, ellipse, roundedBox, Float, float2, VectorItem (+4 more)

### Community 96 - "Graphics2D.swift"
Cohesion: 0.40
Nodes (5): DebugData, SceneData, ShapeArgBuffer, Bool, UInt64

### Community 98 - "IMView"
Cohesion: 0.39
Nodes (4): IMView, Spacer, Float, Void

### Community 99 - "assertSnapshot"
Cohesion: 0.23
Nodes (15): ImageIO, assertSnapshot(), failureURL(), loadPNG(), rgba(), rgbaImage(), CGImage, Double (+7 more)

### Community 100 - "TransitionState"
Cohesion: 0.23
Nodes (4): Float, float2, TransitionState, UITransition

### Community 101 - "float3"
Cohesion: 0.14
Nodes (11): float3, .depth, .height, .width, .xy, Float, float2, float4 (+3 more)

### Community 102 - "VectorItem"
Cohesion: 0.09
Nodes (23): ImageQuad, depth, flags, lod, position, size, textureIndex, tint (+15 more)

### Community 103 - "LazyStack"
Cohesion: 0.12
Nodes (20): LazyHStack, .crossAlignment, LazyStack, .crossAlignment, .defaultLength, .estimatedLength, .initialExtent, .overscan (+12 more)

### Community 104 - "HittableView"
Cohesion: 0.23
Nodes (7): HittableView, .hitPosition, .hitSize, Bool, Float, float2, Void

### Community 105 - ".content"
Cohesion: 0.18
Nodes (7): .content, AspectRatioElement, FixedSizeElement, PositionElement, Bool, Float, float2

### Community 106 - "GraphicsGrid2D"
Cohesion: 0.19
Nodes (11): Int32, GPUDevice, MTLDevice, GraphicsGrid2D, GridArgBuffer, GridCell, Shape, Float (+3 more)

### Community 107 - "Utils.swift"
Cohesion: 0.17
Nodes (13): DispatchWorkItem, Debouncer, forEachGridCell(), generateRandomArray(), iterateWithStep(), name(), ClosedRange, DispatchQueue (+5 more)

### Community 108 - "Rectangle"
Cohesion: 0.21
Nodes (4): Rectangle, Float, float2, LayoutTests

### Community 109 - "SVGScanner"
Cohesion: 0.24
Nodes (6): SVGScanner, .isAtEnd, .peek, Bool, Character, UInt8

### Community 110 - "Image"
Cohesion: 0.11
Nodes (17): ContentMode, fill, fit, Image, .naturalSize, Interpolation, high, low (+9 more)

### Community 111 - "Void"
Cohesion: 0.08
Nodes (18): 1. The frame, 3. Hot paths — per frame, or per element per frame, 8. How it lands on screen, Invalidation, Bool, Double, float2, Frame (+10 more)

### Community 112 - "LazyGridElement"
Cohesion: 0.14
Nodes (20): GridItem, LazyGridElement, .defaultCellAlignment, .trackAlignment, LazyHGrid, .defaultCellAlignment, .trackAlignment, LazyVGrid (+12 more)

### Community 113 - "uchar4"
Cohesion: 0.29
Nodes (6): UInt8, uchar4, .a, .b, .g, .r

### Community 114 - "Drag"
Cohesion: 0.15
Nodes (7): Carbon.HIToolbox, GameController, Drag, .description, Float, float2, Void

### Community 115 - "SDFBaker.swift"
Cohesion: 0.14
Nodes (21): PendingBake, SDFAtlas, SDFBakeParams, SDFBaker, SDFRegion, SDFShape, SDFShapeGeometry, SDFShapeMode (+13 more)

### Community 116 - "SIMD2"
Cohesion: 0.31
Nodes (8): Float, .packed, SIMD2, .packed, SIMD4, .packed, Float, UIAnimatable

### Community 117 - "PathBuilder"
Cohesion: 0.19
Nodes (9): PathBuilder, PathMorph, Bool, Double, Float, float2, VectorSegment, VectorGeometry (+1 more)

### Community 118 - "Axis"
Cohesion: 0.07
Nodes (22): ExpressibleByArrayLiteral, FlexFrame, Axis, .inverted, .size, IMView, Float, float2 (+14 more)

### Community 119 - ".expansion"
Cohesion: 0.09
Nodes (17): AccessorDeclSyntax, AccessorMacro, DeclSyntaxProtocol, DiagnosticMessage, DiagnosticSeverity, FixItMessage, MessageID, PeerMacro (+9 more)

### Community 120 - "ViewDimensions"
Cohesion: 0.21
Nodes (7): Float, float2, HorizontalAlignment, VerticalAlignment, ViewDimensions, Mid, Float

### Community 121 - "ListRows"
Cohesion: 0.11
Nodes (18): HStack, 1. The pieces, 2. What a component looks like, 3. What gets generated, 4. Rules that follow, 5. Collections are just `@State` arrays, 6. Composition, not helper methods, Bindings are lowered, not passed (+10 more)

### Community 122 - "View"
Cohesion: 0.23
Nodes (10): ContentView, .body, Editor, Inspector, .body, Navigation, .body, ToggleView (+2 more)

### Community 123 - "float2"
Cohesion: 0.18
Nodes (7): TableColumnLayout, .count, Bool, float2, TableCells, TableColumnDivider, TableHeader

### Community 124 - "Animator"
Cohesion: 0.25
Nodes (11): Apply, Animator, .isIdle, Key, Running, Bool, Double, Float (+3 more)

### Community 125 - "FormControl"
Cohesion: 0.23
Nodes (5): FormControl, .isInteracting, Bool, Self, Void

### Community 126 - "ProposedSize"
Cohesion: 0.12
Nodes (8): MeasureCache, ProposedSize, Float, float2, UInt32, UInt8, LayoutSubview, .priority

### Community 127 - "Write a test"
Cohesion: 0.20
Nodes (8): Headless UI tests, Run, Snapshots, When to launch the app instead (drive-app skill), Write a test, makeImage(), CGImage, UInt8

### Community 128 - "SwiftSyntaxMacros"
Cohesion: 0.13
Nodes (11): CompilerPlugin, ReactiveUIMacrosPlugin, Macro, ListMacroTests, StateMacroTests, ReactiveUIMacrosPlugin, SwiftCompilerPlugin, SwiftSyntaxMacroExpansion (+3 more)

### Community 129 - "oracle.swift"
Cohesion: 0.29
Nodes (6): Probe, .body, render(), CGSize, V, View

### Community 130 - "VectorDemo"
Cohesion: 0.23
Nodes (7): StressCell, StressIndex, StressRow, .body, Bool, VectorDemo, .body

### Community 131 - "BodyParser"
Cohesion: 0.14
Nodes (17): Scopes, BodyParser, Bool, ClosureExprSyntax, ExprSyntax, FunctionCallExprSyntax, ArgCombine, construct (+9 more)

### Community 132 - "StepIterator"
Cohesion: 0.24
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
Cohesion: 0.10
Nodes (15): CalendarView, Components, DatePicker, DatePickerStyle, compact, graphical, DayCell, Bool (+7 more)

### Community 138 - "VList"
Cohesion: 0.33
Nodes (5): Float, HorizontalAlignment, T, Void, VList

### Community 139 - "TextField"
Cohesion: 0.18
Nodes (10): EditKind, deleting, other, typing, Snapshot, Range, Self, Void (+2 more)

### Community 140 - "Path"
Cohesion: 0.13
Nodes (17): .body, Path, .isClosed, .length, .localBounds, Source, builder, commands (+9 more)

### Community 142 - "FieldBox"
Cohesion: 0.30
Nodes (4): FieldBox, .clipRect, Float, float2

### Community 143 - ".step"
Cohesion: 0.47
Nodes (3): Rules, AnimationTests, Double

### Community 144 - "Section"
Cohesion: 0.12
Nodes (14): CaptionSlot, .isEmpty, RowLayout, RowSeparators, RowStack, .inset, Section, .inset (+6 more)

### Community 145 - "AnimationGroup"
Cohesion: 0.36
Nodes (4): AnimationGroup, Void, UITransaction, withAnimation()

### Community 146 - "Stepper"
Cohesion: 0.19
Nodes (10): Stepper, StepperGlyph, Bool, ClosedRange, Double, Float, float2, Text (+2 more)

### Community 147 - "GridCell"
Cohesion: 0.22
Nodes (5): GridCell, count, startIndex, isBetween(), thread

### Community 148 - "GlassPass"
Cohesion: 0.22
Nodes (9): GlassPass, atlasOrigin, direction, maxDepth, padding, pointsPerTexel, sceneOrigin, sigma (+1 more)

### Community 149 - ".endFrame"
Cohesion: 0.10
Nodes (16): How it works (when the harness itself needs changing), GlassItem, Float, float2, MTLTexture, UInt8, MTKView, MTLCommandBuffer (+8 more)

### Community 150 - "ConditionalDemo"
Cohesion: 0.31
Nodes (5): ConditionalDemo, .body, Bool, Float, float4

### Community 151 - "FileWatcher"
Cohesion: 0.22
Nodes (7): CoreServices, FSEventStreamRef, FileWatcher, ArraySlice, DispatchQueue, URL, Void

### Community 152 - "EmptyElement"
Cohesion: 0.22
Nodes (3): EmptyElement, LeafElement, Void

### Community 153 - "ShapeType2D"
Cohesion: 0.25
Nodes (8): ShapeType2D, Circle, Glass, Glyph, Image, Line, Square, Vector

### Community 154 - "TableColumn"
Cohesion: 0.23
Nodes (8): KeyPath, MainActor, HorizontalAlignment, KeyPathComparator, T, V, TableColumn, TableColumnBuilder

### Community 155 - "ZStack"
Cohesion: 0.23
Nodes (6): Alignment, Bool, Float, float2, Void, ZStack

### Community 156 - "TableDemo"
Cohesion: 0.40
Nodes (5): Person, float4, KeyPathComparator, TableDemo, .body

### Community 157 - "TransitionElement"
Cohesion: 0.17
Nodes (5): Float, Void, TransitionElement, .currentState, Void

### Community 158 - "Padding"
Cohesion: 0.31
Nodes (5): IMView, Padding, Float, Self, Void

### Community 159 - "View"
Cohesion: 0.18
Nodes (11): Bool, View, Background, ExpandedFrame, FlexFrame, HStack, .isSpacer, MouseOver (+3 more)

### Community 161 - ".init"
Cohesion: 0.25
Nodes (7): DisclosureChevron, DisclosureGroup, Bool, Float, float2, Text, Void

### Community 163 - "KeyboardDemo"
Cohesion: 0.38
Nodes (5): KeyboardDemo, .body, Bool, Float, float2

### Community 164 - "int2"
Cohesion: 0.40
Nodes (3): int2, float2, from1DTo2DArray()

### Community 165 - "TableCell"
Cohesion: 0.20
Nodes (6): Background, HorizontalAlignment, T, TableCell, .clipRect, TableRowHighlight

### Community 166 - "float2"
Cohesion: 0.18
Nodes (7): Alignment, Float, float2, check(), HorizontalAlignment, layout(), float2

### Community 167 - "Line"
Cohesion: 0.29
Nodes (5): Line, .bounds, Float, float2, float4

### Community 168 - "Binding"
Cohesion: 0.15
Nodes (10): Member, Binding, .wrappedValue, Value, Void, SecureField, Text, ReferenceWritableKeyPath (+2 more)

### Community 169 - ".parseBranch"
Cohesion: 0.47
Nodes (3): IfExprSyntax, Void, BranchIR

### Community 170 - "expand"
Cohesion: 0.30
Nodes (5): BindingMacroTests, component(), expand(), NamedContentTests, SwiftParser

### Community 171 - "Foundation"
Cohesion: 0.10
Nodes (14): Foundation, benchmark(), Bool, Void, SVGPathCommand, close, cubic, line (+6 more)

### Community 172 - "Spacer"
Cohesion: 0.43
Nodes (3): Spacer, Float, float2

### Community 173 - "FormGraphic"
Cohesion: 0.22
Nodes (7): FormGraphic, mix(), Float, float2, float4, V, UIElementWrapping

### Community 174 - "Kind"
Cohesion: 0.33
Nodes (6): Kind, custom, firstTextBaseline, fraction, lastTextBaseline, ObjectIdentifier

### Community 175 - "Shape"
Cohesion: 0.40
Nodes (5): Shape, clip, depth, index, shapeType

### Community 176 - "Button"
Cohesion: 0.33
Nodes (6): Button, ButtonRole, cancel, destructive, Text, Void

### Community 177 - "TableColumnWidth"
Cohesion: 0.36
Nodes (3): Bool, Float, TableColumnWidth

### Community 179 - "HorizontalAlignment"
Cohesion: 0.50
Nodes (3): HorizontalAlignment, Mid, CGFloat

### Community 180 - "TextDemo"
Cohesion: 0.53
Nodes (3): Float, TextDemo, .body

### Community 183 - "Set"
Cohesion: 0.38
Nodes (5): Phases, UInt8, Set, UInt8, OptionSet

### Community 185 - ".readExactly"
Cohesion: 0.29
Nodes (5): PluginMain, StdinFilter, Bool, Int32, UInt8

### Community 188 - "IMGameView"
Cohesion: 0.33
Nodes (3): IMView, IMGameView, float4

### Community 189 - "9. Animation"
Cohesion: 0.53
Nodes (5): 9. Animation, Costs to know, Repeat and keyframes, The runtime, `withAnimation`

### Community 196 - "Result"
Cohesion: 0.67
Nodes (3): Result, handled, ignored

## Knowledge Gaps
- **487 isolated node(s):** `conditional`, `list`, `text`, `layout`, `image` (+482 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 959 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **16 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `String` connect `String` to `Input`, `Text`, `IMView`, `DiagnosticsTests`, `UIHarness`, `ViewItem`, `CodeGen`, `SingleChildElement`, `UIAnimation`, `IMView`, `ColorPicker`, `WindowState`, `.draw`, `.expansion`, `NumberField`, `UIShape`, `KeyPress`, `StateRewriter`, `Inset`, `ElementIR`, `LayoutDemo`, `SVGParser`, `Graphics2D`, `StateProperty`, `ImageManager`, `HStack`, `IDElement`, `AnimationDemo`, `Table`, `ListDemo`, `uidrive/main.swift`, `Demo`, `float4x4`, `OverlayElement`, `UIContext`, `Picker`, `Frame`, `IMView`, `.setValue`, `VectorCanvas`, `UIElement`, `.system`, `MetalKit`, `SVGIcon`, `MouseOver`, `HotReload`, `simd`, `IMView`, `assertSnapshot`, `Utils.swift`, `Rectangle`, `SVGScanner`, `Image`, `Drag`, `SDFBaker.swift`, `.expansion`, `oracle.swift`, `BodyParser`, `FlexFrame`, `AnimationMacroTests`, `DatePicker`, `TextField`, `Path`, `Section`, `Stepper`, `ConditionalDemo`, `FileWatcher`, `TableColumn`, `ZStack`, `TableDemo`, `Padding`, `.init`, `KeyboardDemo`, `float2`, `Binding`, `.parseBranch`, `expand`, `Foundation`, `Button`, `.init`?**
  _High betweenness centrality (0.268) - this node is a cross-community bridge._
- **Why does `Int` connect `Int` to `UIElementWrapping`, `VectorDemo`, `Float`, `BodyParser`, `SDFPathBuilder`, `FlexFrame`, `ViewItem`, `DatePicker`, `TextField`, `Path`, `MathLib.swift`, `UIAnimation`, `IMView`, `FieldBox`, `VList`, `Grid`, `ColorPicker`, `.step`, `.endFrame`, `ConditionalDemo`, `WindowState`, `ZStack`, `TableDemo`, `TransitionElement`, `View`, `.removeRow`, `ElementIR`, `LayoutDemo`, `VectorBaker`, `int2`, `Graphics2D`, `String`, `ImageManager`, `TableColumnWidth`, `AnimationDemo`, `TextDemo`, `Table`, `ListDemo`, `StackElement`, `.readExactly`, `uidrive/main.swift`, `.init`, `Array`, `LayoutSubviews`, `UIContext`, `Picker`, `UIElement`, `.system`, `Sendable`, `HotReload`, `simd`, `.insertRow`, `assertSnapshot`, `LazyStack`, `GraphicsGrid2D`, `Utils.swift`, `Void`, `LazyGridElement`, `SDFBaker.swift`, `ListRows`, `float2`, `Animator`, `ProposedSize`, `Write a test`?**
  _High betweenness centrality (0.188) - this node is a cross-community bridge._
- **Why does `UIElement` connect `UIElement` to `UIElementWrapping`, `VectorDemo`, `FlexFrame`, `TableColumn`, `UIHarness`, `VList`, `SingleChildElement`, `GlyphSDF.metal`, `UIAnimation`, `Section`, `Grid`, `ColorPicker`, `VectorShape`, `PopoverLayer`, `ConditionalDemo`, `EmptyElement`, `UIShape`, `ScrollView`, `TableDemo`, `TransitionElement`, `KeyPress`, `ZStack`, `UIKeyframe`, `Inset`, `.init`, `KeyboardDemo`, `LayoutDemo`, `EffectElement`, `float2`, `TableCell`, `ClipRect`, `HStack`, `IDElement`, `AnimationDemo`, `TextDemo`, `Table`, `ListDemo`, `SnapshotTests`, `StackElement`, `Demo`, `GeometryChangeElement`, `LayoutSubviews`, `UIElement+ReactiveSetters.swift`, `OverlayElement`, `UIContext`, `Picker`, `Frame`, `Int`, `VectorCanvas`, `EffectState`, `.system`, `Sendable`, `simd`, `TransitionState`, `LazyStack`, `HittableView`, `.content`, `Rectangle`, `Void`, `LazyGridElement`, `Axis`, `ViewDimensions`, `ListRows`, `Animator`, `ProposedSize`?**
  _High betweenness centrality (0.173) - this node is a cross-community bridge._
- **Are the 5 inferred relationships involving `UIContext` (e.g. with `Effects and transitions` and `HittableGrid2D`) actually correct?**
  _`UIContext` has 5 INFERRED edges - model-reasoned connections that need verification._
- **Are the 23 inferred relationships involving `UIElement` (e.g. with `7. Diagnostics` and `What needs a relaunch`) actually correct?**
  _`UIElement` has 23 INFERRED edges - model-reasoned connections that need verification._
- **What connects `conditional`, `list`, `text` to the rest of the system?**
  _487 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `UIElementWrapping` be split into smaller, more focused modules?**
  _Cohesion score 0.13054187192118227 - nodes in this community are weakly interconnected._