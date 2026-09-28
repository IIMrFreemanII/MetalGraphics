---
category: Docking
---

# FloatingPanel

A dock panel floating over the others: floating-panel glass, radius 7, a hairline, and a 12pt grip strip with three dots.

Mirrors `DockFloatFill / DockFloatBorder (Docking/DockViews.swift)` in MetalGraphics.

## Props

| Prop | Type | |
|---|---|---|
| `grip` | boolean | Default true. |
| `width, height` | number | At least 180 × 110. |

Every component also takes `className` and `style`. Most take `state` (`"hover" | "pressed" | "focused" | "disabled"`) to draw a state without a pointer on it.

## Example

```jsx
<FloatingPanel width={280} height={160}>
  <DockTabBar tabs={[{ title: "Inspector" }]} />
</FloatingPanel>
```
