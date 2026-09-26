# Graph Report - MetalGraphics  (2026-09-26)

## Corpus Check
- 248 files · ~213,933 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 16 file(s) not represented in the graph (top: (none) 4, .plist 3, .resolved 2)

## Summary
- 4537 nodes · 12542 edges · 212 communities (198 shown, 14 thin omitted)
- Extraction: 90% EXTRACTED · 10% INFERRED · 0% AMBIGUOUS · INFERRED: 1282 edges (avg confidence: 0.83)
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
- Background
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
- Weight
- WindowState
- Float
- ComponentMacro
- NumberField
- UIShape
- ScrollView
- ViewRenderer
- KeyPress
- SDF.metal
- DragDropDemo
- UIKeyframe
- Inset
- Arity
- UIElement+ReactiveSetters.swift
- LayoutDemo
- VectorBaker
- SVGParser
- Graphics2D
- Math.metal
- BoundingBox3D
- bakeVectorSDF
- Shaders/Shaders.metal
- StateProperty
- Naming
- SceneData
- ImageManager
- Rect
- HittableGrid2D
- TextFont
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
- PointerHandlers
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
- SparseSet
- Sendable
- SIMD2
- Slider
- VectorCanvas
- BoundingBox2D
- UIElement
- .draw
- Divider
- .system
- Alignment
- Performance in MetalGraphics
- MetalKit
- SVGIcon
- MouseOver
- HotReload
- simd
- VectorItem
- Text
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
- Void
- VList
- uchar4
- TextEnvironment
- SDFBaker.swift
- TextStyleElement
- PathBuilder
- Axis
- .expansion
- Toggle
- 9. Animation
- TransitionElement
- float2
- TextLayout.swift
- FormControl
- ProposedSize
- FontManager
- SwiftSyntaxMacros
- oracle.swift
- Int
- String
- StepIterator
- SDFPathBuilder
- FlexFrame
- DragGesture
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
- Effects and transitions
- GlassPass
- .endFrame
- ConditionalDemo
- FileWatcher
- SingleChildElement
- expand
- TableColumn
- ZStack
- Animator
- MultiChildElement
- View
- .scan
- Button
- PopoverLayer
- ComponentMacroTests
- KeyboardDemo
- Float
- Kind
- .body
- AnimationGroup
- Binding
- Line
- expand
- Foundation
- HList
- FormGraphic
- ViewThatFits
- Kind
- ButtonFace
- TableColumnWidth
- Padding
- View
- .render
- Square
- AlignmentKey
- .setButtonStyle
- .restyleLayout
- .readExactly
- Driving GPURayMarching
- LabeledContent
- int2
- .removeRow
- expand
- VStack
- TextDemo
- IMGameView
- Phases
- ClipRect
- TableRowHighlight
- .setLayout
- float2x2
- Square
- Kind
- Equatable
- Shape
- float2
- StateMacroTests
- HoverChange
- Set
- ListMacroTests
- HorizontalAlignment
- ImageQuad
- Result
- Owner

## God Nodes (most connected - your core abstractions)
1. `UIContext` - 416 edges
2. `UIElement` - 284 edges
3. `UIAnimation` - 244 edges
4. `ProposedSize` - 171 edges
5. `Graphics2D` - 122 edges
6. `simd` - 93 edges
7. `UIHarness` - 93 edges
8. `TextStyleElement` - 88 edges
9. `TextEnvironment` - 72 edges
10. `Rectangle` - 69 edges

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

## Communities (212 total, 14 thin omitted)

### Community 0 - "UIElementWrapping"
Cohesion: 0.20
Nodes (6): Bool, HorizontalAlignment, Self, VerticalAlignment, Void, UIElementWrapping

### Community 1 - "Input"
Cohesion: 0.10
Nodes (14): Input, .mouseDown, .mouseMoved, .mousePressed, .mouseUp, Bool, Double, NSEvent (+6 more)

### Community 2 - "Text"
Cohesion: 0.07
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
Cohesion: 0.10
Nodes (19): Rules, AnimationTests, InteractionTests, makeImage(), Bool, CGImage, Double, Float (+11 more)

### Community 7 - "AnimatedProperty"
Cohesion: 0.06
Nodes (30): AnimatedProperty, center, color, cornerRadius, fontSize, height, inset, keyframes (+22 more)

### Community 8 - "GPURayMarching/Shaders.metal"
Cohesion: 0.08
Nodes (30): Camera, fov, position, rotation, compute(), distanceToScene(), GridArgBuffer, GridItem (+22 more)

### Community 9 - "Background"
Cohesion: 0.32
Nodes (6): Background, IMView, Float, float4, Self, Void

### Community 10 - "CodeGen"
Cohesion: 0.11
Nodes (12): CodeGen, .armedHandlers, Dependents, RowsMode, full, insert, remove, Bool (+4 more)

### Community 11 - "IMView"
Cohesion: 0.23
Nodes (9): ExpandedFrame, FlexFrame, Frame, IMView, Alignment, Float, float2, Self (+1 more)

### Community 12 - "GlyphSDF.metal"
Cohesion: 0.09
Nodes (34): bakeSDF(), lineWinding(), constant, float2, kernel, texture2d, uint, uint2 (+26 more)

### Community 13 - "MathLib.swift"
Cohesion: 0.18
Nodes (17): int3, dragDirection(), from1DTo3DArray(), from2DTo1DArray(), from3DTo1DArray(), fromPixelCoordToGridIndex(), fromWorldPositionToGridIndex(), lerp() (+9 more)

### Community 14 - "UIAnimation"
Cohesion: 0.05
Nodes (16): UIAnimation, Background, Circle, FlexFrame, Frame, HStack, Alignment, Float (+8 more)

### Community 15 - "IMView"
Cohesion: 0.12
Nodes (18): ExpandedFrame, IMView, Background, FlexFrame, Float, float2, Frame, HStack (+10 more)

### Community 16 - "MyMTKView"
Cohesion: 0.15
Nodes (10): Modifier, MyMTKView, .acceptsFirstResponder, .pointerStyle, Bool, NSEvent, UInt, UInt16 (+2 more)

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
Nodes (26): Text styling, Capsule, Circle, .length, .localBounds, Ellipse, .length, .localBounds (+18 more)

### Community 21 - "Weight"
Cohesion: 0.07
Nodes (27): TextStyle, body, callout, caption, caption2, footnote, headline, largeTitle (+19 more)

### Community 22 - "WindowState"
Cohesion: 0.15
Nodes (13): CaseIterable, Application, Event, Inspector, Navigation, Global, Reload, Bool (+5 more)

### Community 23 - "Float"
Cohesion: 0.13
Nodes (16): ImageQuad, DebugData, GlassItem, GlassPass, GPUClip, SceneData, ShapeArgBuffer, Bool (+8 more)

### Community 24 - "ComponentMacro"
Cohesion: 0.50
Nodes (3): ExtensionMacro, MemberMacro, ComponentMacro

### Community 25 - "NumberField"
Cohesion: 0.15
Nodes (12): Number3Field, .body, SIMD3, T, Number4Field, .body, T, NumberField (+4 more)

### Community 26 - "UIShape"
Cohesion: 0.10
Nodes (15): ClipElement, .clipCornerRadii, .clipRect, float4, Background, GlassBackground, GlassMaterial, Float (+7 more)

### Community 27 - "ScrollView"
Cohesion: 0.08
Nodes (18): LazyStackViewport, ScrollIndicator, .visibility, ScrollIndicatorVisibility, automatic, hidden, never, visible (+10 more)

### Community 28 - "ViewRenderer"
Cohesion: 0.16
Nodes (11): .body, CGSize, Double, Float, float2, MTKView, View, ViewRenderer (+3 more)

### Community 29 - "KeyPress"
Cohesion: 0.25
Nodes (9): CharacterSet, ExpressibleByExtendedGraphemeClusterLiteral, KeyEquivalent, KeyPress, KeyPressElement, Character, NSEvent, Set (+1 more)

### Community 30 - "SDF.metal"
Cohesion: 0.15
Nodes (15): dot2(), float2, float4, sdBox(), sdBoxSquared(), sdCircle(), sdCircleSquared(), sdOrientedBox() (+7 more)

### Community 31 - "DragDropDemo"
Cohesion: 0.18
Nodes (9): DragChip, DragDropDemo, .body, Bool, float4, GlassDemo, .body, Bool (+1 more)

### Community 32 - "UIKeyframe"
Cohesion: 0.19
Nodes (10): KeyframeElement, KeyframeSegment, Any, Float, float2, Self, V, UIKeyframe (+2 more)

### Community 33 - "Inset"
Cohesion: 0.10
Nodes (20): PointerDemo, .body, Bool, float2, Float, .packed, .packed, .packed (+12 more)

### Community 34 - "Arity"
Cohesion: 0.29
Nodes (7): Arity, leaf, multi, single, Attach, arity, door

### Community 35 - "UIElement+ReactiveSetters.swift"
Cohesion: 0.16
Nodes (12): BlurElement, EffectElement, .hasEffect, .localEffect, ShadowElement, Bool, Float, float2 (+4 more)

### Community 36 - "LayoutDemo"
Cohesion: 0.22
Nodes (7): LayoutDemo, .body, Alignment, Float, float2, HorizontalAlignment, VerticalAlignment

### Community 37 - "VectorBaker"
Cohesion: 0.12
Nodes (20): BakedRegion, DynamicSDFAtlas, .maxTileSize, Mode, fillEvenOdd, fillNonZero, stroke, SDFSlot (+12 more)

### Community 38 - "SVGParser"
Cohesion: 0.17
Nodes (16): SVGDocument, SVGPaint, color, currentColor, none, SVGParser, SVGShape, SVGStyle (+8 more)

### Community 39 - "Graphics2D"
Cohesion: 0.11
Nodes (18): CustomStringConvertible, Error, Glyph, Line, Graphics2D, .glassAtlasWidth, .size, PipelineError (+10 more)

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

### Community 44 - "StateProperty"
Cohesion: 0.13
Nodes (13): PatternBindingSyntax, .states, TypeSyntax, .arrayStates, .reactiveNames, .stateNames, StateProperty, AttributeSyntax (+5 more)

### Community 45 - "Naming"
Cohesion: 0.16
Nodes (7): DeclGroupSyntax, ExtensionDeclSyntax, AttributeSyntax, DeclSyntax, TypeSyntax, Naming, TypeSyntaxProtocol

### Community 46 - "SceneData"
Cohesion: 0.29
Nodes (7): DebugData, drawGrid, showFilledCells, SceneData, debug, time, windowSize

### Community 47 - "ImageManager"
Cohesion: 0.14
Nodes (16): CGContext, BitmapTexture, ImageManager, PendingUpload, Bundle, CGFloat, CGImage, Float (+8 more)

### Community 48 - "Rect"
Cohesion: 0.16
Nodes (10): Rect, .center, .height, .maxX, .maxY, .minX, .minY, .width (+2 more)

### Community 49 - "HittableGrid2D"
Cohesion: 0.16
Nodes (17): DragState, Entry, HittableGrid2D, HittableGridCell, Bool, Double, Float, float2 (+9 more)

### Community 50 - "TextFont"
Cohesion: 0.09
Nodes (20): CoreText, SDFFont, Hasher, Design, `default`, monospaced, rounded, serif (+12 more)

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
Cohesion: 0.17
Nodes (10): Bool, float2, KeyPathComparator, Set, T, Text, Void, Table (+2 more)

### Community 55 - "ListDemo"
Cohesion: 0.20
Nodes (12): ChipView, .body, DemoItem, ListDemo, .body, RowView, .body, Bool (+4 more)

### Community 56 - "Float"
Cohesion: 0.28
Nodes (6): Float, .degrees, .isNegative, .radians, Bool, ClosedRange

### Community 57 - "StackElement"
Cohesion: 0.06
Nodes (28): origin, DraggableElement, DragPreviewLayer, .hasEffect, .localEffect, DragSession, DropDestinationElement, ReorderElement (+20 more)

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
Cohesion: 0.06
Nodes (31): graphify, Hot reload, Performance, UI tests, Demo, animation, conditional, containers (+23 more)

### Community 62 - "float4x4"
Cohesion: 0.14
Nodes (12): matrix_double4x4, float3x3, Float, float4x4, .formated, .identity, .upperLeft, Bool (+4 more)

### Community 63 - "Array"
Cohesion: 0.25
Nodes (5): Array, .byteCount, Element, IndexSet, Void

### Community 64 - "PointerHandlers"
Cohesion: 0.10
Nodes (23): AnyObject, PointerHandlers, .gesture, .handlesEvents, .handlesPress, PointerHandling, .gesture, .handlers (+15 more)

### Community 65 - "Glass"
Cohesion: 0.07
Nodes (28): Circle, color, depth, position, radius, Clip, blur, bounds (+20 more)

### Community 66 - "GeometryChangeElement"
Cohesion: 0.17
Nodes (7): GeometryChangeElement, GeometryProxy, GeometryReader, Float, float2, Void, UIElementWrapping

### Community 67 - "Comparable Clamp"
Cohesion: 0.40
Nodes (3): Comparable, ClosedRange, Self

### Community 68 - "LayoutSubviews"
Cohesion: 0.08
Nodes (23): Cache, AnyLayout, AnyLayoutBox, HStackLayout, Layout, LayoutBox, LayoutSubviews, .endIndex (+15 more)

### Community 73 - "BorderElement"
Cohesion: 0.16
Nodes (9): BorderElement, .color, .lineWidth, .shape, BorderLayer, Float, float2, float4 (+1 more)

### Community 74 - "OverlayElement"
Cohesion: 0.23
Nodes (6): OverlayElement, .alignment, Alignment, Bool, float2, Void

### Community 75 - "UIContext"
Cohesion: 0.05
Nodes (14): Float, float4, ObjectIdentifier, UInt32, UIContext, .isDragging, .pointerStyle, LayoutPass (+6 more)

### Community 76 - "Picker"
Cohesion: 0.08
Nodes (23): Kind, check, menuItem, segment, Picker, .selectedTitle, PickerMark, PickerStyle (+15 more)

### Community 77 - "Frame"
Cohesion: 0.26
Nodes (6): Frame, .size, Alignment, Float, float2, Void

### Community 78 - "SparseSet"
Cohesion: 0.18
Nodes (8): AnyIterator, SparseSet, .count, .isEmpty, .storedKeys, .values, Bool, Element

### Community 79 - "Sendable"
Cohesion: 0.12
Nodes (23): Hashable, FrameResizeDirection, inward, outward, FrameResizePosition, bottom, bottomLeading, bottomTrailing (+15 more)

### Community 80 - "SIMD2"
Cohesion: 0.23
Nodes (11): HStack, .size, IMView, Float, HorizontalAlignment, Self, VerticalAlignment, Void (+3 more)

### Community 81 - "Slider"
Cohesion: 0.18
Nodes (11): ProgressView, .fraction, Slider, SliderTrack, ClosedRange, Double, Float, float2 (+3 more)

### Community 82 - "VectorCanvas"
Cohesion: 0.22
Nodes (7): .body, Float, float2, Self, VectorCanvas, .children, VectorShapeList

### Community 83 - "BoundingBox2D"
Cohesion: 0.17
Nodes (12): BoundingBox2D, .bottom, .bottomRight, .height, .left, .right, .top, .topLeft (+4 more)

### Community 84 - "UIElement"
Cohesion: 0.06
Nodes (23): 7. Diagnostics, LayoutTraits, AnyHashable, float4, Void, UIElement, .clipCornerRadii, .clipRect (+15 more)

### Community 85 - ".draw"
Cohesion: 0.21
Nodes (4): EffectState, float4, Void, TextStyle

### Community 86 - "Divider"
Cohesion: 0.27
Nodes (4): Divider, Float, float2, float4

### Community 87 - ".system"
Cohesion: 0.09
Nodes (27): ContainersDemo, .body, Alignment, Bool, Float, GridsDemo, .body, Bool (+19 more)

### Community 88 - "Alignment"
Cohesion: 0.13
Nodes (17): Alignment, .offset, .xOffset, .yOffset, AlignmentID, HorizontalAlignment, .offset, Float (+9 more)

### Community 89 - "Performance in MetalGraphics"
Cohesion: 0.22
Nodes (8): 1. The frame, 2. Invalidation — name the narrowest effect, 4. GPU and Metal (`Graphics2D.swift`, `Shaders/Shaders.metal`), 5. Layout and text, 6. Lists and scrolling, 7. Measure, don't guess, 8. Before finishing, Performance in MetalGraphics

### Community 90 - "MetalKit"
Cohesion: 0.15
Nodes (10): App, Combine, ContentView, .body, GPURayMarchingApp, .body, MetalView, MetalKit (+2 more)

### Community 91 - "SVGIcon"
Cohesion: 0.13
Nodes (15): Layer, SVGIcon, Bool, Bundle, Data, Float, float2, float4 (+7 more)

### Community 92 - "MouseOver"
Cohesion: 0.35
Nodes (6): IMView, MouseOver, Bool, Float, Self, Void

### Community 93 - "HotReload"
Cohesion: 0.09
Nodes (17): Duration, Hot reload, How it fits the frame loop, Quirks, What needs a relaunch, HotReload, Bool, Date (+9 more)

### Community 94 - "simd"
Cohesion: 0.16
Nodes (6): AppKit, Metal, MetalGraphicsLib, ReactiveUI, simd, XCTest

### Community 95 - "VectorItem"
Cohesion: 0.19
Nodes (12): Kind, bakedFill, bakedStroke, ellipse, roundedBox, Float, float2, VectorItem (+4 more)

### Community 96 - "Text"
Cohesion: 0.11
Nodes (3): Pointer, Bool, Text

### Community 97 - "LazyGridElement"
Cohesion: 0.14
Nodes (20): GridItem, LazyGridElement, .defaultCellAlignment, .trackAlignment, LazyHGrid, .defaultCellAlignment, .trackAlignment, LazyVGrid (+12 more)

### Community 98 - "IMView"
Cohesion: 0.39
Nodes (4): IMView, Spacer, Float, Void

### Community 99 - "assertSnapshot"
Cohesion: 0.18
Nodes (16): ImageIO, SnapshotTests, assertSnapshot(), failureURL(), loadPNG(), rgba(), rgbaImage(), CGImage (+8 more)

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
Cohesion: 0.15
Nodes (10): HittableView, .hitPosition, .hitSize, Bool, Float, float2, Void, float2 (+2 more)

### Community 105 - "float2"
Cohesion: 0.15
Nodes (6): AspectRatioElement, FixedSizeElement, PositionElement, Bool, Float, float2

### Community 106 - "GraphicsGrid2D"
Cohesion: 0.11
Nodes (19): Int32, GPUDevice, MTLDevice, GraphicsGrid2D, GridArgBuffer, GridCell, Shape, ShapeType2D (+11 more)

### Community 107 - "Utils.swift"
Cohesion: 0.17
Nodes (13): DispatchWorkItem, Debouncer, forEachGridCell(), generateRandomArray(), iterateWithStep(), name(), ClosedRange, DispatchQueue (+5 more)

### Community 108 - "Rectangle"
Cohesion: 0.10
Nodes (8): Rectangle, Float, float2, LayoutTests, PointerTests, Bool, Frame, Void

### Community 109 - "SVGPathCommand"
Cohesion: 0.12
Nodes (16): SVGPathCommand, close, cubic, line, move, quad, SVGPathData, SVGScanner (+8 more)

### Community 110 - "Image"
Cohesion: 0.11
Nodes (17): ContentMode, fill, fit, Image, .naturalSize, Interpolation, high, low (+9 more)

### Community 111 - "Void"
Cohesion: 0.07
Nodes (17): 3. Hot paths — per frame, or per element per frame, Invalidation, Any, Bool, Double, float2, Frame, UInt8 (+9 more)

### Community 112 - "VList"
Cohesion: 0.29
Nodes (6): Float, HorizontalAlignment, T, Void, VList, VStack

### Community 113 - "uchar4"
Cohesion: 0.29
Nodes (6): UInt8, uchar4, .a, .b, .g, .r

### Community 114 - "TextEnvironment"
Cohesion: 0.09
Nodes (15): RunStyle, Bool, Float, float4, Void, TextDecorationStyle, TextEnvironment, .resolvedFont (+7 more)

### Community 115 - "SDFBaker.swift"
Cohesion: 0.14
Nodes (21): PendingBake, SDFAtlas, SDFBakeParams, SDFBaker, SDFRegion, SDFShape, SDFShapeGeometry, SDFShapeMode (+13 more)

### Community 116 - "TextStyleElement"
Cohesion: 0.12
Nodes (11): TextCase, lowercase, uppercase, Bool, Float, float4, Self, TextStyleElement (+3 more)

### Community 117 - "PathBuilder"
Cohesion: 0.18
Nodes (10): PathBuilder, PathMorph, Bool, Double, Float, float2, VectorSegment, VectorGeometry (+2 more)

### Community 118 - "Axis"
Cohesion: 0.09
Nodes (18): ExpressibleByArrayLiteral, FlexFrame, Axis, .inverted, .size, IMView, Float, float2 (+10 more)

### Community 119 - ".expansion"
Cohesion: 0.13
Nodes (12): AccessorDeclSyntax, DeclSyntaxProtocol, DiagnosticMessage, DiagnosticSeverity, FixItMessage, MessageID, MacroExpansionContext, ReactiveUIDiagnostic (+4 more)

### Community 120 - "Toggle"
Cohesion: 0.26
Nodes (7): Bool, Float, float2, Text, Void, Toggle, ToggleSwitch

### Community 121 - "9. Animation"
Cohesion: 0.16
Nodes (12): 2. What a component looks like, 3. What gets generated, 4. Rules that follow, 6. Composition, not helper methods, 8. How it lands on screen, 9. Animation, Compile-time state in RetainedModeUI, Costs to know (+4 more)

### Community 122 - "TransitionElement"
Cohesion: 0.18
Nodes (6): 1. The pieces, Float, Void, TransitionElement, .currentState, Bool

### Community 123 - "float2"
Cohesion: 0.14
Nodes (10): TableColumnLayout, .count, Bool, float2, HorizontalAlignment, TableCell, .clipRect, TableCells (+2 more)

### Community 124 - "TextLayout.swift"
Cohesion: 0.11
Nodes (36): CTLine, CTRun, CTTypesetter, caretOffsets(), layoutText(), measureText(), ParagraphShaper, .baseHeight (+28 more)

### Community 125 - "FormControl"
Cohesion: 0.21
Nodes (5): FormControl, .isInteracting, Bool, Self, Void

### Community 126 - "ProposedSize"
Cohesion: 0.15
Nodes (8): MeasureCache, ProposedSize, Float, float2, UInt32, UInt8, LayoutSubview, .priority

### Community 127 - "FontManager"
Cohesion: 0.21
Nodes (13): CGGlyph, FontManager, GlyphKey, GlyphMetrics, Bool, CGFloat, CTFont, Float (+5 more)

### Community 128 - "SwiftSyntaxMacros"
Cohesion: 0.16
Nodes (12): AccessorMacro, PeerMacro, StateMacro, DragDropMacroTests, ReactiveUIMacrosPlugin, SwiftDiagnostics, SwiftParser, SwiftSyntax (+4 more)

### Community 129 - "oracle.swift"
Cohesion: 0.29
Nodes (6): Probe, .body, render(), CGSize, V, View

### Community 130 - "Int"
Cohesion: 0.12
Nodes (16): StressCell, StressIndex, StressRow, .body, Bool, VectorDemo, .body, Identifiable (+8 more)

### Community 131 - "String"
Cohesion: 0.11
Nodes (23): String, .uint32, UInt32, Bool, ClosureExprSyntax, ExprSyntax, FunctionCallExprSyntax, Set (+15 more)

### Community 132 - "StepIterator"
Cohesion: 0.22
Nodes (6): IteratorProtocol, StepIterator, StepSequence, Bool, Float, Sequence

### Community 133 - "SDFPathBuilder"
Cohesion: 0.21
Nodes (12): CGPath, PathElement, SDFPathBuilder, .isEmpty, Bool, float2, UInt8, CGRect (+4 more)

### Community 134 - "FlexFrame"
Cohesion: 0.30
Nodes (4): FlexFrame, Alignment, Float, float2

### Community 135 - "DragGesture"
Cohesion: 0.15
Nodes (11): Member, WritableKeyPath, DragGesture, EmptyGesture, Gesture, Double, Float, float2 (+3 more)

### Community 137 - "DatePicker"
Cohesion: 0.07
Nodes (22): EmptyElement, LeafElement, PopoverHandle, .isPresented, CalendarView, Components, DatePicker, DatePickerStyle (+14 more)

### Community 138 - "TextTests"
Cohesion: 0.09
Nodes (6): Write a test, .style, Float, Int32, Void, TextTests

### Community 139 - "TextField"
Cohesion: 0.13
Nodes (13): EditKind, deleting, other, typing, Snapshot, Bool, Character, Float (+5 more)

### Community 140 - "Path"
Cohesion: 0.13
Nodes (16): Path, .isClosed, .length, .localBounds, Source, builder, commands, Bool (+8 more)

### Community 142 - "FieldBox"
Cohesion: 0.31
Nodes (4): FieldBox, .clipRect, float2, Text

### Community 143 - "Drag"
Cohesion: 0.15
Nodes (7): Carbon.HIToolbox, GameController, Drag, .description, Float, float2, Void

### Community 144 - "Section"
Cohesion: 0.13
Nodes (13): CaptionSlot, .isEmpty, RowLayout, RowSeparators, RowStack, .inset, Section, .inset (+5 more)

### Community 145 - "BodyParser"
Cohesion: 0.11
Nodes (24): CodeBlockItemListSyntax, IfExprSyntax, BodyParser, MemberBlockItemListSyntax, VariableDeclSyntax, BranchIR, ChainLink, ChildList (+16 more)

### Community 146 - "Stepper"
Cohesion: 0.19
Nodes (10): Stepper, StepperGlyph, Bool, ClosedRange, Double, Float, float2, Text (+2 more)

### Community 147 - "Effects and transitions"
Cohesion: 0.19
Nodes (13): Effects and transitions, backdrop2D(), compute2D(), glassBlur(), constant, kernel, texture2d, uint2 (+5 more)

### Community 148 - "GlassPass"
Cohesion: 0.22
Nodes (9): GlassPass, atlasOrigin, direction, maxDepth, padding, pointsPerTexel, sceneOrigin, sigma (+1 more)

### Community 149 - ".endFrame"
Cohesion: 0.12
Nodes (13): How it works (when the harness itself needs changing), Float, float2, MTLTexture, UInt8, MTKView, MTLCommandBuffer, Void (+5 more)

### Community 150 - "ConditionalDemo"
Cohesion: 0.36
Nodes (5): ConditionalDemo, .body, Bool, Float, float4

### Community 151 - "FileWatcher"
Cohesion: 0.21
Nodes (8): CoreServices, FSEventStreamRef, FileWatcher, ArraySlice, DispatchQueue, Set, URL, Void

### Community 152 - "SingleChildElement"
Cohesion: 0.13
Nodes (8): SingleChildElement, Float, float2, Void, Form, Bool, ObjectIdentifier, VStack

### Community 153 - "expand"
Cohesion: 0.27
Nodes (3): component(), expand(), TextMacroTests

### Community 154 - "TableColumn"
Cohesion: 0.23
Nodes (8): KeyPath, MainActor, HorizontalAlignment, KeyPathComparator, T, V, TableColumn, TableColumnBuilder

### Community 155 - "ZStack"
Cohesion: 0.23
Nodes (6): Alignment, Bool, Float, float2, Void, ZStack

### Community 156 - "Animator"
Cohesion: 0.25
Nodes (11): Apply, Animator, .isIdle, Key, Running, Bool, Double, Float (+3 more)

### Community 157 - "MultiChildElement"
Cohesion: 0.16
Nodes (7): MultiChildElement, .liveChildrenCount, float2, Void, ListRows, T, Void

### Community 158 - "View"
Cohesion: 0.15
Nodes (13): .inspectorView, Editor, .body, Inspector, .body, Navigation, .body, ToggleView (+5 more)

### Community 159 - ".scan"
Cohesion: 0.21
Nodes (8): DeclReferenceExprSyntax, MemberAccessExprSyntax, StateRewriter, ClosureExprSyntax, ExprSyntax, Set, SyntaxProtocol, SyntaxRewriter

### Community 160 - "Button"
Cohesion: 0.25
Nodes (4): Button, HStack, ButtonTests, float2

### Community 161 - "PopoverLayer"
Cohesion: 0.25
Nodes (6): PopoverFill, PopoverLayer, Float, float2, HorizontalAlignment, Void

### Community 163 - "KeyboardDemo"
Cohesion: 0.32
Nodes (6): KeyboardDemo, .body, Bool, Float, float2, Set

### Community 164 - "Float"
Cohesion: 0.13
Nodes (8): Alignment, Background, FlexFrame, Float, float2, float4, Frame, Alignment

### Community 165 - "Kind"
Cohesion: 0.15
Nodes (13): Kind, columnResize, `default`, frameResize, grabActive, grabIdle, horizontalText, link (+5 more)

### Community 166 - ".body"
Cohesion: 0.19
Nodes (11): AudioSettings, FormDemo, .body, Bool, Date, Double, float4, Theme (+3 more)

### Community 167 - "AnimationGroup"
Cohesion: 0.33
Nodes (5): `withAnimation`, AnimationGroup, Void, UITransaction, withAnimation()

### Community 168 - "Binding"
Cohesion: 0.15
Nodes (11): 5. Collections are just `@State` arrays, Bindings are lowered, not passed, Mutation carries the operation, Named content closures, The plain setter still works, Binding, .wrappedValue, Void (+3 more)

### Community 169 - "Line"
Cohesion: 0.29
Nodes (5): Line, .bounds, Float, float2, float4

### Community 170 - "expand"
Cohesion: 0.29
Nodes (4): BindingMacroTests, component(), expand(), NamedContentTests

### Community 171 - "Foundation"
Cohesion: 0.13
Nodes (10): Foundation, Person, float4, KeyPathComparator, Set, TableDemo, .body, benchmark() (+2 more)

### Community 172 - "HList"
Cohesion: 0.29
Nodes (6): HStack, HList, Float, T, VerticalAlignment, Void

### Community 173 - "FormGraphic"
Cohesion: 0.16
Nodes (8): FormGraphic, FormMetrics, mix(), Float, float2, float4, V, UIElementWrapping

### Community 174 - "ViewThatFits"
Cohesion: 0.23
Nodes (4): Float, float2, Void, ViewThatFits

### Community 175 - "Kind"
Cohesion: 0.20
Nodes (12): AnimationScope, BoundArg, Kind, condition, constructor, modifier, optional, passThrough (+4 more)

### Community 176 - "ButtonFace"
Cohesion: 0.06
Nodes (29): ButtonFace, .inset, ButtonRole, cancel, destructive, ButtonStyle, automatic, bordered (+21 more)

### Community 177 - "TableColumnWidth"
Cohesion: 0.36
Nodes (3): Bool, Float, TableColumnWidth

### Community 178 - "Padding"
Cohesion: 0.31
Nodes (5): IMView, Padding, Float, Self, Void

### Community 179 - "View"
Cohesion: 0.18
Nodes (11): Bool, View, Background, ExpandedFrame, FlexFrame, HStack, .isSpacer, MouseOver (+3 more)

### Community 180 - ".render"
Cohesion: 0.12
Nodes (8): Headless UI tests, Run, Snapshots, When to launch the app instead (drive-app skill), ShadowState, .margin, Int32, Int32

### Community 181 - "Square"
Cohesion: 0.29
Nodes (5): Square, .bounds, Float, float2, float4

### Community 182 - "AlignmentKey"
Cohesion: 0.29
Nodes (5): Float, AlignmentKey, .isFraction, Bool, Hasher

### Community 184 - ".restyleLayout"
Cohesion: 0.25
Nodes (4): V, Void, WritableKeyPath, .runs

### Community 185 - ".readExactly"
Cohesion: 0.17
Nodes (9): CompilerPlugin, PluginMain, ReactiveUIMacrosPlugin, Macro, StdinFilter, Bool, Int32, UInt8 (+1 more)

### Community 186 - "Driving GPURayMarching"
Cohesion: 0.33
Nodes (5): 1. Build and launch, 2. Compile the driver, 3. Drive and look, Driving GPURayMarching, Notes

### Community 187 - "LabeledContent"
Cohesion: 0.32
Nodes (4): LabeledContent, HStack, Text, Void

### Community 188 - "int2"
Cohesion: 0.32
Nodes (3): int2, float2, from1DTo2DArray()

### Community 190 - "expand"
Cohesion: 0.54
Nodes (3): component(), expand(), PointerMacroTests

### Community 191 - "VStack"
Cohesion: 0.33
Nodes (4): Float, HorizontalAlignment, VStack, .crossKey

### Community 192 - "TextDemo"
Cohesion: 0.39
Nodes (4): Bool, Float, TextDemo, .body

### Community 193 - "IMGameView"
Cohesion: 0.33
Nodes (3): IMView, IMGameView, float4

### Community 195 - "ClipRect"
Cohesion: 0.17
Nodes (10): ClipRect, .isEmpty, Bool, float2, check(), Diagonal, HorizontalAlignment, layout() (+2 more)

### Community 196 - "TableRowHighlight"
Cohesion: 0.67
Nodes (3): Background, T, TableRowHighlight

### Community 199 - "Square"
Cohesion: 0.33
Nodes (6): Square, color, depth, position, rotation, size

### Community 200 - "Kind"
Cohesion: 0.33
Nodes (6): Kind, custom, firstTextBaseline, fraction, lastTextBaseline, ObjectIdentifier

### Community 201 - "Equatable"
Cohesion: 0.40
Nodes (5): Equatable, Kind, capsule, circle, rect

### Community 202 - "Shape"
Cohesion: 0.40
Nodes (5): Shape, clip, depth, index, shapeType

### Community 203 - "float2"
Cohesion: 0.18
Nodes (6): float2, .asInt2, .greatestComponent, .height, .width, Float

### Community 205 - "HoverChange"
Cohesion: 0.50
Nodes (4): HoverChange, entered, left, moved

### Community 206 - "Set"
Cohesion: 0.67
Nodes (3): Set, UInt8, OptionSet

### Community 208 - "HorizontalAlignment"
Cohesion: 0.50
Nodes (3): HorizontalAlignment, Mid, CGFloat

### Community 209 - "ImageQuad"
Cohesion: 0.67
Nodes (3): ImageQuad, .bounds, UInt32

### Community 210 - "Result"
Cohesion: 0.67
Nodes (3): Result, handled, ignored

### Community 211 - "Owner"
Cohesion: 0.67
Nodes (3): Owner, component, node

## Knowledge Gaps
- **594 isolated node(s):** `conditional`, `list`, `text`, `layout`, `image` (+589 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 1120 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **14 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `String` connect `String` to `Input`, `Text`, `DragAndDropTests`, `DiagnosticsTests`, `UIHarness`, `Background`, `CodeGen`, `IMView`, `UIAnimation`, `IMView`, `ColorPicker`, `WindowState`, `NumberField`, `UIShape`, `ScrollView`, `KeyPress`, `DragDropDemo`, `Inset`, `Arity`, `LayoutDemo`, `SVGParser`, `Graphics2D`, `StateProperty`, `Naming`, `ImageManager`, `TextFont`, `IDElement`, `AnimationDemo`, `Table`, `ListDemo`, `StackElement`, `uidrive/main.swift`, `Demo`, `float4x4`, `BorderElement`, `OverlayElement`, `UIContext`, `Picker`, `Frame`, `SIMD2`, `Slider`, `VectorCanvas`, `UIElement`, `.draw`, `.system`, `SVGIcon`, `MouseOver`, `HotReload`, `IMView`, `assertSnapshot`, `Utils.swift`, `Rectangle`, `SVGPathCommand`, `Image`, `SDFBaker.swift`, `TextStyleElement`, `.expansion`, `Toggle`, `TextLayout.swift`, `FontManager`, `oracle.swift`, `Int`, `FlexFrame`, `AnimationMacroTests`, `DatePicker`, `TextTests`, `TextField`, `Path`, `Drag`, `Section`, `BodyParser`, `Stepper`, `ConditionalDemo`, `FileWatcher`, `SingleChildElement`, `expand`, `TableColumn`, `ZStack`, `MultiChildElement`, `View`, `.scan`, `KeyboardDemo`, `.body`, `Binding`, `expand`, `Foundation`, `Kind`, `ButtonFace`, `Padding`, `.setButtonStyle`, `LabeledContent`, `expand`, `VStack`, `TextDemo`, `ClipRect`, `Owner`?**
  _High betweenness centrality (0.232) - this node is a cross-community bridge._
- **Why does `UIElement` connect `UIElement` to `UIElementWrapping`, `Int`, `DragAndDropTests`, `FlexFrame`, `TableColumn`, `UIHarness`, `DatePicker`, `TextTests`, `ZStack`, `UIAnimation`, `Section`, `Grid`, `VectorShape`, `ConditionalDemo`, `SingleChildElement`, `UIShape`, `ScrollView`, `Animator`, `MultiChildElement`, `KeyPress`, `DragDropDemo`, `UIKeyframe`, `Inset`, `PopoverLayer`, `KeyboardDemo`, `LayoutDemo`, `UIElement+ReactiveSetters.swift`, `.body`, `Float`, `Foundation`, `HList`, `FormGraphic`, `ViewThatFits`, `ButtonFace`, `IDElement`, `AnimationDemo`, `.render`, `AlignmentKey`, `ListDemo`, `.setButtonStyle`, `StackElement`, `Table`, `LabeledContent`, `Demo`, `VStack`, `TextDemo`, `ClipRect`, `LayoutSubviews`, `TableRowHighlight`, `BorderElement`, `OverlayElement`, `UIContext`, `Picker`, `Frame`, `VectorCanvas`, `.draw`, `.system`, `Alignment`, `HotReload`, `Text`, `LazyGridElement`, `assertSnapshot`, `TransitionState`, `LazyStack`, `HittableView`, `float2`, `Rectangle`, `Void`, `VList`, `Axis`, `TransitionElement`, `float2`, `FormControl`, `ProposedSize`?**
  _High betweenness centrality (0.194) - this node is a cross-community bridge._
- **Why does `Int` connect `Int` to `UIElementWrapping`, `Input`, `Text`, `Float`, `DragAndDropTests`, `UIHarness`, `MathLib.swift`, `UIAnimation`, `IMView`, `Grid`, `ColorPicker`, `VectorShape`, `Weight`, `WindowState`, `DragDropDemo`, `Inset`, `LayoutDemo`, `VectorBaker`, `Graphics2D`, `Naming`, `ImageManager`, `HittableGrid2D`, `AnimationDemo`, `Table`, `ListDemo`, `StackElement`, `uidrive/main.swift`, `Array`, `PointerHandlers`, `LayoutSubviews`, `UIContext`, `Picker`, `SparseSet`, `UIElement`, `.system`, `Alignment`, `HotReload`, `Text`, `LazyGridElement`, `assertSnapshot`, `LazyStack`, `HittableView`, `GraphicsGrid2D`, `Utils.swift`, `Void`, `VList`, `TextEnvironment`, `SDFBaker.swift`, `TextStyleElement`, `float2`, `TextLayout.swift`, `ProposedSize`, `String`, `StepIterator`, `SDFPathBuilder`, `FlexFrame`, `DragGesture`, `DatePicker`, `TextTests`, `TextField`, `Path`, `FieldBox`, `BodyParser`, `.endFrame`, `ConditionalDemo`, `ZStack`, `Animator`, `MultiChildElement`, `.body`, `Foundation`, `HList`, `Kind`, `TableColumnWidth`, `View`, `.render`, `AlignmentKey`, `.readExactly`, `int2`, `.removeRow`, `TextDemo`?**
  _High betweenness centrality (0.184) - this node is a cross-community bridge._
- **Are the 6 inferred relationships involving `UIContext` (e.g. with `Effects and transitions` and `HittableGrid2D`) actually correct?**
  _`UIContext` has 6 INFERRED edges - model-reasoned connections that need verification._
- **Are the 23 inferred relationships involving `UIElement` (e.g. with `7. Diagnostics` and `What needs a relaunch`) actually correct?**
  _`UIElement` has 23 INFERRED edges - model-reasoned connections that need verification._
- **What connects `conditional`, `list`, `text` to the rest of the system?**
  _594 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Input` be split into smaller, more focused modules?**
  _Cohesion score 0.09885057471264368 - nodes in this community are weakly interconnected._