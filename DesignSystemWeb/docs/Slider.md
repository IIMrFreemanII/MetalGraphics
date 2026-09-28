---
category: Controls
---

# Slider

A 4 pt track, the accent up to an 18 pt knob.

Mirrors `Slider` in MetalGraphics.

## Props

| Prop | Type | |
|---|---|---|
| `defaultValue / value` | number | 0…1 unless min and max say otherwise. |
| `min, max` | number |  |
| `width` | number | Default 180. |

Every component also takes `className` and `style`. Most take `state` (`"hover" | "pressed" | "focused" | "disabled"`) to draw a state without a pointer on it.

## Example

```jsx
<Slider defaultValue={0.4} label="Volume" />
```
