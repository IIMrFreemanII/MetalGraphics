import * as React from "react";

// Components import React from here. A claude.ai/design bundle maps `react` to the page's React 18,
// so the bundle never carries a copy of its own.
export { React };

/** Class names, skipping the falsy ones. */
export function cx(...names: unknown[]): string {
  return names.filter(Boolean).join(" ");
}

/** `secondaryLabel` → `secondary-label`, as the tokens name their variables. */
export function kebab(name: string): string {
  return name.replace(/([a-z0-9])([A-Z])/g, "$1-$2").replace(/([a-z])([0-9])/g, "$1-$2").toLowerCase();
}

/** A colour role (`"secondaryLabel"`) as its variable. */
export function role(name: string): string {
  return `var(--mg-color-${kebab(name)})`;
}

/** A palette hue (`"badgeStruct"`) as its variable. */
export function hue(name: string): string {
  return `var(--mg-hue-${kebab(name)})`;
}

/** Inline style, as React takes it. */
export type Style = React.CSSProperties;

/** What every component takes: a state to draw it in without a pointer on it, a class, a style. */
export type State = "hover" | "pressed" | "focused" | "disabled";
export interface Common {
  /** Draw a state without a pointer on it, for specs and mocks. */
  state?: State;
  className?: string;
  style?: React.CSSProperties;
  children?: React.ReactNode;
}
