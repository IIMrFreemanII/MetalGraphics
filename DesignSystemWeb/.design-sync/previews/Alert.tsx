import * as React from "react";
import { MGRoot, Popover, Menu, MenuItem, MenuSeparator, Tooltip, Scrim, Sheet, Alert, Button, TextField, LabeledContent } from "@metalgraphics/frosted-glass";

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

export const Confirm = () => (
  <Both surface="wallpaper">
    <Alert title="Delete “Theme.swift”?" message="The file moves to the Trash." actions={[{ label: "Cancel" }, { label: "Delete", variant: "prominent", destructive: true }]} />
  </Both>
);
export const Informational = () => (
  <Both surface="wallpaper">
    <Alert title="Build succeeded" message="MetalGraphics built in 12.4 s." actions={[{ label: "OK", variant: "prominent" }]} />
  </Both>
);
export const Stacked = () => (
  <Both surface="wallpaper">
    <Alert title="Save changes to “Theme.swift”?" message="Your edits are lost if you don’t save them." actions={[{ label: "Save" }, { label: "Don’t Save", role: "destructive" }, { label: "Cancel", role: "cancel" }]} />
  </Both>
);
