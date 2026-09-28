---
category: Foundations
---

# Icon

The design system's glyphs at their natural size, in the text colour or a role.

Mirrors `ThemeIcon, Image(icon:)` in MetalGraphics.

## Props

| Prop | Type | |
|---|---|---|
| `name` | "chevronRight" \| "chevronDown" \| "chevronLeft" \| "upDown" \| "checkmark" \| "folder" \| "document" \| "magnifier" \| "xmark" | Which glyph. |
| `color` | colour role name | e.g. "secondaryLabel". The text colour when left out. |

Every component also takes `className` and `style`. Most take `state` (`"hover" | "pressed" | "focused" | "disabled"`) to draw a state without a pointer on it.

## Example

```jsx
<Icon name="folder" color="secondaryLabel" />
```
