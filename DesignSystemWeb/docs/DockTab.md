---
category: Docking
---

# DockTab

One tab pill. Normally rendered by DockTabBar.

Mirrors `DockTabItem` in MetalGraphics.

## Props

| Prop | Type | |
|---|---|---|
| `title` | string |  |
| `selected` | boolean |  |
| `tabStyle` | "panel" \| "document" |  |

Every component also takes `className` and `style`. Most take `state` (`"hover" | "pressed" | "focused" | "disabled"`) to draw a state without a pointer on it.

## Example

```jsx
<DockTabBar tabs={[{ title: "Console" }, { title: "Problems", count: 3 }]} defaultSelected={1} label="Panels" />
```
