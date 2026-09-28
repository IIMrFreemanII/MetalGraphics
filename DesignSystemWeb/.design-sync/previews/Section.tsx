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

export const WithHeaderAndFooter = () => (
  <Both surface="grouped">
    <Section header="Appearance" footer="Follows the system unless set here." style={{ alignSelf: "stretch" }}>
      <FormRow label="Theme"><Picker options={["Automatic", "Light", "Dark"]} label="Theme" /></FormRow>
      <FormRow label="Translucent sidebar"><Toggle defaultOn label="Translucent sidebar" /></FormRow>
    </Section>
  </Both>
);
export const Plain = () => (
  <Both surface="grouped">
    <Section style={{ alignSelf: "stretch" }}>
      <FormRow label="Version" value="1.0 (42)" />
    </Section>
  </Both>
);
