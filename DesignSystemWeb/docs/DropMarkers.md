---
category: Docking
---

# DropMarkers

The docking cross shown while a panel is dragged: 28pt markers 34 apart on drop-marker glass with an accent ring, each drawing its zone; the hovered one filled with the accent.

Mirrors `DropMarkers (Docking/DockChrome.swift)` in MetalGraphics.

## Props

| Prop | Type | |
|---|---|---|
| `hovered` | "left" \| "right" \| "top" \| "bottom" \| "center" |  |
| `zones` | DropZone[] | Default all five. |

Every component also takes `className` and `style`. Most take `state` (`"hover" | "pressed" | "focused" | "disabled"`) to draw a state without a pointer on it.

## Example

```jsx
<DropMarkers hovered="center" />
```
