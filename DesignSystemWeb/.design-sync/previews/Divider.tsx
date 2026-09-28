import * as React from "react";
import { MGRoot, Divider, LabeledContent } from "@metalgraphics/frosted-glass";

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

export const Horizontal = () => (
  <Both>
    <div style={{ width: 220, display: "flex", flexDirection: "column", gap: 8 }}>
      <LabeledContent label="Selection" value="Form" />
      <Divider />
      <LabeledContent label="Items" value="4" />
    </div>
  </Both>
);
export const Vertical = () => (
  <Both>
    <div style={{ display: "flex", gap: 10, height: 20, alignItems: "center" }}>
      <span>Line 42</span>
      <Divider vertical />
      <span>Swift</span>
      <Divider vertical />
      <span>UTF-8</span>
    </div>
  </Both>
);
