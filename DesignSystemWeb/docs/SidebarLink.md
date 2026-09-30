---
category: Navigation
---

# SidebarLink

A full-width link, inset 5/10. Selected uses the selection colour and a medium label.

Mirrors `SidebarLink (Navigation/Sidebar.swift); a NavigationLink in a split view's sidebar` in MetalGraphics.

## Props

| Prop | Type | |
|---|---|---|
| `selected` | boolean |  |
| `icon` | Icon name |  |
| `state` | "hover" |  |

Every component also takes `className` and `style`. Most take `state` (`"hover" | "pressed" | "focused" | "disabled"`) to draw a state without a pointer on it.

## Example

```jsx
<Sidebar>
  <SidebarLink icon="folder" selected>Sources</SidebarLink>
</Sidebar>
```
