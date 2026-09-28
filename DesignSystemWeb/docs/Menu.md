---
category: Surfaces
---

# Menu

Menu glass holding MenuItem and MenuSeparator. A hovered item takes the selection colour at radius 5, with an 18-wide check column.

Mirrors `Picker menus, context menus` in MetalGraphics.

## Props

| Prop | Type | |
|---|---|---|
| `label` | string | Accessible name. |

Every component also takes `className` and `style`. Most take `state` (`"hover" | "pressed" | "focused" | "disabled"`) to draw a state without a pointer on it.

## Example

```jsx
<Menu label="Appearance">
  <MenuItem checked>Automatic</MenuItem>
  <MenuItem>Light</MenuItem>
  <MenuSeparator />
  <MenuItem shortcut="⌘,">Settings…</MenuItem>
</Menu>
```
