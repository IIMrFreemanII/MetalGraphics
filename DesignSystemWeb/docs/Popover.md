---
category: Surfaces
---

# Popover

A glass card: popover material, radius 10, a 0.5 pt separator hairline and the popover shadow. Place it 4 px from its anchor.

Mirrors `Popover in place, .popover to present (Presentation/Surfaces.swift)` in MetalGraphics.

## Props

No props of its own; `className` and `style` place it.

Every component also takes `className` and `style`. Most take `state` (`"hover" | "pressed" | "focused" | "disabled"`) to draw a state without a pointer on it.

## Example

```jsx
<Popover style={{ padding: 14, width: 220 }}>
  <LabeledContent label="Line" value="42" />
</Popover>
```
