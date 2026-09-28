---
category: Editor
---

# CodeEditor

Code as the library's TextEditor draws it: a gutter of line numbers with diagnostic dots and fold chevrons, the current line, selections, search matches, error squiggles and a caret, in the editor theme's colours. Static: it shows the state it is given; lines and columns are 0-based.

Mirrors `TextEditor (TextEditor/View/EditorViews.swift) with EditorTheme` in MetalGraphics.

## Props

| Prop | Type | |
|---|---|---|
| `lines` | { spans?: {text, token?}[], text?, diagnostic?, fold? }[] | token: keyword, type, function, string, number, comment, attribute, directive, variable, constant, … |
| `currentLine` | number |  |
| `selections` | { line, from, to }[] | Columns in characters. |
| `matches` | { line, from, to }[] | Search matches; currentMatch indexes the current one. |
| `squiggles` | { line, from, to, severity? }[] |  |
| `caret` | { line, column } |  |
| `focused` | boolean | Unfocused: inactive selection, no caret. |
| `lineNumbers, folding` | boolean |  |
| `firstLineNumber` | number |  |

Every component also takes `className` and `style`. Most take `state` (`"hover" | "pressed" | "focused" | "disabled"`) to draw a state without a pointer on it.

## Example

```jsx
<CodeEditor currentLine={1} caret={{ line: 1, column: 12 }} lines={[
  { spans: [{ text: "public", token: "keyword" }, { text: " struct " , token: "keyword" }, { text: "Glass", token: "type" }, { text: " {" }] },
  { spans: [{ text: "  let " , token: "keyword" }, { text: "blur = " }, { text: "22", token: "number" }] },
  { text: "}" },
]} />
```
