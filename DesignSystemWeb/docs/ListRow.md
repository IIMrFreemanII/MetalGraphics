---
category: Lists
---

# ListRow

A 24-tall row for lists, outlines and navigators. The highlight is inset 8 and the content 8 inside it. Hover uses `hover`; selected uses `selection` and a medium label, or with `prominent` the accent. Children go before the label: a KindBadge or an Icon.

Mirrors `ListRow(label, subtitle:, detail:, status:) (Layout/ListRow.swift)` in MetalGraphics.

## Props

| Prop | Type | |
|---|---|---|
| `subtitle` | string | A second line in the secondary colour (a location); makes a 38-tall row with height={38}. |
| `status` | "error" \| "warning" \| "note" | An 8pt severity square before the content. |
| `label` | string |  |
| `detail` | string | Trailing, in the secondary colour. |
| `selected, prominent` | boolean |  |
| `indent` | number | Leading indent in px, for outline depth. |
| `height` | number | Default 24 (38 for two-line results). |
| `state` | "hover" |  |

Every component also takes `className` and `style`. Most take `state` (`"hover" | "pressed" | "focused" | "disabled"`) to draw a state without a pointer on it.

## Example

```jsx
<ListRow label="Theme" selected>
  <KindBadge letter="C" hue="badgeClass" />
</ListRow>
```
