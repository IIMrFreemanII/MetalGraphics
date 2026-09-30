---
category: Controls
---

# TimePanel

What a compact date picker's time pill opens: hour and minute steppers, 180 wide.

Mirrors `TimePanel (Form/DatePicker.swift)` in MetalGraphics.

## Props

| Prop | Type | |
|---|---|---|
| `date` | string |  |

Every component also takes `className` and `style`. Most take `state` (`"hover" | "pressed" | "focused" | "disabled"`) to draw a state without a pointer on it.

## Example

```jsx
<Popover><TimePanel date="2026-09-28T14:30" /></Popover>
```
