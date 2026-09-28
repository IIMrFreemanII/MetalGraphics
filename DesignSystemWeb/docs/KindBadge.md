---
category: Lists
---

# KindBadge

A 16 × 16 tile with a white letter, radius 4 (the Swift code uses 4, not the xs radius of 3).

Mirrors `KindBadge` in MetalGraphics.

## Props

| Prop | Type | |
|---|---|---|
| `letter` | string | C, S, E, P, M, V… |
| `hue` | palette hue name | badgeClass, badgeStruct, badgeEnum, badgeProperty, badgeMethod, badgeVariable, or any hue. |

Every component also takes `className` and `style`. Most take `state` (`"hover" | "pressed" | "focused" | "disabled"`) to draw a state without a pointer on it.

## Example

```jsx
<KindBadge letter="S" hue="badgeStruct" />
```
