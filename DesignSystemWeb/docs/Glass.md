---
category: Foundations
---

# Glass

Frosted glass by role: the backdrop blurred and saturated under the role's tint, with a light rim along the top. Only shows over something.

Mirrors `.glass(ThemeMaterial) — Background.swift GlassBackground` in MetalGraphics.

## Props

| Prop | Type | |
|---|---|---|
| `role` | "popover" \| "menu" \| "tooltip" \| "sheet" \| "floatingPanel" \| "dropMarker" \| "bar" | Which material. |
| `radius` | number | Corner radius in px (use 10 for cards and popovers, 12 for sheets). |

Every component also takes `className` and `style`. Most take `state` (`"hover" | "pressed" | "focused" | "disabled"`) to draw a state without a pointer on it.

## Example

```jsx
<Glass role="floatingPanel" radius={10} style={{ padding: 12 }}>
  <LabeledContent label="Line" value="42" />
</Glass>
```
