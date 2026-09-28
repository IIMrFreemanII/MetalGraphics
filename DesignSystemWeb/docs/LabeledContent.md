---
category: Controls
---

# LabeledContent

A label and its value, the value in the secondary colour.

Mirrors `LabeledContent` in MetalGraphics.

## Props

| Prop | Type | |
|---|---|---|
| `label` | string |  |
| `value` | string | Or children. |

Every component also takes `className` and `style`. Most take `state` (`"hover" | "pressed" | "focused" | "disabled"`) to draw a state without a pointer on it.

## Example

```jsx
<LabeledContent label="Version" value="1.0" />
```
