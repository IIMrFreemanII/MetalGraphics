---
category: Editor
---

# CompletionList

The completion popup on menu glass: a row per candidate with its kind badge, monospaced name and type, the selected one on the accent, and a detail line under a hairline.

Mirrors `the Editor's completion popup (Editor/LanguageAssist.swift CompletionRowView)` in MetalGraphics.

## Props

| Prop | Type | |
|---|---|---|
| `items` | { badge, label, detail? }[] | badge: C, S, E, P, M, V, Pr. |
| `selected` | number |  |
| `footer` | string |  |

Every component also takes `className` and `style`. Most take `state` (`"hover" | "pressed" | "focused" | "disabled"`) to draw a state without a pointer on it.

## Example

```jsx
<CompletionList selected={0} footer="static let ultraThin: GlassMaterial" items={[{ badge: "P", label: "ultraThin", detail: "GlassMaterial" }, { badge: "P", label: "thin", detail: "GlassMaterial" }]} />
```
