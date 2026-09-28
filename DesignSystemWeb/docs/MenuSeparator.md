---
category: Surfaces
---

# MenuSeparator

A line between groups of menu items.

Mirrors `Menu divider` in MetalGraphics.

## Props

No props of its own; `className` and `style` place it.

Every component also takes `className` and `style`. Most take `state` (`"hover" | "pressed" | "focused" | "disabled"`) to draw a state without a pointer on it.

## Example

```jsx
<Menu>
  <MenuItem>Copy</MenuItem>
  <MenuSeparator />
  <MenuItem>Delete</MenuItem>
</Menu>
```
