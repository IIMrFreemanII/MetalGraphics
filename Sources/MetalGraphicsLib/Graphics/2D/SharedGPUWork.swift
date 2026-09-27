import Metal
import Synchronization

/// The GPU work every window's frames depend on: glyph and icon bakes into the shared SDF atlas
/// (`SDFBaker`) and image uploads (`ImageManager`).
///
/// Any window's thread can queue a bake, and any other can draw that glyph right after, from its
/// own command queue. So the queued work is committed on a queue of its own, which signals `event`
/// with a new generation each time; a frame flushes, then waits on the generation it got back
/// before it samples the atlas or an image:
///
/// - A glyph is queued for baking before it enters `FontManager`'s cache, so a window that finds
///   it there flushes after it was queued: either that flush commits the bake, or an earlier one
///   did and bumped the generation it waits on.
/// - Flushes commit in generation order, under the lock, so a generation's bakes are in every
///   later one's past.
final class SharedGPUWork: @unchecked Sendable {
  static let shared = SharedGPUWork()

  let event: MTLSharedEvent
  private let queue: MTLCommandQueue
  private let lock = NSLock()
  private var generation: UInt64 = 0
  private let reportedError = Atomic<Bool>(false)

  private init() {
    let device = GPUDevice.main
    guard let event = device.makeSharedEvent(), let queue = device.makeCommandQueue() else {
      fatalError("Could not create the shared bake queue")
    }
    event.label = "Shared bakes"
    queue.label = "Shared bakes"
    self.event = event
    self.queue = queue
  }

  /// Commits whatever is queued, from any window, and returns the generation a frame must wait
  /// for to see everything queued so far; 0 when nothing ever was.
  func flush() -> UInt64 {
    self.lock.lock()
    defer { self.lock.unlock() }
    guard
      SDFBaker.shared.hasPendingBakes || ImageManager.shared.hasPendingUploads,
      let commandBuffer = self.queue.makeCommandBuffer()
    else {
      return self.generation
    }
    commandBuffer.label = "Shared bakes"
    SDFBaker.shared.encodePendingBakes(into: commandBuffer)
    ImageManager.shared.encodePendingUploads(into: commandBuffer)

    self.generation += 1
    let generation = self.generation
    commandBuffer.encodeSignalEvent(self.event, value: generation)
    // A command buffer that fails may never signal, and every window waiting on it would stall
    // until the GPU gave up on it: signalled from here instead. What it baked may be garbage;
    // that is reported, once.
    let event = self.event
    commandBuffer.addCompletedHandler { [self] buffer in
      guard buffer.status == .error else { return }
      if event.signaledValue < generation {
        event.signaledValue = generation
      }
      if !self.reportedError.exchange(true, ordering: .relaxed) {
        print("Shared bakes failed on the GPU: \(buffer.error.map(String.init(describing:)) ?? "unknown error")")
      }
    }
    commandBuffer.commit()
    return generation
  }

  /// Flushes, then makes `commandBuffer` wait until everything queued so far has run. Encoded
  /// before anything in `commandBuffer` samples the SDF atlas or an image.
  func wait(in commandBuffer: MTLCommandBuffer) {
    let generation = self.flush()
    if generation > 0 {
      commandBuffer.encodeWaitForEvent(self.event, value: generation)
    }
  }
}
