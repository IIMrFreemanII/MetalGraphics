---
category: Foundations
---

# ScrollIndicator

A scroll bar thumb: 5 thick, square ends, placed 2 from the edge.

Mirrors `ScrollIndicator (Layout/ScrollIndicator.swift); a ScrollView draws its own` in MetalGraphics.

## Props

| Prop | Type | |
|---|---|---|
| `length` | number | Length in px, at least 20. |
| `vertical` | boolean | Default true. |

Every component also takes `className` and `style`. Most take `state` (`"hover" | "pressed" | "focused" | "disabled"`) to draw a state without a pointer on it.

## Example

```jsx
<ScrollIndicator length={80} style={{ position: "absolute", right: 2, top: 8 }} />
```
