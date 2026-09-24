// Layout checks for RetainedModeUI: small trees laid out headlessly, with the sizes and
// positions SwiftUI gives the same trees as the expected values (see Tools/layoutchecks/oracle.swift
// for how those were measured).
//
//   xcodebuild -project MetalGraphics.xcodeproj -scheme GPURayMarching -derivedDataPath "$DD" build
//   swiftc -swift-version 6 -F "$DD/Build/Products/Debug" Tools/layoutchecks/main.swift -o /tmp/layoutchecks \
//     -Xlinker -rpath -Xlinker "$DD/Build/Products/Debug"
//   /tmp/layoutchecks            # fast path for fraction alignment guides
//   /tmp/layoutchecks general    # the same checks with explicit guides turned on
//
import MetalGraphicsLib
import simd

nonisolated(unsafe) var failures = 0

@MainActor func layout(_ root: UIElement, _ size: float2) {
  _ = root.calcSize(ProposedSize(size))
  root.calcPosition(.zero)
}

@MainActor func check(_ name: String, _ got: float2, _ want: float2) {
  if simd_distance(got, want) < 0.01 {
    print("ok   \(name)")
  } else {
    failures += 1
    print("FAIL \(name): got \(got), want \(want)")
  }
}

struct Row: Identifiable { let id: Int }
nonisolated(unsafe) var created = 0

struct Diagonal: Layout {
  func sizeThatFits(proposal: ProposedSize, subviews: LayoutSubviews, cache: inout Void) -> float2 {
    subviews.reduce(.zero) { $0 + $1.sizeThatFits(.unspecified) }
  }
  func placeSubviews(in bounds: ClipRect, proposal: ProposedSize, subviews: LayoutSubviews, cache: inout Void) {
    var point = bounds.min
    for subview in subviews {
      subview.place(at: point, proposal: .unspecified)
      point += subview.sizeThatFits(.unspecified)
    }
  }
}

enum Mid: AlignmentID { static func defaultValue(in d: ViewDimensions) -> Float { d.width * 0.25 } }
extension HorizontalAlignment { static let mid = HorizontalAlignment(Mid.self) }

MainActor.assumeIsolated {
  if CommandLine.arguments.contains("general") {
    // Any explicit guide turns off the fast path for fraction guides everywhere.
    _ = Rectangle(.red).alignmentGuide(.leading) { _ in 0 }
    print("(general alignment path)")
  }
  do {
    let a = Rectangle(.red), b = Rectangle(.blue)
    layout(HStack { a; b }, float2(200, 50))
    check("two rects share an HStack", a.size, float2(100, 50))
    check("second rect after first", b.position, float2(100, 0))
  }
  do {
    let a = Rectangle(.red), b = Rectangle(.blue)
    layout(HStack(spacing: 10) { a; b }, float2(210, 50))
    check("spacing comes off the share", a.size, float2(100, 50))
    check("spacing between", b.position, float2(110, 0))
  }
  do {
    let a = Rectangle(.red), b = Rectangle(.blue)
    layout(HStack { a.frame(width: 50); b }, float2(200, 50))
    check("fixed child keeps its width", a.size, float2(50, 50))
    check("flexible child takes the rest", b.size, float2(150, 50))
  }
  do {
    let a = Rectangle(.red), b = Rectangle(.blue)
    layout(HStack { a; b.layoutPriority(1) }, float2(200, 50))
    check("priority child takes all", b.size, float2(200, 50))
    check("low priority child keeps its minimum", a.size, float2(0, 50))
  }
  do {
    let a = Rectangle(.red), b = Rectangle(.blue)
    layout(HStack { a.frame(minWidth: 30); b.padding(Inset(all: 5)).layoutPriority(1) }, float2(200, 50))
    check("priority through a wrapper, min reserved", b.size, float2(160, 40))
    check("reserved minimum", a.size, float2(30, 50))
  }
  do {
    let a = Rectangle(.red), c = Rectangle(.blue)
    let stack = HStack { a.frame(width: 24, height: 24); Spacer(); c.frame(width: 24, height: 24) }
    layout(stack, float2(300, 24))
    check("spacer pushes apart", c.position, float2(276, 0))
    check("stack fills with a spacer", stack.size, float2(300, 24))
  }
  do {
    let a = Rectangle(.red)
    let stack = HStack { Spacer(minLength: 40); a.frame(width: 24, height: 24) }
    layout(stack.frame(width: 50, alignment: .leading), float2(300, 24))
    check("spacer minLength", a.position, float2(40, 0))
  }
  do {
    let a = Rectangle(.red)
    let frame = a.frame(width: 50, height: 20).frame(maxWidth: .infinity)
    layout(frame, float2(300, 100))
    check("maxWidth infinity fills width", frame.getSize(), float2(300, 20))
    check("child centred", a.position, float2(125, 0))
  }
  do {
    let frame = Rectangle(.red).frame(width: 50, height: 20).frame(minWidth: 100)
    layout(frame, float2(300, 100))
    check("minWidth grows to the minimum only", frame.getSize(), float2(100, 20))
  }
  do {
    let frame = Rectangle(.red).frame(width: 100)
    layout(frame, float2(300, 40))
    check("frame width only", frame.getSize(), float2(100, 40))
  }
  do {
    let top = Rectangle(.red), left = Rectangle(.green), bottom = Rectangle(.blue)
    layout(VStack { HStack { left; Rectangle(.white) }; bottom; top.frame(height: 20) }, float2(200, 100))
    check("nested stack shares height", left.size, float2(100, 40))
    check("rect below", bottom.size, float2(200, 40))
  }
  do {
    let a = Rectangle(.red)
    let scroll = ScrollView { VStack { a } }
    layout(scroll, float2(200, 100))
    check("rect in a vertical scroll view is its ideal height", a.size, float2(200, 10))
    check("scroll view fills", scroll.size, float2(200, 100))
  }
  do {
    let a = Rectangle(.red), b = Rectangle(.blue)
    let stack = HStack { a.frame(width: 30, height: 30); b.frame(width: 30, height: 10) }
    layout(stack.fixedSizeFree(), float2(300, 300))
    check("stack hugs inflexible children", stack.size, float2(60, 30))
    check("centred vertically", b.position, float2(30, 10))
  }

  do {
    let big = Rectangle(.red), small = Rectangle(.blue)
    let z = ZStack(alignment: .bottomTrailing) { big.frame(width: 100, height: 60); small.frame(width: 20, height: 10) }
    layout(z.fixedSizeFree(), float2(300, 300))
    check("zstack is its largest child", z.size, float2(100, 60))
    check("zstack aligns", small.position, float2(80, 50))
  }
  do {
    let badge = Rectangle(.red), base = Rectangle(.blue)
    let o = base.frame(width: 100, height: 40).overlay(alignment: .topTrailing) { badge.frame(width: 10, height: 10) }
    layout(o.fixedSizeFree(), float2(300, 300))
    check("overlay takes the element's size", o.getSize(), float2(100, 40))
    check("overlay content aligned", badge.position, float2(90, 0))
  }
  do {
    let fill = Rectangle(.red)
    let o = Rectangle(.blue).frame(width: 80, height: 30).background { fill }
    layout(o.fixedSizeFree(), float2(300, 300))
    check("background content offered the element's size", fill.size, float2(80, 30))
  }

  // Phase 2, expected values from SwiftUI.
  do {
    let d = Divider()
    let v = VStack { Rectangle(.red).frame(width: 50, height: 10); d }
    layout(v, float2(300, 100))
    check("divider in vstack", d.size, float2(300, 1))
    check("divider below", d.position, float2(0, 10))
  }
  do {
    let d = Divider()
    let h = HStack { Rectangle(.red).frame(width: 50, height: 10); d }
    layout(h, float2(300, 100))
    check("divider in hstack", d.size, float2(1, 100))
  }
  do {
    let d = Divider()
    layout(d.fixedSize(), float2(300, 100))
    check("divider ideal", d.size, float2(10, 1))
  }
  do {
    let p = Rectangle(.red).frame(width: 10, height: 10).padding()
    layout(p.fixedSize(), float2(300, 100))
    check("default padding 16", p.getSize(), float2(42, 42))
  }
  do {
    let p = Rectangle(.red).frame(width: 10, height: 10).padding(.horizontal, 8)
    layout(p.fixedSize(), float2(300, 100))
    check("edge padding", p.getSize(), float2(26, 10))
  }
  do {
    let a = Rectangle(.red)
    layout(a.aspectRatio(2, contentMode: .fit), float2(300, 300))
    check("aspect fit", a.size, float2(300, 150))
  }
  do {
    let a = Rectangle(.red)
    layout(a.aspectRatio(2, contentMode: .fill), float2(300, 300))
    check("aspect fill", a.size, float2(600, 300))
  }
  do {
    let sq = Rectangle(.red), rest = Rectangle(.blue)
    layout(HStack { sq.aspectRatio(1, contentMode: .fit); rest }, float2(300, 100))
    check("aspect fit in hstack", sq.size, float2(100, 100))
    check("rest of hstack", rest.size, float2(200, 100))
  }
  do {
    let a = Rectangle(.red)
    layout(a.aspectRatio(2, contentMode: .fit).fixedSize(), float2(300, 300))
    check("aspect ideal is the child's", a.size, float2(10, 10))
  }
  do {
    let c = Rectangle(.red)
    let p = c.frame(width: 20, height: 10).position(x: 100, y: 50)
    layout(p, float2(300, 300))
    check("position takes all", p.getSize(), float2(300, 300))
    check("position centres", c.position, float2(90, 45))
  }
  do {
    let h = Rectangle(.red), b = Rectangle(.blue)
    let stack = HStack { h.frame(width: 20, height: 10).hidden(); b.frame(width: 20, height: 10) }
    layout(stack.fixedSize(), float2(300, 100))
    check("hidden still laid out", b.position, float2(20, 0))
  }

  // Phase 3: alignment guides, expected values from SwiftUI.
  do {
    let a = Rectangle(.red), b = Rectangle(.blue)
    let v = VStack(alignment: .leading) { a.frame(width: 40, height: 10).alignmentGuide(.leading) { d in d.width }; b.frame(width: 60, height: 10) }
    layout(v.fixedSize(), float2(300, 300))
    check("explicit leading: stack is the union", v.size, float2(100, 20))
    check("explicit leading: a", a.position, float2(0, 0))
    check("explicit leading: b", b.position, float2(40, 10))
  }
  do {
    let a = Rectangle(.red), b = Rectangle(.blue)
    let v = VStack(alignment: .mid) { a.frame(width: 40, height: 10); b.frame(width: 80, height: 10) }
    layout(v.fixedSize(), float2(300, 300))
    check("custom id default", a.position, float2(10, 0))
    check("custom id stack", v.size, float2(80, 20))
  }
  do {
    let b = Rectangle(.blue)
    let v = VStack(alignment: .leading) { Rectangle(.red).frame(width: 40, height: 10).alignmentGuide(.leading) { _ in 10 }.padding(.leading, 5); b.frame(width: 60, height: 10) }
    layout(v.fixedSize(), float2(300, 300))
    check("guide through padding", b.position, float2(15, 10))
    check("guide through padding stack", v.size, float2(75, 20))
  }
  do {
    let b = Rectangle(.blue)
    let v = VStack(alignment: .leading) { Rectangle(.red).frame(width: 40, height: 10).alignmentGuide(.leading) { _ in 10 }.frame(width: 100); b.frame(width: 60, height: 10) }
    layout(v.fixedSize(), float2(300, 300))
    check("guide through frame", b.position, float2(40, 10))
  }
  do {
    let b = Rectangle(.blue)
    let h = HStack(alignment: .firstTextBaseline) { Rectangle(.red).frame(width: 20, height: 30); b.frame(width: 20, height: 10) }
    layout(h.fixedSize(), float2(300, 300))
    check("baseline of a rect is its bottom", b.position, float2(20, 20))
  }
  do {
    let r = Rectangle(.red), b = Rectangle(.blue)
    let h = HStack(alignment: .firstTextBaseline) { r.frame(width: 20, height: 30).alignmentGuide(.firstTextBaseline) { _ in 5 }; b.frame(width: 20, height: 10) }
    layout(h.fixedSize(), float2(300, 300))
    check("explicit baseline: stack", h.size, float2(40, 35))
    check("explicit baseline: r", r.position, float2(0, 5))
    check("explicit baseline: b", b.position, float2(20, 0))
  }
  do {
    let b = Rectangle(.blue)
    let h = HStack(alignment: .firstTextBaseline) {
      VStack { Rectangle(.red).frame(width: 20, height: 30).alignmentGuide(.firstTextBaseline) { _ in 5 }; Rectangle(.green).frame(width: 20, height: 30).alignmentGuide(.firstTextBaseline) { _ in 7 } }
      b.frame(width: 20, height: 10).alignmentGuide(.firstTextBaseline) { _ in 2 }
    }
    layout(h.fixedSize(), float2(300, 300))
    check("vstack first baseline is its first child's", b.position, float2(20, 3))
  }
  do {
    let b = Rectangle(.blue)
    let h = HStack(alignment: .lastTextBaseline) {
      VStack { Rectangle(.red).frame(width: 20, height: 30).alignmentGuide(.lastTextBaseline) { _ in 5 }; Rectangle(.green).frame(width: 20, height: 30).alignmentGuide(.lastTextBaseline) { _ in 7 } }
      b.frame(width: 20, height: 10).alignmentGuide(.lastTextBaseline) { _ in 2 }
    }
    layout(h.fixedSize(), float2(300, 300))
    check("vstack last baseline is its last child's", b.position, float2(20, 35))
  }
  do {
    let b = Rectangle(.blue)
    let v = VStack(alignment: .leading) {
      HStack { Rectangle(.red).frame(width: 20, height: 10); Rectangle(.green).frame(width: 20, height: 10).alignmentGuide(.leading) { _ in 4 } }
      b.frame(width: 50, height: 10)
    }
    layout(v.fixedSize(), float2(300, 300))
    check("hstack does not pass on a guide along its axis", b.position, float2(0, 10))
  }
  do {
    let small = Rectangle(.blue)
    let z = ZStack(alignment: .topLeading) { Rectangle(.red).frame(width: 40, height: 40); small.frame(width: 10, height: 10).alignmentGuide(.leading) { _ in -5 }.alignmentGuide(.top) { _ in -5 } }
    layout(z.fixedSize(), float2(300, 300))
    check("zstack guide", small.position, float2(5, 5))
    check("zstack size", z.size, float2(40, 40))
  }
  do {
    let c = Rectangle(.red)
    let f = c.frame(width: 20, height: 10).alignmentGuide(.mid) { _ in 0 }.frame(width: 100, height: 20, alignment: Alignment(horizontal: .mid, vertical: .top))
    layout(f, float2(300, 300))
    check("frame with a custom guide", c.position, float2(25, 0))
  }

  // Phase 4: grids, expected values from SwiftUI.
  do {
    let a = Rectangle(.red), b = Rectangle(.blue), c = Rectangle(.green), d = Rectangle(.white)
    let g = Grid {
      GridRow { a.frame(width: 20, height: 10); b.frame(width: 50, height: 30) }
      GridRow { c.frame(width: 40, height: 20); d.frame(width: 10, height: 10) }
    }
    layout(g.fixedSize(), float2(300, 300))
    check("grid fixed: size", g.size, float2(90, 50))
    check("grid fixed: a", a.position, float2(10, 10))
    check("grid fixed: b", b.position, float2(40, 0))
    check("grid fixed: c", c.position, float2(0, 30))
    check("grid fixed: d", d.position, float2(60, 35))
  }
  do {
    let a = Rectangle(.red), b = Rectangle(.blue), c = Rectangle(.green), d = Rectangle(.white)
    let g = Grid {
      GridRow { a.frame(width: 20, height: 10); b }
      GridRow { c.frame(width: 40, height: 20); d.frame(height: 10) }
    }
    layout(g, float2(300, 100))
    check("grid flexible: a", a.position, float2(10, 35))
    check("grid flexible: b", b.size, float2(260, 80))
    check("grid flexible: d", d.size, float2(260, 10))
    check("grid flexible: d at", d.position, float2(40, 85))
  }
  do {
    let a = Rectangle(.red), b = Rectangle(.blue)
    layout(Grid(horizontalSpacing: 10) { GridRow { a; b } }, float2(300, 100))
    check("grid two flexible columns", a.size, float2(145, 100))
    check("grid two flexible columns: b", b.position, float2(155, 0))
  }
  do {
    let span = Rectangle(.green), free = Rectangle(.white), c = Rectangle(.white)
    let g = Grid {
      GridRow { Rectangle(.red).frame(width: 20, height: 10); Rectangle(.blue).frame(width: 50, height: 10) }
      GridRow { span.frame(height: 10).gridCellColumns(2) }
      free.frame(height: 5)
      GridRow { c.frame(width: 10, height: 10) }
    }
    layout(g.fixedSize(), float2(300, 300))
    check("grid spanning: size", g.size, float2(70, 35))
    check("grid spanning: span", span.size, float2(70, 10))
    check("grid spanning: free row", free.size, float2(70, 5))
    check("grid spanning: c", c.position, float2(5, 25))
  }
  do {
    let a = Rectangle(.red), b = Rectangle(.blue), span = Rectangle(.green)
    let g = Grid {
      GridRow { a.frame(width: 20, height: 10); b.frame(width: 30, height: 10) }
      GridRow { span.frame(width: 100, height: 10).gridCellColumns(2) }
    }
    layout(g.fixedSize(), float2(300, 300))
    check("wide span widens columns: size", g.size, float2(100, 20))
    check("wide span widens columns: a", a.position, float2(12.5, 0))
    check("wide span widens columns: b", b.position, float2(57.5, 0))
  }
  do {
    let div = Divider()
    let g = Grid {
      GridRow { Rectangle(.red).frame(width: 20, height: 10); Rectangle(.blue).frame(width: 30, height: 10) }
      div
      GridRow { Rectangle(.green).frame(width: 10, height: 10); Rectangle(.blue).frame(width: 10, height: 10) }
    }
    layout(g.fixedSize(), float2(300, 300))
    check("grid divider: size", g.size, float2(50, 21))
    check("grid divider", div.size, float2(50, 1))
  }
  do {
    let u = Rectangle(.green)
    let g = Grid {
      GridRow { Rectangle(.red).frame(width: 20, height: 10); Rectangle(.blue).frame(width: 30, height: 10) }
      GridRow { u.gridCellUnsizedAxes(.both); Rectangle(.blue).frame(width: 10, height: 10) }
    }
    layout(g.fixedSize(), float2(300, 300))
    check("unsized cell: size", g.size, float2(50, 20))
    check("unsized cell", u.size, float2(20, 10))
  }
  do {
    let a = Rectangle(.red), c = Rectangle(.green), d = Rectangle(.white), e = Rectangle(.white)
    let g = Grid(alignment: .topLeading) {
      GridRow { a.frame(width: 20, height: 10); Rectangle(.blue).frame(width: 50, height: 30) }
      GridRow(alignment: .bottom) { c.frame(width: 40, height: 20); d.frame(width: 10, height: 10).gridColumnAlignment(.trailing) }
      GridRow { Rectangle(.green).frame(width: 40, height: 20); e.frame(width: 10, height: 10).gridCellAnchor(.center) }
    }
    layout(g.fixedSize(), float2(300, 300))
    check("grid alignment: a", a.position, float2(0, 0))
    check("grid alignment: c", c.position, float2(0, 30))
    check("grid column alignment", d.position, float2(80, 40))
    check("grid cell anchor", e.position, float2(60, 55))
  }
  do {
    let g = Grid {
      GridRow { Rectangle(.red).frame(width: 20, height: 10); Rectangle(.blue).frame(width: 50, height: 30); Rectangle(.blue).frame(width: 5, height: 5) }
      GridRow { Rectangle(.green).frame(width: 40, height: 20) }
    }
    layout(g.fixedSize(), float2(300, 300))
    check("grid short row", g.size, float2(95, 50))
  }
  do {
    let a = Rectangle(.red), c = Rectangle(.green), b = Rectangle(.blue)
    layout(Grid { GridRow { a.frame(width: 20) }; GridRow { c.frame(width: 20, height: 20) }; GridRow { b.frame(width: 20) } }, float2(300, 100))
    check("grid flexible rows: a", a.size, float2(20, 40))
    check("grid flexible rows: b", b.position, float2(0, 60))
  }
  do {
    let a = Rectangle(.red), b = Rectangle(.blue), c = Rectangle(.green)
    let g = LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible())]) {
      a.frame(height: 10); b.frame(height: 20); c.frame(height: 10)
    }
    layout(g, float2(300, 300))
    check("lazyvgrid flexible: size", g.size, float2(300, 30))
    check("lazyvgrid flexible: a", a.size, float2(146, 10))
    check("lazyvgrid flexible: a at", a.position, float2(0, 5))
    check("lazyvgrid flexible: b at", b.position, float2(154, 0))
    check("lazyvgrid flexible: c at", c.position, float2(0, 20))
  }
  do {
    let b = Rectangle(.blue), c = Rectangle(.green), d = Rectangle(.white)
    let g = LazyVGrid(columns: [GridItem(.fixed(50), spacing: 10), GridItem(.flexible(minimum: 10, maximum: 100), spacing: 8), GridItem(.flexible())], spacing: 5) {
      Rectangle(.red).frame(height: 10); b.frame(height: 20); c.frame(height: 10); d.frame(width: 10, height: 10)
    }
    layout(g, float2(300, 300))
    check("fixed+flex: b", b.size, float2(100, 20))
    check("fixed+flex: b at", b.position, float2(60, 0))
    check("fixed+flex: c", c.size, float2(132, 10))
    check("fixed+flex: c at", c.position, float2(168, 5))
    check("fixed+flex: d at", d.position, float2(20, 25))
  }
  do {
    let b = Rectangle(.blue), d = Rectangle(.white)
    let g = LazyVGrid(columns: [GridItem(.adaptive(minimum: 70), spacing: 8)]) {
      Rectangle(.red).frame(height: 10); b.frame(height: 10); Rectangle(.green).frame(height: 10); d.frame(height: 10)
    }
    layout(g, float2(300, 300))
    check("adaptive: b", b.position, float2(102.666, 0))
    check("adaptive: width", b.size, float2(94.666, 10))
    check("adaptive: wraps", d.position, float2(0, 10))
  }
  do {
    let b = Rectangle(.blue)
    let g = LazyVGrid(columns: [GridItem(.adaptive(minimum: 40, maximum: 60))]) { Rectangle(.red).frame(height: 10); b.frame(height: 10) }
    layout(g, float2(300, 300))
    check("adaptive max", b.size, float2(42.857, 10))
  }
  do {
    let a = Rectangle(.red), b = Rectangle(.blue)
    let g = LazyVGrid(columns: [GridItem(.fixed(100), alignment: .leading), GridItem(.fixed(100))], alignment: .leading) {
      a.frame(width: 10, height: 10); b.frame(width: 10, height: 30)
    }
    layout(g, float2(300, 300))
    check("lazyvgrid alignment: a", a.position, float2(0, 10))
    check("lazyvgrid alignment: b", b.position, float2(100, 0))
  }
  do {
    let a = Rectangle(.red), b = Rectangle(.blue), c = Rectangle(.green)
    let g = LazyHGrid(rows: [GridItem(.flexible(), spacing: 8), GridItem(.flexible())]) { a.frame(width: 10); b.frame(width: 20); c.frame(width: 10) }
    layout(g, float2(300, 100))
    check("lazyhgrid: size", g.size, float2(30, 100))
    check("lazyhgrid: a", a.size, float2(10, 46))
    check("lazyhgrid: a at", a.position, float2(5, 0))
    check("lazyhgrid: b at", b.position, float2(0, 54))
    check("lazyhgrid: c at", c.position, float2(20, 0))
  }

  do {
    let q = Text("12"), n = Text("green"), span = Text("from the market, washed")
    let g = Grid(alignment: .leading, horizontalSpacing: 12) {
      GridRow { Text("Apples"); q; n }
      GridRow { Text("Oranges"); span.gridCellColumns(2) }
    }
    layout(g, float2(400, 300))
    let natural = span.sizeThatFits(.unspecified)
    check("spanning text stays on one line", span.size, natural)
    check("spanned columns widen equally", float2(n.position.x - q.position.x - 12 - q.size.x, 0),
          float2((natural.x - (q.size.x + 12 + n.size.x)) / 2, 0))
  }

  // Phase 5, expected values from SwiftUI.
  do {
    let wide = Rectangle(.red), narrow = Rectangle(.blue)
    let v = ViewThatFits { wide.frame(width: 200, height: 20); narrow.frame(width: 50, height: 20) }
    layout(v, float2(300, 100))
    check("view that fits: first fits", v.getSize(), float2(200, 20))
    layout(v, float2(100, 100))
    check("view that fits: second", v.getSize(), float2(50, 20))
    layout(v, float2(30, 100))
    check("view that fits: none fits, the last", v.getSize(), float2(50, 20))
  }
  do {
    let v = ViewThatFits(in: .horizontal) { Rectangle(.red).frame(width: 200, height: 20); Rectangle(.blue).frame(width: 50, height: 5) }
    layout(v, float2(300, 10))
    check("view that fits: horizontal only", v.getSize(), float2(200, 20))
  }
  do {
    let flex = Rectangle(.red)
    let v = ViewThatFits { flex; Rectangle(.blue).frame(width: 50, height: 20) }
    layout(v, float2(100, 100))
    check("view that fits: flexible fits, laid out with all", flex.size, float2(100, 100))
  }
  do {
    let c = Rectangle(.red)
    let g = GeometryReader { _ in c.frame(width: 20, height: 20) }
    layout(VStack { g; Rectangle(.blue).frame(height: 30) }, float2(300, 100))
    check("geometry reader fills", g.proxy.size, float2(300, 70))
    check("geometry reader content top left", c.position, float2(0, 0))
    layout(GeometryReader { _ in Rectangle(.red) }.fixedSize(), float2(300, 100))
  }
  do {
    let a = Rectangle(.red), b = Rectangle(.blue)
    let v = Diagonal() { a.frame(width: 20, height: 10); b.frame(width: 30, height: 5) }
    layout(v.fixedSize(), float2(300, 300))
    check("custom layout size", v.getSize(), float2(50, 15))
    check("custom layout places", b.position, float2(20, 10))
  }
  do {
    // The built-in layouts lay out exactly as their stacks.
    let a1 = Rectangle(.red), b1 = Rectangle(.blue), a2 = Rectangle(.red), b2 = Rectangle(.blue)
    let stack = HStack(alignment: .top, spacing: 10) { a1.frame(width: 50); b1; Text("wraps against the rest of it").layoutPriority(1) }
    let view = HStackLayout(alignment: .top, spacing: 10) { a2.frame(width: 50); b2; Text("wraps against the rest of it").layoutPriority(1) }
    layout(stack, float2(300, 100))
    layout(view, float2(300, 100))
    check("HStackLayout is an HStack: size", view.getSize(), stack.size)
    check("HStackLayout is an HStack: b", b2.position, b1.position)
    check("HStackLayout is an HStack: b size", b2.size, b1.size)
  }
  do {
    let a = Rectangle(.red), b = Rectangle(.blue)
    let view = LayoutView(VStackLayout(spacing: 4)) { a.frame(width: 20, height: 10); b.frame(width: 40, height: 10) }
    layout(view.fixedSize(), float2(300, 300))
    check("VStackLayout", b.position, float2(0, 14))
    check("VStackLayout centres", a.position, float2(10, 0))
    let c = Rectangle(.red), d = Rectangle(.blue)
    let z = LayoutView(AnyLayout(ZStackLayout(alignment: .topLeading))) { c.frame(width: 20, height: 10); d.frame(width: 40, height: 10) }
    layout(z.fixedSize(), float2(300, 300))
    check("ZStackLayout through AnyLayout", c.position, float2(0, 0))
    check("ZStackLayout through AnyLayout: size", z.getSize(), float2(40, 10))
  }

  do {
    created = 0
    let rows = (0..<10_000).map(Row.init)
    let lazy = LazyVStack(spacing: 2, items: rows) { _ in created += 1; return Rectangle(.red).frame(height: 20) }
    let scroll = ScrollView { lazy }
    layout(scroll, float2(200, 300))
    check("lazy stack in a scroll view builds only what shows", float2(Float(lazy.children.count), 0), float2(Float(lazy.children.count), 0))
    print("     built \(lazy.children.count) of 10000 rows, created \(created)")
    if lazy.children.count > 80 { failures += 1; print("FAIL too many rows built") }
    check("lazy stack length from measured rows", lazy.getSize(), float2(200, 10_000 * 20 + 9_999 * 2))
    check("lazy stack rows placed", lazy.children[3].getSize(), float2(200, 20))
    check("scroll content size", scroll.contentSize, float2(200, 219_998))
  }
  do {
    let lazy = LazyVStack(spacing: 0, items: (0..<50).map(Row.init)) { _ in Rectangle(.red).frame(height: 10) }
    layout(lazy, float2(200, 300))
    check("outside a scroll view every row is built", float2(Float(lazy.children.count), 0), float2(50, 0))
  }

  print(failures == 0 ? "ALL PASSED" : "\(failures) FAILED")
}

extension UIElement {
  // A frame that passes the proposal on unchanged, so the stack's own size can be checked.
  @MainActor func fixedSizeFree() -> UIElement { Frame(width: nil, height: nil, alignment: .topLeading) { self } }
}
