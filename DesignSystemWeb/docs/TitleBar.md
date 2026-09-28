---
category: Window
---

# TitleBar

A floating dock window's own 28pt title bar on the bar tint: traffic lights on the left, the title centred.

Mirrors `DockTitleBar (Docking/DockViews.swift)` in MetalGraphics.

## Props

| Prop | Type | |
|---|---|---|
| `title` | string |  |
| `state` | "hover" | Shows the lights' glyphs. |

Every component also takes `className` and `style`. Most take `state` (`"hover" | "pressed" | "focused" | "disabled"`) to draw a state without a pointer on it.

## Example

```jsx
<TitleBar title="Inspector" />
```
