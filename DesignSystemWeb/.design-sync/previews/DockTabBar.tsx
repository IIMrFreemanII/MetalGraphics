import * as React from "react";
import { MGRoot, DockTabBar, DockTab, DockGap } from "@metalgraphics/frosted-glass";

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

const Frame = ({ children }: { children: React.ReactNode }) => (
  <div style={{ alignSelf: "stretch", borderRadius: 8, overflow: "hidden", boxShadow: "0 0 0 0.5px var(--mg-color-separator)" }}>
    {children}
    <div style={{ height: 28, background: "var(--mg-color-content-background)" }} />
  </div>
);
export const Document = () => (
  <Both surface="window">
    <Frame>
      <DockTabBar tabStyle="document" tabs={[{ title: "Theme.swift" }, { title: "Form.swift", unsaved: true }]} hovered={1} label="Files" />
    </Frame>
  </Both>
);
export const Panel = () => (
  <Both surface="window">
    <Frame>
      <DockTabBar tabs={[{ title: "Console" }, { title: "Problems", count: 3 }, { title: "Outline" }]} defaultSelected={1} hovered={0} label="Panels" />
    </Frame>
  </Both>
);
export const OnSidebar = () => (
  <Both surface="window">
    <div style={{ alignSelf: "stretch", borderRadius: 8, overflow: "hidden", boxShadow: "0 0 0 0.5px var(--mg-color-separator)" }}>
      <DockTabBar onSidebar tabs={[{ title: "Files" }, { title: "Symbols" }]} label="Navigator" />
    </div>
  </Both>
);
