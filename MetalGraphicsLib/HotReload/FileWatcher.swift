#if DEBUG
import CoreServices
import Foundation

/// Watches a directory tree with FSEvents and reports the files with the given extensions that
/// changed, one batch per burst of saves (the stream's latency coalesces them).
///
/// File-level events catch both an atomic save (a temp file renamed over the original, as Xcode
/// does) and an in-place write; a vnode source on the directory only sees the first.
final class FileWatcher: @unchecked Sendable {
  private let directory: URL
  private let extensions: Set<String>
  private let onChange: @Sendable ([URL]) -> Void
  private var stream: FSEventStreamRef?

  /// `onChange` runs on `queue`, never on the main thread.
  init(directory: URL, extensions: Set<String>, queue: DispatchQueue, onChange: @escaping @Sendable ([URL]) -> Void) {
    self.directory = directory
    self.extensions = extensions
    self.onChange = onChange

    var context = FSEventStreamContext(
      version: 0, info: Unmanaged.passUnretained(self).toOpaque(), retain: nil, release: nil, copyDescription: nil
    )
    let callback: FSEventStreamCallback = { _, info, count, paths, _, _ in
      guard let info else { return }
      let watcher = Unmanaged<FileWatcher>.fromOpaque(info).takeUnretainedValue()
      // `kFSEventStreamCreateFlagUseCFTypes` makes `paths` a CFArray of CFStrings.
      let paths = Unmanaged<CFArray>.fromOpaque(paths).takeUnretainedValue() as? [String] ?? []
      watcher.handle(paths.prefix(count))
    }
    let flags = kFSEventStreamCreateFlagFileEvents | kFSEventStreamCreateFlagUseCFTypes | kFSEventStreamCreateFlagNoDefer
    guard let stream = FSEventStreamCreate(
      nil, callback, &context, [directory.path] as CFArray,
      FSEventStreamEventId(kFSEventStreamEventIdSinceNow), 0.1, FSEventStreamCreateFlags(flags)
    ) else {
      print("🔥 HotReload: could not watch \(directory.path)")
      return
    }
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
    var seen = Set<String>()
    let changed = paths.compactMap { path -> URL? in
      let url = URL(fileURLWithPath: path)
      // An atomic save also reports the temp file and the removed original; only files that
      // exist now, with a watched extension, count.
      guard self.extensions.contains(url.pathExtension),
            seen.insert(path).inserted,
            FileManager.default.fileExists(atPath: path)
      else { return nil }
      return url
    }
    guard !changed.isEmpty else { return }
    self.onChange(changed)
  }
}
#endif
