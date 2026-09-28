---
category: Controls
---

# TextField

A single-line field on the control background with a 0.5 pt border; focused shows a 3.5 pt focus ring.

Mirrors `TextField, SecureField, .leadingIcon` in MetalGraphics.

## Props

| Prop | Type | |
|---|---|---|
| `placeholder` | string |  |
| `defaultValue / value` | string |  |
| `icon` | Icon name | A leading glyph, e.g. "magnifier" for search. |
| `secure` | boolean | A password field. |
| `width` | number | Default 180 (240 in a form row). |
| `state` | "focused" \| "disabled" |  |

Every component also takes `className` and `style`. Most take `state` (`"hover" | "pressed" | "focused" | "disabled"`) to draw a state without a pointer on it.

## Example

```jsx
<TextField icon="magnifier" placeholder="Search" width={220} />
```
