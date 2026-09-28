---
category: Window
---

# Window

A macOS window as MetalGraphics frames one: the traffic lights in the leading 78pt, and a bar: title (32, centred title), unified (52, a toolbar in the title row), dock (40, the dock's tab row) or none (content under the lights).

Mirrors `a translucent window (Core/TitleBar.swift TitleBarInsets)` in MetalGraphics.

## Props

| Prop | Type | |
|---|---|---|
| `bar` | "title" \| "unified" \| "dock" \| "none" |  |
| `title` | string | For the title bar. |
| `toolbar` | element | What the unified or dock bar holds. |
| `width, height` | number |  |
| `inactive` | boolean | Grey traffic lights. |

Every component also takes `className` and `style`. Most take `state` (`"hover" | "pressed" | "focused" | "disabled"`) to draw a state without a pointer on it.

## Example

```jsx
<Window bar="unified" width={720} height={420} toolbar={<><span style={{ font: "var(--mg-font-headline)" }}>Form</span><span style={{ flex: 1 }} /><Button variant="bordered">Share</Button></>}>
  <Sidebar title="Demos"><SidebarLink selected>Form</SidebarLink></Sidebar>
</Window>
```
