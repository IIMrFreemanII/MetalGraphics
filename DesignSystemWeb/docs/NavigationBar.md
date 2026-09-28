---
category: Navigation
---

# NavigationBar

38 tall on the bar tint, a headline title, leading and trailing slots.

Mirrors `Navigation bar (NavigationStack)` in MetalGraphics.

## Props

| Prop | Type | |
|---|---|---|
| `title` | string |  |
| `leading, trailing` | element | Buttons. |

Every component also takes `className` and `style`. Most take `state` (`"hover" | "pressed" | "focused" | "disabled"`) to draw a state without a pointer on it.

## Example

```jsx
<NavigationBar title="Settings" leading={<Button icon="chevronLeft" label="Back" />} trailing={<Button variant="bordered">Share</Button>} />
```
