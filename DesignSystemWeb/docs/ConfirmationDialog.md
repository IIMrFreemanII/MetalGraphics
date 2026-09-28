---
category: Surfaces
---

# ConfirmationDialog

An alert whose actions always stack, with Cancel added when none is given; the title can be hidden.

Mirrors `.confirmationDialog (PresentationContent.swift)` in MetalGraphics.

## Props

| Prop | Type | |
|---|---|---|
| `title` | string |  |
| `message` | string |  |
| `actions` | { label, role?, variant? }[] |  |
| `titleVisible` | boolean |  |

Every component also takes `className` and `style`. Most take `state` (`"hover" | "pressed" | "focused" | "disabled"`) to draw a state without a pointer on it.

## Example

```jsx
<ConfirmationDialog title="Discard the build log?" actions={[{ label: "Discard", role: "destructive" }, { label: "Keep" }]} />
```
