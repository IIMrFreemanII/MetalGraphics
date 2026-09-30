import { React, cx, type Common } from "../react";
import { AnimatedIcon } from "./motion";

export type DockTabStyle = "panel" | "document";

export interface DockTabItem {
  title: string;
  /** Shows a dot: the panel's file is not saved. */
  unsaved?: boolean;
  /** A count capsule on the warning colour: problems, say. */
  count?: number;
}

/**
 * A tab group's bar. `panel` (30 tall, 22 pills) is for tool panels; `document` (40 tall, 28 pills,
 * a document icon, a hairline under the bar) is for an editor's files. `onSidebar` draws it on the
 * sidebar tint. Mirrors `DockTabsView` with `DockTabStyle`.
 */
export function DockTabBar({
  tabs,
  selected: controlled,
  defaultSelected = 0,
  tabStyle = "panel",
  onSidebar = false,
  onSelect,
  onClose,
  hovered,
  label,
  className,
  style,
}: Common & {
  tabs: DockTabItem[];
  selected?: number;
  defaultSelected?: number;
  tabStyle?: DockTabStyle;
  onSidebar?: boolean;
  onSelect?: (index: number) => void;
  onClose?: (index: number) => void;
  /** A tab to draw hovered, for specs. */
  hovered?: number;
  label?: string;
}) {
  const [own, setOwn] = React.useState(defaultSelected);
  const selected = controlled ?? own;
  return (
    <div
      className={cx("mg-dock-bar", `mg-dock-bar--${tabStyle}`, className)}
      role="tablist"
      aria-label={label}
      data-on-sidebar={onSidebar ? "" : undefined}
      style={style}
    >
      {tabs.map((tab, i) => (
        <DockTab
          key={tab.title + i}
          {...tab}
          tabStyle={tabStyle}
          selected={i === selected}
          state={i === hovered ? "hover" : undefined}
          onSelect={() => {
            setOwn(i);
            onSelect?.(i);
          }}
          onClose={onClose ? () => onClose(i) : undefined}
        />
      ))}
    </div>
  );
}

/** One tab pill. Use it inside a `DockTabBar`. */
export function DockTab({
  title,
  unsaved,
  count,
  tabStyle = "panel",
  selected = false,
  onSelect,
  onClose,
  state,
  className,
  style,
}: Common & DockTabItem & { tabStyle?: DockTabStyle; selected?: boolean; onSelect?: () => void; onClose?: () => void }) {
  return (
    <div
      className={cx("mg-dock-tab", className)}
      role="tab"
      tabIndex={selected ? 0 : -1}
      aria-selected={selected}
      data-selected={selected ? "" : undefined}
      data-state={state}
      onClick={onSelect}
      style={style}
    >
      {tabStyle === "document" && <AnimatedIcon glyph="document" size={14} className="mg-dock-tab__icon" />}
      <span className="mg-dock-tab__title">{title}</span>
      {unsaved && <span className="mg-dock-tab__dot" aria-label="Unsaved" />}
      {count !== undefined && count > 0 && <span className="mg-dock-tab__count">{count}</span>}
      <button
        type="button"
        className="mg-dock-tab__close"
        aria-label={`Close ${title}`}
        onClick={(e: any) => {
          e.stopPropagation();
          onClose?.();
        }}
      >
        <AnimatedIcon glyph="xmark" />
      </button>
    </div>
  );
}

/** The 1-point gap between docked panels, on the gap tint. */
export function DockGap({ vertical = true, style }: { vertical?: boolean; style?: React.CSSProperties }) {
  return <div className="mg-dock-gap" style={{ ...(vertical ? { width: 1, alignSelf: "stretch" } : { height: 1 }), ...style }} />;
}
