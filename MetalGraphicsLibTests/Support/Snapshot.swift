import Foundation
import ImageIO
import UniformTypeIdentifiers
import XCTest

/// Compares `image` with the golden PNG `__Snapshots__/<TestClass>/<name>.png` next to the
/// test file.
///
/// A pixel differs when any channel is off by more than `tolerance` (0...255); the test fails
/// when more than `maxDifferentFraction` of the pixels differ. SDF edges are antialiased on the
/// GPU, and another GPU may round them slightly differently: the defaults absorb that and still
/// catch a wrong colour or a shape that moved.
///
/// With `RECORD_SNAPSHOTS=1` in the test's environment (`TEST_RUNNER_RECORD_SNAPSHOTS=1
/// xcodebuild test ...`: xcodebuild passes on only `TEST_RUNNER_` variables), or with no golden yet, it writes the golden
/// and fails, so a test never passes against an image nobody has looked at. On a mismatch it
/// writes the actual image and a diff (differing pixels in red over a faded actual) next to
/// each other in `$TMPDIR/MetalGraphicsSnapshots/`, and attaches them to the test result.
@MainActor
func assertSnapshot(
  _ image: CGImage, named name: String,
  tolerance: UInt8 = 8, maxDifferentFraction: Double = 0.002,
  file: StaticString = #filePath, line: UInt = #line, testCase: XCTestCase
) {
  let testClass = String(describing: type(of: testCase))
  let golden = URL(fileURLWithPath: "\(file)")
    .deletingLastPathComponent()
    .appendingPathComponent("__Snapshots__/\(testClass)/\(name).png")
  let record = ProcessInfo.processInfo.environment["RECORD_SNAPSHOTS"] == "1"

  guard !record, let expected = loadPNG(golden) else {
    try? FileManager.default.createDirectory(at: golden.deletingLastPathComponent(), withIntermediateDirectories: true)
    writePNG(image, to: golden)
    XCTFail("Recorded \(golden.path). Look at it, then run again without TEST_RUNNER_RECORD_SNAPSHOTS.", file: file, line: line)
    return
  }

  guard expected.width == image.width, expected.height == image.height else {
    let actual = failureURL(testClass, name, "actual")
    writePNG(image, to: actual)
    XCTFail(
      "\(name): size \(image.width)x\(image.height), golden is \(expected.width)x\(expected.height). Actual: \(actual.path)",
      file: file, line: line
    )
    return
  }

  let a = rgba(expected), b = rgba(image)
  var diff = [UInt8](repeating: 0, count: a.count)
  var differing = 0
  var worst: UInt8 = 0
  for i in stride(from: 0, to: a.count, by: 4) {
    var delta: UInt8 = 0
    for c in 0 ..< 3 {
      let d = a[i + c] > b[i + c] ? a[i + c] - b[i + c] : b[i + c] - a[i + c]
      delta = max(delta, d)
    }
    worst = max(worst, delta)
    if delta > tolerance {
      differing += 1
      diff[i] = 255; diff[i + 1] = 0; diff[i + 2] = 0
    } else {
      diff[i] = b[i] / 4 + 191; diff[i + 1] = b[i + 1] / 4 + 191; diff[i + 2] = b[i + 2] / 4 + 191
    }
    diff[i + 3] = 255
  }

  let fraction = Double(differing) / Double(image.width * image.height)
  guard fraction > maxDifferentFraction else { return }

  let actualURL = failureURL(testClass, name, "actual")
  let diffURL = failureURL(testClass, name, "diff")
  writePNG(image, to: actualURL)
  let diffImage = rgbaImage(width: image.width, height: image.height, diff)
  writePNG(diffImage, to: diffURL)
  for (label, url) in [("actual", actualURL), ("diff", diffURL)] {
    let attachment = XCTAttachment(contentsOfFile: url)
    attachment.name = "\(name)-\(label)"
    attachment.lifetime = .keepAlways
    testCase.add(attachment)
  }
  XCTFail(
    String(
      format: "%@: %.2f%% of pixels differ (worst channel delta %d). Golden: %@ Actual: %@ Diff: %@",
      name, fraction * 100, Int(worst), golden.path, actualURL.path, diffURL.path
    ),
    file: file, line: line
  )
}

private func failureURL(_ testClass: String, _ name: String, _ kind: String) -> URL {
  let dir = FileManager.default.temporaryDirectory.appendingPathComponent("MetalGraphicsSnapshots/\(testClass)")
  try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
  return dir.appendingPathComponent("\(name)-\(kind).png")
}

private func loadPNG(_ url: URL) -> CGImage? {
  guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
  return CGImageSourceCreateImageAtIndex(source, 0, nil)
}

func writePNG(_ image: CGImage, to url: URL) {
  guard let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else {
    return
  }
  CGImageDestinationAddImage(destination, image, nil)
  CGImageDestinationFinalize(destination)
}

/// `image` redrawn as sRGB RGBA bytes, so a golden read from disk and a fresh frame compare
/// byte for byte whatever layout each came in.
private func rgba(_ image: CGImage) -> [UInt8] {
  var bytes = [UInt8](repeating: 0, count: image.width * image.height * 4)
  let context = CGContext(
    data: &bytes, width: image.width, height: image.height, bitsPerComponent: 8, bytesPerRow: image.width * 4,
    space: CGColorSpace(name: CGColorSpace.sRGB)!,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
  )!
  context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
  return bytes
}

private func rgbaImage(width: Int, height: Int, _ bytes: [UInt8]) -> CGImage {
  let data = CFDataCreate(nil, bytes, bytes.count)!
  return CGImage(
    width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: width * 4,
    space: CGColorSpace(name: CGColorSpace.sRGB)!,
    bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue),
    provider: CGDataProvider(data: data)!, decode: nil, shouldInterpolate: false, intent: .defaultIntent
  )!
}
