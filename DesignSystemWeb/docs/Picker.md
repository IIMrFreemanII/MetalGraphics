---
category: Controls
---

# Picker

A pop-up button with the accent up-down tile, a segmented control, or inline rows with a check.

Mirrors `Picker with .pickerStyle(.menu / .segmented / .inline)` in MetalGraphics.

## Props

| Prop | Type | |
|---|---|---|
| `chevrons` | boolean | Default true. false gives the plain pill a date picker uses. |
| `options` | string[] |  |
| `defaultSelection / selection` | string |  |
| `pickerStyle` | "menu" \| "segmented" \| "inline" | Default menu. Show the open menu with Menu. |
| `label` | string | Accessible name. |

Every component also takes `className` and `style`. Most take `state` (`"hover" | "pressed" | "focused" | "disabled"`) to draw a state without a pointer on it.

## Example

```jsx
<Picker pickerStyle="segmented" options={["Day", "Week", "Month"]} defaultSelection="Week" label="Range" />
```
