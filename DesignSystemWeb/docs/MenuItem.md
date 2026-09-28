---
category: Surfaces
---

# MenuItem

An item in a Menu.

Mirrors `Menu item (Picker.swift)` in MetalGraphics.

## Props

| Prop | Type | |
|---|---|---|
| `checked` | boolean |  |
| `shortcut` | string | e.g. "⌘," |
| `state` | "hover" \| "disabled" |  |

Every component also takes `className` and `style`. Most take `state` (`"hover" | "pressed" | "focused" | "disabled"`) to draw a state without a pointer on it.

## Example

```jsx
<Menu>
  <MenuItem shortcut="⌘R">Run</MenuItem>
</Menu>
```
