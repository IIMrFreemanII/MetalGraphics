---
category: Lists
---

# Table

A header in callout on the bar colour, 1 pt column dividers, cells padded 6/3, and selected rows in the selection colour.

Mirrors `Table, TableRow` in MetalGraphics.

## Props

| Prop | Type | |
|---|---|---|
| `columns` | string[] |  |
| `rows` | string[][] |  |
| `selected` | number[] | Selected row indexes. |

Every component also takes `className` and `style`. Most take `state` (`"hover" | "pressed" | "focused" | "disabled"`) to draw a state without a pointer on it.

## Example

```jsx
<Table columns={["Name", "Kind"]} rows={[["Theme.swift", "Swift"], ["README.md", "Markdown"]]} selected={[0]} />
```
