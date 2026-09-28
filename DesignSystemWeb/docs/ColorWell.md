---
category: Controls
---

# ColorWell

The 44 × 24 well on the control-button fill: the colour on a radius-3 patch, a checkerboard under it when translucent.

Mirrors `ColorWell (Form/ColorPicker.swift)` in MetalGraphics.

## Props

| Prop | Type | |
|---|---|---|
| `color` | CSS colour |  |
| `opacity` | number |  |
| `label` | string |  |

Every component also takes `className` and `style`. Most take `state` (`"hover" | "pressed" | "focused" | "disabled"`) to draw a state without a pointer on it.

## Example

```jsx
<ColorWell color="var(--mg-hue-orange)" />
```
