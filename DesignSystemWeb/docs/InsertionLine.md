---
category: Lists
---

# InsertionLine

Where a dragged row would drop: a 2pt accent line across the list.

Mirrors `InsertionLine (Layout/InsertionLine.swift)` in MetalGraphics.

## Props

| Prop | Type | |
|---|---|---|
| `indent` | number | Inset from the list's edges, default 8. |

Every component also takes `className` and `style`. Most take `state` (`"hover" | "pressed" | "focused" | "disabled"`) to draw a state without a pointer on it.

## Example

```jsx
<InsertionLine />
```
