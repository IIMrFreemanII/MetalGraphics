import * as React from "react";
import { MGRoot, AnimatedIcon, ListRow, Button, animatedGlyphs, glyphMeta, type AnimatedGlyphName } from "@metalgraphics/frosted-glass";

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


const names = Object.keys(animatedGlyphs) as AnimatedGlyphName[];
const stateful = names.filter((n) => glyphMeta(n)?.state);
// A tile of the template: hover it, press it, click it to change a state it has.
const Tile = ({ name, active }: { name: AnimatedGlyphName; active?: boolean }) => (
  <span data-icon-host="" title={name} style={{ width: 34, height: 34, borderRadius: 7, display: "flex", alignItems: "center", justifyContent: "center", background: "var(--mg-color-fill)", cursor: "pointer" }}>
    <AnimatedIcon glyph={name} trigger={glyphMeta(name)?.state ? "click" : "hover"} active={active} loop={name === "spinner"} scale={1.5} />
  </span>
);

// At rest: hover a tile to play its glyph, click a stateful one to change its state.
export const Glyphs = () => (
  <Both>
    {[0, 16, 32, 48].map((i) => <Row key={i}>{names.slice(i, i + 16).map((n) => <Tile key={n} name={n} />)}</Row>)}
  </Both>
);
// The stateful glyphs held active: turned, open, unlocked, badged, targeted.
export const EndStates = () => (
  <Both>
    <Row>{stateful.slice(0, 16).map((n) => <Tile key={n} name={n} active />)}</Row>
    <Row>{stateful.slice(16).map((n) => <Tile key={n} name={n} active />)}</Row>
  </Both>
);
export const InASidebar = () => (
  <Both surface="window" pad={10}>
    <div style={{ width: 230 }}>
      <ListRow label="Sources" detail="3">
        <AnimatedIcon glyph="chevronRight" trigger="click" active color="secondaryLabel" />
        <AnimatedIcon glyph="folder" trigger="click" active color="folder" />
      </ListRow>
      <ListRow label="Renderer.swift" indent={26} selected><AnimatedIcon glyph="swift" scale={0.9} color="secondaryLabel" /></ListRow>
      <ListRow label="Shaders.metal" indent={26}><AnimatedIcon glyph="langMetal" scale={0.9} color="secondaryLabel" /></ListRow>
      <ListRow label="Resources" detail="12">
        <AnimatedIcon glyph="chevronRight" trigger="click" active={false} color="secondaryLabel" />
        <AnimatedIcon glyph="folder" trigger="click" active={false} color="folder" />
      </ListRow>
    </div>
  </Both>
);
export const InAToolbar = () => (
  <Both>
    <Row>
      <Button variant="plain" label="Toggle sidebar"><AnimatedIcon glyph="sidebarLeft" trigger="click" active={false} scale={1.15} /></Button>
      <Button variant="plain" label="Back"><AnimatedIcon glyph="chevronLeft" scale={1.3} /></Button>
      <Button variant="plain" label="Forward"><AnimatedIcon glyph="chevronRight" scale={1.3} /></Button>
      <Button variant="plain" label="Split right"><AnimatedIcon glyph="splitRight" trigger="click" active={false} scale={1.15} fill="accent" /></Button>
      <Button variant="plain" label="Play"><AnimatedIcon glyph="playPause" trigger="click" active={false} scale={1.15} /></Button>
      <Button variant="plain" label="Notifications"><AnimatedIcon glyph="bell" trigger="click" active scale={1.15} badge="destructive" /></Button>
      <Button variant="plain" label="Lock"><AnimatedIcon glyph="lock" trigger="click" active={false} scale={1.15} /></Button>
      <Button variant="plain" label="Settings"><AnimatedIcon glyph="gear" scale={1.15} /></Button>
    </Row>
    <Row>
      <Button variant="bordered" destructive><AnimatedIcon glyph="trash" />Delete</Button>
      <Button variant="bordered"><AnimatedIcon glyph="copyCheck" trigger="click" active={false} check="success" />Copy path</Button>
      <Button variant="bordered"><AnimatedIcon glyph="refresh" />Refresh</Button>
      <Button variant="prominent"><AnimatedIcon glyph="plus" />New file</Button>
    </Row>
  </Both>
);
export const Problems = () => (
  <Both surface="window" pad={10}>
    <div style={{ width: 280 }}>
      <ListRow label="Cannot find 'device' in scope" detail="42"><AnimatedIcon glyph="error" mount color="destructive" /></ListRow>
      <ListRow label="'scale' was never used" detail="88"><AnimatedIcon glyph="warning" mount color="warning" /></ListRow>
      <ListRow label="Metal 3 features available" detail="1"><AnimatedIcon glyph="note" mount color="accent" /></ListRow>
    </div>
    <span style={{ display: "flex", alignItems: "center", gap: 6, font: "var(--mg-font-callout)", color: "var(--mg-color-secondary-label)" }}>
      <AnimatedIcon glyph="spinner" color="accent" />Checking for changes…
    </span>
  </Both>
);
