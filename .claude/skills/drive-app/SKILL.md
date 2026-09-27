---
name: drive-app
description: Build, launch and drive the Demo macOS app with real clicks, hovers and key presses, then screenshot it. Slow (seconds per click and shot) and it takes over the mouse, so prefer the ui-tests skill (headless, seconds per suite) for checking layout, input, focus, animation and rendering logic. Use this for what the headless tests cannot see: real NSEvent input, windowing and resizing, hot reload, frame pacing and idle CPU, the @Component demos, a final end-to-end check of a finished feature, or when asked to run or screenshot the app.
---

# Driving Demo

The app is macOS-only and draws its UI with Metal, so there is no accessibility tree to query:
you look at screenshots and act on window coordinates. `Tools/uidrive` posts real window-server
events, which reach the app exactly like a user's (all input comes from `RetainedLayerView`'s
`NSEvent` handlers — never GameController — and is applied on the window's own thread).

Use a scratch directory for everything below (`$S`); nothing here belongs in the repo.

## 1. Build and launch

```bash
swift build --product Demo 2>&1 | grep -E "error:|Compiling|Build complete"
pkill -x Demo
(NSUnbufferedIO=YES .build/debug/Demo > "$S/run.log" 2>&1 &)
sleep 3
```

The app is a bare executable, not an `.app` bundle: `UserDefaults` and `UIStorage` live in the
`Demo` preferences domain, and its window-server owner name is `Demo`. For Release, use
`swift build -c release --product Demo` and `.build/release/Demo`.

`NSUnbufferedIO=YES` makes `print` reach the log immediately; without it stdout is block
buffered and log timestamps are useless for timing. Never truncate the log while the app runs
(it keeps writing at its old offset and the file fills with NULs) — count lines instead.

## 2. Build the driver

```bash
swift build -c release --product uidrive
```

## 3. Drive and look

```bash
U=.build/release/uidrive
$U activate                 # hover tracking needs the key window: do this first
$U shot "$S/a.png"          # whole window, at 1x
$U click 451 65             # coordinates read straight off that screenshot
$U shot "$S/b.png" 0 40 700 380   # crop x y w h, in the same coordinates
```

Then Read the PNG. Screenshots are saved at 1x, so **a pixel in the image is a window point**:
read a position off the image and pass it to `click`/`move` unchanged. A cropped shot is offset
by its crop origin — add it back.

Commands: `windows`, `activate`, `bounds`, `move X Y`, `click X Y [COUNT]`, `rightclick X Y`,
`drag X1 Y1 X2 Y2 [STEPS [MS]]`, `scroll X Y DX DY [STEPS]`, `key TEXT`, `keycode CODE [cmd|shift|alt|ctrl ...]`, `shot FILE [X Y W H]`.
The header of `Tools/uidrive/main.swift` documents each.

### Several windows

Commands act on the app's frontmost window. `--window SEL` before a command (or
`UIDRIVE_WINDOW=SEL`) picks another: SEL is an index from `windows` (creation order, so it stays
put as windows are raised) or a title.

```bash
$U keycode 45 cmd                  # ⌘N: another Demos window
$U windows                         # 0 id 4220 'Demos' x … / 1 id 4231 'Demos' x …
$U --window 1 activate             # raise it and make it key
$U --window 1 click 48 521
$U --window 0 shot "$S/w0.png"     # a window behind others is captured all the same
```

- Events go to whatever is on screen at the point, so raise a window with `--window N activate`
  before clicking into it.
- The first click on a window that isn't key only activates it, as in any macOS app.
- Keys go to the key window.
- ⌘W closes the key window.

### Docking

The Workspace window (⌘⇧D, or the Docking demo) holds dock panels; `docs/Docking.md` covers
what a drag does.

- `drag X1 Y1 X2 Y2 STEPS MS` drags slowly. A tear-out or a window drag crosses threads before
  the window follows, so give it time: `40 40` works.
- Tear a panel out by dragging its tab past the window's edge (a negative or too-large
  coordinate). The new window appears in `windows` under the panel's title, or "N panels".
- To dock a detached window, drag its title bar (y 14 in a shot, in either look) or its tab onto a marker
  of another window. Only this app's windows count, frontmost first, so raise the target with
  `--window N activate` before raising the dragged one. A window listed in front of the target
  at that point, such as Demos, takes the drop instead. Markers are 28 pt: aim at the middle one's
  center (the group's center), or the drop just moves the window.
- `uidrive shot` captures a window even when it is covered, but the markers are drawn only in the
  window the pointer is over.
- Indices from `windows` follow creation order. Detached windows are made at launch, so they
  come first after a relaunch: list them again before acting.
- The layout is saved in the app's sandbox container, which `defaults` cannot read; use Reset
  layout on the Docking page to start over.

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
- Hot reload (`docs/HotReload.md`): with a Debug build running, saving a file in
  `Sources/MetalGraphicsLib/Shaders/` recompiles and swaps the shaders in ~1 s (watch `$S/run.log` for
  `🔥 HotReload: shaders reloaded`), so a shader tweak needs no rebuild or relaunch — edit, wait,
  `shot`. Swift and macro edits reload too when InjectionNext is running, but only for a build in
  the *default* DerivedData with per-file commands in its log (InjectionNext reads Xcode's build
  logs; `swift build` writes none): build and launch as in `docs/HotReload.md` ▸ Setup
  (`xcodebuild -scheme Demo -destination 'platform=macOS' EMIT_FRONTEND_COMMAND_LINES=YES build`,
  then the `Demo` in that DerivedData folder's `Build/Products/Debug`). Save with a
  rename (`sed -i ''`, or write a temp file and `mv`); InjectionNext ignores in-place writes, and
  may miss the first save after launch. Look for `✅ Hot reload complete` then
  `🔥 HotReload: rebuilding the UI tree in N window(s)` before taking the shot. Each window's
  selected demo tab is restored from its scene storage. After a rebuild the window stays on its
  tab; a new window, or a relaunch that restores no windows, opens on the last tab picked in any
  window rather than Text.
