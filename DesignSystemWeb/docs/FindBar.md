---
category: Editor
---

# FindBar

The editor's find and replace bar: query with a magnifier, match count, previous and next, the Aa / Word / .* chips, replacement, Replace, All and Done.

Mirrors `FindBar (TextEditor/Chrome/FindBar.swift)` in MetalGraphics.

## Props

| Prop | Type | |
|---|---|---|
| `query, replacement, count` | string |  |
| `caseSensitive, wholeWord, regex` | boolean | The chips' state. |
| `showReplace` | boolean | Default true. |
| `focused` | boolean | Draws the query field focused. |

Every component also takes `className` and `style`. Most take `state` (`"hover" | "pressed" | "focused" | "disabled"`) to draw a state without a pointer on it.

## Example

```jsx
<FindBar query="blurRadius" count="4 of 8" caseSensitive />
```
