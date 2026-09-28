---
category: Window
---

# TrafficLights

Close, minimize and zoom: 12pt dots 8 apart, with ×, − and + on hover. The only literal colours in the system.

Mirrors `DockWindowButton (Docking/DockViews.swift)` in MetalGraphics.

## Props

| Prop | Type | |
|---|---|---|
| `state` | "hover" |  |
| `inactive` | boolean |  |

Every component also takes `className` and `style`. Most take `state` (`"hover" | "pressed" | "focused" | "disabled"`) to draw a state without a pointer on it.

## Example

```jsx
<TrafficLights state="hover" />
```
