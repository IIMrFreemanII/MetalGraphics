import * as React from "react";
import { MGRoot, Window, Sidebar, SidebarLink, Button, LabeledContent } from "@metalgraphics/frosted-glass";

// Each cell shows light and dark side by side: the design system is drawn in both.
const Both = ({ children, surface = "content", pad = 16 }: { children: React.ReactNode; surface?: "content" | "grouped" | "window" | "wallpaper"; pad?: number }) => (
  <div style={{ display: "flex", flexDirection: "column" }}>
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


export const Unified = () => (
  <Both surface="wallpaper">
    <Window bar="unified" width={420} height={200} toolbar={<><span style={{ font: "var(--mg-font-headline)" }}>Form</span><span style={{ flex: 1 }} /><Button variant="bordered">Share</Button></>}>
      <div style={{ padding: 16, display: "flex", flexDirection: "column", gap: 8, flex: 1, background: "var(--mg-color-content-background)" }}>
        <LabeledContent label="Selection" value="Form" />
      </div>
    </Window>
  </Both>
);
export const TitleOnly = () => (
  <Both surface="wallpaper">
    <Window bar="title" title="Settings" width={420} height={140}>
      <div style={{ flex: 1, background: "var(--mg-color-grouped-background)" }} />
    </Window>
  </Both>
);
export const UnderSidebar = () => (
  <Both surface="wallpaper">
    <Window bar="none" width={420} height={180}>
      <Sidebar title="Demos" style={{ width: 170, paddingTop: 36 }}><SidebarLink selected>Form</SidebarLink><SidebarLink>Glass</SidebarLink></Sidebar>
      <div style={{ flex: 1, background: "var(--mg-color-content-background)" }} />
    </Window>
  </Both>
);
