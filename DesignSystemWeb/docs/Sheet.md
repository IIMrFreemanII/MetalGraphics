---
category: Surfaces
---

# Sheet

Sheet glass, radius 12, with the sheet shadow, a headline title, content and trailing actions.

Mirrors `.sheet (Presentation/ModalLayer.swift)` in MetalGraphics.

## Props

| Prop | Type | |
|---|---|---|
| `title` | string |  |
| `actions` | { label, variant?, destructive? }[] | Buttons at the trailing end; bordered unless a variant is given. |
| `width` | number | Default 420. |

Every component also takes `className` and `style`. Most take `state` (`"hover" | "pressed" | "focused" | "disabled"`) to draw a state without a pointer on it.

## Example

```jsx
<Sheet title="Rename file" width={320} actions={[{ label: "Cancel" }, { label: "Rename", variant: "prominent" }]}>
  <TextField defaultValue="Theme.swift" width={280} label="File name" />
</Sheet>
```
