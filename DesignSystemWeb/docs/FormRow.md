---
category: Forms
---

# FormRow

A label on the leading side and a control or value on the trailing side. Hairlines between rows start 14 in.

Mirrors `LabeledContent, or any control in a Section (FormMetrics: inset 9/14)` in MetalGraphics.

## Props

| Prop | Type | |
|---|---|---|
| `label` | string |  |
| `value` | string | A trailing value in the secondary colour. |

Every component also takes `className` and `style`. Most take `state` (`"hover" | "pressed" | "focused" | "disabled"`) to draw a state without a pointer on it.

## Example

```jsx
<FormRow label="Appearance"><Picker options={["Automatic", "Light", "Dark"]} label="Appearance" /></FormRow>
```
