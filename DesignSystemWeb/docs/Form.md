---
category: Forms
---

# Form

Settings on the grouped background, in a centred column at most 600 wide with 20 between sections. Contains Section, which contains FormRow.

Mirrors `Form, Section, FormMetrics` in MetalGraphics.

## Props

No props of its own; `className` and `style` place it.

Every component also takes `className` and `style`. Most take `state` (`"hover" | "pressed" | "focused" | "disabled"`) to draw a state without a pointer on it.

## Example

```jsx
<Form>
  <Section header="Editor" footer="Applies to every open file.">
    <FormRow label="Show line numbers"><Toggle defaultOn label="Show line numbers" /></FormRow>
    <FormRow label="Location" value="~/Projects" />
  </Section>
</Form>
```
