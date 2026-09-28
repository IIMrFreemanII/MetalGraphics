---
category: Controls
---

# Stepper

− and + keys; a key at the end of the range dims to 0.3.

Mirrors `Stepper` in MetalGraphics.

## Props

| Prop | Type | |
|---|---|---|
| `defaultValue / value` | number |  |
| `min, max, step` | number |  |

Every component also takes `className` and `style`. Most take `state` (`"hover" | "pressed" | "focused" | "disabled"`) to draw a state without a pointer on it.

## Example

```jsx
<Stepper defaultValue={4} min={0} max={8} label="Tab width" />
```
