---
category: Surfaces
---

# Tooltip

A short label on tooltip glass.

Mirrors `Tooltip(text, multiline:), .help(_:) (Presentation/Tooltip.swift)` in MetalGraphics.

## Props

| Prop | Type | |
|---|---|---|
| `multiline` | boolean | A hover card: several lines, at most 420 wide, radius 8. |

Every component also takes `className` and `style`. Most take `state` (`"hover" | "pressed" | "focused" | "disabled"`) to draw a state without a pointer on it.

## Example

```jsx
<Tooltip>Build and run (⌘R)</Tooltip>
```
