---
category: Foundations
---

# MGRoot

Wrap every artboard's content in it. Picks light or dark, sets JetBrains Mono (with its ligatures) and the label colour, and can paint a surface.

Mirrors `ThemeStore (Theme.light / Theme.dark)` in MetalGraphics.

## Props

| Prop | Type | |
|---|---|---|
| `mode` | "light" \| "dark" \| "system" | "system" follows the viewer's appearance. |
| `surface` | "content" \| "grouped" \| "window" \| "card" \| "none" | The opaque background under the content. |

Every component also takes `className` and `style`. Most take `state` (`"hover" | "pressed" | "focused" | "disabled"`) to draw a state without a pointer on it.

## Example

```jsx
<MGRoot mode="light" surface="window">
  <Button variant="prominent">Run</Button>
</MGRoot>
```
