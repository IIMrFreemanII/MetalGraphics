---
category: Controls
---

# ColorPickerPanel

What a colour well opens: 12 hues in three shades and a row of greys (16pt swatches, the selection ringed), then Hue, Saturation, Brightness and Opacity sliders.

Mirrors `ColorPickerPanel (Form/ColorPicker.swift)` in MetalGraphics.

## Props

| Prop | Type | |
|---|---|---|
| `selected` | [row, column] |  |
| `hue, saturation, brightness` | number | 0…1. |
| `opacity` | number | Shows the Opacity slider. |

Every component also takes `className` and `style`. Most take `state` (`"hover" | "pressed" | "focused" | "disabled"`) to draw a state without a pointer on it.

## Example

```jsx
<Popover><ColorPickerPanel selected={[1, 7]} opacity={1} /></Popover>
```
