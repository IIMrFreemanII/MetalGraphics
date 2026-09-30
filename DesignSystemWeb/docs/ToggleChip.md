---
category: Editor
---

# ToggleChip

A small on/off chip, 11.5 semibold on radius 5; on shows the selection behind the accent.

Mirrors `ToggleChip (Form/ToggleChip.swift)` in MetalGraphics.

## Props

| Prop | Type | |
|---|---|---|
| `isOn` | boolean |  |
| `label` | string | Accessible name. |

Every component also takes `className` and `style`. Most take `state` (`"hover" | "pressed" | "focused" | "disabled"`) to draw a state without a pointer on it.

## Example

```jsx
<ToggleChip isOn>Aa</ToggleChip>
```
