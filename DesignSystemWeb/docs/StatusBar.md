---
category: Editor
---

# StatusBar

The 24pt line under an editor: caret position, the first problem in the destructive colour, and the file name.

Mirrors `the Editor's status line (Editor/FileEditorPanel.swift)` in MetalGraphics.

## Props

| Prop | Type | |
|---|---|---|
| `position` | string | "Ln 92, Col 45" |
| `problem` | string |  |
| `file` | string |  |

Every component also takes `className` and `style`. Most take `state` (`"hover" | "pressed" | "focused" | "disabled"`) to draw a state without a pointer on it.

## Example

```jsx
<StatusBar position="Ln 92, Col 45" problem="Cannot find 'glassMaterial' in scope" file="Background.swift" />
```
