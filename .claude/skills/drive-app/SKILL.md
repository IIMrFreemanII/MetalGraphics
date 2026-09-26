---
name: drive-app
description: Build, launch and drive the GPURayMarching macOS app with real clicks, hovers and key presses, then screenshot it. Slow (seconds per click and shot) and it takes over the mouse, so prefer the ui-tests skill (headless, seconds per suite) for checking layout, input, focus, animation and rendering logic. Use this for what the headless tests cannot see: real NSEvent input, windowing and resizing, hot reload, frame pacing and idle CPU, the @Component demos, a final end-to-end check of a finished feature, or when asked to run or screenshot the app.
---

# Driving GPURayMarching

The app is macOS-only and draws its UI with Metal, so there is no accessibility tree to query:
you look at screenshots and act on window coordinates. `Tools/uidrive` posts real window-server
events, which reach the app exactly like a user's (all input comes from `MyMTKView`'s `NSEvent`
handlers — never GameController).

Use a scratch directory for everything below (`$S`); nothing here belongs in the repo.

## 1. Build and launch

```bash
xcodebuild -project MetalGraphics.xcodeproj -scheme GPURayMarching -configuration Debug \
  -destination 'platform=macOS' -derivedDataPath "$S/dd" build 2>&1 | grep -E "error:|BUILD"
pkill -x GPURayMarching
(NSUnbufferedIO=YES "$S/dd/Build/Products/Debug/GPURayMarching.app/Contents/MacOS/GPURayMarching" > "$S/run.log" 2>&1 &)
sleep 3
```

`NSUnbufferedIO=YES` makes `print` reach the log immediately; without it stdout is block
buffered and log timestamps are useless for timing. Never truncate the log while the app runs
(it keeps writing at its old offset and the file fills with NULs) — count lines instead.

## 2. Compile the driver

```bash
swiftc -O Tools/uidrive/main.swift -o "$S/uidrive"
```

## 3. Drive and look

```bash
U="$S/uidrive"
$U activate                 # hover tracking needs the key window: do this first
$U shot "$S/a.png"          # whole window, at 1x
$U click 451 65             # coordinates read straight off that screenshot
$U shot "$S/b.png" 0 40 700 380   # crop x y w h, in the same coordinates
```

Then Read the PNG. Screenshots are saved at 1x, so **a pixel in the image is a window point**:
read a position off the image and pass it to `click`/`move` unchanged. A cropped shot is offset
by its crop origin — add it back.

Commands: `activate`, `bounds`, `move X Y`, `click X Y [COUNT]`, `rightclick X Y`,
`drag X1 Y1 X2 Y2`, `scroll X Y DX DY [STEPS]`, `key TEXT`, `keycode CODE [cmd|shift|alt|ctrl ...]`, `shot FILE [X Y W H]`.
The header of `Tools/uidrive/main.swift` documents each.

## Notes

- The window's top-left includes the title bar; the retained UI starts below it, at the Metal
  view's top-left. The SwiftUI inspector on the right is not part of the Metal UI.
- A click takes ~235 ms to return (move, down, up), and a tap fires on mouse down, ~55 ms in.
  A `shot` takes ~350 ms. An animation of 0.3 s is therefore over before a shot taken after
  `click` lands. To catch short motion, start several shots in the background with staggered
  sleeps *before* clicking:
  `( for d in 0.05 0.12 0.2 0.3; do (sleep $d; $U shot $S/f_$d.png …) & done; wait ) & $U click …; wait`
  then measure the frames with PIL. Or lengthen the animation temporarily (e.g. to 2.5 s) and
  take shots 0.3 s apart. To see it settled, wait ~1.2 s past its duration.
- Pixels can be measured instead of eyeballed: PIL is available (`python3 -c "from PIL import Image"`).
- Several screenshots can be stitched into one contact sheet with PIL to review a sequence.
- Posting events needs Accessibility permission for the process running `uidrive`. If clicks do
  nothing and `bounds` works, that permission is the first thing to check.
- In zsh, a glob that matches nothing aborts the whole line. Don't start a script with
  `rm $S/shot_*.png`; use `rm -f` on explicit names or `find -delete`.
- Hot reload (`MetalGraphicsLib/docs/HotReload.md`): with a Debug build running, saving a file in
  `MetalGraphicsLib/Shaders/` recompiles and swaps the shaders in ~1 s (watch `$S/run.log` for
  `🔥 HotReload: shaders reloaded`), so a shader tweak needs no rebuild or relaunch — edit, wait,
  `shot`. Swift and macro edits reload too when InjectionNext is running, but only for a build in
  the *default* DerivedData (InjectionNext reads its build logs): build without
  `-derivedDataPath`, and launch with
  `open -n <app> --env INJECTION_PROJECT_ROOT=$PWD --env NSUnbufferedIO=YES --stdout $S/run.log --stderr $S/run.log`
  (via `open`, so neither the app nor InjectionNext inherits the shell's sandbox). Save with a
  rename (`sed -i ''`, or write a temp file and `mv`); InjectionNext ignores in-place writes, and
  may miss the first save after launch. Look for `✅ Hot reload complete` then
  `🔥 HotReload: rebuilding the UI tree` before taking the shot. The selected demo tab is restored
  from `UIStorage`, so after a rebuild or relaunch the app opens on the last tab rather than Text.
