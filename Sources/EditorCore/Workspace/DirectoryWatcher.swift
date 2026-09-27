import CoreServices
import Foundation

/// Watches a folder tree with FSEvents and reports the paths that changed, in batches: one per
/// burst of changes, `latency` seconds after it started. Paths inside folders the scanner leaves
/// out (`.build`, `.git`, `build`, …) are not reported, so a build does not wake it for every
/// object file.
///
/// File-level events catch atomic saves (a temp file renamed over the original) as well as writes
/// in place.
public final class DirectoryWatcher: @unchecked Sendable {
  private let root: String
  /// The root with its symbolic links resolved, which is how FSEvents reports paths: `/var` is
  /// `/private/var`. Reported paths are given back under `root`, as the caller named it.
  private let realRoot: String
  private let onChange: @Sendable ([String]) -> Void
  private var stream: FSEventStreamRef?

  /// `onChange` runs on `queue`.
  public init?(
    _ root: String, latency: Double = 0.3, queue: DispatchQueue = DispatchQueue(label: "DirectoryWatcher", qos: .utility),
    onChange: @escaping @Sendable ([String]) -> Void
  ) {
    let root = root.hasSuffix("/") ? String(root.dropLast()) : root
    self.root = root
    self.realRoot = realpath(root, nil).map { pointer in
      defer { free(pointer) }
      return String(cString: pointer)
    } ?? root
    self.onChange = onChange
    var context = FSEventStreamContext(
      version: 0, info: Unmanaged.passUnretained(self).toOpaque(), retain: nil, release: nil, copyDescription: nil
    )
    let callback: FSEventStreamCallback = { _, info, count, paths, _, _ in
      guard let info else { return }
      let watcher = Unmanaged<DirectoryWatcher>.fromOpaque(info).takeUnretainedValue()
      // `kFSEventStreamCreateFlagUseCFTypes` makes `paths` a CFArray of CFStrings.
      let paths = Unmanaged<CFArray>.fromOpaque(paths).takeUnretainedValue() as? [String] ?? []
      watcher.handle(paths.prefix(count))
    }
    let flags = kFSEventStreamCreateFlagFileEvents | kFSEventStreamCreateFlagUseCFTypes
    guard let stream = FSEventStreamCreate(
      nil, callback, &context, [self.realRoot] as CFArray,
      FSEventStreamEventId(kFSEventStreamEventIdSinceNow), latency, FSEventStreamCreateFlags(flags)
    ) else { return nil }
    self.stream = stream
    FSEventStreamSetDispatchQueue(stream, queue)
    FSEventStreamStart(stream)
  }

  deinit {
    guard let stream else { return }
    FSEventStreamStop(stream)
    FSEventStreamInvalidate(stream)
    FSEventStreamRelease(stream)
  }

  private func handle(_ paths: ArraySlice<String>) {
    let changed = Set(paths.map(self.callersPath).filter { self.isWatched($0) })
    guard !changed.isEmpty else { return }
    self.onChange(changed.sorted())
  }

  /// `path`, reported under the real root, under the root as the caller named it.
  func callersPath(_ path: String) -> String {
    guard self.realRoot != self.root, path.hasPrefix(self.realRoot + "/") else { return path }
    return self.root + path.dropFirst(self.realRoot.count)
  }

  /// Whether `path` is inside the root, and in no folder the scanner leaves out.
  func isWatched(_ path: String) -> Bool {
    guard path.hasPrefix(self.root + "/") else { return false }
    let relative = path.dropFirst(self.root.count + 1)
    return !relative.split(separator: "/").contains { WorkspaceScanner.isIgnored(String($0)) }
  }
}
