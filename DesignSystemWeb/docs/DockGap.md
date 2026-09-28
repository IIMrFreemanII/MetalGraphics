---
category: Docking
---

# DockGap

The 1 pt gap between docked panels, on the gap tint.

Mirrors `DockGap (Docking/DockChrome.swift)` in MetalGraphics.

## Props

| Prop | Type | |
|---|---|---|
| `vertical` | boolean | Default true. |

Every component also takes `className` and `style`. Most take `state` (`"hover" | "pressed" | "focused" | "disabled"`) to draw a state without a pointer on it.

## Example

```jsx
<div style={{ display: "flex", height: 120 }}>
  <div style={{ flex: 1 }} />
  <DockGap />
  <div style={{ flex: 1 }} />
</div>
```
