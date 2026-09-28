import { React, cx, role, type Common } from "../react";
import icons from "../../generated/icons.json";

export type Mode = "light" | "dark" | "system";
export type Surface = "content" | "grouped" | "window" | "card" | "none";

/**
 * Wrap everything in this: it picks light or dark (`mode`; "system" follows the viewer's
 * setting), sets the type and the label colour, and paints a surface under its content.
 * Mirrors `ThemeStore` choosing `Theme.light` or `Theme.dark`.
 */
export function MGRoot({
  mode = "system",
  surface = "none",
  className,
  style,
  children,
}: Common & { mode?: Mode; surface?: Surface }) {
  return (
    <div
      className={cx("mg-root", className)}
      data-mg-theme={mode === "system" ? undefined : mode}
      data-surface={surface === "none" ? undefined : surface}
      style={style}
    >
      {children}
    </div>
  );
}

export type GlassRole = "popover" | "menu" | "tooltip" | "sheet" | "floatingPanel" | "dropMarker" | "bar";

const glassClass = (r: GlassRole) => `mg-glass mg-glass--${r.replace(/[A-Z]/g, (c) => "-" + c.toLowerCase())}`;

/**
 * A frosted glass panel: what is behind it blurred, made more vivid, under the role's tint, with a
 * light rim. Mirrors `.glass(role)`. Glass shows only over something: put it over content.
 */
export function Glass({ role: r = "popover", radius, className, style, children }: Common & { role?: GlassRole; radius?: number }) {
  return (
    <div className={cx(glassClass(r), className)} style={{ borderRadius: radius, ...style }}>
      {children}
    </div>
  );
}

/** The glyphs `ThemeIcon` has, by name. */
export type IconName =
  | "chevronRight"
  | "chevronDown"
  | "chevronLeft"
  | "upDown"
  | "checkmark"
  | "folder"
  | "document"
  | "magnifier"
  | "xmark";

// Fails to compile when ThemeIcon gains or loses a glyph and the union above does not follow.
const glyphs: Record<IconName, string> = icons satisfies Record<IconName, string>;

/** One of the design system's glyphs, at its natural size, in `color` (a role; the text colour by default). Mirrors `ThemeIcon`. */
export function Icon({ name, color, className, style }: { name: IconName; color?: string; className?: string; style?: React.CSSProperties }) {
  return (
    <span
      className={cx("mg-icon", className)}
      aria-hidden="true"
      style={{ color: color ? role(color) : undefined, ...style }}
      dangerouslySetInnerHTML={{ __html: glyphs[name] }}
    />
  );
}

/** A hairline between groups. Mirrors `Divider`. */
export function Divider({ vertical = false, className, style }: { vertical?: boolean; className?: string; style?: React.CSSProperties }) {
  return <hr className={cx("mg-divider", vertical ? "mg-divider--vertical" : "mg-divider--horizontal", className)} style={style} />;
}

/** A scroll bar's thumb: 5 thick, square ends, 2 from the edge. Mirrors `ScrollView`'s indicators. */
export function ScrollIndicator({ length = 60, vertical = true, style }: { length?: number; vertical?: boolean; style?: React.CSSProperties }) {
  const size = vertical ? { width: 5, height: Math.max(length, 20) } : { width: Math.max(length, 20), height: 5 };
  return <div className="mg-scroll-indicator" style={{ ...size, ...style }} />;
}
