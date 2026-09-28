import * as React from "react";
import { MGRoot, Picker } from "@metalgraphics/frosted-glass";

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

export const Menu = () => (
  <Both>
    <Row>
      <Picker options={["Automatic", "Light", "Dark"]} label="Appearance" />
      <Picker options={["Debug", "Release"]} defaultSelection="Release" label="Configuration" />
    </Row>
  </Both>
);
export const Segmented = () => (
  <Both>
    <Picker pickerStyle="segmented" options={["Day", "Week", "Month"]} defaultSelection="Week" label="Range" />
  </Both>
);
export const Inline = () => (
  <Both>
    <div style={{ width: 220, background: "var(--mg-color-card)", borderRadius: 10, boxShadow: "0 0 0 0.5px var(--mg-color-separator)" }}>
      <Picker pickerStyle="inline" options={["Spaces", "Tabs"]} label="Indent with" />
    </div>
  </Both>
);
export const Pill = () => (
  <Both><Row><Picker options={["Sep 28, 2026"]} chevrons={false} label="Date" /><Picker options={["2:30 PM"]} chevrons={false} label="Time" /></Row></Both>
);
