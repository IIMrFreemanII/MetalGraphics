import * as React from "react";
import { MGRoot, DatePicker, Popover, CalendarView, TimePanel } from "@metalgraphics/frosted-glass";

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


export const Compact = () => (
  <Both><div style={{ width: 300 }}><DatePicker label="Deadline" date="2026-09-28T14:30" /></div></Both>
);
export const DateOnly = () => (
  <Both><div style={{ width: 300 }}><DatePicker label="Released" date="2026-03-02" showTime={false} /></div></Both>
);
export const Graphical = () => (
  <Both><DatePicker datePickerStyle="graphical" date="2026-09-28T14:30" today="2026-09-24" min="2026-09-03" /></Both>
);
