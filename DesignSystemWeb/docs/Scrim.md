---
category: Surfaces
---

# Scrim

Dims what is behind a sheet or an alert and centres it.

Mirrors `Scrim (Presentation/Surfaces.swift)` in MetalGraphics.

## Props

No props of its own; `className` and `style` place it.

Every component also takes `className` and `style`. Most take `state` (`"hover" | "pressed" | "focused" | "disabled"`) to draw a state without a pointer on it.

## Example

```jsx
<Scrim>
  <Alert title="Discard changes?" actions={[{ label: "Cancel" }, { label: "Discard", variant: "prominent", destructive: true }]} />
</Scrim>
```
