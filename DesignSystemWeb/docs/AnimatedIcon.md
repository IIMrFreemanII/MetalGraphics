---
category: Foundations
---

# AnimatedIcon

Sixty-three animated glyphs, as the Claude Design template "Animated icons" draws them: each in its own box (the static icon's size at scale 1), in the text colour or a role, on one spring. The pointer on its host (the button, link or row it sits in, or an element marked `data-icon-host`) plays it: a one-shot as it enters, a pose held while it stays, a squash while pressed. `active` holds a state (a chevron turned, a folder open, a lock undone, a bell badged); left out, the glyph has none (the checkmark drawn, sort unsorted). `loop` repeats a motion (the gear, the bell, a warning); `mount` plays an entrance (a problem's icon appearing). Every component draws its glyphs with it (a disclosure's chevron, a pop-up's arrows, checks, a stepper's keys, a tab's document and close cross), and an `icon` prop given a static name draws the animated glyph of that name. Documents carry their type: `swift`, `fileImage`… `fileFont`, and a language's badge, `langJS`… `langShell`.

Mirrors `AnimatedIcon, AnimatedGlyph` in MetalGraphics.

## Props

| Prop | Type | |
|---|---|---|
| `glyph` | "chevronRight" \| "chevronDown" \| "chevronLeft" \| "upDown" \| "checkmark" \| "folder" \| "document" \| "magnifier" \| "xmark" \| "plus" \| "trash" \| "gear" \| "searchClear" \| "spinner" \| "copyCheck" \| "bell" \| "lock" \| "eye" \| "playPause" \| "refresh" \| "menuX" \| "warning" \| "error" \| "note" \| "pin" \| "sort" \| "stepperMinus" \| "stepperPlus" \| "splitRight" \| "splitBottom" \| "splitLeft" \| "splitTop" \| "sidebarLeft" \| "sidebarRight" \| "swift" \| "fileImage" \| "fileVideo" \| "fileAudio" \| "fileArchive" \| "fileCode" \| "fileJSON" \| "fileSheet" \| "filePDF" \| "fileFont" \| "langJS" \| "langTS" \| "langPY" \| "langRS" \| "langGO" \| "langC" \| "langCPP" \| "langRB" \| "langKT" \| "langJava" \| "langMetal" \| "langShell" \| "calendar" \| "clock" \| "color" \| "slider" \| "toggle" \| "code" \| "dock" | Which glyph. |
| `active` | boolean | Its state: true or false. Left out, it has none. |
| `trigger` | "hover" \| "click" \| "none" | "click": a click on the host toggles `active` too; "none": the host's pointer does nothing. |
| `loop` | boolean | Repeats its motion, where it has one. |
| `mount` | boolean | Plays its entrance as it appears. |
| `replay` | number | A changed value plays the entrance again. |
| `scale` | number | Its size is its box times this: 1 by default, 1.15 to 1.3 in a toolbar. |
| `size` | number | Fits its box's longer side to this many pixels, instead of scale. |
| `color` | colour role or hue name | e.g. "secondaryLabel", "accent", "folder". The text colour when left out. |
| `fill | badge | check | swift | fileType` | colour role or hue name | Colours for its tintable parts: a split's or the dock's fill, the bell's badge, the copied check, the Swift bird, a document's type. |
| `speed` | number | Motion speed, 1 by default. |
| `label` | string | An accessible name; without it the glyph is hidden from assistive tech. |

Every component also takes `className` and `style`. Most take `state` (`"hover" | "pressed" | "focused" | "disabled"`) to draw a state without a pointer on it.

## Example

```jsx
<ListRow label="Sources" detail="3">
  <AnimatedIcon glyph="chevronRight" active={open} color="secondaryLabel" />
  <AnimatedIcon glyph="folder" active={open} color="folder" />
</ListRow>
<Button variant="plain" label="Notifications"><AnimatedIcon glyph="bell" active scale={1.15} badge="destructive" /></Button>
```
