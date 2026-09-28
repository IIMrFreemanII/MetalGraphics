---
category: Controls
---

# DisclosureGroup

A label with a chevron that turns down and shows its content.

Mirrors `DisclosureGroup` in MetalGraphics.

## Props

| Prop | Type | |
|---|---|---|
| `label` | string |  |
| `defaultExpanded / isExpanded` | boolean |  |

Every component also takes `className` and `style`. Most take `state` (`"hover" | "pressed" | "focused" | "disabled"`) to draw a state without a pointer on it.

## Example

```jsx
<DisclosureGroup label="Advanced" defaultExpanded>
  <LabeledContent label="Configuration" value="Debug" />
</DisclosureGroup>
```
