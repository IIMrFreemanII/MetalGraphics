---
category: Forms
---

# Section

A card (radius 10, 0.5 pt hairline) of rows, with a 12 semibold header above and an 11 footer below.

Mirrors `Section` in MetalGraphics.

## Props

| Prop | Type | |
|---|---|---|
| `header` | string |  |
| `footer` | string |  |

Every component also takes `className` and `style`. Most take `state` (`"hover" | "pressed" | "focused" | "disabled"`) to draw a state without a pointer on it.

## Example

```jsx
<Section header="Project">
  <FormRow label="Name"><TextField defaultValue="MetalGraphics" width={200} label="Name" /></FormRow>
</Section>
```
