---
category: Controls
---

# DatePicker

A date and time. compact: chevron-less pills that open CalendarView and TimePanel; graphical: the calendar in place with the time pill under it. date is local ISO, "2026-09-28T14:30".

Mirrors `DatePicker (Form/DatePicker.swift)` in MetalGraphics.

## Props

| Prop | Type | |
|---|---|---|
| `label` | string |  |
| `date` | string |  |
| `today, min, max` | string | Today in the accent; days outside min…max faint. |
| `datePickerStyle` | "compact" \| "graphical" |  |
| `showTime` | boolean |  |
| `open` | "date" \| "time" | Which pill is open, for specs. |

Every component also takes `className` and `style`. Most take `state` (`"hover" | "pressed" | "focused" | "disabled"`) to draw a state without a pointer on it.

## Example

```jsx
<DatePicker label="Deadline" date="2026-09-28T14:30" />
```
