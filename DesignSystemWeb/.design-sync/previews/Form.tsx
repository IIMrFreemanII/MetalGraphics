import * as React from "react";
import { MGRoot, Form, Section, FormRow, Toggle, Stepper, Picker, TextField } from "@metalgraphics/frosted-glass";

// Each cell shows light and dark side by side: the design system is drawn in both.
const Both = ({ children, surface = "content", pad = 16 }: { children: React.ReactNode; surface?: "content" | "grouped" | "window" | "wallpaper"; pad?: number }) => (
  <div style={{ display: "flex" }}>
    {(["light", "dark"] as const).map((mode) => (
      <MGRoot
        key={mode}
        mode={mode}
        surface={surface === "wallpaper" ? "none" : surface}
        style={{
          flex: "1 1 0",
          minWidth: 0,
          padding: pad,
          display: "flex",
          flexDirection: "column",
          alignItems: "flex-start",
          gap: 10,
          background:
            surface === "wallpaper"
              ? "radial-gradient(circle at 20% 25%, var(--mg-hue-teal), transparent 55%), radial-gradient(circle at 80% 30%, var(--mg-hue-pink), transparent 50%), radial-gradient(circle at 50% 90%, var(--mg-hue-indigo), transparent 60%), var(--mg-color-window-background)"
              : undefined,
        }}
      >
        {children}
      </MGRoot>
    ))}
  </div>
);
const Row = ({ children }: { children: React.ReactNode }) => <div style={{ display: "flex", gap: 12, alignItems: "center", flexWrap: "wrap" }}>{children}</div>;

export const Settings = () => (
  <Both surface="grouped" pad={0}>
    <Form style={{ alignSelf: "stretch" }}>
      <Section header="Editor" footer="Applies to every open file.">
        <FormRow label="Font size"><Stepper defaultValue={13} label="Font size" /></FormRow>
        <FormRow label="Show line numbers"><Toggle defaultOn label="Show line numbers" /></FormRow>
        <FormRow label="Indent with"><Picker pickerStyle="segmented" options={["Spaces", "Tabs"]} label="Indent with" /></FormRow>
      </Section>
      <Section header="Project">
        <FormRow label="Name"><TextField defaultValue="MetalGraphics" width={170} label="Name" /></FormRow>
        <FormRow label="Location" value="~/xcode-projects" />
      </Section>
    </Form>
  </Both>
);
