---
category: Controls
---

# CalendarView

A month: title with ‹ ›, weekdays, six weeks of 32 × 28 days; the selection a 26pt accent circle, today in the accent, other months at 35%, out of range at 20%.

Mirrors `CalendarView (Form/DatePicker.swift)` in MetalGraphics.

## Props

| Prop | Type | |
|---|---|---|
| `date` | string |  |
| `today, min, max` | string |  |

Every component also takes `className` and `style`. Most take `state` (`"hover" | "pressed" | "focused" | "disabled"`) to draw a state without a pointer on it.

## Example

```jsx
<Popover><CalendarView date="2026-09-28" today="2026-09-24" /></Popover>
```
