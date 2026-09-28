import * as React from "react";
import { MGRoot, Icon } from "@metalgraphics/frosted-glass";

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

const names = ["chevronRight", "chevronDown", "chevronLeft", "upDown", "checkmark", "folder", "document", "magnifier", "xmark"] as const;
export const Glyphs = () => (
  <Both>
    <Row>
      {names.map((name) => (
        <span key={name} title={name} style={{ width: 30, height: 30, borderRadius: 6, display: "flex", alignItems: "center", justifyContent: "center", background: "var(--mg-color-fill)" }}>
          <Icon name={name} />
        </span>
      ))}
    </Row>
  </Both>
);
export const Tinted = () => (
  <Both>
    <Row>
      <Icon name="folder" style={{ color: "var(--mg-hue-folder)" }} />
      <Icon name="document" color="secondaryLabel" />
      <Icon name="magnifier" color="secondaryLabel" />
      <Icon name="checkmark" color="accent" />
      <Icon name="xmark" color="destructive" />
    </Row>
  </Both>
);
