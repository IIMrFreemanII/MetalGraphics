# Hot reload

Save a file and the running Debug app updates in about a second, on the same screen. Everything
here is `#if DEBUG` (see `MetalGraphicsLib/HotReload/`). Release is unaffected.

| You edit | What happens | Measured |
|---|---|---|
| Swift in `GPURayMarching/` or `MetalGraphicsLib/` | InjectionNext recompiles the file, rebinds its functions and patches the class vtables. `ViewRenderer.hotReload()` then rebuilds the UI tree. | 0.4–1 s |
| `MetalGraphicsLib/Shaders/*.metal`, `*.h` | `ShaderReloader` recompiles the Metal library and swaps `Graphics2D`'s pipelines. | 0.8–2 s |
| `ReactiveUIMacros/Sources/ReactiveUIMacrosPlugin/*` | `MacroReloader` rebuilds the plugin, puts it where Xcode's compile commands load it, and re-injects every `@Component` file. The UI rebuilds once at the end. | ~8 s + ~1 s per component file |

After a rebuild, the app reopens on the screen you were on. Components read their navigation
state from `UIStorage`, a store backed by `UserDefaults`, similar to SwiftUI's `@SceneStorage`.
`Demos` keeps the selected tab there, so the tab also survives a relaunch. Anything not stored
there, such as scroll offsets or text field contents, resets.

## Setup

1. Install **InjectionNext** (github.com/johnno1962/InjectionNext, Releases) into `/Applications`
   and start it.
2. Build and run the `GPURayMarching` scheme in the **Debug** configuration. The console shows
   `🔥 HotReload: loaded …/macOSInjection.bundle`. The scheme sets
   `INJECTION_PROJECT_ROOT=$(SRCROOT)`, so InjectionNext starts watching the repository on its own.
   Its menu bar icon turns orange once the app connects.
3. After a clean build, choose **InjectionNext ▸ Unhide Symbols**, then build again. See
   "Default arguments" below for why.

InjectionNext reads compile commands from Xcode's build logs. Build with Xcode, or with
`xcodebuild` without a custom `-derivedDataPath`, so the logs land in the default DerivedData.

### Why the Debug settings are what they are

- **`OTHER_LDFLAGS = -Xlinker -interposable`**, set at project level so both targets inherit it:
  injected functions replace the old ones by interposing.
- **`EMIT_FRONTEND_COMMAND_LINES = YES`**: Xcode 16.3 and later only log per-file compile
  commands with this setting.
- **App Sandbox and hardened runtime off.** The injection bundle is signed by another team, and
  library validation refuses it. `xcrun` and the Metal compiler refuse to run inside a sandbox.
- **`BUILD_LIBRARY_FOR_DISTRIBUTION = NO` for MetalGraphicsLib.** With library evolution on,
  every subclass of a library class gets runtime-initialised metadata and no static class symbol.
  InjectionNext then cannot find the class, so it cannot patch its vtable. Overrides such as
  `mount` and `render`, and the private builders they call, would keep running the old code.

### Macro plugin: the zero-length message

The Swift 6.4 compiler ends each plugin session with a zero-length message. swift-syntax 602 (the
version pinned in `Package.swift`) cannot decode it, so it prints `Internal Error: … unexpected end
of file` after every compile. Builds ignore this, but InjectionNext treats any `error: ` in
compiler output as a failed compile. `ReactiveUIMacrosPlugin/StdinFilter.swift` turns that message
into a clean end of input. Remove the filter once swift-syntax is bumped past 602.

### Default arguments

Swift emits default-argument generators as *private external* symbols. A statically linked
image can use them, but a dynamically loaded one cannot. Injecting a file that relies on a
library default, such as `Square(position:size:color:)` without `rotation`, fails with
`symbol not found in flat namespace '…A1_'`. **Unhide Symbols** marks these symbols as exported
in the object files in DerivedData, and the next build links them that way. Run it again after
a clean build. Alternatively, pass the argument explicitly.

## What needs a relaunch

- **Changes to the stored layout of a class**, meaning adding or removing a stored property. That
  includes a new `@State`, and any `body` or macro change that adds a generated node field, such
  as a new reactive read of state.
- **Adding or removing methods or overrides in a non-final class**, for example the `UIElement`
  hierarchy. The vtable's shape is fixed. Changing the *body* of an existing override is fine.
- **Swift and Metal shared struct layouts.**
- **Macro declarations in the `ReactiveUI` target** (roles, names).
- **The bake kernels** (`bakeSDF`, `bakeVectorSDF`). Atlases that were already baked would not
  change anyway.

## Quirks

- InjectionNext sometimes misses the first save after the app connects. Save again.
- InjectionNext also watches the macro plugin's own sources. When you edit one, it tries to inject
  that file into the app and fails with a `dlopen` or compile error. That error is harmless;
  `MacroReloader` handles those files.
- Injected classes log `Class … is implemented in both …`. That line is expected.

## How it fits the frame loop

Nothing runs per frame. FSEvents and the injection socket wait on background threads, and
compiling happens off the main thread. The main thread does one thing per reload: it either
swaps the pipelines and invalidates `.render`, or it rebuilds the tree with `setChild`, which
invalidates `[.layout, .treeOrder]`. A macro reload's burst of injections produces a single
rebuild. When nothing changes, the app stays idle.
