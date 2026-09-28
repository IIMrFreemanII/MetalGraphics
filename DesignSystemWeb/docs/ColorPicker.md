---
category: Controls
---

# ColorPicker

A form row with a label and a 44 × 24 colour well. The well opens ColorPickerPanel in a Popover.

Mirrors `ColorPicker (Form/ColorPicker.swift)` in MetalGraphics.

## Props

| Prop | Type | |
|---|---|---|
| `label` | string |  |
| `color` | CSS colour | Any colour: a hue variable or a value (this is user content, not UI chrome). |
| `opacity` | number | Below 1 shows the checkerboard. |

Every component also takes `className` and `style`. Most take `state` (`"hover" | "pressed" | "focused" | "disabled"`) to draw a state without a pointer on it.

## Example

```jsx
<ColorPicker label="Tint" color="var(--mg-hue-teal)" />
```
