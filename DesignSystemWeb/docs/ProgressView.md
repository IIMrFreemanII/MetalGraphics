---
category: Controls
---

# ProgressView

A 6 pt capsule filled with the accent.

Mirrors `ProgressView(value:)` in MetalGraphics.

## Props

| Prop | Type | |
|---|---|---|
| `value` | number | 0…1. |
| `width` | number | Default 180. |

Every component also takes `className` and `style`. Most take `state` (`"hover" | "pressed" | "focused" | "disabled"`) to draw a state without a pointer on it.

## Example

```jsx
<ProgressView value={0.6} label="Indexing" />
```
