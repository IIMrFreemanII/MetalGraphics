---
category: Docking
---

# DockTabBar

A tab group's bar. Panel style is 30 tall with 22 pills and 11.5 type; document style is 40 tall with 28 pills, 12.5 type, a document icon and a hairline under the bar. The selected tab is a raised pill; hover shows a close cross.

Mirrors `DockTabsView, DockTabStyle, DockTabMetrics` in MetalGraphics.

## Props

| Prop | Type | |
|---|---|---|
| `tabs` | { title, unsaved?, count? }[] | `unsaved` shows a dot; `count` a warning capsule. |
| `tabStyle` | "panel" \| "document" |  |
| `defaultSelected / selected` | number |  |
| `onSidebar` | boolean | Draw on the sidebar tint. |
| `hovered` | number | A tab to draw hovered, for specs. |

Every component also takes `className` and `style`. Most take `state` (`"hover" | "pressed" | "focused" | "disabled"`) to draw a state without a pointer on it.

## Example

```jsx
<DockTabBar tabStyle="document" tabs={[{ title: "Theme.swift" }, { title: "Button.swift", unsaved: true }]} label="Files" />
```
