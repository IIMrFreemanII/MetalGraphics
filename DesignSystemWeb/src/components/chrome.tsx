import { React, cx, type Common } from "../react";

// ── Window chrome ───────────────────────────────────────────────────────

/**
 * The window's close, minimize and zoom buttons: 12pt dots 8 apart, showing ×, − and + when the
 * pointer is over them. Mirrors `DockWindowButton` (and what AppKit draws on a native window).
 */
export function TrafficLights({ state, inactive = false, className, style }: Common & { inactive?: boolean }) {
  return (
    <span className={cx("mg-traffic-lights", className)} data-state={state} data-inactive={inactive ? "" : undefined} style={style}>
      {(["close", "minimize", "zoom"] as const).map((kind) => (
        <span key={kind} className={`mg-traffic-light mg-traffic-light--${kind}`} role="img" aria-label={kind}>
          <svg viewBox="0 0 12 12" width="12" height="12" aria-hidden="true">
            {kind === "close" && <path d="M3.4 3.4 L8.6 8.6 M8.6 3.4 L3.4 8.6" />}
            {kind === "minimize" && <path d="M2.8 6 H9.2" />}
            {kind === "zoom" && <path d="M2.8 6 H9.2 M6 2.8 V9.2" />}
          </svg>
        </span>
      ))}
    </span>
  );
}

export type WindowBar = "title" | "unified" | "dock" | "none";

/**
 * A macOS window, as MetalGraphics frames one. The bar:
 * - `title`: the standard 32pt title bar, the title centred;
 * - `unified`: a 52pt bar sharing the title bar's row (a split view's navigation bar), `toolbar` in it
 *   clear of the traffic lights;
 * - `dock`: the 40pt row a dock area gives the title bar, its tab bar in it;
 * - `none`: content runs under the traffic lights (a sidebar's top).
 * The traffic lights sit in the leading 78pt (`TitleBarInsets.standard`).
 */
export function Window({
  title,
  bar = "title",
  toolbar,
  width,
  height,
  inactive = false,
  state,
  className,
  style,
  children,
}: Common & { title?: string; bar?: WindowBar; toolbar?: React.ReactNode; width?: number; height?: number; inactive?: boolean }) {
  return (
    <div className={cx("mg-window", className)} data-bar={bar} style={{ width, height, ...style }}>
      {bar !== "none" && (
        <div className="mg-window__bar">
          {bar === "title" ? <span className="mg-window__title">{title}</span> : toolbar}
        </div>
      )}
      <TrafficLights className="mg-window__lights" state={state} inactive={inactive} />
      <div className="mg-window__content">{children}</div>
    </div>
  );
}

/** A floating dock panel's own 28pt title bar, the traffic lights at its left. Mirrors `DockTitleBar`. */
export function TitleBar({ title, state, className, style }: Common & { title?: string }) {
  return (
    <div className={cx("mg-title-bar", className)} style={style}>
      <TrafficLights state={state} />
      <span className="mg-title-bar__title">{title}</span>
    </div>
  );
}

// ── Docking ─────────────────────────────────────────────────────────────

/**
 * A dock panel floating over the others: floating-panel glass, radius 7, a hairline, and a grip strip
 * with three dots on top when `grip` is set. Mirrors `DockFloatFill` / `DockFloatBorder`.
 */
export function FloatingPanel({ grip = true, width = 280, height, className, style, children }: Common & { grip?: boolean; width?: number; height?: number }) {
  return (
    <div className={cx("mg-glass mg-glass--floating-panel mg-floating-panel", className)} style={{ width, height, ...style }}>
      {grip && (
        <div className="mg-floating-panel__grip" aria-hidden="true">
          <i />
          <i />
          <i />
        </div>
      )}
      <div className="mg-floating-panel__content">{children}</div>
    </div>
  );
}

export type DropZone = "left" | "right" | "top" | "bottom" | "center";

/**
 * The docking cross shown while a panel is dragged: a 28pt marker per zone, 34 apart, on drop-marker
 * glass with an accent ring and the zone drawn inside; the hovered one filled with the accent.
 * Mirrors `DockDropOverlay`.
 */
export function DropMarkers({ hovered, zones = ["top", "left", "center", "right", "bottom"], className, style }: Common & { hovered?: DropZone; zones?: DropZone[] }) {
  const at: Record<DropZone, [number, number]> = { top: [1, 0], left: [0, 1], center: [1, 1], right: [2, 1], bottom: [1, 2] };
  return (
    <div className={cx("mg-drop-markers", className)} role="group" aria-label="Drop zones" style={style}>
      {zones.map((zone) => (
        <span
          key={zone}
          className={cx("mg-drop-marker", zone !== hovered && "mg-glass mg-glass--drop-marker")}
          data-zone={zone}
          data-hovered={zone === hovered ? "" : undefined}
          style={{ left: at[zone][0] * 34, top: at[zone][1] * 34 }}
        >
          <i />
        </span>
      ))}
    </div>
  );
}

/** Where a dropped panel will land: the accent at 18% with a 2pt ring. Place it over the target area. */
export function DropPreview({ className, style }: Common) {
  return <div className={cx("mg-drop-preview", className)} style={style} />;
}
