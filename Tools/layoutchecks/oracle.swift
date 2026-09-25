// Measures how SwiftUI lays out a tree: each probed view prints its size and origin. Used to
// get the expected values in Tools/layoutchecks/main.swift.
//
//   swiftc Tools/layoutchecks/oracle.swift -o /tmp/oracle && /tmp/oracle
//
import SwiftUI
import AppKit

struct Probe: View {
  let name: String
  var body: some View {
    GeometryReader { g in
      let _ = print(name, g.size.width, g.size.height, g.frame(in: .named("root")).origin.x, g.frame(in: .named("root")).origin.y)
      Color.clear
    }
  }
}

extension View {
  func probe(_ name: String) -> some View { background(Probe(name: name)) }
}

@MainActor func render<V: View>(_ title: String, _ size: CGSize, _ view: V) {
  print("--", title)
  let r = ImageRenderer(content: view.frame(width: size.width, height: size.height, alignment: .topLeading).coordinateSpace(name: "root"))
  _ = r.nsImage
}

let long = "The quick brown fox jumps over the lazy dog, twice over and again"
extension HorizontalAlignment {
  enum Mid: AlignmentID { static func defaultValue(in d: ViewDimensions) -> CGFloat { d.width * 0.25 } }
  static let mid = HorizontalAlignment(Mid.self)
}
MainActor.assumeIsolated {
  render("vtf first fits", CGSize(width: 300, height: 100),
    ViewThatFits { Color.red.frame(width: 200, height: 20).probe("wide"); Color.blue.frame(width: 50, height: 20).probe("narrow") }.probe("v"))
  render("vtf second", CGSize(width: 100, height: 100),
    ViewThatFits { Color.red.frame(width: 200, height: 20).probe("wide"); Color.blue.frame(width: 50, height: 20).probe("narrow") }.probe("v"))
  render("vtf none fits", CGSize(width: 30, height: 100),
    ViewThatFits { Color.red.frame(width: 200, height: 20).probe("wide"); Color.blue.frame(width: 50, height: 20).probe("narrow") }.probe("v"))
  render("vtf text", CGSize(width: 100, height: 100),
    ViewThatFits { Text("The quick brown fox jumps").probe("long"); Text("Fox").probe("short") }.probe("v"))
  render("vtf horizontal only", CGSize(width: 300, height: 10),
    ViewThatFits(in: .horizontal) { Color.red.frame(width: 200, height: 20).probe("wide"); Color.blue.frame(width: 50, height: 5).probe("narrow") }.probe("v"))
  render("vtf flexible", CGSize(width: 100, height: 100),
    ViewThatFits { Color.red.probe("flex"); Color.blue.frame(width: 50, height: 20).probe("narrow") }.probe("v"))
  render("vtf ideal", CGSize(width: 300, height: 100),
    ViewThatFits { Color.red.frame(width: 200, height: 20).probe("wide"); Color.blue.frame(width: 50, height: 20).probe("narrow") }.probe("v").fixedSize())
  render("geometry reader", CGSize(width: 300, height: 100),
    VStack(spacing: 0) { GeometryReader { g in Color.red.frame(width: 20, height: 20).probe("c") }.probe("gr"); Color.blue.frame(height: 30) })
  render("geometry reader ideal", CGSize(width: 300, height: 100),
    GeometryReader { g in Color.red.frame(width: 20, height: 20) }.probe("gr").fixedSize())
}
