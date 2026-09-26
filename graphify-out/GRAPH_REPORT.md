# Graph Report - MetalGraphics  (2026-09-26)

## Corpus Check
- 231 files · ~177,377 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 16 file(s) not represented in the graph (top: (none) 4, .plist 3, .resolved 2)

## Summary
- 3855 nodes · 10283 edges · 178 communities (165 shown, 13 thin omitted)
- Extraction: 90% EXTRACTED · 10% INFERRED · 0% AMBIGUOUS · INFERRED: 1003 edges (avg confidence: 0.84)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `bd52fb10`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- UIElementWrapping
- Input
- Text
- .body
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
- Axis
- ColorPicker
- VectorShape
- .system
- WindowState
- Float
- BodyParser
- View
- UIShape
- ScrollView
- ViewRenderer
- KeyPress
- SDF.metal
- Padding
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
- BitmapTexture
- Rect
- Hittable
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
- Toggle
- Glass
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
- Slider
- VectorCanvas
- BoundingBox2D
- UIElement
- .draw
- Divider
- ScrollRow
- AlignmentKey
- Performance in MetalGraphics
- MetalKit
- SVGIcon
- MouseOver
- HotReload
- simd
- VectorItem
- Graphics2D.swift
- ImageManager
- IMView
- assertSnapshot
- ReactiveUIDiagnostic
- float3
- VectorItem
- LazyStack
- Form
- .content
- GraphicsGrid2D
- Plugin.swift
- Rectangle
- SVGPathCommand
- Image
- Void
- LazyGridElement
- uchar4
- Drag
- SDFBaker.swift
- SIMD2
- PathBuilder
- ViewThatFits
- .expansion
- 1. The pieces
- ListRows
- VStack
- HittableView
- Animator
- Interpolation
- ProposedSize
- Write a test
- SwiftSyntaxMacros
- oracle.swift
- Line
- ModifierSpec
- .mapViewToGrid
- SDFPathBuilder
- FlexFrame
- Square
- AnimationMacroTests
- DatePicker
- VList
- TextField
- Path
- LayoutMacroTests
- GameController
- Rules
- Section
- AnimationGroup
- Stepper
- GridCell
- GlassPass
- Circle2D
- ConditionalDemo
- FileWatcher
- StateMacroTests
- float2x2
- ContentMode
- ZStack
- Content
- MultiChildElement
- Padding
- View
- TemplateRenderingMode
- .init
- ComponentMacroTests
- KeyboardDemo
- ListMacroTests
- Line
- expand
- Foundation
- Spacer
- FormControl
- Shape
- Button
- Phases
- .readExactly
- IMGameView
- 9. Animation
- .setLayout

## God Nodes (most connected - your core abstractions)
1. `UIContext` - 338 edges
2. `UIElement` - 261 edges
3. `UIAnimation` - 195 edges
4. `ProposedSize` - 164 edges
5. `Graphics2D` - 119 edges
6. `simd` - 82 edges
7. `Inset` - 64 edges
8. `SingleChildElement` - 61 edges
9. `Input` - 59 edges
10. `SIMD2` - 57 edges

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

## Communities (178 total, 13 thin omitted)

### Community 0 - "UIElementWrapping"
Cohesion: 0.11
Nodes (11): AnyObject, Bool, Float, float2, float4, HorizontalAlignment, Self, VerticalAlignment (+3 more)

### Community 1 - "Input"
Cohesion: 0.11
Nodes (13): Input, .mouseDown, .mouseMoved, .mousePressed, .mouseUp, Bool, Double, NSEvent (+5 more)

### Community 2 - "Text"
Cohesion: 0.07
Nodes (35): CGGlyph, CoreText, CTFont, FontManager, GlyphKey, GlyphMetrics, SDFFont, Float (+27 more)

### Community 3 - ".body"
Cohesion: 0.13
Nodes (15): AudioSettings, FormDemo, .body, Bool, Date, Double, float4, Theme (+7 more)

### Community 4 - "IMView"
Cohesion: 0.23
Nodes (9): ExpandedFrame, FlexFrame, Frame, IMView, Alignment, Float, float2, Self (+1 more)

### Community 5 - "DiagnosticsTests"
Cohesion: 0.25
Nodes (3): component(), DiagnosticsTests, stubsOnly()

### Community 6 - "UIHarness"
Cohesion: 0.13
Nodes (13): ButtonTests, float2, InteractionTests, Bool, Float, float2, MTLTexture, NSEvent (+5 more)

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
Cohesion: 0.14
Nodes (16): CodeGen, .armedHandlers, Dependents, RowsMode, full, insert, remove, Bool (+8 more)

### Community 11 - "SingleChildElement"
Cohesion: 0.16
Nodes (5): EmptyElement, SingleChildElement, Float, float2, Void

### Community 12 - "GlyphSDF.metal"
Cohesion: 0.08
Nodes (35): What needs a relaunch, bakeSDF(), lineWinding(), constant, float2, kernel, texture2d, uint (+27 more)

### Community 13 - "MathLib.swift"
Cohesion: 0.18
Nodes (17): int3, dragDirection(), from1DTo3DArray(), from2DTo1DArray(), from3DTo1DArray(), fromPixelCoordToGridIndex(), fromWorldPositionToGridIndex(), lerp() (+9 more)

### Community 14 - "UIAnimation"
Cohesion: 0.07
Nodes (14): UIAnimation, FlexFrame, Frame, HStack, Alignment, Float, float2, float4 (+6 more)

### Community 15 - "IMView"
Cohesion: 0.12
Nodes (17): ExpandedFrame, IMView, Background, FlexFrame, Float, float2, Frame, HStack (+9 more)

### Community 16 - "MyMTKView"
Cohesion: 0.17
Nodes (8): Modifier, MyMTKView, .acceptsFirstResponder, Bool, NSEvent, UInt, UInt16, MTKView

### Community 17 - "Alignment"
Cohesion: 0.27
Nodes (8): Alignment, .offset, HorizontalAlignment, IMView, Float, float2, Self, VerticalAlignment

### Community 18 - "Axis"
Cohesion: 0.07
Nodes (27): ExpressibleByArrayLiteral, FlexFrame, Axis, .inverted, .size, IMView, Float, float2 (+19 more)

### Community 19 - "ColorPicker"
Cohesion: 0.19
Nodes (12): ColorPicker, ColorSwatch, ColorWell, drawCheckerboard(), hsbFromRGB(), rgbFromHSB(), Bool, Float (+4 more)

### Community 20 - "VectorShape"
Cohesion: 0.09
Nodes (26): Text styling, Capsule, Circle, .length, .localBounds, Ellipse, .length, .localBounds (+18 more)

### Community 21 - ".system"
Cohesion: 0.17
Nodes (12): ContainersDemo, .body, Alignment, Bool, Float, GridsDemo, .body, Bool (+4 more)

### Community 22 - "WindowState"
Cohesion: 0.15
Nodes (13): CaseIterable, Application, Event, Inspector, Navigation, Global, Reload, Bool (+5 more)

### Community 23 - "Float"
Cohesion: 0.14
Nodes (10): ImageQuad, GlassItem, GlassPass, GPUClip, Float, float2, float4, Int32 (+2 more)

### Community 24 - "BodyParser"
Cohesion: 0.16
Nodes (11): CodeBlockItemListSyntax, IfExprSyntax, BodyParser, Bool, ClosureExprSyntax, ExprSyntax, FunctionCallExprSyntax, MemberBlockItemListSyntax (+3 more)

### Community 25 - "View"
Cohesion: 0.09
Nodes (23): .inspectorView, Inspector, .body, Navigation, .body, ToggleView, .body, Number2Field (+15 more)

### Community 26 - "UIShape"
Cohesion: 0.06
Nodes (24): Background, GlassBackground, GlassMaterial, Float, float2, float4, BorderElement, .color (+16 more)

### Community 27 - "ScrollView"
Cohesion: 0.08
Nodes (18): Bool, FormMetrics, ScrollIndicator, .visibility, ScrollIndicatorVisibility, automatic, hidden, never (+10 more)

### Community 28 - "ViewRenderer"
Cohesion: 0.12
Nodes (15): .body, MetalView, .body, CGSize, Double, Float, float2, MTKView (+7 more)

### Community 29 - "KeyPress"
Cohesion: 0.29
Nodes (8): CharacterSet, ExpressibleByExtendedGraphemeClusterLiteral, KeyEquivalent, KeyPress, KeyPressElement, Character, NSEvent, UIElementWrapping

### Community 30 - "SDF.metal"
Cohesion: 0.12
Nodes (7): metal_stdlib, dot2(), float4, sdBoxSquared(), sdCircleSquared(), sdRoundedBoxSquared(), sdTriangle()

### Community 31 - "Padding"
Cohesion: 0.23
Nodes (4): Padding, Float, float2, float2

### Community 32 - "Sendable"
Cohesion: 0.05
Nodes (32): Any, Float, Void, TransitionElement, .currentState, Curve, easeIn, easeInOut (+24 more)

### Community 33 - "Inset"
Cohesion: 0.12
Nodes (14): .body, .body, Float, TextDemo, .body, .packed, Padding, Edge (+6 more)

### Community 34 - "Set"
Cohesion: 0.11
Nodes (26): Set, UInt8, Owner, component, node, AnimationScope, Attach, arity (+18 more)

### Community 35 - "EffectElement"
Cohesion: 0.16
Nodes (11): BlurElement, EffectElement, .hasEffect, .localEffect, ShadowState, .margin, Bool, Float (+3 more)

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
Cohesion: 0.08
Nodes (24): How it works (when the harness itself needs changing), CustomStringConvertible, Error, Glyph, Line, Graphics2D, .glassAtlasWidth, .size (+16 more)

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
Cohesion: 0.14
Nodes (34): Effects and transitions, float2, sdBox(), sdCircle(), sdOrientedBox(), sdRoundedBox(), sdSegment(), backdrop2D() (+26 more)

### Community 44 - ".expansion"
Cohesion: 0.09
Nodes (22): DeclGroupSyntax, ExtensionDeclSyntax, ExtensionMacro, MemberMacro, PatternBindingSyntax, .states, TypeSyntax, .arrayStates (+14 more)

### Community 45 - "String"
Cohesion: 0.12
Nodes (5): String, .uint32, UInt32, FunctionCallExprSyntax, Naming

### Community 46 - "SceneData"
Cohesion: 0.29
Nodes (7): DebugData, drawGrid, showFilledCells, SceneData, debug, time, windowSize

### Community 47 - "BitmapTexture"
Cohesion: 0.23
Nodes (9): CGContext, BitmapTexture, Bundle, CGImage, Float, float2, MTLTexture, NSImage (+1 more)

### Community 48 - "Rect"
Cohesion: 0.16
Nodes (10): Rect, .center, .height, .maxX, .maxY, .minX, .minY, .width (+2 more)

### Community 49 - "Hittable"
Cohesion: 0.05
Nodes (37): DispatchWorkItem, HittableGrid2D, HittableGridCell, HoveredView, Bool, Float, float2, ObjectIdentifier (+29 more)

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
Cohesion: 0.18
Nodes (8): Bool, float2, KeyPathComparator, T, Text, Void, Table, .clipRect

### Community 55 - "ListDemo"
Cohesion: 0.24
Nodes (10): ChipView, DemoItem, ListDemo, .body, RowView, Bool, Float, float4 (+2 more)

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
Cohesion: 0.05
Nodes (34): graphify, Hot reload, Performance, 1. Build and launch, 2. Compile the driver, 3. Drive and look, Driving GPURayMarching, Notes (+26 more)

### Community 62 - "float4x4"
Cohesion: 0.14
Nodes (12): matrix_double4x4, float3x3, Float, float4x4, .formated, .identity, .upperLeft, Bool (+4 more)

### Community 63 - "Array"
Cohesion: 0.33
Nodes (4): Array, .byteCount, Element, Void

### Community 64 - "Toggle"
Cohesion: 0.26
Nodes (7): Bool, Float, float2, Text, Void, Toggle, ToggleSwitch

### Community 65 - "Glass"
Cohesion: 0.07
Nodes (27): Circle, color, depth, position, radius, Clip, blur, bounds (+19 more)

### Community 66 - "GeometryChangeElement"
Cohesion: 0.14
Nodes (11): CoordinateSpace, global, local, GeometryChangeElement, GeometryProxy, GeometryReader, Float, float2 (+3 more)

### Community 67 - "Comparable Clamp"
Cohesion: 0.40
Nodes (3): Comparable, ClosedRange, Self

### Community 68 - "LayoutSubviews"
Cohesion: 0.08
Nodes (25): Cache, AnyLayout, AnyLayoutBox, HStackLayout, Layout, LayoutBox, LayoutSubview, .priority (+17 more)

### Community 73 - "UIElement+ReactiveSetters.swift"
Cohesion: 0.18
Nodes (7): Sliding layout, Background, Circle, ExpandedFrame, Padding, Spacer, Text

### Community 74 - "OverlayElement"
Cohesion: 0.14
Nodes (10): Alignment, Background, FlexFrame, Frame, OverlayElement, .alignment, Alignment, Bool (+2 more)

### Community 75 - "UIContext"
Cohesion: 0.05
Nodes (9): Float, float4, ObjectIdentifier, UIContext, LayoutPass, UInt32, Void, Void (+1 more)

### Community 76 - "Picker"
Cohesion: 0.09
Nodes (22): Kind, check, menuItem, segment, Picker, .selectedTitle, PickerMark, PickerStyle (+14 more)

### Community 77 - "Frame"
Cohesion: 0.26
Nodes (6): Frame, .size, Alignment, Float, float2, Void

### Community 78 - "Int"
Cohesion: 0.09
Nodes (21): AnyIterator, StressCell, .body, StressIndex, StressRow, .body, Bool, VectorDemo (+13 more)

### Community 79 - "Square"
Cohesion: 0.29
Nodes (5): Square, .bounds, Float, float2, float4

### Community 80 - "IMView"
Cohesion: 0.23
Nodes (10): HStack, .size, IMView, Float, HorizontalAlignment, Self, VerticalAlignment, Void (+2 more)

### Community 81 - "Slider"
Cohesion: 0.15
Nodes (14): ProgressView, .fraction, Slider, SliderTrack, ClosedRange, Double, Float, float2 (+6 more)

### Community 82 - "VectorCanvas"
Cohesion: 0.24
Nodes (6): Float, float2, Self, VectorCanvas, .children, VectorShapeList

### Community 83 - "BoundingBox2D"
Cohesion: 0.17
Nodes (12): BoundingBox2D, .bottom, .bottomRight, .height, .left, .right, .top, .topLeft (+4 more)

### Community 84 - "UIElement"
Cohesion: 0.06
Nodes (28): LayoutTraits, Alignment, AnyHashable, Float, float2, float4, Void, UIElement (+20 more)

### Community 85 - ".draw"
Cohesion: 0.17
Nodes (6): Equatable, EffectState, ClipRect, .isEmpty, float4, .scrollableSize

### Community 86 - "Divider"
Cohesion: 0.27
Nodes (4): Divider, Float, float2, float4

### Community 87 - "ScrollRow"
Cohesion: 0.21
Nodes (10): LazyRowCounter, ScrollDemo, ScrollRow, .name, ScrollRowView, .body, Bool, float4 (+2 more)

### Community 88 - "AlignmentKey"
Cohesion: 0.08
Nodes (30): Hasher, Alignment, .offset, .xOffset, .yOffset, AlignmentID, AlignmentKey, .isFraction (+22 more)

### Community 89 - "Performance in MetalGraphics"
Cohesion: 0.25
Nodes (7): 2. Invalidation — name the narrowest effect, 4. GPU and Metal (`Graphics2D.swift`, `Shaders/Shaders.metal`), 5. Layout and text, 6. Lists and scrolling, 7. Measure, don't guess, 8. Before finishing, Performance in MetalGraphics

### Community 90 - "MetalKit"
Cohesion: 0.19
Nodes (8): App, Combine, ContentView, GPURayMarchingApp, .body, MetalKit, Scene, SwiftUI

### Community 91 - "SVGIcon"
Cohesion: 0.18
Nodes (10): Layer, SVGIcon, Bool, Bundle, Data, Float, float2, float4 (+2 more)

### Community 92 - "MouseOver"
Cohesion: 0.35
Nodes (6): IMView, MouseOver, Bool, Float, Self, Void

### Community 93 - "HotReload"
Cohesion: 0.09
Nodes (16): Duration, Hot reload, How it fits the frame loop, Quirks, HotReload, Bool, Date, Int32 (+8 more)

### Community 94 - "simd"
Cohesion: 0.14
Nodes (10): AppKit, GlassDemo, .body, Bool, Metal, MetalGraphicsLib, QuartzCore, ReactiveUI (+2 more)

### Community 95 - "VectorItem"
Cohesion: 0.19
Nodes (12): Kind, bakedFill, bakedStroke, ellipse, roundedBox, Float, float2, VectorItem (+4 more)

### Community 96 - "Graphics2D.swift"
Cohesion: 0.40
Nodes (5): DebugData, SceneData, ShapeArgBuffer, Bool, UInt64

### Community 97 - "ImageManager"
Cohesion: 0.20
Nodes (9): ImageManager, ImageQuad, .bounds, PendingUpload, CGFloat, MTLBuffer, MTLCommandBuffer, MTLDevice (+1 more)

### Community 98 - "IMView"
Cohesion: 0.39
Nodes (4): IMView, Spacer, Float, Void

### Community 99 - "assertSnapshot"
Cohesion: 0.23
Nodes (15): ImageIO, assertSnapshot(), failureURL(), loadPNG(), rgba(), rgbaImage(), CGImage, Double (+7 more)

### Community 100 - "ReactiveUIDiagnostic"
Cohesion: 0.24
Nodes (7): DiagnosticMessage, DiagnosticSeverity, FixItMessage, MessageID, ReactiveUIDiagnostic, ReactiveUIFixIt, SwiftDiagnostics

### Community 101 - "float3"
Cohesion: 0.14
Nodes (11): float3, .depth, .height, .width, .xy, Float, float2, float4 (+3 more)

### Community 102 - "VectorItem"
Cohesion: 0.09
Nodes (23): ImageQuad, depth, flags, lod, position, size, textureIndex, tint (+15 more)

### Community 103 - "LazyStack"
Cohesion: 0.11
Nodes (21): LazyHStack, .crossAlignment, LazyStack, .crossAlignment, .defaultLength, .estimatedLength, .initialExtent, .overscan (+13 more)

### Community 104 - "Form"
Cohesion: 0.27
Nodes (5): Form, Bool, ObjectIdentifier, Void, VStack

### Community 105 - ".content"
Cohesion: 0.14
Nodes (11): .content, AspectRatioElement, ClipElement, .clipCornerRadii, .clipRect, FixedSizeElement, PositionElement, Bool (+3 more)

### Community 106 - "GraphicsGrid2D"
Cohesion: 0.12
Nodes (19): Int32, GPUDevice, MTLDevice, GraphicsGrid2D, GridArgBuffer, GridCell, Shape, ShapeType2D (+11 more)

### Community 107 - "Plugin.swift"
Cohesion: 0.29
Nodes (5): CompilerPlugin, PluginMain, ReactiveUIMacrosPlugin, Macro, SwiftCompilerPlugin

### Community 108 - "Rectangle"
Cohesion: 0.19
Nodes (4): Rectangle, Float, float2, LayoutTests

### Community 109 - "SVGPathCommand"
Cohesion: 0.12
Nodes (16): SVGPathCommand, close, cubic, line, move, quad, SVGPathData, SVGScanner (+8 more)

### Community 110 - "Image"
Cohesion: 0.23
Nodes (6): Image, .naturalSize, Float, float2, float4, Self

### Community 111 - "Void"
Cohesion: 0.08
Nodes (19): 1. The frame, 3. Hot paths — per frame, or per element per frame, 8. How it lands on screen, ShadowElement, Invalidation, Bool, Double, float2 (+11 more)

### Community 112 - "LazyGridElement"
Cohesion: 0.14
Nodes (20): GridItem, LazyGridElement, .defaultCellAlignment, .trackAlignment, LazyHGrid, .defaultCellAlignment, .trackAlignment, LazyVGrid (+12 more)

### Community 113 - "uchar4"
Cohesion: 0.29
Nodes (6): UInt8, uchar4, .a, .b, .g, .r

### Community 114 - "Drag"
Cohesion: 0.24
Nodes (5): Drag, .description, Float, float2, Void

### Community 115 - "SDFBaker.swift"
Cohesion: 0.14
Nodes (21): PendingBake, SDFAtlas, SDFBakeParams, SDFBaker, SDFRegion, SDFShape, SDFShapeGeometry, SDFShapeMode (+13 more)

### Community 116 - "SIMD2"
Cohesion: 0.31
Nodes (8): Float, .packed, SIMD2, .packed, SIMD4, .packed, Float, UIAnimatable

### Community 117 - "PathBuilder"
Cohesion: 0.17
Nodes (10): PathBuilder, PathMorph, Bool, Double, Float, float2, VectorSegment, VectorGeometry (+2 more)

### Community 118 - "ViewThatFits"
Cohesion: 0.26
Nodes (4): Float, float2, Void, ViewThatFits

### Community 119 - ".expansion"
Cohesion: 0.09
Nodes (15): AccessorDeclSyntax, AccessorMacro, DeclReferenceExprSyntax, DeclSyntaxProtocol, MemberAccessExprSyntax, PeerMacro, StateRewriter, ClosureExprSyntax (+7 more)

### Community 120 - "1. The pieces"
Cohesion: 0.29
Nodes (6): 1. The pieces, 2. What a component looks like, 3. What gets generated, 4. Rules that follow, 6. Composition, not helper methods, Compile-time state in RetainedModeUI

### Community 121 - "ListRows"
Cohesion: 0.22
Nodes (7): Float, VerticalAlignment, ListRows, T, Void, Float, HorizontalAlignment

### Community 122 - "VStack"
Cohesion: 0.33
Nodes (4): Float, HorizontalAlignment, VStack, .crossKey

### Community 123 - "HittableView"
Cohesion: 0.05
Nodes (32): Background, KeyPath, MainActor, HittableView, .hitPosition, .hitSize, Bool, Float (+24 more)

### Community 124 - "Animator"
Cohesion: 0.25
Nodes (11): Apply, Animator, .isIdle, Key, Running, Bool, Double, Float (+3 more)

### Community 125 - "Interpolation"
Cohesion: 0.33
Nodes (5): Interpolation, high, low, medium, none

### Community 126 - "ProposedSize"
Cohesion: 0.19
Nodes (8): MeasureCache, ProposedSize, Float, float2, UInt32, UInt8, Diagonal, Void

### Community 127 - "Write a test"
Cohesion: 0.12
Nodes (12): Headless UI tests, Run, Snapshots, When to launch the app instead (drive-app skill), Write a test, Float, float2, MTLTexture (+4 more)

### Community 128 - "SwiftSyntaxMacros"
Cohesion: 0.42
Nodes (5): ReactiveUIMacrosPlugin, SwiftSyntaxMacroExpansion, SwiftSyntaxMacros, SwiftSyntaxMacrosGenericTestSupport, Testing

### Community 129 - "oracle.swift"
Cohesion: 0.29
Nodes (6): Probe, .body, render(), CGSize, V, View

### Community 130 - "Line"
Cohesion: 0.33
Nodes (6): Line, color, depth, end, start, thickness

### Community 131 - "ModifierSpec"
Cohesion: 0.18
Nodes (15): ArgCombine, construct, float2, identity, labeled, ArgSpec, Arity, leaf (+7 more)

### Community 132 - ".mapViewToGrid"
Cohesion: 0.20
Nodes (6): IteratorProtocol, StepIterator, StepSequence, Bool, Float, Sequence

### Community 133 - "SDFPathBuilder"
Cohesion: 0.21
Nodes (12): CGPath, PathElement, SDFPathBuilder, .isEmpty, Bool, float2, UInt8, CGRect (+4 more)

### Community 134 - "FlexFrame"
Cohesion: 0.30
Nodes (4): FlexFrame, Alignment, Float, float2

### Community 135 - "Square"
Cohesion: 0.33
Nodes (6): Square, color, depth, position, rotation, size

### Community 137 - "DatePicker"
Cohesion: 0.10
Nodes (15): CalendarView, Components, DatePicker, DatePickerStyle, compact, graphical, DayCell, Bool (+7 more)

### Community 138 - "VList"
Cohesion: 0.14
Nodes (11): makeScrollToDemo(), .body, .body, HStack, 7. Diagnostics, HList, T, Void (+3 more)

### Community 139 - "TextField"
Cohesion: 0.07
Nodes (30): Member, 5. Collections are just `@State` arrays, Bindings are lowered, not passed, Mutation carries the operation, Named content closures, The plain setter still works, Binding, .wrappedValue (+22 more)

### Community 140 - "Path"
Cohesion: 0.14
Nodes (16): Path, .isClosed, .length, .localBounds, Source, builder, commands, Bool (+8 more)

### Community 143 - "Rules"
Cohesion: 0.24
Nodes (5): Rules, AnimationTests, SnapshotTests, Double, XCTestCase

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
Nodes (5): GridCell, count, startIndex, isBetween(), thread

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
Cohesion: 0.22
Nodes (7): CoreServices, FSEventStreamRef, FileWatcher, ArraySlice, DispatchQueue, URL, Void

### Community 154 - "ContentMode"
Cohesion: 0.50
Nodes (3): ContentMode, fill, fit

### Community 155 - "ZStack"
Cohesion: 0.23
Nodes (6): Alignment, Bool, Float, float2, Void, ZStack

### Community 156 - "Content"
Cohesion: 0.50
Nodes (4): Content, bitmap, missing, svg

### Community 157 - "MultiChildElement"
Cohesion: 0.24
Nodes (4): MultiChildElement, .liveChildrenCount, float2, Void

### Community 158 - "Padding"
Cohesion: 0.31
Nodes (5): IMView, Padding, Float, Self, Void

### Community 159 - "View"
Cohesion: 0.18
Nodes (11): Bool, View, Background, ExpandedFrame, FlexFrame, HStack, .isSpacer, MouseOver (+3 more)

### Community 160 - "TemplateRenderingMode"
Cohesion: 0.50
Nodes (3): TemplateRenderingMode, original, template

### Community 161 - ".init"
Cohesion: 0.25
Nodes (7): DisclosureChevron, DisclosureGroup, Bool, Float, float2, Text, Void

### Community 163 - "KeyboardDemo"
Cohesion: 0.38
Nodes (5): KeyboardDemo, .body, Bool, Float, float2

### Community 167 - "Line"
Cohesion: 0.29
Nodes (5): Line, .bounds, Float, float2, float4

### Community 170 - "expand"
Cohesion: 0.26
Nodes (5): BindingMacroTests, component(), expand(), NamedContentTests, SwiftParser

### Community 171 - "Foundation"
Cohesion: 0.14
Nodes (9): Foundation, Person, float4, KeyPathComparator, TableDemo, .body, benchmark(), Bool (+1 more)

### Community 172 - "Spacer"
Cohesion: 0.31
Nodes (4): LeafElement, Spacer, Float, float2

### Community 173 - "FormControl"
Cohesion: 0.10
Nodes (12): FormControl, .isInteracting, FormGraphic, mix(), Bool, Float, float2, float4 (+4 more)

### Community 175 - "Shape"
Cohesion: 0.40
Nodes (5): Shape, clip, depth, index, shapeType

### Community 176 - "Button"
Cohesion: 0.09
Nodes (23): Button, .labelColor, ButtonFace, .inset, ButtonRole, cancel, destructive, ButtonStyle (+15 more)

### Community 183 - "Phases"
Cohesion: 0.67
Nodes (3): Phases, UInt8, OptionSet

### Community 185 - ".readExactly"
Cohesion: 0.39
Nodes (4): StdinFilter, Bool, Int32, UInt8

### Community 188 - "IMGameView"
Cohesion: 0.33
Nodes (3): IMView, IMGameView, float4

### Community 189 - "9. Animation"
Cohesion: 0.47
Nodes (5): 9. Animation, Costs to know, Repeat and keyframes, Scopes, The runtime

## Knowledge Gaps
- **494 isolated node(s):** `conditional`, `list`, `text`, `layout`, `image` (+489 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 970 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **13 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `String` connect `String` to `Input`, `Text`, `.body`, `IMView`, `DiagnosticsTests`, `UIHarness`, `ViewItem`, `CodeGen`, `SingleChildElement`, `UIAnimation`, `IMView`, `ColorPicker`, `.system`, `WindowState`, `BodyParser`, `View`, `UIShape`, `KeyPress`, `Padding`, `Inset`, `Set`, `LayoutDemo`, `SVGParser`, `Graphics2D`, `.expansion`, `BitmapTexture`, `Hittable`, `HStack`, `IDElement`, `AnimationDemo`, `Table`, `ListDemo`, `uidrive/main.swift`, `Demo`, `float4x4`, `Toggle`, `OverlayElement`, `UIContext`, `Picker`, `Frame`, `IMView`, `Slider`, `VectorCanvas`, `UIElement`, `.draw`, `ScrollRow`, `SVGIcon`, `MouseOver`, `HotReload`, `ImageManager`, `IMView`, `assertSnapshot`, `ReactiveUIDiagnostic`, `Rectangle`, `SVGPathCommand`, `Image`, `Drag`, `SDFBaker.swift`, `.expansion`, `VStack`, `HittableView`, `oracle.swift`, `ModifierSpec`, `FlexFrame`, `AnimationMacroTests`, `DatePicker`, `TextField`, `Path`, `Section`, `Stepper`, `ConditionalDemo`, `FileWatcher`, `ZStack`, `MultiChildElement`, `Padding`, `.init`, `KeyboardDemo`, `expand`, `Foundation`, `Button`?**
  _High betweenness centrality (0.243) - this node is a cross-community bridge._
- **Why does `UIContext` connect `UIContext` to `UIHarness`, `DatePicker`, `VList`, `TextField`, `UIAnimation`, `AnimationGroup`, `Stepper`, `ColorPicker`, `UIShape`, `ScrollView`, `ViewRenderer`, `KeyPress`, `MultiChildElement`, `Sendable`, `.init`, `EffectElement`, `VectorBaker`, `Graphics2D`, `Shaders/Shaders.metal`, `FormControl`, `Button`, `Hittable`, `IDElement`, `AnimationDemo`, `Table`, `Toggle`, `GeometryChangeElement`, `.setLayout`, `UIElement+ReactiveSetters.swift`, `Picker`, `Int`, `Slider`, `UIElement`, `.draw`, `Divider`, `simd`, `LazyStack`, `Form`, `Void`, `ViewThatFits`, `ListRows`, `Animator`?**
  _High betweenness centrality (0.210) - this node is a cross-community bridge._
- **Why does `UIElement` connect `UIElement` to `UIElementWrapping`, `.body`, `FlexFrame`, `UIHarness`, `VList`, `SingleChildElement`, `GlyphSDF.metal`, `UIAnimation`, `Rules`, `Section`, `Axis`, `VectorShape`, `.system`, `ConditionalDemo`, `UIShape`, `ScrollView`, `ZStack`, `MultiChildElement`, `KeyPress`, `Padding`, `Sendable`, `Inset`, `.init`, `KeyboardDemo`, `LayoutDemo`, `EffectElement`, `Foundation`, `Spacer`, `FormControl`, `Button`, `Hittable`, `HStack`, `IDElement`, `AnimationDemo`, `ListDemo`, `StackElement`, `Demo`, `GeometryChangeElement`, `LayoutSubviews`, `UIElement+ReactiveSetters.swift`, `OverlayElement`, `UIContext`, `Picker`, `Frame`, `Int`, `VectorCanvas`, `.draw`, `ScrollRow`, `AlignmentKey`, `simd`, `LazyStack`, `Form`, `.content`, `Rectangle`, `Void`, `LazyGridElement`, `ViewThatFits`, `ListRows`, `VStack`, `HittableView`, `Animator`, `ProposedSize`?**
  _High betweenness centrality (0.181) - this node is a cross-community bridge._
- **Are the 5 inferred relationships involving `UIContext` (e.g. with `Effects and transitions` and `HittableGrid2D`) actually correct?**
  _`UIContext` has 5 INFERRED edges - model-reasoned connections that need verification._
- **Are the 23 inferred relationships involving `UIElement` (e.g. with `7. Diagnostics` and `What needs a relaunch`) actually correct?**
  _`UIElement` has 23 INFERRED edges - model-reasoned connections that need verification._
- **What connects `conditional`, `list`, `text` to the rest of the system?**
  _494 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `UIElementWrapping` be split into smaller, more focused modules?**
  _Cohesion score 0.1051693404634581 - nodes in this community are weakly interconnected._