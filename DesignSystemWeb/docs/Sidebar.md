---
category: Navigation
---

# Sidebar

232 wide on the sidebar tint, inset 10, with a hairline edge. Holds SidebarLinks.

Mirrors `Sidebar(title:), SidebarTitle (Navigation/Sidebar.swift); NavigationSplitView's column` in MetalGraphics.

## Props

| Prop | Type | |
|---|---|---|
| `title` | string | A small section title. |

Every component also takes `className` and `style`. Most take `state` (`"hover" | "pressed" | "focused" | "disabled"`) to draw a state without a pointer on it.

## Example

```jsx
<Sidebar title="Demos">
  <SidebarLink selected>Form</SidebarLink>
  <SidebarLink>Glass</SidebarLink>
</Sidebar>
```
