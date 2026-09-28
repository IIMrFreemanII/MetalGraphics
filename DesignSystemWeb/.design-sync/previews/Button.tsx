import * as React from "react";
import { MGRoot, Button } from "@metalgraphics/frosted-glass";

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

const states = [undefined, "hover", "pressed", "disabled"] as const;
const Sweep = ({ variant, label, destructive = false }: { variant: "borderless" | "plain" | "bordered" | "prominent"; label: string; destructive?: boolean }) => (
  <Both>
    <Row>
      {states.map((state) => (
        <Button key={state ?? "normal"} variant={variant} destructive={destructive} state={state}>{label}</Button>
      ))}
    </Row>
  </Both>
);
export const Borderless = () => <Sweep variant="borderless" label="Open…" />;
export const Plain = () => <Sweep variant="plain" label="Clear" />;
export const Bordered = () => <Sweep variant="bordered" label="Build" />;
export const Prominent = () => <Sweep variant="prominent" label="Run" />;
export const Destructive = () => (
  <Both>
    <Row>
      <Button variant="bordered" destructive>Reset</Button>
      <Button variant="prominent" destructive>Delete</Button>
      <Button destructive>Remove</Button>
    </Row>
  </Both>
);
export const WithIcon = () => (
  <Both>
    <Row>
      <Button icon="chevronLeft" label="Back" />
      <Button variant="bordered" icon="magnifier">Find</Button>
      <Button variant="bordered" icon="folder">Open Folder…</Button>
    </Row>
  </Both>
);
