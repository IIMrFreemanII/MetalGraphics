/// The animation for writes made right now, outside any `.animation(_:value:)` scope.
///
/// A `@State` write runs its generated update synchronously, so whatever is set here while the
/// write happens is what that update sees. `withAnimation` is the only thing meant to set it.
public enum UITransaction {
  /// Per thread: each window's writes run on its own.
  public internal(set) static var animation: UIAnimation? {
    get { ThreadState.current.transactionAnimation }
    set { ThreadState.current.transactionAnimation = newValue }
  }

  /// The group of the innermost `withAnimation` that has a completion. Every animation started
  /// while it is set joins it.
  static var group: AnimationGroup? {
    get { ThreadState.current.transactionGroup }
    set { ThreadState.current.transactionGroup = newValue }
  }
}

/// The animations one `withAnimation(_:_:completion:)` started, and what to run once they are
/// all over.
///
/// Counts rather than lists: an animation joins when the animator starts it and leaves however it
/// ends — arriving, replaced by another, cancelled, or snapped by an unmount. A layout pass the
/// body caused holds the group too, until the slides it starts have joined.
final class AnimationGroup {
  private var remaining = 0
  /// True while the body runs: the group cannot be over before everything in it has started.
  private var open = true
  private var completion: (() -> Void)?

  init(_ completion: @escaping () -> Void) {
    self.completion = completion
  }

  func retain() {
    self.remaining += 1
  }

  /// Hands the completion to `schedule` once the last member leaves a closed group.
  func release(_ schedule: (@escaping () -> Void) -> Void) {
    self.remaining -= 1
    if self.remaining == 0, !self.open, let completion = self.takeCompletion() {
      schedule(completion)
    }
  }

  /// Called when the body returns. With nothing animating, the completion runs right away.
  func close() {
    self.open = false
    if self.remaining == 0, let completion = self.takeCompletion() {
      completion()
    }
  }

  private func takeCompletion() -> (() -> Void)? {
    defer { self.completion = nil }
    return self.completion
  }
}

/// Animates every change the writes in `body` cause, except where an `.animation(_:value:)`
/// scope already decides how that change animates.
///
/// ```swift
/// .onTap { _ in
///   withAnimation(.spring()) { self.size = self.size == 24 ? 48 : 24 }
/// }
/// ```
///
/// Nested calls restore the outer animation on the way out. SwiftUI declares a function with the
/// same name, so a file importing both must write `MetalGraphicsLib.withAnimation`.
@discardableResult
public func withAnimation<Result>(
  _ animation: UIAnimation? = .default, _ body: () throws -> Result
) rethrows -> Result {
  let state = ThreadState.current
  let previous = state.transactionAnimation
  state.transactionAnimation = animation
  defer { state.transactionAnimation = previous }

  return try body()
}

/// Like `withAnimation(_:_:)`, then runs `completion` once everything the body started animating
/// is over: every animation it started has arrived, been replaced or been cancelled, and every
/// row it moved has finished sliding.
///
/// ```swift
/// withAnimation(.easeOut(0.3)) { self.removeItems(at: 0) } completion: { self.removed += 1 }
/// ```
///
/// When nothing animates, `completion` runs as soon as the body returns; otherwise it runs from
/// the frame loop. An animation that repeats forever never completes.
@discardableResult
public func withAnimation<Result>(
  _ animation: UIAnimation? = .default, _ body: () throws -> Result,
  completion: @escaping () -> Void
) rethrows -> Result {
  let state = ThreadState.current
  let previousAnimation = state.transactionAnimation
  let previousGroup = state.transactionGroup
  let group = AnimationGroup(completion)
  state.transactionAnimation = animation
  state.transactionGroup = group
  defer {
    state.transactionAnimation = previousAnimation
    state.transactionGroup = previousGroup
    group.close()
  }

  return try body()
}
