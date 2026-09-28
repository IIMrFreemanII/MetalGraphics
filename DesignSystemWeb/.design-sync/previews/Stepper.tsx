import * as React from "react";
import { MGRoot, Stepper, LabeledContent } from "@metalgraphics/frosted-glass";

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

export const InRange = () => (
  <Both>
    <div style={{ display: "flex", gap: 12, alignItems: "center" }}>
      <LabeledContent label="Tab width" value="4" />
      <Stepper defaultValue={4} min={1} max={8} label="Tab width" />
    </div>
  </Both>
);
export const AtMinimum = () => (
  <Both>
    <div style={{ display: "flex", gap: 12, alignItems: "center" }}>
      <LabeledContent label="Retries" value="0" />
      <Stepper defaultValue={0} min={0} label="Retries" />
    </div>
  </Both>
);
