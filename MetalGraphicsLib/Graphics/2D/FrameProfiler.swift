import Foundation
import QuartzCore

/// Where a drawn frame's time goes, averaged and printed every two seconds. Off unless the app
/// is launched with `METALGRAPHICS_PROFILE=1`; off, each call is one Bool check.
///
/// A phase is timed with `start()` and `add(_:since:)`. `update` runs every frame; the other
/// phases only on frames that are drawn, so their averages are per drawn frame.
///
/// One per window, owned by its `Graphics2D`: each window runs its frames on a thread of its
/// own, so each reports its own, under `label`.
public final class FrameProfiler {
  /// Names the window in the report.
  public var label = ""
  public var isEnabled = ProcessInfo.processInfo.environment["METALGRAPHICS_PROFILE"] == "1"

  public enum Phase: Int, CaseIterable {
    /// `UIContext.update`: hit-testing, animations, layout.
    case update
    /// `UIContext.render`: the walk over `paintOrder` and every element's draw calls.
    case uiRender
    /// `Graphics2D.endFrame`: hashing every shape, cutting it to its clip, filing it in cells.
    case gridMapping
    /// `GraphicsGrid2D.updateBuffers`: sorting cells, writing the shape buffer, hashing cells.
    case gridBuffers
    /// Copying every shape array into its buffer.
    case upload
    /// Deciding the damage and encoding the passes.
    case encode
    /// Committing and waiting for the GPU to finish.
    case gpuWait

    var name: String {
      switch self {
      case .update: "update"
      case .uiRender: "uiRender"
      case .gridMapping: "gridMapping"
      case .gridBuffers: "gridBuffers"
      case .upload: "upload"
      case .encode: "encode"
      case .gpuWait: "gpuWait"
      }
    }
  }

  /// Sizes of the last drawn frame.
  public enum Count: Int, CaseIterable {
    case elements, shapes, glyphs, vectors, filedShapes, dirtyCells, maxPerCell

    var name: String {
      switch self {
      case .elements: "elements"
      case .shapes: "shapes"
      case .glyphs: "glyphs"
      case .vectors: "vectors"
      case .filedShapes: "filed"
      case .dirtyCells: "dirtyCells"
      case .maxPerCell: "maxPerCell"
      }
    }
  }

  private var sums = [UInt64](repeating: 0, count: Phase.allCases.count)
  private var maxima = [UInt64](repeating: 0, count: Phase.allCases.count)
  private var samples = [Int](repeating: 0, count: Phase.allCases.count)
  private var counts = [Int](repeating: 0, count: Count.allCases.count)
  private var gpuSeconds: Double = 0
  private var gpuSamples = 0
  private var drawnFrames = 0
  private var lastReport = CACurrentMediaTime()
  private let nanosecondsPerTick: Double

  public init() {
    var timebase = mach_timebase_info_data_t()
    mach_timebase_info(&timebase)
    self.nanosecondsPerTick = Double(timebase.numer) / Double(timebase.denom)
  }

  @inline(__always)
  public func start() -> UInt64 {
    self.isEnabled ? mach_absolute_time() : 0
  }

  public func add(_ phase: Phase, since start: UInt64) {
    guard self.isEnabled, start != 0 else { return }
    let ticks = mach_absolute_time() - start
    self.sums[phase.rawValue] += ticks
    self.maxima[phase.rawValue] = max(self.maxima[phase.rawValue], ticks)
    self.samples[phase.rawValue] += 1
  }

  public func set(_ count: Count, _ value: Int) {
    guard self.isEnabled else { return }
    self.counts[count.rawValue] = value
  }

  func addGPUTime(_ seconds: Double) {
    guard self.isEnabled, seconds > 0 else { return }
    self.gpuSeconds += seconds
    self.gpuSamples += 1
  }

  /// Ends a drawn frame; prints and starts over once two seconds have passed.
  func frameEnded() {
    guard self.isEnabled else { return }
    self.drawnFrames += 1
    let now = CACurrentMediaTime()
    guard now - self.lastReport >= 2 else { return }
    self.report(seconds: now - self.lastReport)
    self.lastReport = now
    for i in self.sums.indices {
      self.sums[i] = 0
      self.maxima[i] = 0
      self.samples[i] = 0
    }
    self.gpuSeconds = 0
    self.gpuSamples = 0
    self.drawnFrames = 0
  }

  private func milliseconds(_ ticks: UInt64) -> Double {
    Double(ticks) * self.nanosecondsPerTick / 1_000_000
  }

  private func report(seconds: Double) {
    func format(_ value: Double) -> String { String(format: "%.3f", value) }
    var cpu = 0.0
    var phases: [String] = []
    for phase in Phase.allCases {
      let n = self.samples[phase.rawValue]
      let average = n == 0 ? 0 : self.milliseconds(self.sums[phase.rawValue]) / Double(n)
      if phase != .gpuWait { cpu += average }
      phases.append("\(phase.name) \(format(average)) (max \(format(self.milliseconds(self.maxima[phase.rawValue]))))")
    }
    let gpu = self.gpuSamples == 0 ? 0 : self.gpuSeconds / Double(self.gpuSamples) * 1000
    let sizes = Count.allCases.map { "\($0.name) \(self.counts[$0.rawValue])" }.joined(separator: " ")
    print("⏱ \(self.label.isEmpty ? "" : "[\(self.label)] ")\(self.drawnFrames) drawn in \(format(seconds)) s | CPU \(format(cpu)) ms | GPU \(format(gpu)) ms | \(sizes)")
    print("⏱   " + phases.joined(separator: " | "))
  }
}
