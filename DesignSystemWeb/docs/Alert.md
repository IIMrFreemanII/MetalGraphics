---
category: Surfaces
---

# Alert

An alert: a 260-wide sheet with a centred title, a message and full-width buttons. Actions carry a role (cancel, destructive); the first without one is the default, prominent. More than two stack.

Mirrors `.alert, .confirmationDialog` in MetalGraphics.

## Props

| Prop | Type | |
|---|---|---|
| `layout` | "auto" \| "row" \| "stack" | auto: two actions or fewer side by side (cancel on the left), more stacked (cancel last). |
| `titleVisible` | boolean |  |
| `title` | string |  |
| `message` | string |  |
| `actions` | { label, variant?, destructive? }[] |  |

Every component also takes `className` and `style`. Most take `state` (`"hover" | "pressed" | "focused" | "disabled"`) to draw a state without a pointer on it.

## Example

```jsx
<Alert title="Save changes to “Theme.swift”?" message="Your edits are lost if you don’t save them." actions={[{ label: "Save" }, { label: "Don’t Save", role: "destructive" }, { label: "Cancel", role: "cancel" }]} />
```
