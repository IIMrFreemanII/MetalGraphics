---
category: Controls
---

# Toggle

A 38 × 22 switch; the accent when on, the knob sliding over 0.18 s.

Mirrors `Toggle` in MetalGraphics.

## Props

| Prop | Type | |
|---|---|---|
| `defaultOn / isOn` | boolean | Uncontrolled / controlled. |
| `label` | string | Accessible name. |
| `state` | "disabled" |  |

Every component also takes `className` and `style`. Most take `state` (`"hover" | "pressed" | "focused" | "disabled"`) to draw a state without a pointer on it.

## Example

```jsx
<Toggle defaultOn label="Show line numbers" />
```
