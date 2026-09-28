---
category: Controls
---

# Button

Borderless (an accent label, the default), plain, bordered (a fill) or prominent (the accent). Hover, pressed and disabled follow the Swift faces.

Mirrors `Button with .buttonStyle(.borderless / .plain / .bordered / .borderedProminent), role: .destructive` in MetalGraphics.

## Props

| Prop | Type | |
|---|---|---|
| `variant` | "borderless" \| "plain" \| "bordered" \| "prominent" | The style. |
| `destructive` | boolean | The destructive red. |
| `icon` | Icon name | A glyph before the label. |
| `label` | string | Accessible name, for an icon-only button. |
| `disabled` | boolean | Dims to 0.4. |
| `state` | "hover" \| "pressed" \| "disabled" | Draw a state without a pointer, for specs. |

Every component also takes `className` and `style`. Most take `state` (`"hover" | "pressed" | "focused" | "disabled"`) to draw a state without a pointer on it.

## Example

```jsx
<div style={{ display: "flex", gap: 8 }}>
  <Button variant="bordered">Cancel</Button>
  <Button variant="prominent">Run</Button>
  <Button variant="prominent" destructive>Delete</Button>
</div>
```
