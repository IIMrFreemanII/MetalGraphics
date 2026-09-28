import * as React from "react";
import { MGRoot, ScrollIndicator } from "@metalgraphics/frosted-glass";

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

export const OverContent = () => (
  <Both>
    <div style={{ position: "relative", width: 220, height: 110, borderRadius: 6, background: "var(--mg-color-content-background)", boxShadow: "0 0 0 0.5px var(--mg-color-separator)", padding: 10, overflow: "hidden" }}>
      {["Theme.swift", "Theme+Presets.swift", "ThemeIcon.swift", "ThemeStore.swift", "AppearanceObserver.swift"].map((f) => (
        <div key={f} style={{ font: "var(--mg-font-callout)", lineHeight: "20px" }}>{f}</div>
      ))}
      <ScrollIndicator length={48} style={{ position: "absolute", right: 2, top: 14 }} />
    </div>
  </Both>
);
export const Horizontal = () => (
  <Both>
    <div style={{ position: "relative", width: 220, height: 30, borderRadius: 6, background: "var(--mg-color-content-background)", boxShadow: "0 0 0 0.5px var(--mg-color-separator)" }}>
      <ScrollIndicator vertical={false} length={90} style={{ position: "absolute", left: 40, bottom: 2 }} />
    </div>
  </Both>
);
