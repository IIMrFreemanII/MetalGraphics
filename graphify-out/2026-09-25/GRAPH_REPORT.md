# Graph Report - MetalGraphics  (2026-09-25)

## Corpus Check
- 221 files · ~168,483 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 15 file(s) not represented in the graph (top: (none) 4, .plist 3, .resolved 2)

## Summary
- 3690 nodes · 9785 edges · 189 communities (173 shown, 16 thin omitted)
- Extraction: 91% EXTRACTED · 9% INFERRED · 0% AMBIGUOUS · INFERRED: 851 edges (avg confidence: 0.83)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `fa00f9f7`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- UIElementWrapping
- Input
- Text
- .system
- IMView
- DiagnosticsTests
- ClipRect
- AnimatedProperty
- GPURayMarching/Shaders.metal
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
- ColorPicker
- VectorShape
- LayoutSubviews
- WindowState
- Float
- String
- View
- BorderElement
- ScrollView
- ViewRenderer
- KeyPress
- SDF.metal
- Set
- Float
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
- .expansion
- NumberField
- SceneData
- ImageManager
- Rect
- PopoverLayer
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
- Driving GPURayMarching
- float4
- GeometryChangeElement
- Comparable Clamp
- .draw
- Macro Package Manifest
- Line
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
- .texture
- Divider
- ScrollRow
- Sendable
- Performance in MetalGraphics
- KeyboardDemo
- SVGIcon
- MouseOver
- HotReload
- MetalGraphicsLib
- VectorItem
- Graphics2D.swift
- HList
- IMView
- Background
- Interpolation
- float3
- VectorItem
- LazyStack
- HittableView
- ProposedSize
- GraphicsGrid2D
- Utils.swift
- Rectangle
- SVGScanner
- Image
- Void
- LazyGridElement
- uchar4
- Padding
- SDFBaker.swift
- post
- PathBuilder
- Demos
- .expansion
- layoutText
- MultiChildElement
- Content
- float2
- ImageQuad
- SDFFont
- MetalKit
- simd
- SwiftSyntaxMacros
- oracle.swift
- Drag
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
- Void
- Plugin.swift
- Section
- SVGPathCommand
- Stepper
- GridCell
- GlassPass
- .beginFrame
- float2
- FormGraphic
- .body
- ViewThatFits
- TableColumn
- ZStack
- TableDemo
- .append
- Shape
- View
- Form
- .init
- ComponentMacroTests
- Toggle
- int2
- TableColumnDivider
- layoutchecks/main.swift
- UIShape
- Binding
- ShapeType2D
- expand
- Foundation
- Kind
- FormControl
- Hot reload
- ListRows
- Button
- TableColumnWidth
- ConditionalDemo
- 1. The pieces
- TextDemo
- ListMacroTests
- StateMacroTests
- Phases
- TemplateRenderingMode
- .subscript
- Mid
- Mid
- .hash

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
- `3. Drive and look` --references--> `click()`  [INFERRED]
  .claude/skills/drive-app/SKILL.md → Tools/uidrive/main.swift
- `Hot reload` --references--> `Demos`  [INFERRED]
  MetalGraphicsLib/docs/HotReload.md → GPURayMarching/Demos.swift
- `5. Collections are just `@State` arrays` --references--> `DemoItem`  [INFERRED]
  MetalGraphicsLib/docs/CompileTimeState.md → GPURayMarching/ListDemo.swift

## Import Cycles
- None detected.

## Communities (189 total, 16 thin omitted)

### Community 0 - "UIElementWrapping"
Cohesion: 0.11
Nodes (10): Bool, Float, float2, HorizontalAlignment, Self, V, VerticalAlignment, Void (+2 more)

### Community 1 - "Input"
Cohesion: 0.11
Nodes (13): Input, .mouseDown, .mouseMoved, .mousePressed, .mouseUp, Bool, Double, NSEvent (+5 more)

### Community 2 - "Text"
Cohesion: 0.17
Nodes (9): Float, float2, float4, Self, Text, .displayedColor, .displayedFontSize, .fontScale (+1 more)

### Community 3 - ".system"
Cohesion: 0.11
Nodes (20): ContainersDemo, .body, Alignment, Bool, Float, animation, .body, GlassDemo (+12 more)

### Community 4 - "IMView"
Cohesion: 0.23
Nodes (9): ExpandedFrame, FlexFrame, Frame, IMView, Alignment, Float, float2, Self (+1 more)

### Community 5 - "DiagnosticsTests"
Cohesion: 0.26
Nodes (3): component(), DiagnosticsTests, stubsOnly()

### Community 6 - "ClipRect"
Cohesion: 0.26
Nodes (4): Int32, ClipRect, .isEmpty, Bool

### Community 7 - "AnimatedProperty"
Cohesion: 0.05
Nodes (51): Apply, 9. Animation, Costs to know, Repeat and keyframes, Scopes, Sliding layout, The runtime, `withAnimation` (+43 more)

### Community 8 - "GPURayMarching/Shaders.metal"
Cohesion: 0.08
Nodes (30): Camera, fov, position, rotation, compute(), distanceToScene(), GridArgBuffer, GridItem (+22 more)

### Community 9 - "SIMD2"
Cohesion: 0.19
Nodes (12): Background, IMView, Float, Self, Float, .packed, SIMD2, .packed (+4 more)

### Community 10 - "CodeGen"
Cohesion: 0.11
Nodes (16): CodeGen, .armedHandlers, Dependents, RowsMode, full, insert, remove, Bool (+8 more)

### Community 11 - "SingleChildElement"
Cohesion: 0.15
Nodes (7): SingleChildElement, Float, float2, Void, LabeledContent, HStack, Text

### Community 12 - "GlyphSDF.metal"
Cohesion: 0.09
Nodes (34): bakeSDF(), lineWinding(), constant, float2, kernel, texture2d, uint, uint2 (+26 more)

### Community 13 - "MathLib.swift"
Cohesion: 0.18
Nodes (17): int3, dragDirection(), from1DTo3DArray(), from2DTo1DArray(), from3DTo1DArray(), fromPixelCoordToGridIndex(), fromWorldPositionToGridIndex(), lerp() (+9 more)

### Community 14 - "UIAnimation"
Cohesion: 0.06
Nodes (21): UIAnimation, Background, Circle, ExpandedFrame, FlexFrame, Frame, HStack, Padding (+13 more)

### Community 15 - "IMView"
Cohesion: 0.11
Nodes (20): ExpandedFrame, float4, Void, IMView, Background, FlexFrame, Float, float2 (+12 more)

### Community 16 - "MyMTKView"
Cohesion: 0.18
Nodes (8): Modifier, MyMTKView, .acceptsFirstResponder, Bool, NSEvent, UInt, UInt16, MTKView

### Community 17 - "Alignment"
Cohesion: 0.27
Nodes (8): Alignment, .offset, HorizontalAlignment, IMView, Float, float2, Self, VerticalAlignment

### Community 18 - "Axis"
Cohesion: 0.07
Nodes (27): ExpressibleByArrayLiteral, FlexFrame, Axis, .inverted, .size, IMView, Float, float2 (+19 more)

### Community 19 - "ColorPicker"
Cohesion: 0.20
Nodes (12): ColorPicker, ColorSwatch, ColorWell, drawCheckerboard(), hsbFromRGB(), rgbFromHSB(), Bool, Float (+4 more)

### Community 20 - "VectorShape"
Cohesion: 0.09
Nodes (26): Text styling, Capsule, Circle, .length, .localBounds, Ellipse, .length, .localBounds (+18 more)

### Community 21 - "LayoutSubviews"
Cohesion: 0.08
Nodes (25): Cache, AnyLayout, AnyLayoutBox, HStackLayout, Layout, LayoutBox, LayoutSubview, .priority (+17 more)

### Community 22 - "WindowState"
Cohesion: 0.15
Nodes (13): CaseIterable, Application, Event, Inspector, Navigation, Global, Reload, Bool (+5 more)

### Community 23 - "Float"
Cohesion: 0.20
Nodes (8): ImageQuad, GlassItem, GlassPass, GPUClip, Float, float2, float4, UInt32

### Community 24 - "String"
Cohesion: 0.15
Nodes (4): String, .uint32, UInt32, Naming

### Community 25 - "View"
Cohesion: 0.20
Nodes (10): Inspector, .body, Navigation, .body, ToggleView, .body, Number4Field, .body (+2 more)

### Community 26 - "BorderElement"
Cohesion: 0.16
Nodes (9): BorderElement, .color, .lineWidth, .shape, BorderLayer, Float, float2, float4 (+1 more)

### Community 27 - "ScrollView"
Cohesion: 0.09
Nodes (17): Bool, ScrollIndicator, .visibility, ScrollIndicatorVisibility, automatic, hidden, never, visible (+9 more)

### Community 28 - "ViewRenderer"
Cohesion: 0.14
Nodes (13): MetalView, .body, CGSize, Double, Float, float2, MTKView, View (+5 more)

### Community 29 - "KeyPress"
Cohesion: 0.22
Nodes (11): CharacterSet, ExpressibleByExtendedGraphemeClusterLiteral, KeyEquivalent, KeyPress, KeyPressElement, Result, handled, ignored (+3 more)

### Community 30 - "SDF.metal"
Cohesion: 0.14
Nodes (11): dot2(), float2, float4, sdBoxSquared(), sdCircle(), sdCircleSquared(), sdOrientedBox(), sdRoundedBoxSquared() (+3 more)

### Community 31 - "Set"
Cohesion: 0.11
Nodes (15): DeclReferenceExprSyntax, FSEventStreamRef, MemberAccessExprSyntax, FileWatcher, ArraySlice, DispatchQueue, URL, Void (+7 more)

### Community 32 - "Float"
Cohesion: 0.10
Nodes (19): Any, Curve, easeIn, easeInOut, easeOut, keyframes, linear, spring (+11 more)

### Community 33 - "Inset"
Cohesion: 0.12
Nodes (15): .body, .body, IMView, Padding, Float, Void, .packed, Padding (+7 more)

### Community 34 - "ElementIR"
Cohesion: 0.10
Nodes (29): Owner, component, node, Arity, leaf, multi, single, AnimationScope (+21 more)

### Community 35 - "EffectElement"
Cohesion: 0.17
Nodes (11): BlurElement, EffectElement, .hasEffect, .localEffect, ShadowState, .margin, Bool, Float (+3 more)

### Community 36 - "LayoutDemo"
Cohesion: 0.22
Nodes (7): LayoutDemo, .body, Alignment, Float, float2, HorizontalAlignment, VerticalAlignment

### Community 37 - "VectorBaker"
Cohesion: 0.11
Nodes (20): BakedRegion, DynamicSDFAtlas, .maxTileSize, Mode, fillEvenOdd, fillNonZero, stroke, SDFSlot (+12 more)

### Community 38 - "SVGParser"
Cohesion: 0.17
Nodes (16): SVGDocument, SVGPaint, color, currentColor, none, SVGParser, SVGShape, SVGStyle (+8 more)

### Community 39 - "Graphics2D"
Cohesion: 0.09
Nodes (21): CustomStringConvertible, Error, Glyph, Line, Graphics2D, .glassAtlasWidth, .size, PipelineError (+13 more)

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
Cohesion: 0.14
Nodes (29): metal_stdlib, Effects and transitions, sdBox(), sdRoundedBox(), backdrop2D(), compute2D(), ellipseAlong(), glassBlur() (+21 more)

### Community 44 - ".expansion"
Cohesion: 0.09
Nodes (22): DeclGroupSyntax, ExtensionDeclSyntax, ExtensionMacro, MemberMacro, PatternBindingSyntax, .states, TypeSyntax, .arrayStates (+14 more)

### Community 45 - "NumberField"
Cohesion: 0.21
Nodes (9): Number3Field, .body, SIMD3, T, NumberField, .body, stringToSIMDScalar(), Bool (+1 more)

### Community 46 - "SceneData"
Cohesion: 0.29
Nodes (7): DebugData, drawGrid, showFilledCells, SceneData, debug, time, windowSize

### Community 47 - "ImageManager"
Cohesion: 0.20
Nodes (11): CGContext, BitmapTexture, ImageManager, PendingUpload, CGFloat, float2, MTLBuffer, MTLCommandBuffer (+3 more)

### Community 48 - "Rect"
Cohesion: 0.16
Nodes (10): Rect, .center, .height, .maxX, .maxY, .minX, .minY, .width (+2 more)

### Community 49 - "PopoverLayer"
Cohesion: 0.05
Nodes (30): AnyObject, HittableGrid2D, HittableGridCell, HoveredView, Bool, Float, float2, ObjectIdentifier (+22 more)

### Community 50 - "HStack"
Cohesion: 0.33
Nodes (4): HStack, .crossKey, Float, VerticalAlignment

### Community 51 - "IDElement"
Cohesion: 0.11
Nodes (13): ID, IDElement, ScrollViewProxy, ScrollViewReader, Alignment, AnyHashable, float2, Void (+5 more)

### Community 52 - "AnimationDemo"
Cohesion: 0.31
Nodes (6): AnimatedItem, AnimationDemo, .body, Bool, Float, float4

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

### Community 57 - "StackElement"
Cohesion: 0.25
Nodes (8): origin, StackElement, .crossKey, .size, Bool, Float, float2, Void

### Community 58 - "uidrive/main.swift"
Cohesion: 0.22
Nodes (16): CGKeyCode, CGWindowID, fail(), findWindow(), keyCode(), modifierFlags(), postKey(), run() (+8 more)

### Community 59 - "SDF.swift"
Cohesion: 0.24
Nodes (15): clamp(), T, closestPointToSDBox(), pointInAABBox(), pointInAABBoxTopLeftOrigin(), sdBox(), sdBoxTopLeft(), sdCircle() (+7 more)

### Community 60 - "Glyph"
Cohesion: 0.22
Nodes (9): Glyph, blur, color, depth, fontSize, position, size, uvMax (+1 more)

### Community 61 - "Demo"
Cohesion: 0.11
Nodes (18): Demo, conditional, containers, form, glass, grids, .id, image (+10 more)

### Community 62 - "float4x4"
Cohesion: 0.14
Nodes (12): matrix_double4x4, float3x3, Float, float4x4, .formated, .identity, .upperLeft, Bool (+4 more)

### Community 63 - "Array"
Cohesion: 0.33
Nodes (4): Array, .byteCount, Element, Void

### Community 64 - "Driving GPURayMarching"
Cohesion: 0.13
Nodes (10): graphify, Hot reload, Performance, 1. Build and launch, 2. Compile the driver, 3. Drive and look, Driving GPURayMarching, Notes (+2 more)

### Community 65 - "float4"
Cohesion: 0.07
Nodes (27): Circle, color, depth, position, radius, Clip, blur, bounds (+19 more)

### Community 66 - "GeometryChangeElement"
Cohesion: 0.14
Nodes (11): CoordinateSpace, global, local, GeometryChangeElement, GeometryProxy, GeometryReader, Float, float2 (+3 more)

### Community 67 - "Comparable Clamp"
Cohesion: 0.40
Nodes (3): Comparable, ClosedRange, Self

### Community 73 - "Line"
Cohesion: 0.29
Nodes (5): Line, .bounds, Float, float2, float4

### Community 74 - "OverlayElement"
Cohesion: 0.11
Nodes (11): Alignment, Background, FlexFrame, float4, Frame, OverlayElement, .alignment, Alignment (+3 more)

### Community 75 - "UIContext"
Cohesion: 0.06
Nodes (8): Float, float4, ObjectIdentifier, UIContext, LayoutPass, UInt32, Void, Void

### Community 76 - "Picker"
Cohesion: 0.08
Nodes (23): Kind, check, menuItem, segment, Picker, .selectedTitle, PickerMark, PickerStyle (+15 more)

### Community 77 - "Frame"
Cohesion: 0.26
Nodes (6): Frame, .size, Alignment, Float, float2, Void

### Community 78 - "Int"
Cohesion: 0.09
Nodes (20): AnyIterator, StressCell, StressIndex, StressRow, .body, Bool, VectorDemo, .body (+12 more)

### Community 79 - "Square"
Cohesion: 0.29
Nodes (5): Square, .bounds, Float, float2, float4

### Community 80 - "IMView"
Cohesion: 0.23
Nodes (10): HStack, .size, IMView, Float, HorizontalAlignment, Self, VerticalAlignment, Void (+2 more)

### Community 81 - "Slider"
Cohesion: 0.16
Nodes (12): ProgressView, .fraction, Slider, SliderTrack, ClosedRange, Double, Float, float2 (+4 more)

### Community 82 - "VectorCanvas"
Cohesion: 0.22
Nodes (7): .body, Float, float2, Self, VectorCanvas, .children, VectorShapeList

### Community 83 - "BoundingBox2D"
Cohesion: 0.12
Nodes (14): BoundingBox2D, .bottom, .bottomRight, .height, .left, .right, .top, .topLeft (+6 more)

### Community 84 - "UIElement"
Cohesion: 0.07
Nodes (23): LayoutTraits, Alignment, AnyHashable, Float, float2, float4, UIElement, .clipCornerRadii (+15 more)

### Community 85 - ".texture"
Cohesion: 0.25
Nodes (6): CGImage, Bundle, Float, NSImage, Bundle, NSImage

### Community 86 - "Divider"
Cohesion: 0.31
Nodes (4): Divider, Float, float2, float4

### Community 87 - "ScrollRow"
Cohesion: 0.27
Nodes (10): 7. Measure, don't guess, makeScrollToDemo(), ScrollDemo, .body, ScrollRow, .name, ScrollRowView, .body (+2 more)

### Community 88 - "Sendable"
Cohesion: 0.16
Nodes (18): Equatable, Alignment, .offset, .xOffset, .yOffset, AlignmentID, AlignmentKey, .isFraction (+10 more)

### Community 89 - "Performance in MetalGraphics"
Cohesion: 0.25
Nodes (7): 1. The frame, 2. Invalidation — name the narrowest effect, 4. GPU and Metal (`Graphics2D.swift`, `Shaders/Shaders.metal`), 5. Layout and text, 6. Lists and scrolling, 8. Before finishing, Performance in MetalGraphics

### Community 90 - "KeyboardDemo"
Cohesion: 0.38
Nodes (5): KeyboardDemo, .body, Bool, Float, float2

### Community 91 - "SVGIcon"
Cohesion: 0.22
Nodes (8): Layer, SVGIcon, Bool, Bundle, Data, Float, float2, float4

### Community 92 - "MouseOver"
Cohesion: 0.19
Nodes (9): IMView, IMGameView, float4, IMView, MouseOver, Bool, Float, Self (+1 more)

### Community 93 - "HotReload"
Cohesion: 0.13
Nodes (11): HotReload, Bool, Date, Int32, Never, URL, Void, MacroReloader (+3 more)

### Community 94 - "MetalGraphicsLib"
Cohesion: 0.21
Nodes (4): AppKit, LazyRowCounter, MetalGraphicsLib, ReactiveUI

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

### Community 99 - "Background"
Cohesion: 0.18
Nodes (6): Background, GlassBackground, GlassMaterial, Float, float2, float4

### Community 100 - "Interpolation"
Cohesion: 0.40
Nodes (5): Interpolation, high, low, medium, none

### Community 101 - "float3"
Cohesion: 0.14
Nodes (11): float3, .depth, .height, .width, .xy, Float, float2, float4 (+3 more)

### Community 102 - "VectorItem"
Cohesion: 0.09
Nodes (23): ImageQuad, depth, flags, lod, position, size, textureIndex, tint (+15 more)

### Community 103 - "LazyStack"
Cohesion: 0.10
Nodes (21): LazyHStack, .crossAlignment, LazyStack, .crossAlignment, .defaultLength, .estimatedLength, .initialExtent, .overscan (+13 more)

### Community 104 - "HittableView"
Cohesion: 0.23
Nodes (7): HittableView, .hitPosition, .hitSize, Bool, Float, float2, Void

### Community 105 - "ProposedSize"
Cohesion: 0.09
Nodes (16): MeasureCache, ProposedSize, Float, float2, UInt32, UInt8, .content, ClipElement (+8 more)

### Community 106 - "GraphicsGrid2D"
Cohesion: 0.19
Nodes (11): Int32, GPUDevice, MTLDevice, GraphicsGrid2D, GridArgBuffer, GridCell, Shape, Float (+3 more)

### Community 107 - "Utils.swift"
Cohesion: 0.17
Nodes (13): DispatchWorkItem, Debouncer, forEachGridCell(), generateRandomArray(), iterateWithStep(), name(), ClosedRange, DispatchQueue (+5 more)

### Community 108 - "Rectangle"
Cohesion: 0.25
Nodes (3): Rectangle, Float, float2

### Community 109 - "SVGScanner"
Cohesion: 0.16
Nodes (10): SVGPathData, SVGScanner, .isAtEnd, .peek, SVGTransform, .lengthScale, Bool, Character (+2 more)

### Community 110 - "Image"
Cohesion: 0.17
Nodes (9): ContentMode, fill, fit, Image, .naturalSize, Float, float2, float4 (+1 more)

### Community 111 - "Void"
Cohesion: 0.08
Nodes (17): 3. Hot paths — per frame, or per element per frame, ShadowElement, Invalidation, Bool, Double, float2, Frame, UInt8 (+9 more)

### Community 112 - "LazyGridElement"
Cohesion: 0.14
Nodes (20): GridItem, LazyGridElement, .defaultCellAlignment, .trackAlignment, LazyHGrid, .defaultCellAlignment, .trackAlignment, LazyVGrid (+12 more)

### Community 113 - "uchar4"
Cohesion: 0.29
Nodes (6): UInt8, uchar4, .a, .b, .g, .r

### Community 114 - "Padding"
Cohesion: 0.21
Nodes (5): Self, Padding, Float, float2, float2

### Community 115 - "SDFBaker.swift"
Cohesion: 0.13
Nodes (22): CoreGraphics, PendingBake, SDFAtlas, SDFBakeParams, SDFBaker, SDFRegion, SDFShape, SDFShapeGeometry (+14 more)

### Community 116 - "post"
Cohesion: 0.25
Nodes (14): CGEventFlags, CGEventType, CGMouseButton, Int64, click(), drag(), holdModifiers(), post() (+6 more)

### Community 117 - "PathBuilder"
Cohesion: 0.24
Nodes (7): PathBuilder, Double, Float, float2, VectorSegment, VectorGeometry, .isEmpty

### Community 118 - "Demos"
Cohesion: 0.33
Nodes (4): Demos, MTKView, TestViewRenderer, 8. How it lands on screen

### Community 119 - ".expansion"
Cohesion: 0.08
Nodes (17): AccessorDeclSyntax, AccessorMacro, DeclSyntaxProtocol, DiagnosticMessage, DiagnosticSeverity, FixItMessage, MessageID, PeerMacro (+9 more)

### Community 120 - "layoutText"
Cohesion: 0.32
Nodes (12): CoreText, caretOffsets(), layoutText(), measureText(), PlacedGlyph, Bool, Float, float2 (+4 more)

### Community 121 - "MultiChildElement"
Cohesion: 0.24
Nodes (4): MultiChildElement, .liveChildrenCount, float2, Void

### Community 122 - "Content"
Cohesion: 0.50
Nodes (4): Content, bitmap, missing, svg

### Community 123 - "float2"
Cohesion: 0.18
Nodes (9): TableColumnLayout, .count, Bool, float2, HorizontalAlignment, TableCell, .clipRect, TableCells (+1 more)

### Community 124 - "ImageQuad"
Cohesion: 0.67
Nodes (3): ImageQuad, .bounds, UInt32

### Community 125 - "SDFFont"
Cohesion: 0.33
Nodes (7): CGGlyph, CTFont, FontManager, GlyphKey, GlyphMetrics, SDFFont, Float

### Community 126 - "MetalKit"
Cohesion: 0.17
Nodes (9): App, Combine, ContentView, .body, GPURayMarchingApp, .body, MetalKit, Scene (+1 more)

### Community 127 - "simd"
Cohesion: 0.17
Nodes (6): .inspectorView, Number2Field, .body, T, QuartzCore, simd

### Community 128 - "SwiftSyntaxMacros"
Cohesion: 0.42
Nodes (5): ReactiveUIMacrosPlugin, SwiftSyntaxMacroExpansion, SwiftSyntaxMacros, SwiftSyntaxMacrosGenericTestSupport, Testing

### Community 129 - "oracle.swift"
Cohesion: 0.25
Nodes (7): HorizontalAlignment, Probe, .body, render(), CGSize, V, View

### Community 130 - "Drag"
Cohesion: 0.15
Nodes (7): Carbon.HIToolbox, GameController, Drag, .description, Float, float2, Void

### Community 131 - "BodyParser"
Cohesion: 0.12
Nodes (20): CodeBlockItemListSyntax, IfExprSyntax, BodyParser, Bool, ClosureExprSyntax, ExprSyntax, FunctionCallExprSyntax, MemberBlockItemListSyntax (+12 more)

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
Cohesion: 0.07
Nodes (20): EmptyElement, LeafElement, CalendarView, Components, DatePicker, DatePickerStyle, compact, graphical (+12 more)

### Community 138 - "VList"
Cohesion: 0.52
Nodes (3): T, Void, VList

### Community 139 - "TextField"
Cohesion: 0.09
Nodes (18): EditKind, deleting, other, typing, FieldBox, .clipRect, SecureField, Snapshot (+10 more)

### Community 140 - "Path"
Cohesion: 0.14
Nodes (16): Path, .isClosed, .length, .localBounds, Source, builder, commands, Bool (+8 more)

### Community 143 - "Plugin.swift"
Cohesion: 0.40
Nodes (4): CompilerPlugin, ReactiveUIMacrosPlugin, Macro, SwiftCompilerPlugin

### Community 144 - "Section"
Cohesion: 0.12
Nodes (14): CaptionSlot, .isEmpty, RowLayout, RowSeparators, RowStack, .inset, Section, .inset (+6 more)

### Community 145 - "SVGPathCommand"
Cohesion: 0.17
Nodes (9): SVGPathCommand, close, cubic, line, move, quad, PathMorph, Bool (+1 more)

### Community 146 - "Stepper"
Cohesion: 0.19
Nodes (10): Stepper, StepperGlyph, Bool, ClosedRange, Double, Float, float2, Text (+2 more)

### Community 147 - "GridCell"
Cohesion: 0.22
Nodes (5): GridCell, count, startIndex, isBetween(), thread

### Community 148 - "GlassPass"
Cohesion: 0.22
Nodes (9): GlassPass, atlasOrigin, direction, maxDepth, padding, pointsPerTexel, sceneOrigin, sigma (+1 more)

### Community 149 - ".beginFrame"
Cohesion: 0.25
Nodes (5): Circle2D, .bounds, Float, float2, float4

### Community 150 - "float2"
Cohesion: 0.15
Nodes (7): float2, .asInt2, .greatestComponent, .height, .width, Float, .text

### Community 151 - "FormGraphic"
Cohesion: 0.21
Nodes (7): FormGraphic, FormMetrics, mix(), Float, float2, float4, UIElementWrapping

### Community 152 - ".body"
Cohesion: 0.31
Nodes (7): AudioSettings, FormDemo, .body, Bool, Date, Double, float4

### Community 153 - "ViewThatFits"
Cohesion: 0.26
Nodes (4): Float, float2, Void, ViewThatFits

### Community 154 - "TableColumn"
Cohesion: 0.23
Nodes (8): KeyPath, MainActor, HorizontalAlignment, KeyPathComparator, T, V, TableColumn, TableColumnBuilder

### Community 155 - "ZStack"
Cohesion: 0.23
Nodes (6): Alignment, Bool, Float, float2, Void, ZStack

### Community 156 - "TableDemo"
Cohesion: 0.40
Nodes (5): Person, float4, KeyPathComparator, TableDemo, .body

### Community 158 - "Shape"
Cohesion: 0.40
Nodes (5): Shape, clip, depth, index, shapeType

### Community 159 - "View"
Cohesion: 0.18
Nodes (11): Bool, View, Background, ExpandedFrame, FlexFrame, HStack, .isSpacer, MouseOver (+3 more)

### Community 160 - "Form"
Cohesion: 0.27
Nodes (5): Form, Bool, ObjectIdentifier, Void, VStack

### Community 161 - ".init"
Cohesion: 0.25
Nodes (7): DisclosureChevron, DisclosureGroup, Bool, Float, float2, Text, Void

### Community 163 - "Toggle"
Cohesion: 0.26
Nodes (7): Bool, Float, float2, Text, Void, Toggle, ToggleSwitch

### Community 164 - "int2"
Cohesion: 0.40
Nodes (3): int2, float2, from1DTo2DArray()

### Community 165 - "TableColumnDivider"
Cohesion: 0.17
Nodes (6): Background, Float, T, TableColumnDivider, TableMetrics, TableRowHighlight

### Community 166 - "layoutchecks/main.swift"
Cohesion: 0.31
Nodes (6): check(), Diagonal, HorizontalAlignment, layout(), float2, Void

### Community 167 - "UIShape"
Cohesion: 0.20
Nodes (9): Kind, capsule, circle, rect, Bool, Float, float4, UIShape (+1 more)

### Community 168 - "Binding"
Cohesion: 0.23
Nodes (8): Member, Binding, .wrappedValue, Value, Void, ReferenceWritableKeyPath, Root, WritableKeyPath

### Community 169 - "ShapeType2D"
Cohesion: 0.25
Nodes (8): ShapeType2D, Circle, Glass, Glyph, Image, Line, Square, Vector

### Community 170 - "expand"
Cohesion: 0.30
Nodes (5): BindingMacroTests, component(), expand(), NamedContentTests, SwiftParser

### Community 171 - "Foundation"
Cohesion: 0.15
Nodes (5): CoreServices, Foundation, benchmark(), Bool, Void

### Community 172 - "Kind"
Cohesion: 0.18
Nodes (11): Theme, dark, light, system, Hashable, Kind, custom, firstTextBaseline (+3 more)

### Community 173 - "FormControl"
Cohesion: 0.14
Nodes (6): FormControl, .isInteracting, Bool, Self, V, Void

### Community 174 - "Hot reload"
Cohesion: 0.29
Nodes (5): Hot reload, How it fits the frame loop, Setup, What needs a relaunch, ShaderReloader

### Community 175 - "ListRows"
Cohesion: 0.29
Nodes (5): ListRows, T, Void, Float, HorizontalAlignment

### Community 176 - "Button"
Cohesion: 0.33
Nodes (6): Button, ButtonRole, cancel, destructive, Text, Void

### Community 177 - "TableColumnWidth"
Cohesion: 0.36
Nodes (3): Bool, Float, TableColumnWidth

### Community 178 - "ConditionalDemo"
Cohesion: 0.36
Nodes (5): ConditionalDemo, .body, Bool, Float, float4

### Community 179 - "1. The pieces"
Cohesion: 0.17
Nodes (11): 1. The pieces, 2. What a component looks like, 3. What gets generated, 4. Rules that follow, 5. Collections are just `@State` arrays, 6. Composition, not helper methods, Bindings are lowered, not passed, Compile-time state in RetainedModeUI (+3 more)

### Community 180 - "TextDemo"
Cohesion: 0.70
Nodes (3): Float, TextDemo, .body

### Community 183 - "Phases"
Cohesion: 0.67
Nodes (3): Phases, UInt8, OptionSet

### Community 184 - "TemplateRenderingMode"
Cohesion: 0.50
Nodes (3): TemplateRenderingMode, original, template

## Knowledge Gaps
- **477 isolated node(s):** `conditional`, `list`, `text`, `layout`, `image` (+472 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 937 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **16 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `String` connect `String` to `Input`, `Text`, `.system`, `IMView`, `DiagnosticsTests`, `SIMD2`, `CodeGen`, `SingleChildElement`, `UIAnimation`, `IMView`, `ColorPicker`, `WindowState`, `View`, `BorderElement`, `KeyPress`, `Set`, `Inset`, `ElementIR`, `LayoutDemo`, `SVGParser`, `Graphics2D`, `.expansion`, `NumberField`, `ImageManager`, `HStack`, `IDElement`, `AnimationDemo`, `Table`, `ListDemo`, `uidrive/main.swift`, `Demo`, `float4x4`, `Driving GPURayMarching`, `.draw`, `OverlayElement`, `UIContext`, `Picker`, `Frame`, `IMView`, `Slider`, `VectorCanvas`, `.texture`, `ScrollRow`, `KeyboardDemo`, `SVGIcon`, `MouseOver`, `HotReload`, `IMView`, `Background`, `Utils.swift`, `Rectangle`, `SVGScanner`, `Image`, `Padding`, `SDFBaker.swift`, `.expansion`, `layoutText`, `MultiChildElement`, `SDFFont`, `simd`, `oracle.swift`, `Drag`, `BodyParser`, `FlexFrame`, `AnimationMacroTests`, `DatePicker`, `TextField`, `Path`, `Void`, `Section`, `Stepper`, `float2`, `FormGraphic`, `.body`, `TableColumn`, `ZStack`, `TableDemo`, `.init`, `Toggle`, `layoutchecks/main.swift`, `expand`, `Foundation`, `Button`, `ConditionalDemo`?**
  _High betweenness centrality (0.254) - this node is a cross-community bridge._
- **Why does `UIElement` connect `UIElement` to `UIElementWrapping`, `.system`, `ClipRect`, `AnimatedProperty`, `FlexFrame`, `DatePicker`, `SingleChildElement`, `Void`, `UIAnimation`, `Section`, `Axis`, `VectorShape`, `LayoutSubviews`, `.body`, `ViewThatFits`, `BorderElement`, `ScrollView`, `TableDemo`, `KeyPress`, `ZStack`, `TableColumn`, `Float`, `Inset`, `.init`, `EffectElement`, `LayoutDemo`, `Form`, `layoutchecks/main.swift`, `TableColumnDivider`, `FormControl`, `Hot reload`, `ListRows`, `PopoverLayer`, `ConditionalDemo`, `HStack`, `AnimationDemo`, `TextDemo`, `IDElement`, `ListDemo`, `Table`, `StackElement`, `GeometryChangeElement`, `.draw`, `OverlayElement`, `UIContext`, `Picker`, `Frame`, `Int`, `VectorCanvas`, `ScrollRow`, `Sendable`, `KeyboardDemo`, `HList`, `Background`, `LazyStack`, `HittableView`, `ProposedSize`, `Rectangle`, `Void`, `LazyGridElement`, `Padding`, `Demos`, `MultiChildElement`, `float2`?**
  _High betweenness centrality (0.189) - this node is a cross-community bridge._
- **Why does `Int` connect `Int` to `UIElementWrapping`, `.system`, `BodyParser`, `SDFPathBuilder`, `ClipRect`, `AnimatedProperty`, `FlexFrame`, `DatePicker`, `VList`, `TextField`, `MathLib.swift`, `UIAnimation`, `IMView`, `Axis`, `ColorPicker`, `LayoutSubviews`, `WindowState`, `Float`, `.body`, `String`, `ZStack`, `TableDemo`, `View`, `Float`, `ElementIR`, `LayoutDemo`, `VectorBaker`, `int2`, `Graphics2D`, `ImageManager`, `ListRows`, `TableColumnWidth`, `ConditionalDemo`, `AnimationDemo`, `TextDemo`, `Table`, `ListDemo`, `StackElement`, `Array`, `UIContext`, `Picker`, `UIElement`, `ScrollRow`, `Sendable`, `HList`, `LazyStack`, `ProposedSize`, `GraphicsGrid2D`, `Utils.swift`, `Void`, `LazyGridElement`, `SDFBaker.swift`, `post`, `PathBuilder`, `MultiChildElement`, `float2`?**
  _High betweenness centrality (0.172) - this node is a cross-community bridge._
- **Are the 5 inferred relationships involving `UIContext` (e.g. with `Effects and transitions` and `HittableGrid2D`) actually correct?**
  _`UIContext` has 5 INFERRED edges - model-reasoned connections that need verification._
- **Are the 23 inferred relationships involving `UIElement` (e.g. with `7. Diagnostics` and `What needs a relaunch`) actually correct?**
  _`UIElement` has 23 INFERRED edges - model-reasoned connections that need verification._
- **What connects `conditional`, `list`, `text` to the rest of the system?**
  _477 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `UIElementWrapping` be split into smaller, more focused modules?**
  _Cohesion score 0.11174242424242424 - nodes in this community are weakly interconnected._