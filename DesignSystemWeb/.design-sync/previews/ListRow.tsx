import * as React from "react";
import { MGRoot, ListRow, KindBadge, Icon } from "@metalgraphics/frosted-glass";

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

export const Navigator = () => (
  <Both surface="window" pad={10}>
    <div style={{ width: 230 }}>
      <ListRow label="Sources"><Icon name="folder" style={{ color: "var(--mg-hue-folder)" }} /></ListRow>
      <ListRow label="Theme.swift" indent={16} state="hover"><Icon name="document" color="secondaryLabel" /></ListRow>
      <ListRow label="Theme+Presets.swift" indent={16} selected><Icon name="document" color="secondaryLabel" /></ListRow>
      <ListRow label="ThemeIcon.swift" indent={16}><Icon name="document" color="secondaryLabel" /></ListRow>
    </div>
  </Both>
);
export const Outline = () => (
  <Both surface="window" pad={10}>
    <div style={{ width: 230 }}>
      <ListRow label="Theme"><KindBadge letter="C" hue="badgeClass" /></ListRow>
      <ListRow label="appearance" indent={16} detail="Appearance"><KindBadge letter="P" hue="badgeProperty" /></ListRow>
      <ListRow label="resolve(_:)" indent={16} selected prominent><KindBadge letter="M" hue="badgeMethod" /></ListRow>
      <ListRow label="ThemeColor" ><KindBadge letter="E" hue="badgeEnum" /></ListRow>
      <ListRow label="ThemeColors"><KindBadge letter="S" hue="badgeStruct" /></ListRow>
    </div>
  </Both>
);
export const TwoLineResults = () => (
  <Both surface="window" pad={10}>
    <div style={{ width: 260 }}>
      <ListRow height={38} selected>
        <KindBadge letter="S" hue="badgeStruct" />
        <span style={{ display: "flex", flexDirection: "column" }}>
          <span>ThemeSpacing</span>
          <span style={{ font: "var(--mg-font-subheadline)", color: "var(--mg-color-secondary-label)" }}>Theme.swift:148</span>
        </span>
      </ListRow>
      <ListRow height={38}>
        <KindBadge letter="S" hue="badgeStruct" />
        <span style={{ display: "flex", flexDirection: "column" }}>
          <span>ThemeRadii</span>
          <span style={{ font: "var(--mg-font-subheadline)", color: "var(--mg-color-secondary-label)" }}>Theme.swift:163</span>
        </span>
      </ListRow>
    </div>
  </Both>
);
export const Problems = () => (
  <Both surface="window" pad={10}>
    <div style={{ width: 280 }}>
      <ListRow status="error" label="Cannot find 'glassMaterial' in scope" subtitle="Background.swift:112:54" height={38} spacing={10} state="hover" />
      <ListRow status="warning" label="Variable 'half' was never mutated" subtitle="Graphics2D.swift:1231:9" height={38} spacing={10} />
      <ListRow status="note" label="'regular' declared here" subtitle="Background.swift:95:21" height={38} spacing={10} />
    </div>
  </Both>
);
