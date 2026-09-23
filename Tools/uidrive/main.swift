// uidrive: drives the running GPURayMarching app with real window-server events.
//
// Coordinates are points relative to the app window's top-left corner (title bar included).
// `shot` saves the window at 1x, so a pixel in the screenshot is a point here: read a position
// off the image and pass it straight to `click`.
//
//   swiftc -O Tools/uidrive/main.swift -o <dir>/uidrive
//
//   uidrive activate                     bring the app to the front (hover needs the key window)
//   uidrive bounds                       print the window id and frame
//   uidrive move X Y
//   uidrive click X Y [COUNT]            COUNT 2 for a double click
//   uidrive rightclick X Y
//   uidrive drag X1 Y1 X2 Y2
//   uidrive key TEXT                     types TEXT (letters, digits, space, return)
//   uidrive keycode CODE [cmd|shift|alt|ctrl ...]   one kVK_* key, with modifiers held
//   uidrive shot FILE [X Y W H]          screenshot of the window, optionally cropped
//
// Posting events needs Accessibility permission for the process that runs this.

import AppKit
import CoreGraphics
import Foundation

let appName = "GPURayMarching"

func fail(_ message: String) -> Never {
  FileHandle.standardError.write((message + "\n").data(using: .utf8)!)
  exit(1)
}

// MARK: - Window

struct Window {
  let id: CGWindowID
  let frame: CGRect
}

/// The app's largest on-screen normal window.
func findWindow() -> Window {
  guard let list = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID)
    as? [[String: Any]]
  else { fail("cannot list windows") }

  let windows = list.compactMap { info -> Window? in
    guard info[kCGWindowOwnerName as String] as? String == appName,
          info[kCGWindowLayer as String] as? Int == 0,
          let id = info[kCGWindowNumber as String] as? CGWindowID,
          let boundsDict = info[kCGWindowBounds as String] as? NSDictionary,
          let frame = CGRect(dictionaryRepresentation: boundsDict)
    else { return nil }
    return Window(id: id, frame: frame)
  }
  guard let window = windows.max(by: { $0.frame.width * $0.frame.height < $1.frame.width * $1.frame.height })
  else { fail("\(appName) has no window on screen — is it running?") }
  return window
}

func screenPoint(_ x: String, _ y: String) -> CGPoint {
  guard let x = Double(x), let y = Double(y) else { fail("coordinates must be numbers") }
  let frame = findWindow().frame
  return CGPoint(x: frame.minX + x, y: frame.minY + y)
}

// MARK: - Mouse

func post(_ type: CGEventType, _ point: CGPoint, button: CGMouseButton = .left, clickState: Int64 = 1) {
  guard let event = CGEvent(mouseEventSource: nil, mouseType: type, mouseCursorPosition: point, mouseButton: button)
  else { fail("cannot create mouse event") }
  event.setIntegerValueField(.mouseEventClickState, value: clickState)
  event.post(tap: .cghidEventTap)
}

// Not `pause`: that name is libc's wait-for-a-signal, which a no-argument call resolves to.
func sleepMs(_ ms: UInt32 = 50) {
  usleep(ms * 1000)
}

func click(_ point: CGPoint, count: Int, right: Bool = false) {
  post(.mouseMoved, point)
  sleepMs()
  for n in 1 ... max(count, 1) {
    post(right ? .rightMouseDown : .leftMouseDown, point, button: right ? .right : .left, clickState: Int64(n))
    sleepMs()
    post(right ? .rightMouseUp : .leftMouseUp, point, button: right ? .right : .left, clickState: Int64(n))
    sleepMs()
  }
}

func drag(from: CGPoint, to: CGPoint) {
  post(.mouseMoved, from)
  sleepMs()
  post(.leftMouseDown, from)
  sleepMs()
  let steps = 12
  for step in 1 ... steps {
    let t = CGFloat(step) / CGFloat(steps)
    post(.leftMouseDragged, CGPoint(x: from.x + (to.x - from.x) * t, y: from.y + (to.y - from.y) * t))
    sleepMs(16)
  }
  post(.leftMouseUp, to)
}

// MARK: - Keyboard

/// The ANSI virtual key code for a character `key` can type; its case comes from the unicode
/// string attached to the event.
func keyCode(for character: Character) -> CGKeyCode? {
  let letters: [Character: CGKeyCode] = [
    "a": 0x00, "s": 0x01, "d": 0x02, "f": 0x03, "h": 0x04, "g": 0x05, "z": 0x06, "x": 0x07,
    "c": 0x08, "v": 0x09, "b": 0x0B, "q": 0x0C, "w": 0x0D, "e": 0x0E, "r": 0x0F, "y": 0x10,
    "t": 0x11, "o": 0x1F, "u": 0x20, "i": 0x22, "p": 0x23, "l": 0x25, "j": 0x26, "k": 0x28,
    "n": 0x2D, "m": 0x2E,
    "1": 0x12, "2": 0x13, "3": 0x14, "4": 0x15, "6": 0x16, "5": 0x17, "9": 0x19, "7": 0x1A,
    "8": 0x1C, "0": 0x1D,
    " ": 0x31, "\n": 0x24, "\r": 0x24,
  ]
  return letters[Character(character.lowercased())]
}

/// kVK_RightCommand ... kVK_RightControl, plus kVK_Command/Shift/CapsLock/Option/Control.
let modifierKeyCodes: ClosedRange<CGKeyCode> = 0x36 ... 0x3E

func postKey(_ code: CGKeyCode, flags: CGEventFlags = [], text: String? = nil) {
  for down in [true, false] {
    guard let event = CGEvent(keyboardEventSource: nil, virtualKey: code, keyDown: down)
    else { fail("cannot create key event") }
    // A modifier key posts as `flagsChanged`: its own flag has to go when it is released.
    event.flags = !down && modifierKeyCodes.contains(code) ? [] : flags
    if let text {
      let units = Array(text.utf16)
      event.keyboardSetUnicodeString(stringLength: units.count, unicodeString: units)
    }
    event.post(tap: .cghidEventTap)
    sleepMs(30)
  }
}

func type(_ text: String) {
  for character in text {
    guard let code = keyCode(for: character) else { fail("cannot type '\(character)'") }
    let flags: CGEventFlags = character.isUppercase ? .maskShift : []
    postKey(code, flags: flags, text: String(character))
  }
}

func modifierFlags(_ names: ArraySlice<String>) -> CGEventFlags {
  var flags: CGEventFlags = []
  for name in names {
    switch name {
    case "cmd": flags.insert(.maskCommand)
    case "shift": flags.insert(.maskShift)
    case "alt": flags.insert(.maskAlternate)
    case "ctrl": flags.insert(.maskControl)
    default: fail("unknown modifier '\(name)'")
    }
  }
  return flags
}

// MARK: - Screenshot

func run(_ path: String, _ arguments: [String]) {
  let process = Process()
  process.executableURL = URL(fileURLWithPath: path)
  process.arguments = arguments
  process.standardOutput = FileHandle.nullDevice
  do { try process.run() } catch { fail("cannot run \(path): \(error)") }
  process.waitUntilExit()
  guard process.terminationStatus == 0 else { fail("\(path) failed") }
}

/// The window at 1x, so pixels are points; cropped to a rect in points when one is given.
func shot(_ file: String, crop: [String]) {
  let window = findWindow()
  run("/usr/sbin/screencapture", ["-x", "-o", "-l", String(window.id), file])
  run("/usr/bin/sips", [
    "-z", String(Int(window.frame.height)), String(Int(window.frame.width)), file,
  ])
  if crop.count == 4 {
    let numbers = crop.compactMap { Int($0) }
    guard numbers.count == 4 else { fail("crop must be four integers") }
    guard let image = NSImage(contentsOfFile: file),
          let cg = image.cgImage(forProposedRect: nil, context: nil, hints: nil),
          let cropped = cg.cropping(to: CGRect(x: numbers[0], y: numbers[1], width: numbers[2], height: numbers[3])),
          let data = NSBitmapImageRep(cgImage: cropped).representation(using: .png, properties: [:])
    else { fail("cannot crop \(file)") }
    do { try data.write(to: URL(fileURLWithPath: file)) } catch { fail("cannot write \(file)") }
  }
  print(file)
}

// MARK: - Main

let arguments = CommandLine.arguments.dropFirst()
guard let command = arguments.first else { fail("usage: see the header of Tools/uidrive/main.swift") }
let rest = Array(arguments.dropFirst())

switch command {
case "activate":
  guard let app = NSWorkspace.shared.runningApplications.first(where: { $0.localizedName == appName })
  else { fail("\(appName) is not running") }
  app.activate()
  sleepMs(300)
case "bounds":
  let window = findWindow()
  print("id \(window.id) x \(Int(window.frame.minX)) y \(Int(window.frame.minY)) w \(Int(window.frame.width)) h \(Int(window.frame.height))")
case "move" where rest.count == 2:
  post(.mouseMoved, screenPoint(rest[0], rest[1]))
case "click" where rest.count >= 2:
  click(screenPoint(rest[0], rest[1]), count: rest.count > 2 ? Int(rest[2]) ?? 1 : 1)
case "rightclick" where rest.count == 2:
  click(screenPoint(rest[0], rest[1]), count: 1, right: true)
case "drag" where rest.count == 4:
  drag(from: screenPoint(rest[0], rest[1]), to: screenPoint(rest[2], rest[3]))
case "key" where rest.count == 1:
  type(rest[0])
case "keycode" where rest.count >= 1:
  guard let code = CGKeyCode(rest[0]) else { fail("keycode must be a number") }
  postKey(code, flags: modifierFlags(rest.dropFirst()))
case "shot" where rest.count == 1 || rest.count == 5:
  shot(rest[0], crop: Array(rest.dropFirst()))
default:
  fail("bad arguments for '\(command)': see the header of Tools/uidrive/main.swift")
}
