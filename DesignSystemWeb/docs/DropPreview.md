---
category: Docking
---

# DropPreview

Where a dropped panel lands: the accent at 18% with a 2pt ring. Place it over the target area.

Mirrors `DropPreview (Docking/DockChrome.swift)` in MetalGraphics.

## Props

No props of its own; `className` and `style` place it.

Every component also takes `className` and `style`. Most take `state` (`"hover" | "pressed" | "focused" | "disabled"`) to draw a state without a pointer on it.

## Example

```jsx
<DropPreview style={{ width: 200, height: 120 }} />
```
